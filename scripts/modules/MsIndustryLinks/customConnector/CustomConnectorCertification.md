# Power Platform Custom Connector Certification

The **MsIndustryLinks** module contains commands to automate some of the steps required to build and create a Power Platform custom connector in preparation of making it publicly available to all users outside of your organization through the certification process. See [Getting your connector certified](https://learn.microsoft.com/en-us/connectors/custom-connectors/submit-certification) for more information.

Use the following steps to prepare your custom connector assets for certification:

## Step 1: Login to your Microsoft Power Platform environment

Sign into your Power Platform environment with the Power Platform CLI.
```
pac auth create --url <Power Platform Resource URL>
```

Where the Power Platform Resource URL is in the format `https://org12345.crm.dynamics.com/`.

See the [pac auth create](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/auth#pac-auth-create) documentation for more examples.

## Step 2: Create the custom connector configuration assets

### Configure your API definition file

An OpenAPI definition file is required to create the custom connector assets. This file needs to be less than 1 MB and in OpenAPI 2.0 (formerly known as Swagger) format.

If your API uses OAuth 2.0 authentication, ensure that the required attributes are populated in your `config.json`.

### Configure connector details in config.json

Create a `config.json` file using the [config template](config.json.tmpl). The config file contains the path of the API definition and the icon used for the custom connector assets. The config file also contains the OAuth 2.0 authentication details that are only required for scenarios where the API referenced in the custom connector uses OAuth 2.0 authentication.

### Generate the custom connector assets

See the cmdlet [New-CustomConnectorConfig](./New-CustomConnectorConfig.md) for more information on creating the custom connector assets.

### Verify configured custom connector assets

Verify that the following files have been correctly referenced and configured in the chosen output directory:
- `apiProperties.json`
- `apiDefinition.json`
- `icon.png`
- `settings.json`
- `script.csx` (optional)

## Step 3: Deploy & test the custom connector

### Create the custom connector

See the cmdlet [New-CustomConnector](./New-CustomConnector.md) for more information on creating the custom connector in your Power Platform environment.

### Test the custom connector

The custom connector can be tested in the [Power Automate Maker portal](https://make.powerautomate.com) in the custom connector settings or by adding it to a flow. This will ensure that the connector has been created and configured as expected.

## Step 4: Certify the custom connector

### Register your custom connector

Fill out the [registration form](https://aka.ms/ConnectorRegistration). This can be done while the custom connector is in development. [~2 days]

### Prepare your custom connector assets

To certify a custom connector, the following assets are required:

- The asset configuration files generated in [Step 2](#step-2-create-the-custom-connector-configuration-assets). This should include:
  - The API definition file (`apiDefinition.json`). Ensure all [metadata](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-submission#step-3-add-metadata) is added.
  - The API properties file (`apiProperties.json`)
  - The connector icon (`icon.png`). Ensure it meets the [requirements](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-submission#design-an-icon-for-your-connector).
  - The custom code (`script.csx`)
  - The settings file pointing to the correct configuration files (`settings.json`) 
- A `README.md` file from the [SAMPLE_README.md](./assets/SAMPLE_README.md) template to document your connectors features and functionality. See the [sample Azure Key Vault documenation](https://github.com/microsoft/PowerPlatformConnectors/blob/dev/custom-connectors/AzureKeyVault/Readme.md) as an example. 
- An `INTRO.md` file from the [SAMPLE_INTRO.md](./assets/SAMPLE_INTRO.md) template. This will be included in the public-facing documentation of your connector.
- A set of test credentials for the Microsoft certification team to test with.

### Submit your custom connector for certification

Create a pull request in the Open-Source [Power Platform Connectors repo](https://github.com/microsoft/PowerPlatformConnectors). [~1-2 weeks]

Once the pull request is merged, [submit your connector files in ISV studio](https://learn.microsoft.com/en-us/connectors/custom-connectors/submit-for-certification#submit-to-isv-studio). [~1-2 weeks]

### Test your connector

After your connector passes certification review, you'll be notified that your connector has been deployed to the Preview region for testing. See [Test your connector](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-testing) for more information. Notify your Microsoft contact once testing is complete.

### Deployment

Wait for the [deployment](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-testing#after-you-test-your-connector) of your connector to all public regions. [~5-6 weeks]

A new connector is deployed in *preview*. See [Move your connector from preview to general availability (GA)](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-to-ga) for more information on how to move your custom connector to GA.


Please refer to the [Microsoft Documentation](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-submission) for more detailed steps to get your custom connector certified.