# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates a workflow template that defines the trigger, the data
    source and any workflows called by this workflow. Supports Power
    Automate Flows.

    .Description
    Generates a workflow template that defines the trigger, the data
    source and any workflows called by this workflow. This function
    will generate a Power Automate Flow template.

    .Parameter DataSource
    The data source of the workflow.
    The CustomConnector data source has the ability to reference a certified
    custom connector or a non-certified custom connector which is determined
    by the parameters file.
    Options: AzureBlobStorage, CustomConnector.

    .Parameter BaseTemplate
    The base template to use for generating the customized workflow.
    Options: Flow.

    .Parameter IngestionWorkflowGuid
    The GUID of the ingestion workflow that will be used to ingest data into
    Dataverse. This is returned by the New-IngestionWorkflow function but can
    also be found in the `name` attribute of the ingestion workflow template.

    .Parameter TransformWorkflowGuid
    The GUID of the transformation workflow that will be used to transform
    data into a JSON array. This is returned by the New-TransformWorkflow
    function but can also be found in the `name` attribute of the transformation
    workflow template. If not provided, the transformation workflow will
    not be included.

    .Parameter OutputDirectory
    The directory where the data source workflow template will be saved. If it
    doesn't exist, it will be created.

    .Parameter ParametersFile
    The path to the parameters file (JSON) that will be used to customize the
    data source parameters in the template.

    .Parameter TriggerType
    The type of trigger to use for the workflow.
    Default: Manual. Options: Manual, Scheduled.

    .Example
    # Generate a workflow template with an API as the data source.
    New-DatasourceWorkflow -DataSource CustomConnector -BaseTemplate "Flow" -IngestionWorkflowGuid "41e38419-3821-4686-ae88-ec3400668513" -ParametersFile parameters.json -OutputDirectory output -TriggerType Scheduled

    # Generate a workflow template with Azure Blob Storage as the data source.
    New-DatasourceWorkflow -DataSource AzureBlobStorage -BaseTemplate "Flow" -IngestionWorkflowGuid "41e38419-3821-4686-ae88-ec3400668513" -TransformWorkflowGuid "9bd420a7-5ad4-440f-807c-e5b0f479dc58" -ParametersFile parameters.json -OutputDirectory output -TriggerType Scheduled
#>
function New-DatasourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data source of the workflow. Options: CustomConnector, AzureBlobStorage.")]
        [string] $DataSource,
        [Parameter(Mandatory = $true, HelpMessage = "The base template to use for the workflow. Options: Flow.")]
        [string] $BaseTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The Dataverse ingestion workflow template GUID.")]
        [string] $IngestionWorkflowGuid,
        [Parameter(Mandatory = $false, HelpMessage = "The data transformation workflow template GUID.")]
        [string] $TransformWorkflowGuid,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the workflow template will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $false, HelpMessage = "The type of trigger to use for the workflow. Options: Manual, Scheduled.")]
        [string] $TriggerType = "Manual"
    )

    $baseApp = $BaseTemplate.ToLower()
    if ($baseApp -eq "logicapp") {
        throw "Logic App functionality not yet implemented. Please choose from: Flow."
    }
    elseif ($baseApp -eq "flow") {
        $template = New-FlowDatasourceWorkflow -DataSource $DataSource -ParametersFile $ParametersFile -TriggerType $TriggerType -IngestionWorkflowGuid $IngestionWorkflowGuid -TransformWorkflowGuid $TransformWorkflowGuid
        $templateFilename = $template.properties.displayName
    }
    else {
        throw "The base template, $BaseTemplate, is not supported. Please choose from: Flow."
    }

    if (!(Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    }
    $template | ConvertTo-Json -Depth 20 | Out-File "$OutputDirectory/$templateFilename.json"
}

function New-FlowDatasourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data source of the workflow. Options: CustomConnector, AzureBlobStorage.")]
        [string] $DataSource,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $false, HelpMessage = "The type of trigger to use for the workflow. Options: Manual, Scheduled.")]
        [string] $TriggerType = "Manual",
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the ingestion workflow.")]
        [string] $IngestionWorkflowGuid,
        [Parameter(Mandatory = $false, HelpMessage = "The transformation workflow template GUID.")]
        [string] $TransformWorkflowGuid
    )

    # Configure the data source
    if ($DataSource -eq "CustomConnector") {
        $template = New-FlowCustomConnectorDatasourceWorkflow -ParametersFile $ParametersFile -IngestionWorkflowGuid $IngestionWorkflowGuid
    }
    elseif ($DataSource -eq "AzureBlobStorage") {
        $template = New-FlowAzureBlobStorageDatasourceWorkflow -ParametersFile $ParametersFile -IngestionWorkflowGuid $IngestionWorkflowGuid -TransformWorkflowGuid $TransformWorkflowGuid
    }
    else {
        throw "The data source specified is not supported. Please choose from: CustomConnector."
    }

    # Set the ID and name of the workflow
    $template.name = [guid]::NewGuid().ToString()
    $template.properties.displayName = "GetDataFrom$DataSource"

    # Configure the trigger
    # By default, the flow configuration is set to manual
    if ($TriggerType -eq "Scheduled") {
        $parameters = Get-Content $ParametersFile | ConvertFrom-Json

        $validFrequency = @("Second", "Minute", "Hour", "Day", "Week", "Month")

        $interval = $parameters.trigger.value.scheduled.interval
        $frequency = $parameters.trigger.value.scheduled.frequency

        if ($frequency -notin $validFrequency) {
            throw "The frequency specified is not valid. Please choose from: $validFrequency"
        }

        $template.properties.definition.triggers = @{
            type       = "Recurrence"
            recurrence = @{
                frequency = $frequency
                interval  = $interval
            }
        }
    }
    elseif ($TriggerType -ne "Manual") {
        throw "The trigger type specified is not valid. Please choose from: Manual, Scheduled."
    }

    return $template
}

function New-FlowCustomConnectorDatasourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the ingestion workflow.")]
        [string] $IngestionWorkflowGuid
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/data_source/customconnector/flow_customconnector.json | ConvertFrom-Json
    $parameters = Get-Content $ParametersFile | ConvertFrom-Json

    # Set variables based on whether the custom connector has been certified
    if ($parameters.isCustomConnectorCertified.value) {
        $definition.actions.Retrieve_data_using_custom_connector.inputs.host.apiId = "/providers/Microsoft.PowerApps/apis/$($parameters.apiName.value)"

        $apiConfig = @{
            name = $parameters.apiName.value
        }

        $connectionReferenceName = "$($parameters.apiName.value)_ref"
    }
    else {
        $connectorIdentifiers = Get-ConnectorIdentifiers -ConnectorId $parameters.connectorId.value -TenantId $parameters.tenantId.value -ClientId $parameters.clientId.value -ClientSecret $parameters.clientSecret.value -OrgWebApiUrl $parameters.orgWebApiUrl.value

        $apiConfig = $connectorIdentifiers

        $connectionReferenceName = "$($connectorIdentifiers.logicalName)_ref"
    }

    # Update the connector operation ID
    $definition.actions.Retrieve_data_using_custom_connector.inputs.host.operationId = $parameters.connectorOperationId.value

    # Update Dataverse ingestion sub-workflow configuration
    $definition.actions.Ingest_data_subflow.inputs.host.workflowReferenceName = $IngestionWorkflowGuid

    $baseTemplate.properties.definition = $definition
    $baseTemplate.properties.connectionReferences = @{
        customconnector = @{
            runtimeSource = "invoker"
            connection    = @{
                connectionReferenceLogicalName = $connectionReferenceName
            }
            api           = $apiConfig
        }
    }

    return $baseTemplate
}

function New-FlowAzureBlobStorageDatasourceWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the ingestion workflow.")]
        [string] $IngestionWorkflowGuid,
        [Parameter(Mandatory = $true, HelpMessage = "The transformation workflow template GUID.")]
        [string] $TransformWorkflowGuid
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/data_source/azureblob/flow_azureblob.json | ConvertFrom-Json
    $parameters = Get-Content $ParametersFile | ConvertFrom-Json

    # Update the connector operation ID
    $definition.actions.Retrieve_data_from_Azure_Blob_Storage.inputs.host.operationId = $parameters.connectorOperationId.value

    # Update data transformation sub-workflow configuration
    $definition.actions.Transform_CSV_data_to_JSON.inputs.host.workflowReferenceName = $TransformWorkflowGuid

    # Update data ingestion sub-workflow configuration
    $definition.actions.Ingest_Data_Subflow.inputs.host.workflowReferenceName = $IngestionWorkflowGuid

    $baseTemplate.properties.definition = $definition
    $baseTemplate.properties.connectionReferences = @{
        shared_azureblob = @{
            runtimeSource = "invoker"
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

function Get-ConnectorIdentifiers {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The custom connector GUID.")]
        [string] $ConnectorId,
        [Parameter(Mandatory = $true, HelpMessage = "The tenant ID.")]
        [String] $TenantId,
        [Parameter(Mandatory = $true, HelpMessage = "The client ID of the service principal.")]
        [string] $ClientId,
        [Parameter(Mandatory = $true, HelpMessage = "The client secret of the service principal.")]
        [string] $ClientSecret,
        [Parameter(Mandatory = $true, HelpMessage = "The Dataverse Web API URL.")]
        [string] $OrgWebApiUrl
    )

    try {
        # Get authentication token to access the Dataverse Web API
        $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        $authHeaders = @{
            "Content-Type" = "application/x-www-form-urlencoded"
        }

        $authBody =
        @{
            client_id     = $ClientId
            client_secret = $ClientSecret
            scope         = "$OrgWebApiUrl/.default"
            grant_type    = 'client_credentials'
        }

        $authResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Headers $authHeaders -Body $authBody -ErrorAction Stop
        $accessToken = $authResponse.access_token
    }
    catch {
        throw "An error occurred while retrieving the access token. Error: $($_.Exception.Message)"
    }

    try {
        # Query custom connector config using the connector ID using the Dataverse Web API
        $uriConnectorFilter = '$select=name,connectorinternalid'
        $uri = "$OrgWebApiUrl/api/data/v9.2/connectors($ConnectorId)?$($uriConnectorFilter)"
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

Export-ModuleMember -Function New-DatasourceWorkflow
