# Solution-Aware Power Automate Flows in AppSource

This template demonstrates how to build an Industry Link using solution-aware Power Automate Flows and AppSource. This is ideal for transferring data between an API or file in Azure Blob Storage and Dataverse.

The [MsIndustryLinks](scripts/modules/MsIndustryLinks/README.md) module supports the creation and configuration of Power Automate workflow templates, Power Automate solution and AppSource offer required to publish to AppSource.

## Install MsIndustryLinks module

```powershell
cd scripts/modules

# Build the module file
./BuildModule.ps1 -ModuleDirectory ./MsIndustryLinks

# Import the module
Import-Module -Name MsIndustryLinks
```

## Identify your data source and configure parameters file

### Configure data source

Create a parameters file for the data source workflow with the required parameters for your use case. See [customconnectors.parameters.json.tmpl](scripts/modules/MsIndustryLinks/templates/data_source/customconnector/customconnectors.parameters.json.tmpl) or [azureblob.parameters.json.tmpl](scripts/modules/MsIndustryLinks/templates/data_source/azureblob/azureblob.parameters.json.tmpl) for examples.

The supported workflow data sources include: Azure Blob Storage and Custom Connectors.

The custom connector data source supports both certified and non-certified connectors.

A certifed custom connector allows for the connector to be publicly available for all users across all organizations. See the [Custom Connectors documentation](connectors/power_platform_custom_connector/README.md) to learn more about certifying your custom connector.

A non-certified custom connector is only able to be shared with users in your organization. This is an option for testing your Industry Link while your custom connector is being certified.
To create an Industry Link with a non-certified connector, an Azure AD application is required to obtain the required configuration details of your custom connector via the Dataverse Web API. This will be configured in [customconnectors.parameters.json.tmpl](scripts/modules/MsIndustryLinks/templates/data_source/customconnector/customconnectors.parameters.json.tmpl). See the [Microsoft Dataverse documentation](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/build-web-applications-server-server-s2s-authentication) to associate an Azure AD application with your Dataverse environment.

### Configure data sink

Create a parameters file for the Dataverse ingestion workflow with the required parameters for your use case. See [dataverse.parameters.json.tmpl](scripts/modules/MsIndustryLinks/templates/ingest/dataverse.parameters.json.tmpl) for an example.

Create a mapping definition file with the required parameters for your use case. See [flow_mapping.json.tmpl](scripts/modules/MsIndustryLinks/templates/ingest/flow_mapping.json.tmpl) or [logicapp_mapping.json.tmpl](scripts/modules/MsIndustryLinks/templates/ingest/logicapp_mapping.json.tmpl) for examples.

## Generate workflow templates and deployable solution

### Configure package parameters

Create a parameters file for the workflow packaging with the required parameters for your use case. See [package.parameters.json.tmpl](scripts/modules/MsIndustryLinks/templates/package/package.parameters.json.tmpl) for an example.

A Power Platform Solution Publisher is required to create the solution. Since the solution publisher specifies who developed the solution, you should create your own publisher instead of using the the default. A Solution Publisher includes a prefix, which is a mechanism to avoid naming collisions of components.

Please refer to the [Create a solution publisher](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/create-solution#create-a-solution-publisher) for more information on how to create a Power Platform solution publisher and prefix.

### Generate Industry Link

**Example 1: Generate Industry Link with custom connector as data source**

```powershell
New-MsIndustryLink
    -DataSource CustomConnector
    -BaseTemplate "Flow"
    -DataSourceParametersFile datasource.parameters.json
    -DataverseParametersFile dataverse.parameters.json
    -OutputDirectory output
    -MappingDefinitionFile mapping.json
    -UseUpsert $false
    -TriggerType Scheduled
    -PackageParametersFile package.parameters.json
```

The output directory will contain the Power Platform solution containing the Industry Link workflows that pass data from the source to the sink (Dataverse). A solution zip file is also in the output directory ready to be imported into your Dataverse environment and published to AppSource.

## Generate an AppSource offer in Partner Center

Please refer to [Publishing to Microsoft AppSource](scripts/modules/MsIndustryLinks/appsource/AppSourcePublishing.md) for more information on how to publish your Industry Link to AppSource.
