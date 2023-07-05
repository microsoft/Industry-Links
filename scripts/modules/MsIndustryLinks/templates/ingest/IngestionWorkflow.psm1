# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates an ingestion workflow template. Supports Logic Apps and
    Power Automate Flows.

    .Description
    Generates an ingestion workflow template that will insert or upsert data
    into a Dataverse table. This function will generate a Logic App or Power
    Automate Flow template. Specify the workflow type (Flow or LogicApp)
    in the workflow configuration file.

    .Parameter WorkflowConfigFile
    The workflow configuration file that defines the trigger, the data
    source, the data sink and any transformations that will be applied.

    .Parameter OutputDirectory
    The directory where the ingestion workflow template will be saved. If it
    doesn't exist, it will be created.

    .OUTPUTS
    A Hashtable containing the name and GUID of the workflow template.

    .Example
    # Generate a workflow template to ingest data.
    New-IngestionWorkflow -WorkflowConfigFile workflow.json -OutputDirectory output
#>
function New-IngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the workflow configuration JSON file.")]
        [string] $WorkflowConfigFile,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the workflow template will be saved.")]
        [string] $OutputDirectory
    )

    $workflowConfig = Get-Content $WorkflowConfigFile | ConvertFrom-Json
    $workflowType = $workflowConfig.workflowType.ToLower()

    if ($null -eq $workflowConfig.dataSink -or 0 -eq @($workflowConfig.dataSink.psobject.Properties).Count) {
        throw "No data sink was specified. Please specify a data sink."
    }

    $templateGuid = ""
    if ($workflowType -eq "logicapp") {
        $template = New-LogicAppIngestionWorkflow -DataSinkConfig $workflowConfig.dataSink
        $templateName = "$($workflowConfig.name)_Sink"
    }
    elseif ($workflowType -eq "flow") {
        if ($null -eq $workflowConfig.dataSink.name -or "" -eq $workflowConfig.dataSink.name) {
            throw "No data sink workflow name was specified. Please specify a name."
        }

        $template = New-FlowIngestionWorkflow -DataSinkConfig $workflowConfig.dataSink
        $templateGuid = $template.name
        $templateName = $template.properties.displayName
    }
    else {
        throw "The workflow type, $($workflowConfig.workflowType), is not supported. Please choose from: Flow, LogicApp."
    }

    # Save the workflow template to the output directory. Create directory if it doesn't exist.
    if (!(Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    }
    $template | ConvertTo-Json -Depth 20 | Out-File "$OutputDirectory/$templateName.json"

    return @{
        name = $templateName
        guid = $templateGuid
    }
}

function New-LogicAppIngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data sink workflow configuration object.")]
        [object] $DataSinkConfig
    )

    $definitionFileSuffix = $(if ($DataSinkConfig.upsert) { "upsert" } else { "insert" })

    $baseTemplate = Get-Content $PSScriptRoot/templates/logicapp_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/ingest/logicapp_dataverse_${definitionFileSuffix}.json | ConvertFrom-Json

    $definition.actions.For_each_item.actions.Ingest_record.inputs.body = $DataSinkConfig.mapping

    $dataSinkConnections = @{
        value = @{
            commondataservice = @{
                connectionId   = "[resourceId('Microsoft.Web/connections', 'commondataservice')]"
                connectionName = "commondataservice"
                id             = "[subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'commondataservice')]"
            }
        }
    }
    $DataSinkConfig.parameters | Add-Member -NotePropertyName '$connections' -NotePropertyValue $dataSinkConnections
    $DataSinkConfig.parameters | Add-Member -NotePropertyName 'organization_url' -NotePropertyValue @{value = "[parameters('organization_url')]"}
    $baseTemplate.parameters = $DataSinkConfig.parameters
    $baseTemplate.definition = $definition

    return $baseTemplate
}

function New-FlowIngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data sink workflow configuration object.")]
        [object] $DataSinkConfig
    )

    $useUpsert = $DataSinkConfig.upsert
    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $parameters = $DataSinkConfig.parameters
    $mappingDefinition = $DataSinkConfig.mapping

    $baseTemplate.name = [guid]::NewGuid().ToString()
    $baseTemplate.properties.displayName = $DataSinkConfig.name

    $hasAlternateKeys = $parameters.alternate_keys?.value.length -gt 0
    $definitionFileSuffix = $(if ($useUpsert -and $hasAlternateKeys) { "upsert" } else { "insert" })
    $definition = Get-Content $PSScriptRoot/templates/ingest/flow_dataverse_${definitionFileSuffix}.json | ConvertFrom-Json

    if (($null -eq $parameters.plural_table_name?.value) -or ($parameters.plural_table_name.value -eq "")) {
        throw "Parameters file is missing the 'plural_table_name' parameter."
    }
    $mappingDefinition | Add-Member -NotePropertyName entityName -NotePropertyValue $parameters.plural_table_name.value

    if ($useUpsert) {
        $guidKey = "item/$($parameters.guid_column.value)"

        if ($hasAlternateKeys) {
            $filter = @()
            foreach ($key in $parameters.alternate_keys.value) {
                $quote = if ($key.type -eq "string") { "'" } else { "" }
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
                connectionReferenceLogicalName = "shared_commondataserviceforapps_ref"
            }
            api           = @{
                name = "shared_commondataserviceforapps"
            }
        }
    }

    return $baseTemplate
}

Export-ModuleMember -Function New-IngestionWorkflow
