# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates a transform workflow template. Supports Logic Apps and
    Power Automate Flows.

    .Description
    Generates a transform workflow template that will transform content
    into a JSON array of objects. This function will generate a Logic App
    or Power Automate Flow template. Specify the workflow type (Flow or
    LogicApp) and data transform type in the workflow configuration file.

    .Parameter WorkflowConfigFile
    The workflow configuration file that defines the trigger, the data
    source, the data sink and any transformations that will be applied.

    .Parameter OutputDirectory
    The directory where the transform workflow template will be saved. If it
    doesn't exist, it will be created.

    .OUTPUTS
    A Hashtable containing the name and GUID of the workflow template.

    .Example
    # Generate a workflow template to transform data.
    New-TransformWorkflow -WorkflowConfigFile workflow.json -OutputDirectory output
#>
function New-TransformWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the workflow configuration JSON file.")]
        [string] $WorkflowConfigFile,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the workflow template will be saved.")]
        [string] $OutputDirectory
    )

    $workflowConfig = Get-Content $WorkflowConfigFile | ConvertFrom-Json
    $workflowType = $workflowConfig.workflowType.ToLower()

    if ($null -eq $workflowConfig.dataTransform -or 0 -eq @($workflowConfig.dataTransform.psobject.Properties).Count) {
        throw "No data transform was specified. Please specify a data transform."
    }

    if ($null -eq $workflowConfig.dataTransform.type -or "" -eq $workflowConfig.dataTransform.type) {
        throw "No data transform type was specified. Please choose from: csv_to_json."
    }

    $transformType = $workflowConfig.dataTransform.type.ToLower()
    $validTransforms = @("csv_to_json")
    if ($transformType -notin $validTransforms) {
        throw "The data transform type, $($workflowConfig.dataTransform.type), is not supported. Please choose from: $($validTransforms -join ', ')."
    }

    $transformTemplate = Get-Content $PSScriptRoot/templates/data_transform/$($workflowType)_$transformType.json | ConvertFrom-Json
    $template = Get-Content $PSScriptRoot/templates/$($workflowType)_base.json | ConvertFrom-Json

    $templateGuid = ""
    if ($workflowType -eq "logicapp") {
        $template.definition = $transformTemplate
        $templateName = "$($workflowConfig.name)_Transform"
    }
    elseif ($workflowType -eq "flow") {
        if ($null -eq $workflowConfig.dataTransform.name -or "" -eq $workflowConfig.dataTransform.name) {
            throw "No transform workflow name was specified. Please specify a name."
        }

        $templateGuid = [guid]::NewGuid().ToString()

        $template.properties.definition = $transformTemplate
        $template.name = $templateGuid
        $template.properties.displayName = $workflowConfig.dataTransform.name

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

Export-ModuleMember -Function New-TransformWorkflow
