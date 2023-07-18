# Logic App-based Industry Link in Azure Marketplace

This template demonstrates how to build an Industry Link using Logic Apps deployed to Azure. This is ideal for transferring data between any of the following data sources and sinks: API using a custom connector, files in Azure Blob Storage, Azure Event Hubs and Dataverse.

The [MsIndustryLinks](scripts/modules/MsIndustryLinks/README.md) module supports the creation and configuration of Logic App workflow templates, ARM templates for deploying the Industry Link resources to Azure, and the application offer for publishing to the Azure Marketplace.

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

Create a configuration file for the workflow with the required parameters for your use case. See [logicapp_workflow.json.tmpl](scripts/modules/MsIndustryLinks/templates/logicapp_workflow.json.tmpl) for examples of the workflow configuration file.

|                 |                                                                       |
| --------------- | --------------------------------------------------------------------- |
| Data sources    | Azure Blob Storage, Custom Connector (API key), Dataverse, Event Hubs |
| Data transforms | CSV to JSON                                                           |
| Data sinks      | Custom Connector (API key), Dataverse                                 |

The custom connector data source and sink supports both certified and non-certified connectors. Currently, only the API key security method is supported. More security methods will be added in the future.

A certifed custom connector allows the connector to be publicly available for all users. See the [Custom Connectors documentation](scripts/modules/MsIndustryLinks/customConnector/CustomConnectorCertification.md) to learn more about certifying your custom connector.

A non-certified custom connector can only be shared with users in your subscription. This is an option for testing your Industry Link while your custom connector is being certified. Non-certified Logic App custom connectors will be deployed to the same resource group as the Industry Link. When generating the Industry Link ARM templates, you can simply provide the Swagger API definition file for your custom connector.

## Generate workflow templates and deployable solution

### Generate Industry Link

#### Generate the Logic App Industry Link workflow templates

```powershell
New-MsIndustryLink
    -WorkflowConfigFile logicapp_workflow.json
    -OutputDirectory templates
```

The output directory will contain the Industry Link Logic App workflow templates that pass data from the source to the sink, optionally transforming the data in between.

#### Generate the ARM templates for deploying the Industry Link to Azure

```powershell
New-AzureDeploymentPackage
    -WorkflowConfigFile logicapp_workflow.json
    -TemplateDirectory templates
    -OutputDirectory output
```

The output directory will contain the ARM templates for deploying the Industry Link to Azure and the application offer's marketplacePackage.zip file for publishing the offer to Azure Marketplace.

#### Test deployment of the Industry Link to Azure

```powershell
New-AzureDeployment
    -ResourceGroup contosorg
    -Location eastus
    -TemplatesFolder output
    -ParametersFile parameters.json
    -StorageAccountName mystorageaccount
```

A storage account is required to upload the linked ARM templates for deployment. If you don't already have an existing storage account, you can create one. Replace "MyResourceGroup" with your own resource group name.

```
az group create --name MyResourceGroup --location westus
az storage account create -n mystorageacct -g MyResourceGroup -l westus --sku Standard_LRS
```

The parameters.json file contains the parameters for the deployment. See [parameters.json.tmpl](scripts/modules/MsIndustryLinks/package/azureDeploymentPackage/parameters.json.tmpl) for an example of the format.

## Generate an Azure Marketplace application (solution template) offer in Partner Center

Please refer to [Publishing to Azure Marketplace](scripts/modules/MsIndustryLinks/publish/application/AzureMarketplacePublishing.md) for more information on how to publish your Industry Link to Azure Marketplace.

```powershell
New-AzureApplicationOffer
    -AssetsDirectory listingAssets
    -MarketplacePackageZipFile marketplacePackage.zip
    -OfferName contoso-industry-link
    -PlanName contoso-industry-link
```
