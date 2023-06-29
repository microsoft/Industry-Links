# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Param (
    [Parameter(Mandatory = $True, HelpMessage = "Resource group where Azure resources are deployed to")]
    [string] $resourceGroup,
    [Parameter(Mandatory = $True, HelpMessage = "Name of server side App Registration to be created")]
    [string] $serverAppRegistrationName,
    [Parameter(Mandatory = $True, HelpMessage = "Name of client side App Registration to be created")]
    [string] $clientAppRegistrationName
)

function Generate-SampleData {
    python ../sample_data/generate_measurements.py "2023-01-01 00:00:00" "2023-01-10 00:00:00" 2 water water_measurements.json
    python ../sample_data/generate_measurements.py "2023-01-01 00:00:00" "2023-01-04 00:00:00" 2 weather weather_measurements.json
    python ../sample_data/generate_transactions.py "2023-01-01 00:00:00" "2023-02-01 00:00:00" 100 5 10 transactions.json
}

try {
    # Get tenant ID
    Write-Output "Getting tenant ID"
    $tenantId = $(az account show --query tenantId --output tsv)
}
catch {
    Write-Error "There was a problem getting the tenant ID."
    Exit 1
}

try {
    # Create generic function app
    Write-Output "Create generic function app"
    $deployment = az deployment group create -g $resourceGroup --template-file ./functionapp.bicep --parameters ./parameters.json -o json | ConvertFrom-Json

    $functionAppName = $deployment.properties.parameters.name.value
}
catch {
    Write-Error "There was a problem creating the function app."
    Exit 1
}

try {
    # Create the server app registration in Azure AD
    Write-Output "Create server side Azure AD app registration"
    $serverAppRegistration = az ad app create --display-name $serverAppRegistrationName --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --web-home-page-url "https://$functionAppName.azurewebsites.net" --web-redirect-uris "https://$functionAppName.azurewebsites.net/.auth/login/aad/callback" -o json | ConvertFrom-Json

    # Get the ID of the new app registration
    $serverAppClientId = $serverAppRegistration.appId

    # Create a service principal for the app registration
    Write-Output "Create server side service principal"
    az ad sp create --id $serverAppClientId

    $serverApiScopeId = [guid]::NewGuid().Guid
    $serverApiScopeJson = @{
        oauth2PermissionScopes = @(
            @{
                adminConsentDescription = "Allow the application to access $functionAppName on behalf of the signed-in user."
                adminConsentDisplayName = "Access $functionAppName"
                id                      = "$serverApiScopeId"
                isEnabled               = $true
                type                    = "User"
                userConsentDescription  = "Allow the application to access $functionAppName on your behalf."
                userConsentDisplayName  = "Access $functionAppName"
                value                   = "user_impersonation"
            }
        )
    } | ConvertTo-Json -d 4 -Compress

    $apiUpdateBody = $serverApiScopeJson | ConvertTo-Json -d 4

    # Add the application ID URI & API scopes
    Write-Output "Update server side app registation identifier URL and authentication scope"
    az ad app update --id $serverAppClientId --identifier-uris "api://$serverAppClientId" --set api=$apiUpdateBody

    # Create a secret for the app registration
    Write-Output "Create a client secret for server side app registration"
    $serverClientSecret = $(az ad app credential reset --id $serverAppClientId --append --display-name $functionAppName --years 1 --query password --output tsv)
}
catch {
    Write-Error "There was a problem creating or configuring the server side Azure AD application registration."
    Exit 1
}

try {
    # Add the client secret to the function app configuration
    Write-Output "Add server side client secret configuration to the function app"
    $secretsConfig = $(az functionapp config appsettings set -g $resourceGroup -n $functionAppName --settings MICROSOFT_PROVIDER_AUTHENTICATION_SECRET=$serverClientSecret)

    # Get tenant ID to create the Open Issuer URL
    $openIdIssuer = "https://sts.windows.net/$tenantId/v2.0"

    # Set up the authentication on the function app
    Write-Output "Configure AAD authentication on the function app"
    az deployment group create -g $resourceGroup --template-file ./functionapp_auth_aad.bicep --parameters appRegistrationClientId=$serverAppClientId openIdIssuer=$openIdIssuer functionAppName=$functionAppName

    Write-Output "Generate sample data"
    Generate-SampleData

    # Create functions in function app using sample data
    Write-Output "Create GET and POST functions on the function app"
    az deployment group create -g $resourceGroup --template-file ./functionapp_functions.bicep --parameters functionAppName=$functionAppName

    Write-Output "Get endpoint URLs"
    $mockApiEndpoints = az functionapp function list -g $resourceGroup -n $functionAppName --query '[*].invokeUrlTemplate' -o json
}
catch {
    Write-Error "There was a problem configuring the function app."
    Exit 1
}

try {
    # Create client app registration to access API
    Write-Output "Create client side Azure AD app registration"
    $clientAppClientId = (az ad app create --display-name $clientAppRegistrationName --sign-in-audience AzureADMyOrg -o json | ConvertFrom-Json).appId

    Write-Output "Create client side service principal"
    az ad sp create --id $clientAppClientId

    Write-Output "Add Microsoft Graph delegated permission User.Read to client side service principal"
    az ad app permission add --id $clientAppClientId --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope

    Write-Output "Add server API delegated permission user_impersonation to client side service principal"
    az ad app permission add --id $clientAppClientId --api $serverAppClientId --api-permissions "$serverApiScopeId=Scope"

    Write-Output "Create a client secret for client side app registration"
    $clientAppClientSecret = $(az ad app credential reset --id $clientAppClientId --append --display-name $functionAppName --years 1 --query password --output tsv)

    $clientConfigFile = "./clientConfig.json"
    $clientConfig = @{
        accessTokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
        apiEndpoints   = $mockApiEndpoints
        clientId       = $clientAppClientId
        clientSecret   = $clientAppClientSecret
        scope          = "api://$serverAppClientId/.default"
    } | ConvertTo-Json

    Write-Output "Export client side app registration details to $clientConfigFile"
    Out-File -FilePath $clientConfigFile -InputObject $clientConfig
}
catch {
    Write-Error "There was a problem creating or configuring the client Azure AD application registration."
    Exit 1
}
