# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates an ingestion workflow template. Supports Logic Apps and
    Power Automate Flows.

    .Description
    Generates an ingestion workflow template that will insert or upsert data
    into a Dataverse table. This function will generate a Logic App or Power
    Automate Flow template.

    .Parameter BaseTemplate
    The base template to use for generating the customized workflow.
    Options: LogicApp, Flow.

    .Parameter ParametersFile
    The path to the parameters file (JSON) that will be used to customize the
    parameters in the template.

    .Parameter MappingDefinitionFile
    The path to the mapping definition file (JSON) that will be used to
    customize the mapping between your source data and Dataverse table.

    .Parameter OutputDirectory
    The directory where the ingestion workflow template will be saved. If it
    doesn't exist, it will be created.

    .Parameter UseUpsert
    If set to true, the workflow will upsert records. Otherwise, it will insert
    records.
    Default: true.

    .OUTPUTS
    The generated GUID of the ingestion workflow template.

    .Example
    # Generate a Power Automate workflow template to upsert data.
    New-IngestionWorkflow -BaseTemplate "Flow" -ParametersFile parameters.json -MappingDefinitionFile flow_mapping.json -OutputDirectory output

    .Example
    # Generate a Logic App workflow template to insert data.
    New-IngestionWorkflow -BaseTemplate "LogicApp" -ParametersFile parameters.json -MappingDefinitionFile mapping.json -UseUpsert $false -OutputDirectory output
#>
function New-IngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The base template to use for the workflow. Options: LogicApp, Flow.")]
        [string] $BaseTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the mapping definition file (JSON).")]
        [string] $MappingDefinitionFile,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the workflow template will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $false, HelpMessage = "If true, perform upsert operations.")]
        [bool] $UseUpsert = $true
    )

    $templateGuid = ""
    $baseApp = $BaseTemplate.ToLower()
    if ($baseApp -eq "logicapp") {
        $template = New-LogicAppIngestionWorkflow -ParametersFile $ParametersFile -MappingDefinitionFile $MappingDefinitionFile -UseUpsert $UseUpsert
        $templateName = "ingest_dataverse_workflow"
    }
    elseif ($baseApp -eq "flow") {
        $template = New-FlowIngestionWorkflow -ParametersFile $ParametersFile -MappingDefinitionFile $MappingDefinitionFile -UseUpsert $UseUpsert
        $templateGuid = $template.name
        $templateName = $template.properties.displayName
    }
    else {
        throw "The base template specified is not supported. Please choose from: LogicApp, Flow."
    }

    # Save the workflow template to the output directory. Create directory if it doesn't exist.
    if (!(Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    }
    $template | ConvertTo-Json -Depth 20 | Out-File "$OutputDirectory/$templateName.json"

    return $templateGuid
}

function New-LogicAppIngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the mapping definition file (JSON).")]
        [string] $MappingDefinitionFile,
        [Parameter(Mandatory = $false, HelpMessage = "If true, perform upsert operations.")]
        [bool] $UseUpsert = $true
    )

    $definitionFileSuffix = $(if ($UseUpsert) {"upsert"} else {"insert"})

    $baseTemplate = Get-Content $PSScriptRoot/templates/logicapp_base.json | ConvertFrom-Json
    $parameters = Get-Content $ParametersFile | ConvertFrom-Json
    $mappingDefinition = Get-Content $MappingDefinitionFile | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/ingest/logicapp_dataverse_${definitionFileSuffix}.json | ConvertFrom-Json

    $definition.actions.For_each_item.actions.Ingest_record.inputs.body = $mappingDefinition

    $baseTemplate.parameters = $parameters
    $baseTemplate.definition = $definition

    return $baseTemplate
}

function New-FlowIngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the mapping definition file (JSON).")]
        [string] $MappingDefinitionFile,
        [Parameter(Mandatory = $false, HelpMessage = "If true, perform upsert operations.")]
        [bool] $UseUpsert = $true
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $parameters = Get-Content $ParametersFile | ConvertFrom-Json
    $mappingDefinition = Get-Content $MappingDefinitionFile | ConvertFrom-Json

    $baseTemplate.name = [guid]::NewGuid().ToString()
    $baseTemplate.properties.displayName = "IngestIntoDataverse"

    $hasAlternateKeys = $parameters.alternate_keys?.value.length -gt 0
    $definitionFileSuffix = $(if ($UseUpsert -and $hasAlternateKeys) {"upsert"} else {"insert"})
    $definition = Get-Content $PSScriptRoot/templates/ingest/flow_dataverse_${definitionFileSuffix}.json | ConvertFrom-Json

    if (($null -eq $parameters.plural_table_name?.value) -or ($parameters.plural_table_name.value -eq "")) {
        throw "Parameters file is missing the 'plural_table_name' parameter."
    }
    $mappingDefinition | Add-Member -NotePropertyName entityName -NotePropertyValue $parameters.plural_table_name.value

    if ($UseUpsert) {
        $guidKey = "item/$($parameters.guid_column.value)"

        if ($hasAlternateKeys) {
            $filter = @()
            foreach ($key in $parameters.alternate_keys.value) {
                $quote = if ($key.type -eq "string") {"'"} else {""}
                $filter += "$($key.column) eq $quote@{item()['$($key.property)']}$quote"
            }
            $definition.actions.For_each_item.actions.Find_existing_record.inputs.parameters = @{
                entityName = $parameters.plural_table_name.value
                '$select'  = $parameters.guid_column.value
                '$filter'  = $filter -join " and "
                '$top'     = 1
            }

            # copy the mapping definition and add the primary key
            $updateMappingDefinition = $mappingDefinition.PSObject.Copy()
            $updateMappingDefinition | Add-Member -NotePropertyName recordId -NotePropertyValue "@first(outputs('Find_existing_record')?['body/value'])['$($parameters.guid_column.value)']"
            if ($null -ne $updateMappingDefinition.$guidKey) {
                $updateMappingDefinition.PSObject.Properties.Remove($guidKey)
            }

            $definition.actions.For_each_item.actions.Insert_or_update_record.actions.Update_record.inputs.parameters = $updateMappingDefinition
            $definition.actions.For_each_item.actions.Insert_or_update_record.else.actions.Add_record.inputs.parameters = $mappingDefinition
        }
        else {
            $mappingDefinition | Add-Member -NotePropertyName recordId -NotePropertyValue $mappingDefinition."item/$($parameters.guid_column.value)"
            $mappingDefinition.PSObject.Properties.Remove("item/$($parameters.guid_column.value)")
            $definition.actions.For_each_item.actions.Ingest_record.inputs.parameters = $mappingDefinition
            $definition.actions.For_each_item.actions.Ingest_record.inputs.host.operationId = "UpdateRecord"
        }
    }
    else {
        $definition.actions.For_each_item.actions.Ingest_record.inputs.parameters = $mappingDefinition
    }

    $baseTemplate.properties.definition = $definition
    $baseTemplate.properties.connectionReferences = @{
        shared_commondataserviceforapps = @{
            runtimeSource = "embedded"
            connection    = @{
                connectionReferenceLogicalName = $parameters.connectionReferenceLogicalName.value
            }
            api           = @{
                name = "shared_commondataserviceforapps"
            }
        }
    }

    return $baseTemplate
}

Export-ModuleMember -Function New-IngestionWorkflow
