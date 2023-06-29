# Generating mock APIs using Azure Function Apps
These templates provide an easy way to get started to create mock APIs for testing using Azure Function Apps.

The templates provide multiple authentication configuration options:
- Azure Active Directory
- Generic OAuth 2.0
- API key

## Getting Started

### Install tools

The templates and scripts to create the mock APIs require the following tools:
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)

### Login to Azure

Sign in using the Azure CLI. You will need the Microsoft Graph scope so that Azure Active Directory application registrations can be created and configured.
```
az login --scope https://graph.microsoft.com/.default
```

## Azure Active Directory Authentication

### Deploy the mock API

This template creates and configures the the function app and functions along with all other required resources, including a client and server side Azure AD Application Registrations.

To create these assets, run the following command:
```
.\deploy_aad.ps1 -resourceGroup <Resource Group Name> -serverAppRegistrationName <Server Application Registration Name> -clientAppRegistrationName <Client Application Registration Name>
```

### Testing the mock API

The deployment script will output a configuration file (./clientConfig.json) that contains the details to authenticate and access the configured mock APIs.
As a user, you will use the client side Azure AD application registration to get a bearer token, which will be used to authenticate to the mock API endpoints.

## Generic OAuth2.0 Authentication

### Deploy the mock API

This template creates and configures the the function app and functions along with all other required resources using a custom OAuth2.0 identity provider.

To create these assets, run the following command:
```
.\deploy_genericOAuth.ps1 -resourceGroup <Resource Group Name> -clientId <Application Client ID> -clientSecret <Application Client Secret> -openIdConfiguration <OpenID Connect configuration metadata document URL>
```

Note: You will need the OpenID Connect metadata for the provider. This is often exposed via a [configuration metadata document](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig), which is the provider's Issuer URL suffixed with /.well-known/openid-configuration. Gather this configuration URL.

### Testing the mock API

The deployment script will output the configured mock API URLs. As a user, you will use the identity provider's client ID and secret to authenticate to the mock API endpoints.


## API Key Authentication

### Deploy the mock API

This template creates and configures the the function app and functions along with all other required resources using. The mock API can use the function app's function host key as the API key to authenticate which is stored in a key vault.

To create these assets, run the following command:
```
.\deploy_apiKey.ps1 -resourceGroup <Resource Group Name>
```

### Testing the mock API

The deployment script will output the configured mock API URLs. The [function API key](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=python-v2%2Cin-process%2Cfunctionsv2&pivots=programming-language-javascript#api-key-authorization) (stored in the new keyvault) will be used to authenticate to the mock API endpoints.