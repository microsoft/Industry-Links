// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

param clientId string
param openIdConfiguration string
param functionAppName string

resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionAppName
}

resource functionAppAuth 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionApp
  name: 'authsettingsV2'
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      redirectToProvider: 'genericOAuth'
      unauthenticatedClientAction: 'Return401'
    }
    identityProviders: {
      customOpenIdConnectProviders: {
        genericOAuth: {
          registration: {
            clientId: clientId
            clientCredential: {
              clientSecretSettingName: 'GENERIC_OAUTH2_AUTHENTICATION_SECRET'
            }
            openIdConnectConfiguration: {
              wellKnownOpenIdConfiguration: openIdConfiguration
            }
          }
        }
      }
    }
    login: {
      tokenStore: {
        enabled: true
      }
    }
  }
}
