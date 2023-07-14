# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates ARM templates that deploys the Azure resources
    required for an Industry Link.

    .Description
    Generates ARM templates that deploys the Azure resources such
    as storage account, event hub, connections and Logic Apps
    required for an Industry Link.

    .Parameter WorkflowConfigFile
    The workflow configuration file that defines the trigger, the data
    source, the data sink and any transformations that will be applied.

    .Parameter TemplateDirectory
    The path to the workflow templates required for your Industry Link. This
    should contain at least one workflow template.

    .Parameter OutputDirectory
    The directory path where the ARM templates will be saved.

    .Example
    # Generate ARM templates from Logic App workflow templates
    New-AzureDeploymentPackage -WorkflowConfigFile workflow.json -TemplateDirectory templates -OutputDirectory output
#>
function New-AzureDeploymentPackage {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the workflow configuration JSON file.")]
        [string] $WorkflowConfigFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the directory containing the workflow templates.")]
        [string] $TemplateDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory
    )

    $workflowConfig = Get-Content $WorkflowConfigFile | ConvertFrom-Json
    $workflowName = $workflowConfig.name

    if (!(Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    }

    # Parent Logic App template dependencies
    $dependencies = @(
        "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', variables('managedIdentityName'))]"
    )

    $mainTemplate = Get-Content "$PSScriptRoot/azureDeploymentPackage/azuredeploy.json" | ConvertFrom-Json
    $mainTemplate.variables.managedIdentityName = "$($workflowName)User"

    # Generate ARM templates for data sink workflow
    $sinkDeploymentName = "$($workflowName)_Sink"
    New-ResourceTemplate -WorkflowName $workflowName -MainTemplate $mainTemplate -SubWorkflowConfig $workflowConfig.dataSink -OutputDirectory $OutputDirectory
    New-LogicAppTemplate -Name $sinkDeploymentName -Dependencies $dependencies -MainTemplate $mainTemplate -SubWorkflowConfig $workflowConfig.dataSink -TemplateDirectory $TemplateDirectory -OutputDirectory $OutputDirectory

    # Generate ARM templates for data transform workflow
    if ($null -ne $workflowConfig.dataTransform.type) {
        $transformDeploymentName = "$($workflowName)_Transform"
        New-LogicAppTemplate -Name $transformDeploymentName -Dependencies $dependencies -MainTemplate $mainTemplate -SubWorkflowConfig @{ type = "" } -TemplateDirectory $TemplateDirectory -OutputDirectory $OutputDirectory
        $dependencies += "[resourceId('Microsoft.Resources/deployments', '$transformDeploymentName')]"
    }

    # Generate ARM templates for data source workflow
    $dependencies += "[resourceId('Microsoft.Resources/deployments', '$sinkDeploymentName')]"
    New-ResourceTemplate -WorkflowName $workflowName -MainTemplate $mainTemplate -SubWorkflowConfig $workflowConfig.dataSource -OutputDirectory $OutputDirectory
    New-LogicAppTemplate -Name $workflowName -Dependencies $dependencies -MainTemplate $mainTemplate -SubWorkflowConfig $workflowConfig.dataSource -TemplateDirectory $TemplateDirectory -OutputDirectory $OutputDirectory

    # Generate main ARM template
    $mainTemplate | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/azuredeploy.json"
}

function New-ResourceTemplate {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the workflow.")]
        [string] $WorkflowName,
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The configuration object of the sub-workflow (source, sink, transform).")]
        [object] $SubWorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory
    )

    switch ($SubWorkflowConfig.type.ToLower()) {
        "azureblobstorage" {
            New-BlobStorageTemplate -MainTemplate $MainTemplate -Parameters $SubWorkflowConfig.parameters -OutputDirectory $OutputDirectory
            break
        }
        "dataverse" {
            New-DataverseTemplates -MainTemplate $MainTemplate -OutputDirectory $OutputDirectory
            break
        }
        "eventhub" {
            New-EventHubTemplates -WorkflowName $WorkflowName -MainTemplate $MainTemplate -Parameters $SubWorkflowConfig.parameters -OutputDirectory $OutputDirectory
            break
        }
        Default {
            throw "Sub-workflow type, $($SubWorkflowConfig.type), not supported."
        }
    }
}

function New-BlobStorageTemplate {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The sub-workflow parameters.")]
        [object] $Parameters,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory
    )

    try {
        $deployTemplate = Get-Content "$PSScriptRoot/azureDeploymentPackage/azureblobstorage/deploy.json" | ConvertFrom-Json
        $deployTemplate.variables.storageAccountName = $Parameters.storage_account_name.value
        $deployTemplate.variables.containerName = $Parameters.storage_container_name.value
        $deployTemplate | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/deploy.azureBlobStorage.json"
    }
    catch {
        throw "Failed to generate deployment template for Azure Blob Storage."
    }

    try {
        $deployDependencies = @(
            "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', variables('managedIdentityName'))]"
        )
        $deployLinkedTemplate = Get-LinkedTemplate -Name "azureblobstorage" -FileName "deploy.azureBlobStorage.json" -Dependencies $deployDependencies
        $deployLinkedTemplate.properties.parameters.managedIdentityName = @{
            value = "[variables('managedIdentityName')]"
        }
        $MainTemplate.resources += $deployLinkedTemplate
    }
    catch {
        throw "Failed to add linked template for Azure Blob Storage resource."
    }

    try {
        $connectionDependencies = @(
            "[resourceId('Microsoft.Resources/deployments', 'azureblobstorage')]"
        )
        Copy-Item "$PSScriptRoot/azureDeploymentPackage/azureblobstorage/connection.json" "$OutputDirectory/connection.azureBlobStorage.json"
        $MainTemplate.resources += Get-LinkedTemplate -Name "azureblobstorageconnection" -FileName "connection.azureBlobStorage.json" -Dependencies $connectionDependencies
    }
    catch {
        throw "Failed to add linked template for Azure Blob Storage connection."
    }
}

function New-DataverseTemplates {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory
    )

    # If this connection type was already added, skip adding another one
    $connectionName = "dataverseconnection"
    foreach ($resource in $MainTemplate.resources) {
        if ($connectionName -eq $resource.name) {
            return
        }
    }

    try {
        $linkedTemplate = Get-LinkedTemplate -Name $connectionName -FileName "connection.dataverse.json"
        $connectionTemplate = Get-Content "$PSScriptRoot/azureDeploymentPackage/dataverse/connection.json" | ConvertFrom-Json

        foreach ($param in @("tenantId", "clientId", "clientSecret")) {
            $linkedTemplate.properties.parameters.$param = @{
                value = "[parameters('$param')]"
            }

            if ($null -eq $MainTemplate.parameters.$param) {
                $MainTemplate.parameters | Add-Member -MemberType NoteProperty -Name $param -Value $connectionTemplate.parameters.$param
            }
        }
        $MainTemplate.resources += $linkedTemplate

        Copy-Item "$PSScriptRoot/azureDeploymentPackage/dataverse/connection.json" "$OutputDirectory/connection.dataverse.json"
    }
    catch {
        throw "Failed to add linked template for Dataverse connection."
    }
}

function New-EventHubTemplates {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the workflow.")]
        [string] $WorkflowName,
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The sub-workflow parameters.")]
        [object] $Parameters,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory
    )

    try {
        $deployTemplate = Get-Content "$PSScriptRoot/azureDeploymentPackage/eventhub/deploy.json" | ConvertFrom-Json
        $deployTemplate.variables.eventHubNamespaceName = "$($WorkflowName)eh".ToLower()
        $deployTemplate.variables.eventHubName = $Parameters.event_hub_name.value
        $deployTemplate.variables.consumerGroupName = $Parameters.event_hub_parameters.value.consumerGroupName
        $deployTemplate | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/deploy.eventHub.json"
    }
    catch {
        throw "Failed to generate deployment template for Event Hub."
    }

    try {
        $deployDependencies = @(
            "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', variables('managedIdentityName'))]"
        )
        $linkedTemplate = Get-LinkedTemplate -Name "eventhub" -FileName "deploy.eventHub.json" -Dependencies $deployDependencies
        $linkedTemplate.properties.parameters.managedIdentityName = @{
            value = "[variables('managedIdentityName')]"
        }
        $MainTemplate.resources += $linkedTemplate
    }
    catch {
        throw "Failed to add linked template for Event Hub resource."
    }

    try {
        $connectionDependencies = @(
            "[resourceId('Microsoft.Resources/deployments', 'eventhub')]"
        )
        $connectionTemplate = Get-Content "$PSScriptRoot/azureDeploymentPackage/eventhub/connection.json" | ConvertFrom-Json
        $connectionTemplate.variables.eventHubNamespaceName = "$($WorkflowName)eh".ToLower()
        $connectionTemplate | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/connection.eventHub.json"
        $MainTemplate.resources += Get-LinkedTemplate -Name "eventhubconnection" -FileName "connection.eventHub.json" -Dependencies $connectionDependencies
    }
    catch {
        throw "Failed to add linked template for Event Hub connection."
    }
}

function New-LogicAppTemplate {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the sub-workflow.")]
        [string] $Name,
        [Parameter(Mandatory = $true, HelpMessage = "The list of dependencies for the Logic App ARM template.")]
        [array] $Dependencies,
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The configuration object of the sub-workflow (source, sink, transform).")]
        [object] $SubWorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the directory containing the workflow templates.")]
        [string] $TemplateDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory
    )

    try {
        $logicAppTemplatePath = Join-Path $TemplateDirectory "$Name.json"
        $deployTemplate = Get-Content "$PSScriptRoot/azureDeploymentPackage/logicApp/deploy.json" | ConvertFrom-Json
        $resourceType = $SubWorkflowConfig.type.ToLower()

        if ("" -ne $resourceType) {
            $Dependencies += "[resourceId('Microsoft.Resources/deployments', '$($resourceType)connection')]"
        }
        $linkedTemplate = Get-LinkedTemplate -Name $Name -FileName "deploy.$Name.json" -Dependencies $Dependencies

        if ($resourceType -eq "dataverse") {
            $orgUrlParam = @{
                type     = "string"
                metadata = @{
                    description = "Azure AD authentication tenant ID."
                }
            }

            $deployTemplate.parameters | Add-Member -MemberType NoteProperty -Name "organizationUrl" -Value $orgUrlParam
            if ($null -eq $MainTemplate.parameters.organizationUrl) {
                $MainTemplate.parameters | Add-Member -MemberType NoteProperty -Name "organizationUrl" -Value $orgUrlParam
            }

            $linkedTemplate.properties.parameters.organizationUrl = @{
                value = "[parameters('organizationUrl')]"
            }
        }

        $deployTemplate.variables.name = $Name
        $deployTemplate.resources[0].properties = Get-Content $logicAppTemplatePath | ConvertFrom-Json
        $deployTemplate | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/deploy.$Name.json"

        $linkedTemplate.properties.parameters.managedIdentityName = @{
            value = "[variables('managedIdentityName')]"
        }
        $MainTemplate.resources += $linkedTemplate
    }
    catch {
        throw "Failed to generate deployment template for Logic App."
    }
}

function Get-LinkedTemplate {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the linked template.")]
        [string] $Name,
        [Parameter(Mandatory = $true, HelpMessage = "The name of the file for this linked template.")]
        [string] $FileName,
        [Parameter(Mandatory = $false, HelpMessage = "The list of dependencies for this linked template.")]
        [array] $Dependencies = @()
    )

    return @{
        type       = "Microsoft.Resources/deployments"
        apiVersion = "2021-04-01"
        name       = $Name
        properties = @{
            mode         = "Incremental"
            templateLink = @{
                uri            = "[concat(parameters('_artifactsLocation'), '$FileName', parameters('_artifactsLocationSasToken'))]"
                contentVersion = "1.0.0.0"
            }
            parameters   = @{
                location = @{
                    value = "[parameters('location')]"
                }
            }
        }
        dependsOn  = $Dependencies
    }
}

Export-ModuleMember -Function New-AzureDeploymentPackage
