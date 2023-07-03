# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates a deployable package that contains a set of workflows
    that retrieves data from a source and ingests it into Dataverse.

    .Description
    Generates a set of workflow templates that will insert or upsert data
    into a Dataverse table. For Flows, the templates are packaged into a
    Power Platform solution that can be imported into your Dataverse
    environment or used for publishing to AppSource.

    .Parameter DataSource
    The data source of the workflow.
    Options: AzureBlobStorage, CustomConnector.

    .Parameter BaseTemplate
    The base template to use for generating the customized workflow.
    Options: Flow.

    .Parameter OutputDirectory
    The directory where the generated deployable package will be saved. If it
    doesn't exist, it will be created.

    .Parameter WorkflowConfigFile
    The workflow configuration file that defines the trigger, the data
    source, the data sink and any transformations that will be applied.

    .Parameter DataverseParametersFile
    The path to the parameters file (JSON) that will be used to customize the
    parameters in the Dataverse ingestion workflow template.

    .Parameter MappingDefinitionFile
    The path to the mapping definition file (JSON) that will be used to
    customize the mapping between your source data and Dataverse table.

    .Parameter PackageParametersFile
    The path to the parameters file (JSON) that will be used to customize the
    solution.

    .Parameter TriggerType
    The type of trigger to use for the Industry Link.
    Default: Manual. Options: Manual, Scheduled.

    .Parameter UseUpsert
    If set to true, the workflow will upsert records. Otherwise, it will insert
    records.
    Default: true.

    .Parameter AuthConfigFile
    The path to the authentication configuration JSON file. This file is only
    required if the data source is a non-certified custom connector. Provide
    the tenantId, clientId, clientSecret, and orgWebApiUrl for the service
    principal that will be used to authenticate with the Dataverse API.

    .Example
    # Generate an Industry Link package with a certified custom connector as the data source.
    New-MsIndustryLink -DataSource CustomConnector -BaseTemplate "Flow" -WorkflowConfigFile workflow.json -DataverseParametersFile dataverse.parameters.json -OutputDirectory output -MappingDefinitionFile mapping.json -UseUpsert $false -TriggerType Scheduled -PackageParametersFile package.parameters.json

    # Generate an Industry Link package with Azure Blob Storage as the data source.
    New-MsIndustryLink -DataSource AzureBlobStorage -BaseTemplate "Flow" -WorkflowConfigFile workflow.json -DataverseParametersFile dataverse.parameters.json -OutputDirectory output -MappingDefinitionFile mapping.json -UseUpsert $false -TriggerType Scheduled -PackageParametersFile package.parameters.json
#>
function New-MsIndustryLink {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data source of the Industry Link. Options: CustomConnector, AzureBlobStorage.")]
        [string] $DataSource,
        [Parameter(Mandatory = $true, HelpMessage = "The base template to use for the workflow. Options: LogicApp, Flow.")]
        [string] $BaseTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the Industry Link solution will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the workflow configuration JSON file.")]
        [string] $WorkflowConfigFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the Dataverse workflow parameters file (JSON).")]
        [string] $DataverseParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the ingestion mapping definition file (JSON).")]
        [string] $MappingDefinitionFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the package parameters file (JSON).")]
        [string] $PackageParametersFile,
        [Parameter(Mandatory = $false, HelpMessage = "The type of trigger to use for the Industry Link. Options: Manual, Scheduled.")]
        [string] $TriggerType = "Manual",
        [Parameter(Mandatory = $false, HelpMessage = "If true, perform upsert operations on data ingestion.")]
        [bool] $UseUpsert = $true,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the authentication configuration JSON file.")]
        [string] $AuthConfigFile
    )

    $workflowGuids = @{}

    # Create ingestion workflow template
    $ingestionMetadata = New-IngestionWorkflow -BaseTemplate $BaseTemplate -ParametersFile $DataverseParametersFile -MappingDefinitionFile $MappingDefinitionFile -OutputDirectory $OutputDirectory -UseUpsert $UseUpsert
    $workflowGuids[$ingestionMetadata.name] = $ingestionMetadata.guid

    if ($DataSource.ToLower() -eq "azureblobstorage") {
        # Create transformation workflow template
        $transformMetadata = New-TransformWorkflow -WorkflowConfigFile $WorkflowConfigFile -OutputDirectory $OutputDirectory
        $workflowGuids[$transformMetadata.name] = $transformMetadata.guid
    }

    # Create data source workflow template
    New-DataSourceWorkflow -WorkflowConfigFile $WorkflowConfigFile -TemplateDirectory $OutputDirectory -WorkflowGuids $workflowGuids -AuthConfigFile $AuthConfigFile

    # Package Industry Link into a solution
    New-WorkflowPackage -BaseTemplate $BaseTemplate -WorkflowAssetsPath $OutputDirectory -OutputDirectory $OutputDirectory -ParametersFile $PackageParametersFile
}

Export-ModuleMember -Function New-MsIndustryLink
