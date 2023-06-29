// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

param appRegistrationClientId string
param openIdIssuer string
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
      requireAuthentication: true
      unauthenticatedClientAction: 'Return401'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: appRegistrationClientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
          openIdIssuer: openIdIssuer
        }
        validation: {
          allowedAudiences: [ 'api://${appRegistrationClientId}' ]
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
