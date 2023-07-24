# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .Synopsis
    Generates an App Source package and creates an offer for the Industry Link.

    .Description
    Generates an App Source package and creates an Industry Link offer that is
    ready for publishing.

    .Parameter ProviderName
    Name of the managed solution provider.

    .Parameter ConfigFile
    The configuration file containing settings for Partner Center API authentication
    and creating the AppSource offer.

    .Parameter SolutionZip
    The managed solution package file (zip) containing the Industry Link components
    such as Power Automate Flows.

    .Parameter AppSourceAssets
    The path to the folder containing assets for the AppSource package and offer
    such as input.xml, terms of use HTML file, logos, screenshots, and marketing
    materials.

    .Parameter StorageAccount
    Name of the Azure Storage account where the AppSource package will be uploaded.
    A SAS URI will be generated for the uploaded package and used to create the
    offer.

    .Parameter StorageContainer
    Name of the storage container where the AppSource package will be uploaded.
    Default: appsource-packages.

    .Example
    # Generate an AppSource package and create offer for the Industry Link
    New-AppSourceOffer -ProviderName Contoso -ConfigFile config.json -SolutionZip ContosoIndustryLink.zip -AppSourceAssets assets -StorageAccount mystorageaccount -StorageContainer appsource-packages
#>
function New-AppSourceOffer {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $ProviderName,
        [Parameter(Mandatory = $true, HelpMessage = "The configuration file for creating the AppSource offer.")]
        [string] $ConfigFile,
        [Parameter(Mandatory = $true, HelpMessage = "The solution package file (zip).")]
        [string] $SolutionZip,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the AppSource assets folder.")]
        [string] $AppSourceAssets,
        [Parameter(Mandatory = $true, HelpMessage = "Name of the Azure Storage Account where the AppSource package will be uploaded.")]
        [string] $StorageAccount,
        [Parameter(Mandatory = $false, HelpMessage = "Name of the storage container where the AppSource package will be uploaded.")]
        [string] $StorageContainer = "appsource-packages"
    )

    $config = Get-Content -Path $ConfigFile | ConvertFrom-Json
    $authConfig = $config.authentication

    # Create AppSource package
    $appSourceZipPackage = New-AppSourcePackage -ProviderName $ProviderName -SolutionZip $SolutionZip -AppSourceAssets $AppSourceAssets

    # Upload AppSource package to Azure Storage and generate SAS URL for it
    $packageUri = Add-FileToStorageAccount -AppSourcePackage $appSourceZipPackage -StorageAccount $StorageAccount -StorageContainer $StorageContainer

    # Create AppSource offer
    $accessToken = Get-PartnerIngestionApiToken -TenantId $authConfig.tenantId -ClientId $authConfig.clientId -ClientSecret $authConfig.clientSecret
    Update-Offer -AccessToken $accessToken -AppSourceAssets $AppSourceAssets -PackageUri $packageUri
}

function Join-Object {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Source object to copy properties from.")]
        [object] $Source,
        [Parameter(Mandatory = $true, HelpMessage = "Target object to copy properties into.")]
        [object] $Target
    )

    # Copy source properties to target object
    foreach ($Property in $Source | Get-Member -type NoteProperty, Property) {
        if ($null -ne $Target.$($Property.Name)) {
            $Target.$($Property.Name) = $Source.$($Property.Name)
        }
        else {
            $Target | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Source.$($Property.Name) -Force
        }
    }
}

function Add-FileToSasUri {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "File path of the asset to upload.")]
        [string] $AssetFilePath,
        [Parameter(Mandatory = $true, HelpMessage = "Location (with SAS) to upload the asset.")]
        [string] $FileSasUri
    )

    azcopy copy $AssetFilePath $FileSasUri --output-level quiet
}

function Send-ApiRequest {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The URI to send the request to.")]
        [string] $Uri,
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken,
        [Parameter(Mandatory = $false, HelpMessage = "The request method.")]
        [string] $Method = "Get",
        [Parameter(Mandatory = $false, HelpMessage = "The URI to send the request to.")]
        [hashtable] $Headers = @{},
        [Parameter(Mandatory = $false, HelpMessage = "The request body.")]
        [string] $Body = ""
    )

    $baseUri = "https://api.partner.microsoft.com/v1.0/ingestion"
    $reqHeaders = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    # Add custom headers
    foreach ($key in $Headers.Keys) {
        $reqHeaders.Add($key, $Headers[$key])
    }

    $response = Invoke-RestMethod -Method $Method -Uri "$baseUri/$Uri" -Headers $reqHeaders -Body $Body

    return $response
}

function Get-PartnerIngestionApiToken {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Authentication tenant ID.")]
        [string] $TenantId,
        [Parameter(Mandatory = $true, HelpMessage = "Authentication client ID.")]
        [string] $ClientId,
        [Parameter(Mandatory = $true, HelpMessage = "Authentication client secret.")]
        [string] $ClientSecret
    )

    # Get Partner Center API token
    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/token"
    $headers = @{
        "Content-Type" = "application/x-www-form-urlencoded"
    }
    $body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=https://api.partner.microsoft.com"
    $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Headers $headers -Body $body

    return $response.access_token
}

function Get-ModuleInstanceId {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken,
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the offer to get the module for.")]
        [string] $OfferGuid,
        [Parameter(Mandatory = $true, HelpMessage = "The module to get the instance ID for. Valid values are Listing, Package, Property, Availability.")]
        [string] $Module,
        [Parameter(Mandatory = $false, HelpMessage = "The plan ID to get the module for.")]
        [string] $PlanId = ""
    )

    $variantId = $PlanId -eq "" ? $null : $PlanId

    try {
        $response = Send-ApiRequest -Uri "products/$OfferGuid/branches/getByModule(module=$Module)" -AccessToken $AccessToken
        $instanceId = $response.value | Where-Object { $variantId -eq $_.variantID } | Select-Object -First 1 -ExpandProperty currentDraftInstanceID
        return $instanceId
    }
    catch {
        throw "There was an issue getting the module, $Module, instance ID for $OfferGuid. Error: $($_.Exception.Message)"
    }
}

function Add-ListingAsset {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the offer to add the listing assets for.")]
        [string] $OfferGuid,
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the listing to add the assets for.")]
        [string] $ListingGuid,
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the offer listing assets folder.")]
        [string] $ListingAssetsPath,
        [Parameter(Mandatory = $true, HelpMessage = "The list of assets to add to the listing.")]
        [object] $ListingAssets
    )

    $listingBaseUri = "products/$OfferGuid/listings/$ListingGuid"
    foreach ($asset in $ListingAssets) {
        $assetType = $asset.resourceType.Substring(7).ToLower()
        $assetBaseUri = "$listingBaseUri/$($assetType)s"

        if ($assetType -eq "video") {
            $assetFilename = $asset.thumbnail.fileName
        }
        else {
            $assetFilename = $asset.fileName
            if ($null -ne $asset.state) {
                $asset.state = "PendingUpload"
            }
            else {
                $asset | Add-Member -MemberType NoteProperty -Name "state" -Value "PendingUpload" -Force | Out-Null
            }
        }
        $assetBody = $asset | ConvertTo-Json

        try {
            $assetResponse = Send-ApiRequest -Method Post -Uri $assetBaseUri -AccessToken $AccessToken -Body $assetBody
            $assetPath = Join-Path -Path $ListingAssetsPath -ChildPath "$assetType/$assetFilename"

            if ($assetType -eq "video") {
                $fileSasUri = $assetResponse.thumbnail.fileSasUri
            }
            else {
                $fileSasUri = $assetResponse.fileSasUri
            }
            Add-FileToSasUri -AssetFilePath $assetPath -FileSasUri $fileSasUri

            if ($assetType -eq "video") {
                $assetResponse.thumbnail.state = "Uploaded"
                $assetResponse.thumbnail.PSObject.Properties.Remove('fileSasUri')
            }
            else {
                $assetResponse.state = "Uploaded"
                $assetResponse.PSObject.Properties.Remove('fileSasUri')
            }
            $assetBody = $assetResponse | ConvertTo-Json

            $putHeaders = @{
                "If-Match" = $assetResponse.'@odata.etag'
            }
            Send-ApiRequest -Method Put -Uri "$assetBaseUri/$($assetResponse.id)" -AccessToken $AccessToken -Headers $putHeaders -Body $assetBody | Out-Null
        }
        catch {
            throw "There was an issue adding the listing $assetType, $assetFilename. Error: $($_.Exception.Message)"
        }
    }
}

function Remove-ListingAsset {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the offer to add the listing assets for.")]
        [string] $OfferGuid,
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the listing to add the assets for.")]
        [string] $ListingGuid,
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken
    )

    $listingBaseUri = "products/$OfferGuid/listings/$ListingGuid"
    $assetTypes = "assets", "images", "videos"
    foreach ($assetType in $assetTypes) {
        $assets = (Send-ApiRequest -Uri "$listingBaseUri/$assetType" -AccessToken $AccessToken).value
        foreach ($asset in $assets) {
            try {
                if ($PSCmdlet.ShouldProcess("$assetType/$($asset.id)", "Removing listing asset")) {
                    Send-ApiRequest -Method Delete -Uri "$listingBaseUri/$assetType/$($asset.id)" -AccessToken $AccessToken | Out-Null
                }
            }
            catch {
                throw "There was an issue removing the listing $assetType with ID $($asset.id). Error: $($_.Exception.Message)"
            }
        }
    }
}

function Update-Offer {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the AppSource assets folder.")]
        [string] $AppSourceAssets,
        [Parameter(Mandatory = $true, HelpMessage = "The AppSource package SAS URI.")]
        [string] $PackageUri
    )

    $offerConfig = Get-Content -Path "$AppSourceAssets/offer.json" | ConvertFrom-Json
    $externalId = $offerConfig.product.externalIDs | Select-Object -First 1 -ExpandProperty value
    $listingAssetsPath = Join-Path -Path $AppSourceAssets -ChildPath "listing"

    # Check for existing offer. Create a new offer if none found.
    $response = Send-ApiRequest -Uri "products?`$filter=ExternalIDs/Any(i:i/Type eq 'AzureOfferId' and i/Value eq '$externalId')" -AccessToken $AccessToken
    if ($response.value.Count -eq 0) {
        try {
            $productBody = $offerConfig.product | ConvertTo-Json -Depth 5
            $offerGuid = (Send-ApiRequest -Method Post -Uri "products" -AccessToken $AccessToken -Body $productBody).id
        }
        catch {
            throw "There was an issue creating the product and setup. Error: $($_.Exception.Message)"
        }
    }
    else {
        $offerGuid = $response.value[0].id
    }

    # Update offer setup
    try {
        $setupBody = $offerConfig.setup | ConvertTo-Json -Depth 5
        Send-ApiRequest -Method Post -Uri "products/$offerGuid/setup" -AccessToken $AccessToken -Body $setupBody | Out-Null
    }
    catch {
        throw "There was an issue updating the product setup. Error: $($_.Exception.Message)"
    }

    Set-OfferProperty -OfferGuid $offerGuid -AccessToken $AccessToken -OfferProperties $offerConfig.property
    Set-OfferListing -OfferGuid $offerGuid -AccessToken $AccessToken -OfferListing $offerConfig.listing -OfferListingAssets $offerConfig.listingAssets -OfferListingAssetsPath $listingAssetsPath
    Set-OfferAvailability -OfferGuid $offerGuid -AccessToken $AccessToken -OfferAvailability $offerConfig.featureAvailability
    Set-OfferTechnicalConfiguration -OfferGuid $offerGuid -AccessToken $AccessToken -OfferPackageConfig $offerConfig.packageConfiguration -PackageUri $PackageUri
}

function Set-OfferProperty {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the offer to update.")]
        [string] $OfferGuid,
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken,
        [Parameter(Mandatory = $true, HelpMessage = "The offer properties to set.")]
        [object] $OfferProperties
    )

    try {
        $propertiesBaseUri = "products/$OfferGuid/properties"
        $instanceId = Get-ModuleInstanceId -AccessToken $AccessToken -OfferGuid $OfferGuid -Module "Property"
        $properties = (Send-ApiRequest -Uri "$propertiesBaseUri/getByInstanceID(instanceID=$instanceId)" -AccessToken $AccessToken).value[0]
        Join-Object -Source $OfferProperties -Target $properties
        $propertiesBody = $properties | ConvertTo-Json -Depth 10

        $putHeaders = @{
            "If-Match" = $properties.'@odata.etag'
        }
        if ($PSCmdlet.ShouldProcess($properties.id, "Updating offer properties")) {
            Send-ApiRequest -Method Put -Uri "$propertiesBaseUri/$($properties.id)" -AccessToken $AccessToken -Headers $putHeaders -Body $propertiesBody | Out-Null
        }
    }
    catch {
        throw "There was an issue updating the product properties. Error: $($_.Exception.Message)"
    }
}

function Set-OfferListing {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the offer to update.")]
        [string] $OfferGuid,
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken,
        [Parameter(Mandatory = $true, HelpMessage = "The offer listing to set.")]
        [object] $OfferListing,
        [Parameter(Mandatory = $true, HelpMessage = "The offer listing assets to set.")]
        [object] $OfferListingAssets,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the listing assets.")]
        [string] $OfferListingAssetsPath
    )

    try {
        $listingBaseUri = "products/$OfferGuid/listings"
        $instanceId = Get-ModuleInstanceId -AccessToken $AccessToken -OfferGuid $OfferGuid -Module "Listing"
        $listing = (Send-ApiRequest -Uri "$listingBaseUri/getByInstanceID(instanceID=$instanceId)" -AccessToken $AccessToken).value[0]
        Join-Object -Source $OfferListing -Target $listing
        $listingBody = $listing | ConvertTo-Json -Depth 10

        $putHeaders = @{
            "If-Match" = $listing.'@odata.etag'
        }
        if ($PSCmdlet.ShouldProcess($listing.id, "Updating offer listing")) {
            Send-ApiRequest -Method Put -Uri "$listingBaseUri/$($listing.id)" -AccessToken $AccessToken -Headers $putHeaders -Body $listingBody | Out-Null
        }
    }
    catch {
        throw "There was an issue updating the product listing. Error: $($_.Exception.Message)"
    }

    # Add listing assets, images, and videos
    Remove-ListingAsset -OfferGuid $OfferGuid -ListingGuid $listing.id -AccessToken $AccessToken
    Add-ListingAsset -OfferGuid $OfferGuid -ListingGuid $listing.id -AccessToken $AccessToken -ListingAssetsPath $OfferListingAssetsPath -ListingAssets $OfferListingAssets
}

function Set-OfferAvailability {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the offer to update.")]
        [string] $OfferGuid,
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken,
        [Parameter(Mandatory = $true, HelpMessage = "The offer availability to set.")]
        [object] $OfferAvailability
    )

    try {
        $availabilityBaseUri = "products/$OfferGuid/featureAvailabilities"
        $instanceId = Get-ModuleInstanceId -AccessToken $AccessToken -OfferGuid $OfferGuid -Module "Availability"
        $availability = (Send-ApiRequest -Uri "$availabilityBaseUri/getByInstanceID(instanceID=$instanceId)?`$expand=MarketStates,PriceSchedule,Trial" -AccessToken $AccessToken).value[0]
        Join-Object -Source $OfferAvailability -Target $availability
        $availabilityBody = $availability | ConvertTo-Json -Depth 10

        $putHeaders = @{
            "If-Match" = $availability.'@odata.etag'
        }
        if ($PSCmdlet.ShouldProcess($availability.id, "Updating offer availability")) {
            Send-ApiRequest -Method Put -Uri "$availabilityBaseUri/$($availability.id)?`$expand=MarketStates,PriceSchedule,Trial" -AccessToken $AccessToken -Headers $putHeaders -Body $availabilityBody | Out-Null
        }
    }
    catch {
        throw "There was an issue updating the product feature availabilities. Error: $($_.Exception.Message)"
    }
}

function Set-OfferTechnicalConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The GUID of the offer to update.")]
        [string] $OfferGuid,
        [Parameter(Mandatory = $true, HelpMessage = "Partner Ingestion API access token.")]
        [string] $AccessToken,
        [Parameter(Mandatory = $true, HelpMessage = "The offer package configuration to set.")]
        [object] $OfferPackageConfig,
        [Parameter(Mandatory = $true, HelpMessage = "The AppSource package SAS URI.")]
        [string] $PackageUri
    )

    try {
        $packageBaseUri = "products/$OfferGuid/packageConfigurations"
        $instanceId = Get-ModuleInstanceId -AccessToken $AccessToken -OfferGuid $OfferGuid -Module "Package"
        $packageConfiguration = (Send-ApiRequest -Uri "$packageBaseUri/getByInstanceID(instanceID=$instanceId)" -AccessToken $AccessToken).value[0]
        Join-Object -Source $OfferPackageConfig -Target $packageConfiguration
        $packageConfiguration | Add-Member -MemberType NoteProperty -Name "packageLocationUri" -Value $PackageUri -Force
        $packageConfigBody = $packageConfiguration | ConvertTo-Json -Depth 10

        $putHeaders = @{
            "If-Match" = $packageConfiguration.'@odata.etag'
        }
        if ($PSCmdlet.ShouldProcess($packageConfiguration.id, "Updating offer technical configuration")) {
            Send-ApiRequest -Method Put -Uri "$packageBaseUri/$($packageConfiguration.id)" -AccessToken $AccessToken -Headers $putHeaders -Body $packageConfigBody | Out-Null
        }
    }
    catch {
        throw "There was an issue updating the product package configuration. Error: $($_.Exception.Message)"
    }
}

<#
    .Synopsis
    Generates an App Source package for publishing.

    .Description
    Generates an App Source package for the Industry Link that is ready for
    publishing.

    .Parameter ProviderName
    Name of the managed solution provider.

    .Parameter SolutionZip
    The managed solution package file (zip) containing the Industry Link
    components such as Power Automate Flows.

    .Parameter AppSourceAssets
    The path to the folder containing assets for the AppSource package such as
    the icon, input.xml file and terms of use HTML file.

    .Example
    # Generate an AppSource package from managed solution
    New-AppSourcePackage -ProviderName Contoso -SolutionZip ContosoIndustryLink.zip -AppSourceAssets assets
#>
function New-AppSourcePackage {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $ProviderName,
        [Parameter(Mandatory = $true, HelpMessage = "The solution package file (zip).")]
        [string] $SolutionZip,
        [Parameter(Mandatory = $true, HelpMessage = "The path to the AppSource assets folder.")]
        [string] $AppSourceAssets
    )

    $workingDirectory = Get-Item .
    $packageName = (Get-Item $SolutionZip).BaseName
    $solutionPath = Get-Item $SolutionZip
    $assetsFullPath = (Get-Item $AppSourceAssets).FullName

    $cleanProviderName = $ProviderName -Replace "[\W_]", ""
    $cleanPackageName = $packageName -Replace "[\W_]", ""
    $appSourcePackageName = "$($cleanProviderName)_$cleanPackageName.zip"
    $appSourcePackagePath = Join-Path -Path $workingDirectory -ChildPath $appSourcePackageName

    # Create Dynamics 365 package
    try {
        $tmpDirectory = [guid]::NewGuid()
        New-Item -Name $tmpDirectory -Type Directory | Out-Null
        Set-Location $tmpDirectory

        pac package init --outputDirectory $packageName | Out-Null

        Set-Location $packageName
        pac package add-solution --path $solutionPath | Out-Null
        dotnet publish | Out-Null

        $packageFile = Get-ChildItem -Path "bin/Debug" -Filter "$($packageName)*.pdpkg.zip" | Sort-Object -Descending -Property LastWriteTime | Select-Object -First 1
    }
    catch {
        Set-Location $workingDirectory
        throw "There was an issue creating the Dynamics 365 package. Error: $($_.ErrorDetails.Message)"
    }

    # Create AppSource package
    try {
        New-Item -ItemType Directory -Path AppSourcePackage | Out-Null
        Copy-Item -Path $packageFile -Destination AppSourcePackage/package.zip | Out-Null
        Copy-Item -Path "$PSScriptRoot/publish/appsource/assets/``[Content_Types``].xml" -Destination AppSourcePackage | Out-Null
        Copy-Item -Path "$assetsFullPath/input.xml" -Destination AppSourcePackage | Out-Null
        Copy-Item -Path "$assetsFullPath/logo32x32.png" -Destination AppSourcePackage | Out-Null
        Copy-Item -Path "$assetsFullPath/TermsOfUse.html" -Destination AppSourcePackage | Out-Null

        Set-Location AppSourcePackage
        Compress-Archive -Path * -DestinationPath $appSourcePackagePath -Force | Out-Null
    }
    catch {
        throw "There was an issue creating the AppSource package. Error: $($_.ErrorDetails.Message)"
    }
    finally {
        Set-Location $workingDirectory
        Remove-Item -Path $tmpDirectory -Recurse -Force | Out-Null
    }

    return $appSourcePackagePath
}

function Add-FileToStorageAccount {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the solution provider.")]
        [string] $AppSourcePackage,
        [Parameter(Mandatory = $true, HelpMessage = "Name of the Azure Storage Account where the AppSource package will be uploaded.")]
        [string] $StorageAccount,
        [Parameter(Mandatory = $true, HelpMessage = "Name of the storage container where the AppSource package will be uploaded.")]
        [string] $StorageContainer
    )

    $appSourcePackageName = (Get-Item $AppSourcePackage).Name

    # Upload AppSource package to Azure Storage and generate SAS URL for it
    $connectionString = (az storage account show-connection-string --name $StorageAccount -o json | ConvertFrom-Json).connectionString
    try {
        # Create the storage container
        az storage container create --name $StorageContainer --connection-string $connectionString --output none
    }
    catch {
        throw "There was an issue creating the storage container, $StorageContainer. Error: $($_.ErrorDetails.Message)"
    }
    try {
        # Upload the AppSourcePackage to the container
        az storage blob upload -n $appSourcePackageName -c $StorageContainer -f $AppSourcePackage --connection-string $connectionString --overwrite $True --output none
    }
    catch {
        throw "There was an issue uploading your AppSource package, $appSourcePackageName. Error: $($_.ErrorDetails.Message)"
    }
    try {
        # Generate the SAS token to access the AppSource package
        $start = (((Get-Date).ToUniversalTime()).addDays(-1)).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $end = (((Get-Date).ToUniversalTime()).addDays(45)).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $packageSas = az storage blob generate-sas -c $StorageContainer -n $appSourcePackageName --connection-string $connectionString --https-only --permissions r --start $start --expiry $end -o tsv
    }
    catch {
        throw "There was an issue creating a SAS token for your AppSource package, $appSourcePackageName. Error: $($_.ErrorDetails.Message)"
    }
    $packageUri = "https://" + $StorageAccount + ".blob.core.windows.net/" + $StorageContainer + "/" + $appSourcePackageName + "?" + $packageSas

    return $packageUri
}

Export-ModuleMember -Function New-AppSourceOffer
Export-ModuleMember -Function New-AppSourcePackage
