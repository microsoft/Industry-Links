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

## Identify your data source and configure workflow

### Configure data source, transform and sink

Create a configuration file for the workflow with the required parameters for your use case. See [flow_workflow.json.tmpl](scripts/modules/MsIndustryLinks/templates/flow_workflow.json.tmpl) for an example of the workflow configuration file.

|                 |                                                 |
| --------------- | ----------------------------------------------- |
| Data sources    | Azure Blob Storage, Custom Connector, Dataverse |
| Data transforms | CSV to JSON                                     |
| Data sinks      | Custom Connector, Dataverse                     |

The custom connector data source and sink supports both certified and non-certified connectors.

A certifed custom connector allows for the connector to be publicly available for all users across all organizations. See [Power Platform Custom Connector Certification](scripts/modules/MsIndustryLinks/customConnector/CustomConnectorCertification.md) to learn more about certifying your custom connector.

A non-certified custom connector is only able to be shared with users in your organization. This is an option for testing your Industry Link while your custom connector is being certified.
To create an Industry Link with a non-certified connector, an Azure AD application is required to obtain the required configuration details of your custom connector via the Dataverse Web API. This will be configured in an [authentication config file](scripts/modules/MsIndustryLinks/templates/auth.json.tmpl). See the [Microsoft Dataverse documentation](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/build-web-applications-server-server-s2s-authentication) to associate an Azure AD application with your Dataverse environment.

## Generate workflow templates and deployable solution

### Configure package parameters

Create a parameters file for the workflow packaging with the required parameters for your use case. See [package.parameters.json.tmpl](scripts/modules/MsIndustryLinks/templates/package/package.parameters.json.tmpl) for an example.

A Power Platform Solution Publisher is required to create the solution. Since the solution publisher specifies who developed the solution, you should create your own publisher instead of using the the default. A Solution Publisher includes a prefix, which is a mechanism to avoid naming collisions of components.

Please refer to the [Create a solution publisher](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/create-solution#create-a-solution-publisher) for more information on how to create a Power Platform solution publisher and prefix.

### Generate Industry Link

#### Example 1: Generate a Flow Industry Link package

```powershell
New-MsIndustryLink
    -WorkflowConfigFile flow_workflow.json
    -OutputDirectory output
    -PackageParametersFile package.parameters.json
```

The output directory will contain the Power Platform solution containing the Industry Link workflows that pass data from the source to the sink. A solution zip file is also in the output directory ready to be imported into your Dataverse environment and published to AppSource.

## Generate an AppSource offer in Partner Center

Please refer to [Publishing to Microsoft AppSource](scripts/modules/MsIndustryLinks/publish/appsource/AppSourcePublishing.md) for more information on how to publish your Industry Link to AppSource.
