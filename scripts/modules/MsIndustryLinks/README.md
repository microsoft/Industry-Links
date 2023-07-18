# MsIndustryLinks

The **MsIndustryLinks** module contains cmdlets to generate workflow templates (Logic App, Power Automate Flow) for a Microsoft Industry Link, package the workflow templates into a solution and create an AppSource offer in Partner Center.

## Prerequisites

- [PowerShell 7.0+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (Mac users can use brew to install: `brew install azure-cli`)
- [azcopy](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) (Mac users can use brew to install: `brew install azcopy`)
- [Power Platform CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction#install-microsoft-power-platform-cli)
- [Azure Partner Center CLI](https://github.com/microsoft/az-partner-center-cli)

## MsIndustryLinks

|                                                                                            |                                                                                       |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| [New-AppSourceOffer](publish/appsource/New-AppSourceOffer.md)                              | Create an AppSource offer in Partner Center                                           |
| [New-AppSourcePackage](publish/appsource/New-AppSourcePackage.md)                          | Create an AppSource package from managed solution                                     |
| [New-AzureApplicationOffer](publish/application/New-AzureApplicationOffer.md)              | Create an Azure Application offer for an Industry Link                                |
| [New-AzureDeployment](package/azureDeploymentPackage/New-AzureDeployment.md)               | Deploy generated ARM templates to an Azure subscription.                              |
| [New-AzureDeploymentPackage](package/azureDeploymentPackage/New-AzureDeploymentPackage.md) | Generate ARM templates that deploys the Azure resources required for an Industry Link |
| [New-CustomConnector](customConnector/New-CustomConnector.md)                              | Create a custom connector in a Power Platform environment                             |
| [New-CustomConnectorConfig](customConnector/New-CustomConnectorConfig.md)                  | Creates Power Platform custom connector asset configuration files                     |
| [New-DataSourceWorkflow](templates/data_source/New-DataSourceWorkflow.md)                  | Generate an end-to-end workflow template for specified data source                    |
| [New-IngestionWorkflow](templates/data_sink/New-IngestionWorkflow.md)                      | Generate an ingestion workflow template                                               |
| [New-MsIndustryLink](templates/New-MsIndustryLink.md)                                      | Generate a Microsoft Industry Link                                                    |
| [New-TransformWorkflow](templates/data_transform/New-TransformWorkflow.md)                 | Generate a transform workflow template                                                |
| [New-WorkflowPackage](package/powerPlatformSolution/New-WorkflowPackage.md)                | Package workflow templates into a solution                                            |
