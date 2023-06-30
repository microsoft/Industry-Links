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

    .Parameter DataSourceParametersFile
    The path to the parameters file (JSON) that will be used to customize the
    parameters in the data source workflow template.

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

    .Example
    # Generate an Industry Link package with an API as the data source.
    New-MsIndustryLink -DataSource CustomConnector -BaseTemplate "Flow" -DataSourceParametersFile datasource.parameters.json -DataverseParametersFile dataverse.parameters.json -OutputDirectory output -MappingDefinitionFile mapping.json -UseUpsert $false -TriggerType Scheduled -PackageParametersFile package.parameters.json

    # Generate an Industry Link package with Azure Blob Storage as the data source.
    New-MsIndustryLink -DataSource AzureBlobStorage -BaseTemplate "Flow" -DataSourceParametersFile datasource.parameters.json -DataverseParametersFile dataverse.parameters.json -OutputDirectory output -MappingDefinitionFile mapping.json -UseUpsert $false -TriggerType Scheduled -PackageParametersFile package.parameters.json
#>
function New-MsIndustryLink {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The data source of the Industry Link. Options: CustomConnector, AzureBlobStorage.")]
        [string] $DataSource,
        [Parameter(Mandatory = $true, HelpMessage = "The base template to use for the workflow. Options: LogicApp, Flow.")]
        [string] $BaseTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the Industry Link solution will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the data source workflow parameters file (JSON).")]
        [string] $DataSourceParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the Dataverse workflow parameters file (JSON).")]
        [string] $DataverseParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the ingestion mapping definition file (JSON).")]
        [string] $MappingDefinitionFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the package parameters file (JSON).")]
        [string] $PackageParametersFile,
        [Parameter(Mandatory = $false, HelpMessage = "The type of trigger to use for the Industry Link. Options: Manual, Scheduled.")]
        [string] $TriggerType = "Manual",
        [Parameter(Mandatory = $false, HelpMessage = "If true, perform upsert operations on data ingestion.")]
        [bool] $UseUpsert = $true
    )

    # Create ingestion workflow template
    [String] $ingestionWorkflowGuid = New-IngestionWorkflow -BaseTemplate $BaseTemplate -ParametersFile $DataverseParametersFile -MappingDefinitionFile $MappingDefinitionFile -OutputDirectory $OutputDirectory -UseUpsert $UseUpsert

    if ($DataSource -eq "AzureBlobStorage") {
        # Create transformation workflow template
        [String] $TransformWorkflowGuid = New-TransformWorkflow -BaseTemplate $BaseTemplate -SourceFormat CSV -OutputDirectory $OutputDirectory
    }

    # Create data source workflow template
    New-DatasourceWorkflow -DataSource $DataSource -BaseTemplate $BaseTemplate -IngestionWorkflowGuid $ingestionWorkflowGuid -TransformWorkflowGuid $TransformWorkflowGuid -ParametersFile $DataSourceParametersFile -OutputDirectory $OutputDirectory -TriggerType $TriggerType

    # Package Industry Link into a solution
    New-WorkflowPackage -BaseTemplate $BaseTemplate -WorkflowAssetsPath $OutputDirectory -OutputDirectory $OutputDirectory -ParametersFile $PackageParametersFile
}

Export-ModuleMember -Function New-MsIndustryLink
