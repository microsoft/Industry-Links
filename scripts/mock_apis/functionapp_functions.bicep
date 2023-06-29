// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

param functionAppName string
param authLevel string = 'anonymous'

resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionAppName
}

resource getMockDataFunction 'Microsoft.Web/sites/functions@2022-03-01' = {
  name: 'GetMockData'
  kind: 'getRequest'
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          authLevel: authLevel
          type: 'httpTrigger'
          direction: 'in'
          methods: [
            'get'
          ]
        }
        {
          name: 'res'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      'index.js': loadTextContent('functions/getMockData.js')
    }
  }
}

resource postMockDataFunction 'Microsoft.Web/sites/functions@2022-03-01' = {
  name: 'PostMockData'
  kind: 'postRequest'
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          authLevel: authLevel
          type: 'httpTrigger'
          direction: 'in'
          methods: [
            'post'
          ]
        }
        {
          name: 'res'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      'index.js': loadTextContent('functions/postMockData.js')
    }
  }
}

resource getWaterMeasurementsFunction 'Microsoft.Web/sites/functions@2022-03-01' = {
  name: 'GetWaterMeasurements'
  kind: 'getRequest'
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          authLevel: authLevel
          type: 'httpTrigger'
          direction: 'in'
          methods: [
            'get'
          ]
        }
        {
          name: 'res'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      'index.js': loadTextContent('functions/getWaterMeasurements.js')
      'water_measurements.json': loadTextContent('water_measurements.json')
    }
  }
}

resource getWeatherMeasurementsFunction 'Microsoft.Web/sites/functions@2022-03-01' = {
  name: 'GetWeatherMeasurements'
  kind: 'getRequest'
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          authLevel: authLevel
          type: 'httpTrigger'
          direction: 'in'
          methods: [
            'get'
          ]
        }
        {
          name: 'res'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      'index.js': loadTextContent('functions/getWeatherMeasurements.js')
      'weather_measurements.json': loadTextContent('weather_measurements.json')
    }
  }
}

resource getTransactionsFunction 'Microsoft.Web/sites/functions@2022-03-01' = {
  name: 'GetTransactions'
  kind: 'getRequest'
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          authLevel: authLevel
          type: 'httpTrigger'
          direction: 'in'
          methods: [
            'get'
          ]
        }
        {
          name: 'res'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      'index.js': loadTextContent('functions/getTransactions.js')
      'transactions.json': loadTextContent('transactions.json')
    }
  }
}
