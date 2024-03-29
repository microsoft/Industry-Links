# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates a workflow template that defines the trigger, the data
    source and any workflows called by this workflow. Supports Power
    Automate Flows and Logic App.

    .Description
    Generates a workflow template that defines the trigger, the data
    source and any workflows called by this workflow. This function
    will generate a Power Automate Flow or Logic App template.

    .Parameter WorkflowConfigFile
    The workflow configuration file that defines the trigger, the data
    source, the data sink and any transformations that will be applied.

    .Parameter TemplateDirectory
    The directory containing the workflow templates and where the data
    source workflow template will be saved.

    .Parameter WorkflowGuids
    The mapping of workflow templates to GUIDs. If not provided, the
    workflow GUIDs will be retrieved from each workflow template
    in the template directory.

    .Parameter AuthConfigFile
    The path to the authentication configuration JSON file. This file is only
    required if the data source is a non-certified custom connector. Provide
    the tenantId, clientId, clientSecret, and orgWebApiUrl for the service
    principal that will be used to authenticate with the Dataverse API.

    .Example
    # Generate a workflow template with Azure Blob Storage as the data source.
    New-DataSourceWorkflow -WorkflowConfigFile workflow.json -TemplateDirectory templates

    # Generate a workflow template with a non-certified custom connector as the data source.
    New-DataSourceWorkflow -WorkflowConfigFile workflow.json -TemplateDirectory templates -AuthConfigFile auth.json
#>
function New-DataSourceWorkflow {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the workflow configuration JSON file.")]
        [string] $WorkflowConfigFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the directory that contains the workflow templates.")]
        [string] $TemplateDirectory,
        [Parameter(Mandatory = $false, HelpMessage = "The mapping of workflow templates to GUIDs.")]
        [hashtable] $WorkflowGuids,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the authentication configuration JSON file.")]
        [string] $AuthConfigFile
    )

    $workflowConfig = Get-Content $WorkflowConfigFile | ConvertFrom-Json
    $workflowType = $workflowConfig.workflowType.ToLower()

    if ($workflowType -eq "logicapp") {
        $template = Get-LogicAppDataSourceWorkflow -WorkflowConfig $workflowConfig
        $templateFilename = $workflowConfig.name
    }
    elseif ($workflowType -eq "flow") {
        if ($null -eq $WorkflowGuids -or $WorkflowGuids.Count -eq 0) {
            $WorkflowGuids = Get-WorkflowGuidMap -TemplateDirectory $TemplateDirectory -WorkflowConfig $workflowConfig
        }
        $template = Get-FlowDataSourceWorkflow -WorkflowConfig $workflowConfig -WorkflowGuids $WorkflowGuids -AuthConfigFile $AuthConfigFile
        $templateFilename = $template.properties.displayName
    }
    else {
        throw "The workflow type, $($workflowConfig.workflowType), is not supported. Please choose from: Flow."
    }

    if (!(Test-Path $TemplateDirectory)) {
        New-Item -ItemType Directory -Force -Path $TemplateDirectory | Out-Null
    }
    $template | ConvertTo-Json -Depth 20 | Out-File "$TemplateDirectory/$templateFilename.json"
}

function Get-FlowDataSourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The mapping of workflow templates to GUIDs.")]
        [hashtable] $WorkflowGuids,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the authentication configuration JSON file.")]
        [string] $AuthConfigFile
    )

    $dataSource = $WorkflowConfig.dataSource.type.ToLower()
    $workflowName = $WorkflowConfig.dataSource.name
    $triggerType = $WorkflowConfig.trigger.type.ToLower()

    # Configure the data source
    switch ($dataSource) {
        "azureblobstorage" {
            $template = Get-FlowAzureBlobStorageDatasourceWorkflow -WorkflowConfig $WorkflowConfig -WorkflowGuids $WorkflowGuids
            $triggerType = "datasource"
        }
        "customconnector" {
            $template = Get-FlowCustomConnectorDatasourceWorkflow -WorkflowConfig $WorkflowConfig -WorkflowGuids $WorkflowGuids -AuthConfigFile $AuthConfigFile
        }
        "dataverse" {
            $template = Get-FlowDataverseDatasourceWorkflow -WorkflowConfig $WorkflowConfig -WorkflowGuids $WorkflowGuids
        }
        "eventhub" {
            $template = Get-FlowEventHubDataSourceWorkflow -WorkflowConfig $WorkflowConfig -WorkflowGuids $WorkflowGuids
            $triggerType = "datasource"
        }
        default {
            throw "The data source, $($WorkflowConfig.dataSource.type), is not supported. Please choose from: AzureBlobStorage, CustomConnector."
        }
    }

    # Set the ID and name of the workflow
    $template.name = [guid]::NewGuid().ToString()
    if ($null -ne $workflowName -and $workflowName -ne "") {
        $template.properties.displayName = $workflowName
    }
    else {
        $template.properties.displayName = "GetDataFrom$dataSource"
    }

    # Configure the trigger
    # By default, the flow configuration is set to manual
    if ($triggerType -eq "scheduled") {
        $validFrequency = @("Second", "Minute", "Hour", "Day", "Week", "Month")

        $interval = $WorkflowConfig.trigger.parameters.interval
        $frequency = $WorkflowConfig.trigger.parameters.frequency

        if ($frequency -notin $validFrequency) {
            throw "The frequency specified is not valid. Please choose from: $validFrequency"
        }

        $template.properties.definition.triggers = @{
            Recurrence = @{
                type       = "Recurrence"
                recurrence = @{
                    frequency = $frequency
                    interval  = $interval
                }
            }
        }
    }
    elseif ($triggerType -eq "datasource") {
        # Nothing to do, configured with data source
    }
    elseif ($triggerType -ne "manual") {
        throw "The trigger type, $($WorkflowConfig.trigger.type), is not valid. Please choose from: Manual, Scheduled."
    }

    return $template
}

function Get-FlowCustomConnectorDatasourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The mapping of workflow templates to GUIDs.")]
        [hashtable] $WorkflowGuids,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the authentication configuration JSON file.")]
        [string] $AuthConfigFile
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/data_source/customconnector/flow_customconnector.json | ConvertFrom-Json
    $dataSourceConfig = $WorkflowConfig.dataSource

    # Set variables based on whether the custom connector has been certified
    if ($dataSourceConfig.isCertified) {
        $definition.actions.Retrieve_data_using_custom_connector.inputs.host.apiId = "/providers/Microsoft.PowerApps/apis/$($dataSourceConfig.connection.apiName)"

        $apiConfig = @{
            name = $dataSourceConfig.connection.apiName
        }

        $connectionReferenceName = "$($dataSourceConfig.connection.apiName)_ref"
    }
    else {
        if ($null -eq $AuthConfigFile -or $AuthConfigFile -eq "") {
            throw "The authentication configuration file (-AuthConfigFile) is required for uncertified custom connectors."
        }

        $authConfig = Get-Content $AuthConfigFile | ConvertFrom-Json
        $connectorIdentifiers = Get-ConnectorIdentifier -ConnectorId $dataSourceConfig.connection.connectorId -AuthConfig $authConfig

        $apiConfig = $connectorIdentifiers

        $connectionReferenceName = "$($connectorIdentifiers.logicalName)_ref"
    }

    # Update the connector operation ID
    $definition.actions.Retrieve_data_using_custom_connector.inputs.host.operationId = $dataSourceConfig.connection.operationId

    # Add the custom connector parameters if they exist
    if ($null -ne $dataSourceConfig.parameters) {
        $definition.actions.Retrieve_data_using_custom_connector.inputs.parameters = $dataSourceConfig.parameters
    }

    # Update Dataverse ingestion sub-workflow configuration
    $dataSinkWorkflowGuid = $WorkflowGuids[$WorkflowConfig.dataSink.name]
    $definition.actions.Ingest_data_subflow.inputs.host.workflowReferenceName = $dataSinkWorkflowGuid

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

function Get-FlowAzureBlobStorageDatasourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The mapping of workflow templates to GUIDs.")]
        [hashtable] $WorkflowGuids
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/data_source/azureblobstorage/flow_azureblobstorage.json | ConvertFrom-Json
    $dataSourceConfig = $WorkflowConfig.dataSource

    # Update the Azure Blob Storage parameters
    $definition.triggers.When_a_file_is_added_or_modified.recurrence = $WorkflowConfig.trigger.parameters
    $definition.triggers.When_a_file_is_added_or_modified.inputs.parameters = $dataSourceConfig.parameters
    $definition.actions.Get_modified_file_content_using_path.inputs.parameters.dataset = $dataSourceConfig.parameters.dataset

    # Update data transformation sub-workflow configuration
    $transformWorkflowGuid = $WorkflowGuids[$WorkflowConfig.dataTransform.name]
    $definition.actions.Transform_data_subflow.inputs.host.workflowReferenceName = $transformWorkflowGuid

    # Update data ingestion sub-workflow configuration
    $dataSinkWorkflowGuid = $WorkflowGuids[$WorkflowConfig.dataSink.name]
    $definition.actions.Ingest_data_subflow.inputs.host.workflowReferenceName = $dataSinkWorkflowGuid

    $baseTemplate.properties.definition = $definition
    $baseTemplate.properties.connectionReferences = @{
        shared_azureblob = @{
            runtimeSource = "embedded"
            connection    = @{
                connectionReferenceLogicalName = "shared_azureblob_ref"
            }
            api           = @{
                name = "shared_azureblob"
            }
        }
    }

    return $baseTemplate
}

function Get-FlowDataverseDatasourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The mapping of workflow templates to GUIDs.")]
        [hashtable] $WorkflowGuids
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/data_source/dataverse/flow_dataverse.json | ConvertFrom-Json
    $parameters = $WorkflowConfig.dataSource.parameters

    if (($null -eq $parameters.entityName) -or ($parameters.entityName -eq "")) {
        throw "Parameters file is missing the 'entityName' parameter."
    }

    # Update the Dataverse parameters
    $definition.actions.Retrieve_data_from_Dataverse.inputs.parameters = $parameters

    # Update data ingestion sub-workflow configuration
    $dataSinkWorkflowGuid = $WorkflowGuids[$WorkflowConfig.dataSink.name]
    $definition.actions.Ingest_data_subflow.inputs.host.workflowReferenceName = $dataSinkWorkflowGuid

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

function Get-FlowEventHubDataSourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The mapping of workflow templates to GUIDs.")]
        [hashtable] $WorkflowGuids
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/data_source/eventhub/flow_eventhub.json | ConvertFrom-Json
    $dataSourceConfig = $WorkflowConfig.dataSource

    $definition.triggers.When_events_are_available_in_Event_Hub.recurrence = $WorkflowConfig.trigger.parameters
    $definition.triggers.When_events_are_available_in_Event_Hub.inputs.parameters = $dataSourceConfig.parameters

    # Update data ingestion sub-workflow configuration
    $dataSinkWorkflowGuid = $WorkflowGuids[$WorkflowConfig.dataSink.name]
    $definition.actions.Ingest_data_subflow.inputs.host.workflowReferenceName = $dataSinkWorkflowGuid

    $baseTemplate.properties.definition = $definition
    $baseTemplate.properties.connectionReferences = @{
        shared_eventhubs = @{
            runtimeSource = "embedded"
            connection    = @{
                connectionReferenceLogicalName = "shared_eventhubs_ref"
            }
            api           = @{
                name = "shared_eventhubs"
            }
        }
    }

    return $baseTemplate
}

function Get-LogicAppDataSourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/logicapp_base.json | ConvertFrom-Json

    $dataSourceType = $WorkflowConfig.dataSource.type.ToLower()
    $isCustomConnector = "customconnector" -eq $dataSourceType

    # Set the workflow parameters for the data source
    $dataSourceParameters = $WorkflowConfig.dataSource.parameters

    if ($isCustomConnector) {
        $apiName = $WorkflowConfig.dataSource.properties.name
        $apiId = Get-LogicAppApiId -DataSourceType $dataSourceType -ApiName $apiName -IsCustomConnectorCertified $WorkflowConfig.dataSource.isCertified
    }
    else {
        $apiName = Get-ApiName -DataSourceType $dataSourceType
        $apiId = Get-LogicAppApiId -DataSourceType $dataSourceType -ApiName $apiName
    }

    $dataSourceConnections = @{
        value = @{
            $apiName = @{
                connectionId         = "[resourceId('Microsoft.Web/connections', '$apiName')]"
                connectionName       = $apiName
                connectionProperties = Get-ConnectionProperty -DataSourceType $dataSourceType
                id                   = $apiId
            }
        }
    }

    if ($null -eq $dataSourceParameters) {
        $baseTemplate.parameters | Add-Member -MemberType NoteProperty -Name '$connections' -Value $dataSourceConnections
    }
    else {
        $dataSourceParameters | Add-Member -MemberType NoteProperty -Name '$connections' -Value $dataSourceConnections
        $baseTemplate.parameters = $dataSourceParameters
    }

    # Set the custom connector properties if data source is CustomConnector
    $definition = Get-Content $PSScriptRoot/templates/data_source/$dataSourceType/logicapp_$dataSourceType.json | ConvertFrom-Json
    if ($isCustomConnector) {
        Add-LogicAppCustomConnectorConfiguration -WorkflowConfig $WorkflowConfig -Definition $definition | Out-Null
    }

    # Set the Dataverse queries if defined in the workflow configuration
    if ($null -ne $WorkflowConfig.dataSource.queries -and $dataSourceType -eq "dataverse") {
        $definition.actions.Retrieve_data_from_Dataverse.inputs | Add-Member -MemberType NoteProperty -Name "queries" -Value $WorkflowConfig.dataSource.queries
    }

    # Add data transform action if defined in the workflow configuration
    if ($null -ne $WorkflowConfig.dataTransform.type) {
        Add-LogicAppTransformConfiguration -WorkflowConfig $WorkflowConfig -Definition $definition | Out-Null
    }

    # Set the data sink workflow ID
    $definition.actions.Ingest_data_subflow.inputs.host.workflow.id = "[resourceId('Microsoft.Logic/workflows', '$($WorkflowConfig.name)_Sink')]"

    # Configure the trigger
    Add-Trigger -WorkflowConfig $WorkflowConfig -Definition $definition | Out-Null

    $baseTemplate.definition = $definition

    return $baseTemplate
}

function Get-ConnectorIdentifier {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The custom connector GUID.")]
        [string] $ConnectorId,
        [Parameter(Mandatory = $true, HelpMessage = "The authentication configuration object.")]
        [object] $AuthConfig
    )

    $orgWebApiUrl = $AuthConfig.orgWebApiUrl

    try {
        # Get authentication token to access the Dataverse Web API
        $tokenUrl = "https://login.microsoftonline.com/$($AuthConfig.tenantId)/oauth2/v2.0/token"
        $authHeaders = @{
            "Content-Type" = "application/x-www-form-urlencoded"
        }

        $authBody =
        @{
            client_id     = $AuthConfig.clientId
            client_secret = $AuthConfig.clientSecret
            scope         = "$orgWebApiUrl/.default"
            grant_type    = 'client_credentials'
        }

        $authResponse = Invoke-WebRequest -Method Post -Uri $tokenUrl -Headers $authHeaders -Body $authBody -ErrorAction Stop
        $accessToken = ($authResponse.Content | ConvertFrom-Json).access_token
    }
    catch {
        throw "An error occurred while retrieving the access token. Error: $($_.Exception.Message)"
    }

    try {
        # Query custom connector config using the connector ID using the Dataverse Web API
        $uriConnectorFilter = '$select=name,connectorinternalid'
        $uri = "$orgWebApiUrl/api/data/v9.2/connectors($ConnectorId)?$($uriConnectorFilter)"
        $reqHeaders = @{
            "Authorization" = "Bearer $accessToken"
            "Content-Type"  = "application/json"
        }

        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $reqHeaders -ErrorAction Stop

        return @{
            name        = $response.connectorinternalid
            logicalName = $response.name
        }
    }
    catch {
        throw "An error occurred while retrieving the custom connector identifiers from Dataverse. Error: $($_.Exception.Message)"
    }
}

function Get-WorkflowGuidMap {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the directory that contains the workflow templates.")]
        [string] $TemplateDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig
    )

    $workflowGuids = @{}
    $templatePaths = Get-ChildItem -Path $TemplateDirectory -Filter "*.json"
    foreach ($templatePath in $templatePaths) {
        $template = Get-Content $templatePath | ConvertFrom-Json

        if ($null -ne $template.name) {
            try {
                $workflowName = $template.properties.displayName
            }
            catch {
                $workflowName = $templatePath.BaseName
            }

            $workflowGuids[$workflowName] = $template.name
        }
    }

    # Validate the workflow template files exist and are populated with a GUID
    $templates = "dataTransform", "dataSink"
    foreach ($template in $templates) {
        if ($null -eq $WorkflowConfig.$template -or $null -eq $WorkflowConfig.$template.name) {
            continue
        }

        $workflowName = $WorkflowConfig.$template.name
        if ($null -eq $workflowGuids[$workflowName]) {
            throw "No GUID found for the workflow, $workflowName."
        }
    }

    return $workflowGuids
}

function Get-ApiName {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data source type.")]
        [string] $DataSourceType
    )

    switch ($DataSourceType.ToLower()) {
        "azureblobstorage" {
            return "azureblob"
        }
        "dataverse" {
            return "commondataservice"
        }
        "eventhub" {
            return "eventhubs"
        }
        default {
            throw "The connection type, $DataSourceType, is not supported."
        }
    }
}

function Get-LogicAppApiId {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data source type.")]
        [string] $DataSourceType,
        [Parameter(Mandatory = $true, HelpMessage = "The API name.")]
        [string] $ApiName,
        [Parameter(Mandatory = $false, HelpMessage = "If the data source is a custom connector, is it certified.")]
        [bool] $IsCustomConnectorCertified
    )

    $dataSource = $DataSourceType.ToLower()
    if ($dataSource -eq "customconnector" -and !($IsCustomConnectorCertified)) {
        return "[resourceId('Microsoft.Web/customApis', '$ApiName')]"
    }
    return "[subscriptionResourceId('Microsoft.Web/locations/managedApis', parameters('location'), '$apiName')]"
}

function Get-ConnectionProperty {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data source type.")]
        [string] $DataSourceType
    )

    $managedIdentitySources = @("azureblobstorage", "eventhub")
    if ($DataSourceType.ToLower() -in $managedIdentitySources) {
        return @{
            authentication = @{
                identity = "[format('{0}', resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', parameters('managedIdentityName')))]"
                type     = "ManagedServiceIdentity"
            }
        }
    }

    return @{}
}

function Get-TransformDataSubflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow's name.")]
        [string] $WorkflowName,
        [Parameter(Mandatory = $true, HelpMessage = "The subflow input value.")]
        [string] $Text,
        [Parameter(Mandatory = $true, HelpMessage = "The subflow runAfter value")]
        [object] $RunAfter
    )

    return @{
        inputs   = @{
            host = @{
                triggerName = "manual"
                workflow    = @{
                    id = "[resourceId('Microsoft.Logic/workflows', '$($WorkflowName)_Transform')]"
                }
            }
            body = $Text
        }
        runAfter = $RunAfter
        type     = "Workflow"
    }
}

function Add-LogicAppCustomConnectorConfiguration {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The workflow definition object.")]
        [object] $Definition
    )

    $apiName = $WorkflowConfig.dataSource.properties.name
    $method = $WorkflowConfig.dataSource.properties.method.ToLower()
    $Definition.actions.Retrieve_data_using_custom_connector.inputs.host.connection.name = "@parameters('`$connections')['$apiName']['connectionId']"
    $Definition.actions.Retrieve_data_using_custom_connector.inputs.method = $method
    $Definition.actions.Retrieve_data_using_custom_connector.inputs.path = $WorkflowConfig.dataSource.properties.path

    if ($null -ne $WorkflowConfig.dataSource.properties.queries) {
        $Definition.actions.Retrieve_data_using_custom_connector.inputs | Add-Member -MemberType NoteProperty -Name "queries" -Value $WorkflowConfig.dataSource.properties.queries
    }
    $bodyMethods = @("post", "put", "patch")
    if ($null -ne $WorkflowConfig.dataSource.properties.body -and $method -in $bodyMethods) {
        $Definition.actions.Retrieve_data_using_custom_connector.inputs | Add-Member -MemberType NoteProperty -Name "body" -Value $WorkflowConfig.dataSource.properties.body
    }
}

function Add-LogicAppTransformConfiguration {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The workflow definition object.")]
        [object] $Definition
    )

    $ingestDataSubflow = $Definition.actions.Ingest_data_subflow
    $dataTransformSubflow = Get-TransformDataSubflow -WorkflowName $WorkflowConfig.name -Text $ingestDataSubflow.inputs.body.payload -RunAfter $ingestDataSubflow.runAfter
    $Definition.actions | Add-Member -MemberType NoteProperty -Name "Transform_data_subflow" -Value $dataTransformSubflow

    $Definition.actions.Ingest_data_subflow.inputs.body.payload = "@body('Transform_data_subflow')"
    $Definition.actions.Ingest_data_subflow.runAfter = @{
        Transform_data_subflow = @("Succeeded")
    }
}

function Get-TriggerType {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig
    )

    $dataSourcesWithTrigger = @("azureblobstorage", "eventhub")
    if ($WorkflowConfig.dataSource.type.ToLower() -in $dataSourcesWithTrigger) {
        return "datasource"
    }

    return $WorkflowConfig.trigger.type
}

function Add-Trigger {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The workflow configuration object.")]
        [object] $WorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The workflow definition object.")]
        [object] $Definition
    )

    $triggerType = Get-TriggerType -WorkflowConfig $WorkflowConfig
    $triggerParams = $WorkflowConfig.trigger.parameters

    if ($null -ne $triggerParams) {
        $validFrequencies = @("Second", "Minute", "Hour", "Day", "Week", "Month")
        if ($triggerParams.frequency -notin $validFrequencies) {
            throw "The frequency, $($triggerParams.frequency), is not valid. Please choose from: $validFrequencies"
        }
    }

    switch ($triggerType.ToLower()) {
        "scheduled" {
            if ($null -eq $triggerParams) {
                throw "Trigger parameters are required for the scheduled trigger type."
            }

            $Definition.triggers = @{
                Recurrence = @{
                    type       = "Recurrence"
                    recurrence = $triggerParams
                }
            }
            break
        }
        "datasource" {
            if ($null -eq $triggerParams) {
                throw "Trigger parameters are required for the data source type, $($WorkflowConfig.dataSource.type)."
            }

            $propertyName = $Definition.triggers | Get-Member -MemberType NoteProperty | Select-Object -First 1 -ExpandProperty Name
            $Definition.triggers.$propertyName.recurrence = $triggerParams
            break
        }
        "manual" {
            # Default trigger, do nothing
            break
        }
        default {
            throw "The trigger type, $triggerType, is not valid. Please choose from: Manual, Scheduled."
        }
    }
}

Export-ModuleMember -Function New-DataSourceWorkflow
