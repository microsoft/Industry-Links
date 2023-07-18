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

    .Parameter ApiDefinitionFile
    The path to the custom connector Swagger API definition file. This is
    the API definition file required to deploy a non-verified custom
    connector for your API. Support authentication types: API Key.

    .Example
    # Generate ARM templates from Logic App workflow templates
    New-AzureDeploymentPackage -WorkflowConfigFile workflow.json -TemplateDirectory templates -OutputDirectory output

    # Generate ARM templates from Logic App workflow templates that uses a non-verified custom connector as a source or sink
    New-AzureDeploymentPackage -WorkflowConfigFile workflow.json -TemplateDirectory templates -OutputDirectory output -ApiDefinitionFile api.swagger.json
#>
function New-AzureDeploymentPackage {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the workflow configuration JSON file.")]
        [string] $WorkflowConfigFile,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the directory containing the workflow templates.")]
        [string] $TemplateDirectory,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the custom connector Swagger API definition file.")]
        [string] $ApiDefinitionFile = ""
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

    $mainTemplate = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/azuredeploy.json" | ConvertFrom-Json
    $mainTemplate.variables.managedIdentityName = "$($workflowName)User"

    $resourceTypes = @(
        "Microsoft.ManagedIdentity/userAssignedIdentities",
        "Microsoft.Logic/workflows"
    )

    # Generate ARM templates for data sink workflow
    $sinkDeploymentName = "$($workflowName)_Sink"
    New-ResourceTemplate -WorkflowName $workflowName -MainTemplate $mainTemplate -SubWorkflowConfig $workflowConfig.dataSink -OutputDirectory $OutputDirectory -ApiDefinitionFile $ApiDefinitionFile
    New-LogicAppTemplate -Name $sinkDeploymentName -Dependencies $dependencies -MainTemplate $mainTemplate -SubWorkflowConfig $workflowConfig.dataSink -TemplateDirectory $TemplateDirectory -OutputDirectory $OutputDirectory
    $resourceTypes = Add-ResourceType -SubWorkflowConfig $workflowConfig.dataSink -ResourceTypes $resourceTypes

    # Generate ARM templates for data transform workflow
    if ($null -ne $workflowConfig.dataTransform.type) {
        $transformDeploymentName = "$($workflowName)_Transform"
        New-LogicAppTemplate -Name $transformDeploymentName -Dependencies $dependencies -MainTemplate $mainTemplate -SubWorkflowConfig @{ type = "" } -TemplateDirectory $TemplateDirectory -OutputDirectory $OutputDirectory
        $dependencies += "[resourceId('Microsoft.Resources/deployments', '$transformDeploymentName')]"
    }

    # Generate ARM templates for data source workflow
    $dependencies += "[resourceId('Microsoft.Resources/deployments', '$sinkDeploymentName')]"
    New-ResourceTemplate -WorkflowName $workflowName -MainTemplate $mainTemplate -SubWorkflowConfig $workflowConfig.dataSource -OutputDirectory $OutputDirectory -ApiDefinitionFile $ApiDefinitionFile
    New-LogicAppTemplate -Name $workflowName -Dependencies $dependencies -MainTemplate $mainTemplate -SubWorkflowConfig $workflowConfig.dataSource -TemplateDirectory $TemplateDirectory -OutputDirectory $OutputDirectory
    $resourceTypes = Add-ResourceType -SubWorkflowConfig $workflowConfig.dataSource -ResourceTypes $resourceTypes

    # Generate main ARM template
    $mainTemplate | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/mainTemplate.json"

    New-CreateUiDefinition -MainTemplate $mainTemplate -ResourceTypes $resourceTypes -OutputDirectory $OutputDirectory

    Compress-Archive -Path "$OutputDirectory/*.json" -DestinationPath "$OutputDirectory/marketplacePackage.zip" -Force
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
        [string] $OutputDirectory,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the custom connector Swagger API definition file.")]
        [string] $ApiDefinitionFile = ""
    )

    switch ($SubWorkflowConfig.type.ToLower()) {
        "azureblobstorage" {
            New-BlobStorageTemplates -MainTemplate $MainTemplate -Parameters $SubWorkflowConfig.parameters -OutputDirectory $OutputDirectory
            break
        }
        "customconnector" {
            New-CustomConnectorTemplates -MainTemplate $MainTemplate -SubWorkflowConfig $SubWorkflowConfig -OutputDirectory $OutputDirectory -ApiDefinitionFile $ApiDefinitionFile
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

function New-BlobStorageTemplates {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The sub-workflow parameters.")]
        [object] $Parameters,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory
    )

    try {
        $deployTemplate = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/azureblobstorage/deploy.json" | ConvertFrom-Json
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
        Copy-Item "$PSScriptRoot/package/azureDeploymentPackage/azureblobstorage/connection.json" "$OutputDirectory/connection.azureBlobStorage.json"
        $MainTemplate.resources += Get-LinkedTemplate -Name "azureblobstorageconnection" -FileName "connection.azureBlobStorage.json" -Dependencies $connectionDependencies
    }
    catch {
        throw "Failed to add linked template for Azure Blob Storage connection."
    }
}

function New-CustomConnectorTemplates {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The configuration object of the sub-workflow (source, sink, transform).")]
        [object] $SubWorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the ARM templates will be saved.")]
        [string] $OutputDirectory,
        [Parameter(Mandatory = $false, HelpMessage = "The path to the custom connector Swagger API definition file.")]
        [string] $ApiDefinitionFile = ""
    )

    $properties = $SubWorkflowConfig.properties
    $name = $properties.name.ToLower()
    $authType = $properties.authType.ToLower()

    # If this connection type with the same name was already added, skip adding another one
    foreach ($resource in $MainTemplate.resources) {
        if ($name -eq $resource.name) {
            return
        }
    }

    if ("apikey" -ne $authType) {
        throw "The custom connector, $($properties.name), with authentication type, $($properties.authType), is not supported."
    }

    $fileName = "connection.$name.json"
    $connectionTemplate = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/customconnector/$authType.connection.json" | ConvertFrom-Json
    $connectionTemplate.variables.name = $properties.name

    $dependencies = @()
    if (-not $SubWorkflowConfig.isCertified) {
        if ("" -eq $ApiDefinitionFile) {
            throw "The Swagger API definition file is required for custom connectors that are not certified."
        }

        $swaggerDefinition = Get-Content $ApiDefinitionFile | ConvertFrom-Json
        $securityDefinition = ($swaggerDefinition.securityDefinitions.PSObject.Properties | Select -First 1).Value

        if ($null -eq $securityDefinition) {
            throw "An API key security definition must be defined."
        }
        if ("apikey" -ne $securityDefinition.type.ToLower()) {
            throw "The security definition type, $($securityDefinition.type), is not supported. Choose from: apiKey."
        }

        try {
            $deployTemplate = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/customconnector/deploy.json" | ConvertFrom-Json
            $deployTemplate.variables.name = $properties.name
            $deployTemplate.resources[0].properties.backendService.serviceUrl = "$($swaggerDefinition.schemes[0])://$($swaggerDefinition.host)$($swaggerDefinition.basePath)"
            $deployTemplate.resources[0].properties.swagger = $swaggerDefinition
            $deployTemplate | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/deploy.$name.json"

            $deployLinkedTemplate = Get-LinkedTemplate -Name $name -FileName "deploy.$name.json"
            $MainTemplate.resources += $deployLinkedTemplate
        }
        catch {
            throw "Failed to generate deployment template for custom connector."
        }

        $connectionTemplate.resources[0].properties.api.id = "[resourceId('Microsoft.Web/customApis', toLower(variables('name')))]"

        $dependencies = @(
            "[resourceId('Microsoft.Resources/deployments', '$name')]"
        )
    }

    try {
        $connectionLinkedTemplate = Get-LinkedTemplate -Name "$($name)connection" -FileName $fileName -Dependencies $dependencies
        Add-ConnectionTemplateParameters -MainTemplate $MainTemplate -LinkedTemplate $connectionLinkedTemplate -Parameters $connectionTemplate.parameters -Prefix $name
        $MainTemplate.resources += $connectionLinkedTemplate

        $connectionTemplate | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/$fileName"
    }
    catch {
        throw "Failed to add linked template for custom connector connection."
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
        $connectionTemplate = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/dataverse/connection.json" | ConvertFrom-Json
        Add-ConnectionTemplateParameters -MainTemplate $MainTemplate -LinkedTemplate $linkedTemplate -Parameters $connectionTemplate.parameters
        $MainTemplate.resources += $linkedTemplate

        Copy-Item "$PSScriptRoot/package/azureDeploymentPackage/dataverse/connection.json" "$OutputDirectory/connection.dataverse.json"
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
        $deployTemplate = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/eventhub/deploy.json" | ConvertFrom-Json
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
        $connectionTemplate = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/eventhub/connection.json" | ConvertFrom-Json
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
        $deployTemplate = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/logicApp/deploy.json" | ConvertFrom-Json
        $resourceType = $SubWorkflowConfig.type.ToLower()

        if ("" -ne $resourceType) {
            if ("customconnector" -eq $resourceType) {
                $connectionName = "$($SubWorkflowConfig.properties.name)connection"
            }
            else {
                $connectionName = "$($resourceType)connection"
            }
            $Dependencies += "[resourceId('Microsoft.Resources/deployments', '$connectionName')]"
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

function New-CreateUiDefinition {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The list of resource types.")]
        [array] $ResourceTypes,
        [Parameter(Mandatory = $true, HelpMessage = "The directory path where the createUiDefinition.json file will be saved.")]
        [string] $OutputDirectory
    )

    $uiDefinition = Get-Content "$PSScriptRoot/package/azureDeploymentPackage/createUiDefinition.json" | ConvertFrom-Json

    $ignoreParams = @("location", "_artifactsLocation", "_artifactsLocationSasToken")
    foreach ($param in $MainTemplate.parameters.PSObject.Properties) {
        if ($param.Name -notin $ignoreParams) {
            $paramValue = $param.Value
            switch ($paramValue.type.ToLower()) {
                "string" {
                    $uiDefinition.parameters.basics += New-TextBoxUIElement -Name $param.Name -Label $param.Name -Tooltip $paramValue.metadata.description
                    break
                }
                "securestring" {
                    $uiDefinition.parameters.basics += New-SecretTextBoxUIElement -Name $param.Name -Label $param.Name -Tooltip $paramValue.metadata.description
                    break
                }
                Default {
                    throw "Unsupported createUiDefinition parameter type: $($paramValue.type)"
                }
            }

            $uiDefinition.parameters.outputs | Add-Member -MemberType NoteProperty -Name $param.Name -Value "[basics('$($param.Name)')]"
        }
    }

    $uiDefinition.parameters.resourceTypes = $ResourceTypes
    $uiDefinition.parameters.steps[0].elements[0].resources = $ResourceTypes

    $uiDefinition | ConvertTo-Json -Depth 100 | Out-File "$OutputDirectory/createUiDefinition.json"
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

function Add-ConnectionTemplateParameters {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The main ARM template object.")]
        [object] $MainTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The linked ARM template object.")]
        [object] $LinkedTemplate,
        [Parameter(Mandatory = $true, HelpMessage = "The connection template parameters.")]
        [object] $Parameters,
        [Parameter(Mandatory = $false, HelpMessage = "The prefix to add to the parameter names.")]
        [string] $Prefix = ""
    )

    if ("" -ne $Prefix) {
        $Prefix = "$($Prefix)_"
    }

    foreach ($param in $Parameters.PSObject.Properties) {
        $paramName = $param.Name

        # Skip location parameter
        if ("location" -ne $paramName) {
            $mainParamName = "$Prefix$paramName"
            $LinkedTemplate.properties.parameters.$paramName = @{
                value = "[parameters('$mainParamName')]"
            }

            if ($null -eq $MainTemplate.parameters.$mainParamName) {
                $MainTemplate.parameters | Add-Member -MemberType NoteProperty -Name $mainParamName -Value $param.Value
            }
        }
    }
}

function Add-ResourceType {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The configuration object of the sub-workflow (source, sink, transform).")]
        [object] $SubWorkflowConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The list of resource types.")]
        [array] $ResourceTypes
    )

    switch ($SubWorkflowConfig.type.ToLower()) {
        "azureblobstorage" {
            if ("Microsoft.Storage/storageAccounts" -notin $ResourceTypes) {
                $ResourceTypes += "Microsoft.Storage/storageAccounts"
            }
        }
        "eventhub" {
            if ("Microsoft.EventHub/namespaces/eventhubs" -notin $ResourceTypes) {
                $ResourceTypes += "Microsoft.EventHub/namespaces/eventhubs"
            }
        }
        Default {
            # Do nothing
        }
    }

    return $ResourceTypes
}

function New-TextBoxUIElement {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $Name,
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $Label,
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $Tooltip,
        [Parameter(Mandatory = $false, HelpMessage = "Name of the solution provider.")]
        [string] $DefaultValue = "",
        [Parameter(Mandatory = $false, HelpMessage = "Name of the solution provider.")]
        [bool] $Required = $true
    )

    return @{
        name         = $Name
        type         = "Microsoft.Common.TextBox"
        label        = $Label
        toolTip      = $Tooltip
        defaultValue = $DefaultValue
        constraints  = @{
            required = $Required
        }
        visible      = $true
    }
}

function New-SecretTextBoxUIElement {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $Name,
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $Label,
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $Tooltip,
        [Parameter(Mandatory = $false, HelpMessage = "Name of the solution provider.")]
        [bool] $Required = $true
    )

    return @{
        name        = $Name
        type        = "Microsoft.Common.PasswordBox"
        label       = @{
            password        = $Label
            confirmPassword = $Label
        }
        toolTip     = $Tooltip
        constraints = @{
            required = $Required
        }
        options     = @{
            hideConfirmation = $true
        }
        visible     = $true
    }
}

Export-ModuleMember -Function New-AzureDeploymentPackage
