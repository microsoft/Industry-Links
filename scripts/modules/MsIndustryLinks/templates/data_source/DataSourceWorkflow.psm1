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
    param(
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
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the ingestion workflow.")]
        [string] $IngestionWorkflowGuid
    )

    $baseTemplate = Get-Content $PSScriptRoot/templates/flow_base.json | ConvertFrom-Json
    $definition = Get-Content $PSScriptRoot/templates/data_source/customconnector/flow_customconnector.json | ConvertFrom-Json
    $parameters = Get-Content $ParametersFile | ConvertFrom-Json

    # Update the connector operation ID
    $definition.actions.Retrieve_data_using_custom_connector.inputs.host.operationId = $parameters.connectorOperationId.value

    # Update the public connector API reference
    $definition.actions.Retrieve_data_using_custom_connector.inputs.host.apiId = "/providers/Microsoft.PowerApps/apis/$($parameters.connectorLogicalName.value)"

    # Update Dataverse ingestion sub-workflow configuration
    $definition.actions.Ingest_data_subflow.inputs.host.workflowReferenceName = $IngestionWorkflowGuid

    $baseTemplate.properties.definition = $definition
    $baseTemplate.properties.connectionReferences = @{
        customconnector = @{
            runtimeSource = "embedded"
            connection    = @{
                connectionReferenceLogicalName = $parameters.connectionReferenceLogicalName.value
            }
            api           = @{
                name = $parameters.connectorLogicalName.value
            }
        }
    }

    return $baseTemplate
}

function New-FlowAzureBlobStorageDatasourceWorkflow {
    param(
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

    # Update the Azure Blob Connector reference
    $definition.actions.Retrieve_data_from_Azure_Blob_Storage.inputs.host.apiId = "/providers/Microsoft.PowerApps/apis/$($parameters.apiLogicalName.value)"

    # Update data transformation sub-workflow configuration
    $definition.actions.Transform_CSV_data_to_JSON.inputs.host.workflowReferenceName = $TransformWorkflowGuid

    # Update data ingestion sub-workflow configuration
    $definition.actions.Ingest_Data_Subflow.inputs.host.workflowReferenceName = $IngestionWorkflowGuid

    $baseTemplate.properties.definition = $definition
    $baseTemplate.properties.connectionReferences = @{
        shared_azureblob = @{
            runtimeSource = "invoker"
            connection    = @{
                connectionReferenceLogicalName = $parameters.connectionReferenceLogicalName.value
            }
            api           = @{
                name = $parameters.apiLogicalName.value
            }
        }
    }

    return $baseTemplate
}

Export-ModuleMember -Function New-DatasourceWorkflow
