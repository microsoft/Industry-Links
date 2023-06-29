# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates a transform workflow template. Supports Logic Apps and
    Power Automate Flows.

    .Description
    Generates a transform workflow template that will transform content
    into a JSON array of objects. This function will generate a Logic App
    or Power Automate Flow template.

    .Parameter BaseTemplate
    The base template to use for generating the customized workflow.
    Options: LogicApp, Flow.

    .Parameter SourceFormat
    The file format of the source content.
    Options: CSV.

    .Parameter OutputDirectory
    The directory where the transform workflow template will be saved. If it
    doesn't exist, it will be created.

    .OUTPUTS
    The generated GUID of the transform workflow template.

    .Example
    # Generate a Power Automate workflow template to transform data.
    New-TransformWorkflow -BaseTemplate "Flow" -SourceFormat CSV -OutputDirectory output

    .Example
    # Generate a Logic App workflow template to transform data.
    New-TransformWorkflow -BaseTemplate "LogicApp" -SourceFormat CSV -OutputDirectory output
#>
function New-TransformWorkflow {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The base template to use for the workflow. Options: LogicApp, Flow.")]
        [string] $BaseTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The file format of the source content.")]
        [string] $SourceFormat,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the workflow template will be saved.")]
        [string] $OutputDirectory
    )

    $baseApp = $BaseTemplate.ToLower()
    $format = $SourceFormat.ToLower()

    if ($format -ne "csv") {
        throw "The source format specified is not supported. Please choose from: CSV."
    }

    $transformTemplate = Get-Content $PSScriptRoot/templates/data_transform/$($baseApp)_$($format)_to_json.json | ConvertFrom-Json
    $template = Get-Content $PSScriptRoot/templates/$($baseApp)_base.json | ConvertFrom-Json

    $templateGuid = ""
    if ($baseApp -eq "logicapp") {
        $template.definition = $transformTemplate
        $templateName = "$($format)_to_json_workflow"
    }
    elseif ($baseApp -eq "flow") {
        $templateGuid = [guid]::NewGuid().ToString()

        $template.properties.definition = $transformTemplate
        $template.name = $templateGuid
        $template.properties.displayName = "CsvToJson"

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

Export-ModuleMember -Function New-TransformWorkflow
