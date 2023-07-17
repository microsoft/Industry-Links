# Microsoft Industry Links

There are many options for Microsoft partners when creating solutions to transfer data into and out of the [Microsoft Cloud for Industry](https://www.microsoft.com/en-us/industry/) products. To assist, this repository has created a set of quick start templates to be a starting point for partners with a guidance on technology choice on the most common patterns seen to date.

The intent is to minimize the friction for partners to create solutions for Microsoft Cloud for Industry and over time, we expect to add more patterns as required.

## What's Included

- MsIndustryLinks PowerShell module that supports:
  - Generation of Power Automate workflow templates
  - Packaging of workflows into a Power Platform solution
  - Generation of ready-to-publish AppSource offer listing in Partner Center
- Helper scripts to set up mock APIs and sample data for testing

See [MsIndustryLinks](scripts/modules/MsIndustryLinks/README.md) reference for more information on the cmdlets available for this module.

## Getting Started

### 1. Fork the repository

The easiest way to get started is to fork this repository so you can modify the files to meet your needs.

### 2. Install tools

The templates, modules and scripts in this repository use a combination of the following tools:

- [PowerShell 7.0+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3)
- [Power Platform CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction#install-microsoft-power-platform-cli)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- [Python 3.6+](https://www.python.org/downloads/)
- [azcopy](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) (Mac users can use brew to install: `brew install azcopy`)

### 3. Modify the template files

Use the following templates to build and publish your own Industry Link! Each use case includes a README file that contains instructions on how to modify, build and publish a solution.

| Solution                                                                  | Use Case                                                                                |
| ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| [Solution-Aware Power Automate Flows in AppSource](PowerAutomateFlows.md) | Ideal for transfering data between an API or file and Dataverse using Power Platform.   |
| [Logic App-based Industry Link in Azure Marketplace](LogicApps.md)        | Ideal for transfering data between an API, file, Event Hubs, and Dataverse using Azure. |

## Contributing

Contributions to this repository are welcome. Here's how you can contribute:

- Submit bugs and help us verify fixes.
- Submit feature requests and help us implement them.
- Submit pull requests for bug fixes and features.

Please refer to [Contribution Guidelines](CONTRIBUTING.md) for more details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.
