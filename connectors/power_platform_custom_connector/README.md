# Power Platform Custom Connector

This sample template demonstrates how to programatically create a Microsoft Power Platform custom connector and the steps required to certify it.

Please refer to the [Microsoft documentation](https://learn.microsoft.com/en-us/connectors/custom-connectors/) for more information on custom connectors.

## Getting started

### Step 1: Install tools

The scripts in this repository requires the Microsoft Power Platform CLI which can be installed via one of the following tools:
- [Power Platform CLI for Windows](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction#install-power-platform-cli-for-windows)
- [Power Platform CLI for Linux/macOS](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction#install-power-platform-cli-for-linuxmacos)
- [Power Platform Tools for Visual Studio Code](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction#install-using-power-platform-tools-for-visual-studio-code)


### Step 2: Login to your Microsoft Power Platform environment

Sign in using the Power Platform CLI.
```
pac auth create --url <Power Platform Resource URL>
```

Where the Power Platform Resource URL is in the format `https://org12345.crm.dynamics.com/`.


### Step 3: Add your API definition file & update configuration file

Add your OpenAPI definition file to this directory, ensuring it is less than 1 MB and in OpenAPI 2.0 (formerly known as Swagger) format.

If your API uses OAuth 2.0 authentication, ensure that the required [config.json](./config.json) attributes are populated.


### Step 4: Generate the deployment assets

A [script](./generateCustomConnectorConfig.ps1) is provided to generate and configure the deployment assets required to create a Power Platform Custom Connector, using your OpenAPI definition.

To generate the deployment assets, run the following command:
```
./generateCustomConnectorConfig.ps1 -connectorName <Custom Connector Name> -iconPath <Path to the connector icon> -outputPath <Path to store the configured connector assets> -apiDefinitionPath <Path to API definition> -configPath <Path to config file>
```

Once the script has completed successfully, in the output path you will find a new directory that contains the configured files required to create the custom connector.


### Step 6: Create the custom connector

Before you create the custom connector, verify the configuration and attribute values have been correctly set in the `apiProperties.json` file in your output directory.

A [script](./createCustomConnector.ps1) is provided to create the custom connector:

```
./createCustomConnector.ps1 -connectorPath <Path to connector assets>
```

### Step 7: Test your custom connector

Navigate to your custom connector in the [Power Automate Maker portal](https://make.powerautomate.com). To do this, go to Data -> Custom Connectors. Select edit on your new connector and then go to the `5. Test` page to validate that the connection creation and the connector is working as expected.


## Certifying your connector

To make your custom connector publicly available to all users outside of your organization, you will need to submit your connector to Microsoft for certification.

1. Register your connector. Fill out the [registration form](https://aka.ms/ConnectorRegistration). This can be done while the custom connector is in development. [~2 days]
2. Prepare for assets submission. This includes:  
  2.1. Generate the files for the custom connector using the steps provided in [Step 4](#step-4-generate-the-deployment-assets).   
  2.2. Ensure all [required metadata](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-submission#step-3-add-metadata) is added to your connector configuration files.  
  2.3. Ensure your connector icon has been provided and meets the [requirements](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-submission#design-an-icon-for-your-connector).  
  2.4. Fill out the [SAMPLE_README.md](./SAMPLE_README.md) file to document your connectors features and functionality. See the [sample Azure Key Vault documenation](https://github.com/microsoft/PowerPlatformConnectors/blob/dev/custom-connectors/AzureKeyVault/Readme.md) as an example.  
  2.5. Fill out the [SAMPLE_INTRO.md](./SAMPLE_INTRO.md) file. This will be included in the public-facing documenation of your connector.  
  2.6. Prepare some test credentials for the Microsoft certification to test with.
3. Create a pull request in the Open-Source [Power Platform Connectors repo](https://github.com/microsoft/PowerPlatformConnectors). [~1-2 weeks]
4. Once the pull request is merged, [submit your connector files in ISV studio](https://learn.microsoft.com/en-us/connectors/custom-connectors/submit-for-certification#submit-to-isv-studio). [~1-2 weeks]
5. [Test your connector](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-testing). Notify your Microsoft contact once testing is complete.
6. Wait for [deployment](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-testing#after-you-test-your-connector) of your connector. [~5-6 weeks]
7. [Move your connector from preview to general availability (GA)](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-to-ga).

Please refer to the [Microsoft Documentation](https://learn.microsoft.com/en-us/connectors/custom-connectors/certification-submission) for more detailed steps to get your custom connector certified.