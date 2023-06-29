# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Param (
    [Parameter(Mandatory = $True, HelpMessage = "Resource group where Azure resources are deployed to")]
    [string] $resourceGroup,
    [Parameter(Mandatory = $False, HelpMessage = "Client ID of your application")]
    [string] $clientId,
    [Parameter(Mandatory = $False, HelpMessage = "Client Secret of your application")]
    [string] $clientSecret,
    [Parameter(Mandatory = $False, HelpMessage = "OpenID Connect configuration metadata document")]
    [string] $openIdConfiguration
)

function Generate-SampleData {
    python ../sample_data/generate_measurements.py "2023-01-01 00:00:00" "2023-01-10 00:00:00" 2 water water_measurements.json
    python ../sample_data/generate_measurements.py "2023-01-01 00:00:00" "2023-01-04 00:00:00" 2 weather weather_measurements.json
    python ../sample_data/generate_transactions.py "2023-01-01 00:00:00" "2023-02-01 00:00:00" 100 5 10 transactions.json
}

try {
    # Create generic function app
    Write-Output "Create generic function app"
    $functionAppName = $(az deployment group create -g $resourceGroup --template-file ./functionapp.bicep --parameters ./parameters.json -o json | ConvertFrom-Json).properties.parameters.name.value

    # Add the client secret to the function app configuration
    Write-Output "Add client secret configuration to the function app"
    $secretsConfig = $(az functionapp config appsettings set -g $resourceGroup -n $functionAppName --settings GENERIC_OAUTH2_AUTHENTICATION_SECRET=$clientSecret)

    # Set up the authentication on the function app
    Write-Output "Configure generic OAuth2.0 authentication on the function app"
    az deployment group create -g $resourceGroup --template-file ./functionapp_auth_genericOAuth2.bicep --parameters clientId=$clientId openIdConfiguration=$openIdConfiguration functionAppName=$functionAppName

    Write-Output "Generate sample data"
    Generate-SampleData

    # Create functions in function app using sample data
    Write-Output "Create GET and POST functions on the function app"
    az deployment group create -g $resourceGroup --template-file ./functionapp_functions.bicep --parameters functionAppName=$functionAppName

    Write-Output "Get endpoint URLs"
    az functionapp function list -g $resourceGroup -n $functionAppName --query '[*].invokeUrlTemplate' -o json
}
catch {
    Write-Error "There was a problem creating/configuring the function app."
    Exit 1
}
