# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script generates and configures the files required to create a Power Platform custom        #
# connector and outputs to the chosen directory.                                                   #
####################################################################################################

Param (
    [Parameter(Mandatory=$true, HelpMessage="The name of the custom connector")]
    [string]$connectorName,
    [Parameter(Mandatory=$false, HelpMessage="The path to the custom connector icon")]
    [string]$iconPath = "./icon.png",
    [Parameter(Mandatory=$false, HelpMessage="The path to a directory that will store the generated assets")]
    [string]$outputPath = "./output",
    [Parameter(Mandatory=$false, HelpMessage="The path to the OpenAPI definition file")]
    [string]$apiDefinitionPath = "./apiDefinition.json",
    [Parameter(Mandatory=$false, HelpMessage="The path to the configuration file")]
    [string]$configPath = "./config.json"
)

function Get-ApiKeyConnectionParameters {
    return @{
        "api_key" = @{
            "type" = "securestring"
            "uiDefinition" = @{
                "displayName" = "API Key"
                "description" = "The API Key to authenticate with the API"
                "tooltip" = "Provide your API Key"
                "constraints" = @{
                    "tabIndex" = 2
                    "clearText" = $false
                    "required" = "true"
                }
            }
        }
    }
}
function Get-BasicAuthConnectionParameters {
    return @{
        "username" = @{
            "type" = "securestring"
            "uiDefinition" = @{
                "displayName" = "Username"
                "description" = "The username to authenticate with the API"
                "tooltip" = "Provide your API username"
                "constraints" = @{
                    "tabIndex" = 2
                    "clearText" = $true
                    "required" = "true"
                }
            }
        }
        "password" = @{
            "type" = "securestring"
            "uiDefinition" = @{
                "displayName" = "Password"
                "description" = "The password to authenticate with the API"
                "tooltip" = "Provide your API password"
                "constraints" = @{
                    "tabIndex" = 3
                    "clearText" = $false
                    "required" = "true"
                }
            }
        }
    }
}

function Get-AadAccessCodeConnectionParameters {
    param (
        [string] $clientId,
        [string] $scopes,
        [string] $resourceUri,
        [string] $tenantId
    )
    return @{
        "token" = @{
            "type" = "oauthSetting"
            "oAuthSettings" = @{
                "identityProvider" = "aad"
                "clientId" = $clientId
                "scopes" = $scopes
                "redirectMode" = "Global"
                "redirectUrl" = "https://global.consent.azure-apim.net/redirect"
                "properties" = @{
                    "IsFirstParty" = "False"
                    "IsOnbehalfofLoginSupported" = $true
                    "AzureActiveDirectoryResourceId" = $resourceUri
                }
                "customParameters" = @{
                    "loginUrl" = @{
                        "value" = "https://login.microsoftonline.com"
                    }
                    "tenantId" = @{
                        "value" = $tenantId
                    }
                    "resourceUri" = @{
                        "value" = $resourceUri
                    }
                    "enableOnbehalfOfLogin" = @{
                        "value" = "false"
                    }
                }
            }
        }
        "token:TenantId" = @{
            "type" = "string"
            "metadata" = @{
                "sourceType" = "AzureActiveDirectoryTenant"
            }
            "uiDefinition" = @{
                "constraints" = @{
                    "required" = "false"
                    "hidden" = "true"
                }
            }
        }
    }
}

function Get-GenericOAuthAccessCodeConnectionParameters {
    param (
        [string] $clientId,
        [string] $scopes,
        [string] $authorizationUrl,
        [string] $tokenUrl,
        [string] $refreshUrl
    )

    return @{
        "token" = @{
            "type" = "oauthSetting"
            "oAuthSettings" = @{
                "identityProvider" = "oauth2"
                "clientId" = $clientId
                "scopes" = $scopes
                "redirectMode" = "Global"
                "redirectUrl" = "https://global.consent.azure-apim.net/redirect"
                "properties" = @{
                    "IsFirstParty" = "False"
                    "IsOnbehalfofLoginSupported" = $false
                }
                "customParameters" = @{
                    "authorizationUrl" = @{
                        "value" = $authorizationUrl
                    }
                    "tokenUrl" = @{
                        "value" = $tokenUrl
                    }
                    "refreshUrl" = @{
                        "value" = $refreshUrl
                    }
                }
            }
        }
    }
}

function Get-GenericOAuthClientCredentialsConnectionParameters {
    return @{
        "clientId" = @{
            "type" = "string"
            "uiDefinition" = @{
                "displayName" = "Client ID"
                "description" = "The Client ID of the API application."
                "tooltip" = "Provide your Client ID."
                "constraints" = @{
                    "tabIndex" = 2
                    "required" = "true"
                }
            }
        }
        "clientSecret" = @{
            "type" = "securestring"
            "uiDefinition" = @{
                "displayName" = "Client Secret"
                "description" = "The Client Secret of the API application."
                "tooltip" = "Provide your Client Secret."
                "constraints" = @{
                    "tabIndex" = 3
                    "clearText" = $false
                    "required" = "true"
                }
            }
        }
    }
}

function Get-GenericOAuthClientCredentialsPolicyTemplates {
    param (
        [string] $tokenUrl,
        [string[]] $scopes
    )
    $policyTemplateInstances = @(
        @{
            "TemplateId" = "setheader"
            "Title" = "Set HTTP header - Token URL"
            "Parameters" = @{
                "x-ms-apimTemplateParameter.name" = "tokenUrl"
                "x-ms-apimTemplateParameter.value" = $tokenUrl
                "x-ms-apimTemplateParameter.existsAction" = "override"
                "x-ms-apimTemplate-policySection" = "Request"
            }
        },
        @{
            "TemplateId" = "setheader"
            "Title" = "Set HTTP header - Client ID"
            "Parameters" = @{
                "x-ms-apimTemplateParameter.name" = "clientId"
                "x-ms-apimTemplateParameter.value" = "@connectionParameters('clientId','')"
                "x-ms-apimTemplateParameter.existsAction" = "override"
                "x-ms-apimTemplate-policySection" = "Request"
            }
        },
        @{
            "TemplateId" = "setheader"
            "Title" = "Set HTTP header - Client Secret"
            "Parameters" = @{
                "x-ms-apimTemplateParameter.name" = "clientSecret"
                "x-ms-apimTemplateParameter.value" = "@connectionParameters('clientSecret','')"
                "x-ms-apimTemplateParameter.existsAction" = "override"
                "x-ms-apimTemplate-policySection" = "Request"
            }
        }
    )

    if ($scopes) {
        $policyTemplateInstances += @{
            "TemplateId" = "setheader"
            "Title" = "Set HTTP header - Scope"
            "Parameters" = @{
                "x-ms-apimTemplateParameter.name" = "scope"
                "x-ms-apimTemplateParameter.value" = ($scopes -join " ")
                "x-ms-apimTemplateParameter.existsAction" = "override"
                "x-ms-apimTemplate-policySection" = "Request"
            }
        }
    }
}
function Configure-AuthenticationOptions {
    Param(
        [string] $connectorPath
    )

    $apiDefinitionPath = "$connectorPath/apiDefinition.json"
    $apiPropertiesPath = "$connectorPath/apiProperties.json"

    $securityDefinition = (Get-Content $apiDefinitionPath -Raw | ConvertFrom-Json).securityDefinitions
    $connectionParameters = @{}
    $policyTemplateInstances = $null
    $customCodePath = $null

    # Set the connection parameters based on the authentication model of the API
    switch ($securityDefinition.PSObject.Properties.Value.type) {
        "apiKey" {
            Write-Output "API key authentication model found and configured"
            $connectionParameters = Get-ApiKeyConnectionParameters
        }
        "basic" {
            Write-Output "Basic authentication model found and configured"
            $connectionParameters = Get-BasicAuthConnectionParameters
        }
        "oauth2" {
            # Get OAuth 2.0 values from API definition
            $apiDefintionAuth = $securityDefinition.PSObject.Properties.Value
            $scopes = @()

            # Get the scopes from the API definition if they exist
            if(Get-Member -inputobject $apiDefintionAuth -name "scopes" -Membertype Properties) {
                $scopes = @($apiDefintionAuth.scopes.PSObject.Properties.Name)
            }

            # Read the configuration file and get the OAuth2.0 values
            $oauthConfig = (Get-Content $configPath -Raw | ConvertFrom-Json).oauth2

            # Check auth flow type
            if ($apiDefintionAuth.flow -eq "accessCode") {
                # Currently, only access code flow is supported in this script for AAD
                $isAad = (($apiDefintionAuth.authorizationUrl -like "*login.microsoftonline.com*") -or ($apiDefintionAuth.tokenUrl -like "*login.microsoftonline.com*"))

                if($isAad){
                    Write-Output "AAD OAuth2.0 access code authentication model found and configured"
                    $connectionParameters = Get-AadAccessCodeConnectionParameters -clientId $oauthConfig.clientId -scopes $scopes -resourceUri $oauthConfig.resourceUri -tenantId $oauthConfig.tenantId

                } else {
                    Write-Output "OAuth2.0 access code authentication model found and configured"
                    $connectionParameters = Get-GenericOAuthAccessCodeConnectionParameters -clientId $oauthConfig.clientId -scopes $scopes -authorizationUrl $apiDefintionAuth.authorizationUrl -tokenUrl $apiDefintionAuth.tokenUrl -refreshUrl $apiDefintionAuth.refreshUrl
                }

            # Swagger 2.0 specification calls the client credentials flow "application" flow
            } elseif ($apiDefintionAuth.flow -eq "application") {
                Write-Output "OAuth2.0 client credentials authentication model found and configured"
                $connectionParameters = Get-GenericOAuthClientCredentialsConnectionParameters

                $policyTemplateInstances = Get-GenericOAuthClientCredentialsPolicyTemplates -tokenUrl $apiDefintionAuth.tokenUrl -scopes $scopes

                $customCodePath = "./clientCredentialsAuthFlow.csx"
            }
        }
        Default {
            Write-Output "No authentication model found. No configuration will be completed."
        }
    }

    # Get the API properties
    $apiProperties = Get-Content $apiPropertiesPath -Raw | ConvertFrom-Json

    # Add the authentication connection parameters to the API Properties
    if($connectionParameters) {
        $apiProperties.properties.connectionParameters = $connectionParameters
    }

    # Add the policy template instances to the API Properties
    if ($policyTemplateInstances) {
        $apiProperties.properties | Add-Member -MemberType NoteProperty -Name "policyTemplateInstances" -Value $policyTemplateInstances
    }

    # Output the new API properties configuration to the output directory
    Write-Output "Output new API properties configuration to the output directory"
    $apiProperties | ConvertTo-Json -Depth 100 | Out-File $apiPropertiesPath -Force

    # Update the output settings.json to point to custom code if exists
    if ($customCodePath) {
        Write-Output "Adding custom code to the connector settings"
        $settings = (Get-Content "$connectorPath/settings.json" -Raw | ConvertFrom-Json)
        $settings.script = "script.csx"
        $settings | ConvertTo-Json -Depth 100 | Out-File "$connectorPath/settings.json" -Force

        Copy-Item $customCodePath "$connectorPath/script.csx"
    }
}

try {
    Write-Output "Create the output directory to store the connector files"
    $connectorPath = "./$outputPath/$connectorName"
    mkdir $connectorPath

    Write-Output "Generate the connector configuration files"
    pac connector init --outputDirectory $connectorPath --generate-settings-file

    # Copy the API definition to the output directory
    Copy-Item $apiDefinitionPath "$connectorPath/apiDefinition.json"

    # Get the authentication model of the API using the API definition
    Write-Output "Configuring the connector assets with the authentication model of the API"
    Configure-AuthenticationOptions -connectorPath $connectorPath

    if (Test-Path $iconPath){
        # Copy the icon to the output directory and update the settings file
        $settings = (Get-Content "$connectorPath/settings.json" -Raw | ConvertFrom-Json)
        $settings.icon = $iconPath
        $settings | ConvertTo-Json -Depth 100 | Out-File "$connectorPath/settings.json" -Force
        Copy-Item $iconPath "$connectorPath/icon.png"
    } else {
        throw "Icon file not found at $iconPath"
    }
}
catch {
    Write-Error "An error occurred while configuring the custom connector files: $($_.Exception.Message)"
    Exit 1
}

Write-Output "Custom connector files generated successfully and stored in $connectorPath"