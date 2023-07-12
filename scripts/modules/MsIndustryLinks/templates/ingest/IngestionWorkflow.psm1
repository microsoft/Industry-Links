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
        [string] $OutputDirectory,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the authentication configuration JSON file.")]
        [string] $AuthConfigFile
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

        $template = New-FlowIngestionWorkflow -DataSinkConfig $workflowConfig.dataSink -AuthConfigFile $AuthConfigFile
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

    $dataSinkType = $DataSinkConfig.type.ToLower()

    $definitionFileSuffix = $(if ($dataSinkType -eq "dataverse") { if ($DataSinkConfig.upsert) { "_upsert" } else { "_insert" } } else { "" })
    $definition = Get-Content "$PSScriptRoot/templates/ingest/$dataSinkType/logicapp_$($dataSinkType)$($definitionFileSuffix).json" | ConvertFrom-Json
    $baseTemplate = Get-Content $PSScriptRoot/templates/logicapp_base.json | ConvertFrom-Json

    switch ($dataSinkType) {
        "customconnector" {
            $apiName = $DataSinkConfig.properties.name
            Set-LogicAppCustomConnectorDataSinkConfiguration -DataSinkConfig $DataSinkConfig -Definition $definition | Out-Null
        }
        "dataverse" {
            $apiName = Get-ApiName -DataSourceType $dataSinkType

            $DataSinkConfig.parameters | Add-Member -NotePropertyName 'organization_url' -NotePropertyValue @{value = "[parameters('organization_url')]" }

            $definition.actions.For_each_item.actions.Ingest_record.inputs.body = $DataSinkConfig.mapping
        }
        default {
            throw "The data sink type, $dataSinkType, is not supported. Please choose from: CustomConnector, Dataverse."
        }
    }

    $dataSinkConnections = @{
        value = @{
            $apiName = @{
                connectionId   = "[resourceId('Microsoft.Web/connections', '$apiName')]"
                connectionName = $apiName
                id             = "[subscriptionResourceId('Microsoft.Web/locations/managedApis', location, '$apiName')]"
            }
        }
    }
    $DataSinkConfig.parameters | Add-Member -NotePropertyName '$connections' -NotePropertyValue $dataSinkConnections
    $baseTemplate.parameters = $DataSinkConfig.parameters
    $baseTemplate.definition = $definition

    return $baseTemplate
}

function Set-LogicAppCustomConnectorDataSinkConfiguration {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data sink workflow configuration object.")]
        [object] $DataSinkConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The workflow definition object.")]
        [object] $Definition
    )

    $apiName = $DataSinkConfig.properties.name
    $method = $DataSinkConfig.properties.method.ToLower()
    $Definition.actions.Ingest_records.inputs.host.connection.name = "@parameters('`$connections')['$apiName']['connectionId']"
    $Definition.actions.Ingest_records.inputs.method = $method
    $Definition.actions.Ingest_records.inputs.path = $DataSinkConfig.properties.path

    if ($null -ne $DataSinkConfig.properties.queries) {
        $Definition.actions.Ingest_records.inputs | Add-Member -MemberType NoteProperty -Name "queries" -Value $DataSinkConfig.properties.queries
    }

    $inputType = $DataSinkConfig.properties.inputType.ToLower()
    switch ($inputType) {
        "array" {
            # Map the data in the select action
            $Definition.actions.Map_data.inputs.select = $DataSinkConfig.mapping

        }
        "object" {
            # Set the data mapping to the body of the ingest action
            $Definition.actions.Ingest_records.inputs.body = $DataSinkConfig.mapping

            # Create new action to iterate over the records and ingest them one at a time
            $forEachAction = @{
                foreach  = "@array(triggerBody()['payload'])"
                actions  = @{ Ingest_record = $definition.actions.Ingest_records }
                runAfter = @{}
                type     = "Foreach"
            }

            # Add the new action to the workflow
            $definition.actions | Add-Member -NotePropertyName "For_each_item" -NotePropertyValue $forEachAction

            # Remove the unused actions to ingest an array of records
            $definition.actions.PSObject.Properties.Remove("Map_data")
            $definition.actions.PSObject.Properties.Remove("Ingest_records")

            # Update the response runAfter actions
            $Definition.actions.For_each_item.actions.Ingest_record.runAfter = @{}
            $Definition.actions.Response.runAfter = @{For_each_item = @("Succeeded") }
            $Definition.actions.Failure_response.runAfter = @{For_each_item = @("TimedOut", "Failed") }

        }
        default {
            throw "The data sink input type, $($DataSinkConfig.inputType), is not supported. Please choose from: Array, Object."
        }
    }
}

function New-FlowIngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data sink workflow configuration object.")]
        [object] $DataSinkConfig,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the authentication configuration JSON file.")]
        [string] $AuthConfigFile
    )

    $dataSink = $DataSinkConfig.type.ToLower()

    # Configure the data sink
    switch ($dataSink) {
        "customconnector" {
            $template = New-FlowCustomConnectorIngestionWorkflow -DataSinkConfig $DataSinkConfig -AuthConfigFile $AuthConfigFile
        }
        "dataverse" {
            $template = New-FlowDataverseIngestionWorkflow -DataSinkConfig $DataSinkConfig
        }
        default {
            throw "The data sink type, $($DataSinkConfig.type), is not supported. Please choose from: CustomConnector, Dataverse."
        }
    }

    $template.name = [guid]::NewGuid().ToString()
    $template.properties.displayName = $DataSinkConfig.name

    return $template
}

function New-FlowCustomConnectorIngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data sink workflow configuration object.")]
        [object] $DataSinkConfig,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the authentication configuration JSON file.")]
        [string] $AuthConfigFile
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/ingest/customconnector/flow_customconnector.json | ConvertFrom-Json

    # Set variables based on whether the custom connector has been certified
    if ($DataSinkConfig.isCertified) {
        $apiId = "/providers/Microsoft.PowerApps/apis/$($DataSinkConfig.connection.apiName)"

        $apiConfig = @{
            name = $DataSinkConfig.connection.apiName
        }

        $connectionReferenceName = "$($DataSinkConfig.connection.apiName)_ref"
    }
    else {
        if ($null -eq $AuthConfigFile -or $AuthConfigFile -eq "") {
            throw "The authentication configuration file (-AuthConfigFile) is required for uncertified custom connectors."
        }

        $apiId = ""

        $authConfig = Get-Content $AuthConfigFile | ConvertFrom-Json
        $connectorIdentifiers = Get-ConnectorIdentifiers -ConnectorId $DataSinkConfig.connection.connectorId -AuthConfig $authConfig

        $apiConfig = $connectorIdentifiers
        $connectionReferenceName = "$($connectorIdentifiers.logicalName)_ref"
    }

    $inputType = $DataSinkConfig.inputType.ToLower()

    $definition.actions.Ingest_records.inputs.host.operationId = $DataSinkConfig.connection.operationId
    $definition.actions.Ingest_records.inputs.host.apiId = $apiId

    # Configure the flow based on whether the custom connector accepts a single record or an array of records
    switch ($inputType) {
        "array" {
            # Parameters are required to pass the data into the custom connector
            $parameters = $DataSinkConfig.parameters
            if ($null -eq $parameters -or 0 -eq @($parameters.psobject.Properties).Count) {
                throw "No parameters were specified for the custom connector data sink."
            }

            # Map the input data to the format of the custom connector API
            $definition.actions.Map_data.inputs.select = $DataSinkConfig.mapping

            # The parameters are stored in the configuration file to ensure the input attribute is correctly set
            $definition.actions.Ingest_records.inputs.parameters = $parameters

            # Update the runAfter properties
            $definition.actions.Ingest_records.runAfter = @{Map_data = @("Succeeded") }
            $definition.actions.Flow_output.runAfter = @{Ingest_records = @("Succeeded") }
        }
        "object" {
            # Set the input parameters to the sink mapping. This ensures the input object attributes are set to what the API is expecting.
            $definition.actions.Ingest_records.inputs.parameters = $DataSinkConfig.mapping

            # Create new action to iterate over the records and ingest them one at a time
            $forEachAction = @{
                foreach  = "@array(json(triggerBody()['payload']))"
                actions  = @{ Ingest_record = $definition.actions.Ingest_records }
                runAfter = @{}
                type     = "Foreach"
            }

            # Add the new action to the workflow
            $definition.actions | Add-Member -NotePropertyName "For_each_item" -NotePropertyValue $forEachAction

            # Remove the unused actions to ingest an array of records
            $definition.actions.PSObject.Properties.Remove("Map_data")
            $definition.actions.PSObject.Properties.Remove("Ingest_records")

            # Update the runAfter property of the Flow output action
            $definition.actions.Flow_output.runAfter = @{For_each_item = @("Succeeded") }
        }
        default {
            throw "The input type, $($DataSinkConfig.inputType), is not supported. Please choose from: Array, Object."
        }
    }

    $baseTemplate.properties.definition = $definition
    $baseTemplate.properties.connectionReferences = @{
        customconnector = @{
            runtimeSource = "embedded"
            connection    = @{
                connectionReferenceLogicalName = $connectionReferenceName
            }
            api           = $apiConfig
        }
    }

    return $baseTemplate
}

function New-FlowDataverseIngestionWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data sink workflow configuration object.")]
        [object] $DataSinkConfig
    )

    $useUpsert = $DataSinkConfig.upsert
    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $parameters = $DataSinkConfig.parameters
    $mappingDefinition = $DataSinkConfig.mapping

    $hasAlternateKeys = $parameters.alternate_keys?.value.length -gt 0
    $definitionFileSuffix = $(if ($useUpsert -and $hasAlternateKeys) { "upsert" } else { "insert" })
    $definition = Get-Content $PSScriptRoot/templates/ingest/dataverse/flow_dataverse_${definitionFileSuffix}.json | ConvertFrom-Json

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
