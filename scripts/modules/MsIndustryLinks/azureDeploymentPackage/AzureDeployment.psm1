# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

<#
    .Synopsis
    Deploy your solution template offer Azure resources to your Azure
    subscription.

    .Description
    This script allows you to deploy your solution template offer to your
    Azure subscription. It uploads your scripts to a container on your
    storage account and generates a SAS token for the "_artifactsLocation"
    container. The container URI and SAS token is used in place of the
    "_artifactsLocation" and "_artifactsLocationSasToken" parameters in
    the solution template. These two parameters are usually generated by
    Azure during the deployment process.

    .Parameter ResourceGroup
    The name of the resource group where Azure resources are deployed to.
    The resource group will be created.

    .Parameter Location
    The region where Azure resources are deployed to.

    .Parameter TemplatesFolder
    The path to ARM templates folder.

    .Parameter ParametersFile
    The ARM templates parameters file.

    .Parameter StorageAccountName
    The name of the storage account where resources will be uploaded to.

    .Example
    # Deploy resources to the "contoso-rg" resource group in the eastus region
    New-AzureDeployment -ResourceGroup contoso-rg -Location eastus -TemplatesFolder templates -ParametersFile parameters.json -StorageAccountName mystorageaccount
#>
function New-AzureDeployment {
    param (
        [Parameter(Mandatory = $True, HelpMessage = "Resource group where Azure resources are deployed to.")]
        [String] $ResourceGroup,
        [Parameter(Mandatory = $True, HelpMessage = "Region where Azure resources are deployed to.")]
        [String] $Location,
        [Parameter(Mandatory = $True, HelpMessage = "Path to ARM templates folder.")]
        [String] $TemplatesFolder,
        [Parameter(Mandatory = $True, HelpMessage = "Parameters file.")]
        [String] $ParametersFile,
        [Parameter(Mandatory = $True, HelpMessage = "The name of the storage account where resources will be uploaded to.")]
        [String] $StorageAccountName
    )

    $resourceGroupNameRegex = "^[a-zA-Z0-9\.\-_\(\)]{1,89}[a-zA-Z0-9\-_\(\)]{1}$"
    $regionRegex = "^[a-z0-9]{1,30}$"

    # Validate input parameters
    if ($ResourceGroup -notmatch $resourceGroupNameRegex) {
        Write-Error "Please provide a valid Resource Group Name."
        Exit 1
    }

    if ($Location -notmatch $regionRegex) {
        Write-Error "Please provide a valid region."
        Exit 1
    }

    if (-not(Test-Path $TemplatesFolder)) {
        Write-Error "Please provide a valid assets folder path."
        Exit 1
    }

    if (-not(Test-Path $ParametersFile)) {
        Write-Error "Please provide a valid parameters file path."
        Exit 1
    }

    $workingDirectory = Get-Item .
    $parametersFilePath = Resolve-Path $ParametersFile

    try {
        $connectionString = Get-ConnectionString $StorageAccountName

        Set-Location $TemplatesFolder

        # Deploy
        Write-Output "Deploying to $ResourceGroup in $Location using parameters from $ParametersFile..."
        az group create -n $ResourceGroup -l $Location --output none

        $armParameters = (Get-Content -Path mainTemplate.json -Raw | ConvertFrom-Json).parameters
        if ($null -ne $armParameters._artifactsLocation) {
            # Upload scripts to storage account
            $containerName = ("templates" + (get-date).ToString("MMddyyhhmmss"))
            Write-Output "Uploading scripts to $containerName in storage account..."
            az storage container create -n $containerName --connection-string $connectionString --output none
            az storage blob upload-batch -d ($containerName) -s "." --pattern "*.json" --connection-string $connectionString --output none
            $containerLocation = "https://" + $StorageAccountName + ".blob.core.windows.net/" + $containerName + "/"

            # Generate SAS for container
            Write-Output "Generating SAS to $containerName..."
            $end = (Get-Date).ToUniversalTime()
            $end = $end.AddDays(1)
            $endsas = ($end.ToString("yyyy-MM-ddTHH:mm:ssZ"))
            $sas = az storage container generate-sas -n $containerName --https-only --permissions r --expiry $endsas -o tsv --connection-string $connectionString
            $sas = ("?" + $sas)

            $result = az deployment group create -g $ResourceGroup -f mainTemplate.json --parameters "@$parametersFilePath" --parameters location=$Location _artifactsLocation=$containerLocation _artifactsLocationSasToken="""$sas"""
        }
        else {
            $result = az deployment group create -g $ResourceGroup -f mainTemplate.json --parameters "@$parametersFilePath" --parameters location=$Location
        }

        if ($result) {
            Write-Output "Deployment complete!"
        }
        else {
            Write-Error "Deployment failed!"
        }
    }
    catch {
        throw $_.Exception.Message
    }
    finally {
        if ($null -ne $containerName) {
            Write-Output "Cleaning up..."
            az storage container delete -n $containerName --connection-string $connectionString --output none
        }

        Set-Location $workingDirectory
    }
}

<#
    .Description
    Returns the connection string for the provided storage account.
#>
function Get-ConnectionString {
    param (
        [Parameter(Mandatory = $True, HelpMessage = "The storage account to get the connection string for.")]
        [String] $StorageAccountName
    )

    $connectionString = (az storage account show-connection-string --name $StorageAccountName -o json | ConvertFrom-Json).connectionString
    return $connectionString
}

Export-ModuleMember -Function New-AzureDeployment
