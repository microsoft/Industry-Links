# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Packages a directory of workflow templates into a Power Platform solution
    deployable zip file. Supports Power Automate Flows.

    .Description
    Creates and configures Power Automate solution assets using a directory
    of workflow templates. It is then packaged into a solution deployable zip
    file.

    .Parameter ParametersFile
    The path to the parameters file (JSON) that will be used to customize the
    solution.

    .Parameter TemplateDirectory
    The path to the workflow templates required for your Industry Link. This
    should contain at least one workflow template.

    .Parameter OutputDirectory
    The directory where the solution assets and package will be saved.

    .Example
    # Package a directory of workflow templates into a Power Platform solution deployable zip file.
    New-WorkflowPackage -ParametersFile parameters.json -TemplateDirectory output -OutputDirectory output/solution
#>
function New-WorkflowPackage {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters JSON file.")]
        [string] $ParametersFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the directory containing the workflow templates.")]
        [string] $TemplateDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the solution package will be saved.")]
        [string] $OutputDirectory
    )

    New-WorkflowsIntoSolution -WorkflowAssetsPath $TemplateDirectory -OutputDirectory $OutputDirectory -ParametersFile $ParametersFile
}

function New-WorkflowsIntoSolution {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path of the workflow assets to be packaged.")]
        [string] $WorkflowAssetsPath,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the packaged solution will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile
    )

    # Create the solution
    New-Solution -OutputDirectory $OutputDirectory -ParametersFile $ParametersFile

    $solutionName = (Get-Content $ParametersFile | ConvertFrom-Json).solutionName
    $packageType = (Get-Content $ParametersFile | ConvertFrom-Json).packageType
    $solutionAssetsPath = Join-Path $OutputDirectory $solutionName "src"

    # Create the Workflows folder
    $workflowsPath = Join-Path $solutionAssetsPath "Workflows"
    if (!(Test-Path $workflowsPath)) {
        New-Item -ItemType Directory -Force -Path $workflowsPath | Out-Null
    }

    # Add the workflows to the solution
    $workflowFiles = Get-ChildItem $WorkflowAssetsPath -Filter *.json -Recurse
    foreach ($workflowFile in $workflowFiles) {
        New-FlowReferenceInSolution -SolutionAssetsPath $solutionAssetsPath -FlowWorkflowTemplatePath $workflowFile.FullName
    }

    # Package the solution components into a solution.zip ready for import
    pac solution pack --folder $solutionAssetsPath --packagetype $packageType --zipfile "$OutputDirectory/$solutionName.zip" | Out-Null
}

function New-FlowReferenceInSolution {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path of the solution assets.")]
        [string] $SolutionAssetsPath,
        [Parameter(Mandatory = $true, HelpMessage = "The path of the workflow template.")]
        [string] $FlowWorkflowTemplatePath
    )

    try {
        $workflowTemplate = Get-Content $FlowWorkflowTemplatePath | ConvertFrom-Json
        $FlowGuid = $workflowTemplate.name
        $FlowName = $workflowTemplate.properties.displayName
    }
    catch {
        Write-Error "An error occurred while reading the workflow template: $($_.Exception.Message)"
        Exit 1
    }

    try {
        # Update Solution.xml to include the flow
        $solutionXmlPath = "$SolutionAssetsPath/Other/Solution.xml"
        $solutionXml = New-Object xml
        $solutionXml.Load((Convert-Path $solutionXmlPath))

        $rootComponentElement = New-SolutionXmlRootComponentElement -SolutionXml $solutionXml -FlowGuid $FlowGuid
        $rootComponents = $solutionXml.SelectSingleNode("//RootComponents")
        $rootComponents.AppendChild($rootComponentElement) | Out-Null
        $solutionXml.Save((Convert-Path $solutionXmlPath))
    }
    catch {
        Write-Error "An error occurred while adding the flow reference to Solution.xml: $($_.Exception.Message)"
        Exit 1
    }

    try {
        # Add workflows configuration to solution assets
        $solutionWorkflowPath = Join-Path $SolutionAssetsPath "Workflows" (Split-Path $FlowWorkflowTemplatePath -Leaf)
        Copy-Item $FlowWorkflowTemplatePath $solutionWorkflowPath

    }
    catch {
        Write-Error "An error occurred while adding the flow workflow template to the solution: $($_.Exception.Message)"
        Exit 1
    }

    try {
        # Update Customizations.xml to include the flow & connection details
        $customizationsPath = Join-Path $SolutionAssetsPath "Other/Customizations.xml"

        $customizationsXml = New-Object xml
        $customizationsXml.Load((Convert-Path $customizationsPath))

        $workflowElement = New-CustomizationsXmlWorkflowElement -CustomizationsXml $customizationsXml -FlowGuid $FlowGuid -FlowName $FlowName
        $workflowsElement = $customizationsXml.SelectSingleNode("//Workflows")
        $workflowsElement.AppendChild($workflowElement) | Out-Null

        # Read workflow template and add all of the connection references
        $workflowTemplate = Get-Content $FlowWorkflowTemplatePath | ConvertFrom-Json

        # Check if the connectionreferences element exists
        if ($null -eq $customConnectionsElement -and $workflowTemplate.properties.connectionReferences.PSObject.Properties -ne "") {
            # Create and add the element if it does not exist
            $customConnectionsElement = $customizationsXml.CreateElement("connectionreferences")
            $customizationsXml.DocumentElement.AppendChild($customConnectionsElement) | Out-Null
        }

        # Iterate over all of the connection references and add them to the Customizations.xml
        $workflowTemplate.properties.connectionReferences.PSObject.Properties | ForEach-Object {
            $connectionReference = $_.Value
            # XML AppendChild function does not add duplicate XML elements
            $connectionReferenceLogicalName = $connectionReference.connection.connectionReferenceLogicalName
            $connectorId = "/providers/Microsoft.PowerApps/apis/$($connectionReference.api.name)"

            $customConnectionElement = New-CustomizationsXmlCustomConnectorElement -CustomizationsXml $customizationsXml -ConnectionReferenceLogicalName $connectionReferenceLogicalName -ConnectionReferenceDisplayName $connectionReferenceLogicalName -ConnectorId $connectorId
            $customConnectionsElement = $customizationsXml.SelectSingleNode("//connectionreferences")
            $customConnectionsElement.AppendChild($customConnectionElement) | Out-Null
        }

        $customizationsXml.Save((Convert-Path $customizationsPath))
    }
    catch {
        Write-Error "An error occurred while adding the flow & connection references to Customizations.xml: $($_.Exception.Message)"
        Exit 1
    }
}

function New-Solution {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the workflow template will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the parameters file (JSON).")]
        [string] $ParametersFile
    )

    try {
        $parameters = Get-Content $ParametersFile | ConvertFrom-Json
        $SolutionName = $parameters.solutionName

        $solutionPath = Join-Path $OutputDirectory $SolutionName
        if (!(Test-Path $solutionPath)) {
            New-Item -ItemType Directory -Force -Path $solutionPath | Out-Null
        }

        # Generate solution files
        pac solution init --publisher-name $parameters.publisherName --publisher-prefix $parameters.publisherPrefix --outputDirectory $solutionPath | Out-Null
    }
    catch {
        Write-Error "An error occurred while configuring the solution files: $($_.Exception.Message)"
        Exit 1
    }
}

function New-SolutionXmlRootComponentElement {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The solution XML document.")]
        [xml] $SolutionXml,
        [Parameter(Mandatory = $true, HelpMessage = "The flow GUID.")]
        [string] $FlowGuid
    )

    $rootComponentElement = $SolutionXml.CreateElement("RootComponent")
    $rootComponentElement.SetAttribute("type", "29")
    $rootComponentElement.SetAttribute("id", "{$FlowGuid}")
    $rootComponentElement.SetAttribute("behavior", "0")

    return $rootComponentElement
}

function New-CustomizationsXmlWorkflowElement {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The customizations XML document.")]
        [xml] $CustomizationsXml,
        [Parameter(Mandatory = $true, HelpMessage = "The flow GUID.")]
        [string] $FlowGuid,
        [Parameter(Mandatory = $true, HelpMessage = "The flow name.")]
        [string] $FlowName
    )

    $workflowElement = $CustomizationsXml.CreateElement("Workflow")
    $workflowElement.SetAttribute("WorkflowId", "{$FlowGuid}")
    $workflowElement.SetAttribute("Name", "$FlowName")

    $jsonFileNameElement = $CustomizationsXml.CreateElement("JsonFileName")
    $jsonFileNameElement.InnerXml = "/Workflows/$FlowName.json"
    $workflowElement.AppendChild($jsonFileNameElement) | Out-Null

    $typeElement = $CustomizationsXml.CreateElement("Type")
    $typeElement.InnerText = "1"
    $workflowElement.AppendChild($typeElement) | Out-Null

    $subprocessElement = $CustomizationsXml.CreateElement("Subprocess")
    $subprocessElement.InnerText = "0"
    $workflowElement.AppendChild($subprocessElement) | Out-Null

    $categoryElement = $CustomizationsXml.CreateElement("Category")
    $categoryElement.InnerText = "5"
    $workflowElement.AppendChild($categoryElement) | Out-Null

    $modeElement = $CustomizationsXml.CreateElement("Mode")
    $modeElement.InnerText = "0"
    $workflowElement.AppendChild($modeElement) | Out-Null

    $scopeElement = $CustomizationsXml.CreateElement("Scope")
    $scopeElement.InnerText = "4"
    $workflowElement.AppendChild($scopeElement) | Out-Null

    $onDemandElement = $CustomizationsXml.CreateElement("OnDemand")
    $onDemandElement.InnerText = "0"
    $workflowElement.AppendChild($onDemandElement) | Out-Null

    $triggerOnCreateElement = $CustomizationsXml.CreateElement("TriggerOnCreate")
    $triggerOnCreateElement.InnerText = "0"
    $workflowElement.AppendChild($triggerOnCreateElement) | Out-Null

    $triggerOnDeleteElement = $CustomizationsXml.CreateElement("TriggerOnDelete")
    $triggerOnDeleteElement.InnerText = "0"
    $workflowElement.AppendChild($triggerOnDeleteElement) | Out-Null

    $asyncAutoDeleteElement = $CustomizationsXml.CreateElement("AsyncAutoDelete")
    $asyncAutoDeleteElement.InnerText = "0"
    $workflowElement.AppendChild($asyncAutoDeleteElement) | Out-Null

    $syncWorkflowLogOnFailureElement = $CustomizationsXml.CreateElement("SyncWorkflowLogOnFailure")
    $syncWorkflowLogOnFailureElement.InnerText = "0"
    $workflowElement.AppendChild($syncWorkflowLogOnFailureElement) | Out-Null

    $stateCodeElement = $CustomizationsXml.CreateElement("StateCode")
    # 0 = Active, 1 = Inactive
    $stateCodeElement.InnerText = "0"
    $workflowElement.AppendChild($stateCodeElement) | Out-Null

    $statusCodeElement = $CustomizationsXml.CreateElement("StatusCode")
    # 1 = Active, 2 = Inactive
    $statusCodeElement.InnerText = "1"
    $workflowElement.AppendChild($statusCodeElement) | Out-Null

    $runAsElement = $CustomizationsXml.CreateElement("RunAs")
    $runAsElement.InnerText = "1"
    $workflowElement.AppendChild($runAsElement) | Out-Null

    $isTransactedElement = $CustomizationsXml.CreateElement("IsTransacted")
    $isTransactedElement.InnerText = "1"
    $workflowElement.AppendChild($isTransactedElement) | Out-Null

    $introducedVersionElement = $CustomizationsXml.CreateElement("IntroducedVersion")
    $introducedVersionElement.InnerText = "1.0.0.0"
    $workflowElement.AppendChild($introducedVersionElement) | Out-Null

    $isCustomizableElement = $CustomizationsXml.CreateElement("IsCustomizable")
    $isCustomizableElement.InnerText = "1"
    $workflowElement.AppendChild($isCustomizableElement) | Out-Null

    $businessProcessTypeElement = $CustomizationsXml.CreateElement("BusinessProcessType")
    $businessProcessTypeElement.InnerText = "0"
    $workflowElement.AppendChild($businessProcessTypeElement) | Out-Null

    $isCustomProcessingStepAllowedForOtherPublishersElement = $CustomizationsXml.CreateElement("IsCustomProcessingStepAllowedForOtherPublishers")
    $isCustomProcessingStepAllowedForOtherPublishersElement.InnerText = "1"
    $workflowElement.AppendChild($isCustomProcessingStepAllowedForOtherPublishersElement) | Out-Null

    $primaryEntityElement = $CustomizationsXml.CreateElement("PrimaryEntity")
    $primaryEntityElement.InnerText = "none"
    $workflowElement.AppendChild($primaryEntityElement) | Out-Null

    $localizedNamesElement = $CustomizationsXml.CreateElement("LocalizedNames")
    $localizedNameElement = $CustomizationsXml.CreateElement("LocalizedName")
    $localizedNameElement.SetAttribute("languagecode", "1033")
    $localizedNameElement.SetAttribute("description", $FlowName)
    $localizedNamesElement.AppendChild($localizedNameElement) | Out-Null
    $workflowElement.AppendChild($localizedNamesElement) | Out-Null

    return $workflowElement
}

function New-CustomizationsXmlCustomConnectorElement {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The customizations XML document.")]
        [xml] $CustomizationsXml,
        [Parameter(Mandatory = $true, HelpMessage = "The connection reference logical name.")]
        [string] $ConnectionReferenceLogicalName,
        [Parameter(Mandatory = $true, HelpMessage = "The connection reference display name.")]
        [string] $ConnectionReferenceDisplayName,
        [Parameter(Mandatory = $true, HelpMessage = "The connector ID.")]
        [string] $ConnectorId
    )

    $customConnectorElement = $CustomizationsXml.CreateElement("connectionreference")
    $customConnectorElement.SetAttribute("connectionreferencelogicalname", $ConnectionReferenceLogicalName)

    $connectionReferenceDisplayNameElement = $CustomizationsXml.CreateElement("connectionreferencedisplayname")
    $connectionReferenceDisplayNameElement.InnerText = $ConnectionReferenceDisplayName
    $customConnectorElement.AppendChild($connectionReferenceDisplayNameElement) | Out-Null

    $connectorIdElement = $CustomizationsXml.CreateElement("connectorid")
    $connectorIdElement.InnerText = $ConnectorId
    $customConnectorElement.AppendChild($connectorIdElement) | Out-Null

    $isCustomizableElement = $CustomizationsXml.CreateElement("iscustomizable")
    $isCustomizableElement.InnerText = "1"
    $customConnectorElement.AppendChild($isCustomizableElement) | Out-Null

    $stateCodeElement = $CustomizationsXml.CreateElement("statecode")
    # 0 = Active, 1 = Inactive
    $stateCodeElement.InnerText = "0"
    $customConnectorElement.AppendChild($stateCodeElement) | Out-Null

    $statusCodeElement = $CustomizationsXml.CreateElement("statuscode")
    # 1 = Active, 2 = Inactive
    $statusCodeElement.InnerText = "1"
    $customConnectorElement.AppendChild($statusCodeElement) | Out-Null

    return $customConnectorElement
}

Export-ModuleMember -Function New-WorkflowPackage
