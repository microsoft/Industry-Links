# MsIndustryLinks

The **MsIndustryLinks** module contains cmdlets to generate workflow templates (Logic App, Power Automate Flow) for a Microsoft Industry Link, package the workflow templates into a solution and create an AppSource offer in Partner Center.

## Prerequisites

- [PowerShell 7.0+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3)
- [azcopy](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) (Mac users can use brew to install: `brew install azcopy`)

## MsIndustryLinks

|                                                                            |                                                                    |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| [New-AppSourceOffer](appsource/New-AppSourceOffer.md)                      | Create an AppSource offer in Partner Center                        |
| [New-AppSourcePackage](appsource/New-AppSourcePackage.md)                  | Create an AppSource package from managed solution                  |
| [New-DatasourceWorkflow](templates/data_source/New-DatasourceWorkflow.md)  | Generate an end-to-end workflow template for specified data source |
| [New-IngestionWorkflow](templates/ingest/New-IngestionWorkflow.md)         | Generate an ingestion workflow template                            |
| [New-MsIndustryLink](templates/New-MsIndustryLink.md)                      | Generate a Microsoft Industry Link                                 |
| [New-TransformWorkflow](templates/data_transform/New-TransformWorkflow.md) | Generate a transform workflow template                             |
| [New-WorkflowPackage](templates/package/New-WorkflowPackage.md)            | Package workflow templates into a solution                         |