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

    .Parameter WorkflowConfigFile
    The workflow configuration file that defines the trigger, the data
    source, the data sink and any transformations that will be applied.

    .Parameter OutputDirectory
    The directory where the generated deployable package will be saved. If it
    doesn't exist, it will be created.

    .Parameter PackageParametersFile
    The path to the parameters file (JSON) that will be used to customize the
    solution. Not required for Logic App workflow type.

    .Parameter AuthConfigFile
    The path to the authentication configuration JSON file. This file is only
    required if the data source is a non-certified custom connector. Provide
    the tenantId, clientId, clientSecret, and orgWebApiUrl for the service
    principal that will be used to authenticate with the Dataverse API.

    .Example
    # Generate a Flow Industry Link package
    New-MsIndustryLink -WorkflowConfigFile flow_workflow.json -OutputDirectory output -PackageParametersFile package.parameters.json

    # Generate Logic App Industry Link templates
    New-MsIndustryLink -WorkflowConfigFile logicapp_workflow.json -OutputDirectory output
#>
function New-MsIndustryLink {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the workflow configuration JSON file.")]
        [string] $WorkflowConfigFile,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the Industry Link solution will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the package parameters file (JSON).")]
        [string] $PackageParametersFile,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the authentication configuration JSON file.")]
        [string] $AuthConfigFile
    )

    $workflowConfig = Get-Content $WorkflowConfigFile | ConvertFrom-Json
    $dataSourceType = $workflowConfig.dataSource.type.ToLower()
    $workflowType = $workflowConfig.workflowType.ToLower()
    $workflowGuids = @{}

    # Create ingestion workflow template
    $ingestionMetadata = New-IngestionWorkflow -WorkflowConfigFile $WorkflowConfigFile -OutputDirectory $OutputDirectory
    $workflowGuids[$ingestionMetadata.name] = $ingestionMetadata.guid

    if ("azureblobstorage" -eq $dataSourceType) {
        # Create transformation workflow template
        $transformMetadata = New-TransformWorkflow -WorkflowConfigFile $WorkflowConfigFile -OutputDirectory $OutputDirectory
        $workflowGuids[$transformMetadata.name] = $transformMetadata.guid
    }

    # Create data source workflow template
    New-DataSourceWorkflow -WorkflowConfigFile $WorkflowConfigFile -TemplateDirectory $OutputDirectory -WorkflowGuids $workflowGuids -AuthConfigFile $AuthConfigFile

    if ("flow" -eq $workflowType) {
        if ($null -eq $PackageParametersFile -or "" -eq $PackageParametersFile) {
            throw "PackageParametersFile is required for Flow workflows."
        }

        # Package Industry Link into a solution
        New-WorkflowPackage -ParametersFile $PackageParametersFile -TemplateDirectory $OutputDirectory -OutputDirectory $OutputDirectory
    }
}

Export-ModuleMember -Function New-MsIndustryLink
