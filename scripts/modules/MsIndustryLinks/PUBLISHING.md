# Publishing

To make your Industry Link available to customers, create and publish an offer in Partner Center. Use the [MsIndustryLinks](README.md) module to package and create AppSource offers. Currently, only AppSource offers are supported.

## Prerequisites

### Tools

- [PowerShell 7.0+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (Mac users can use brew to install: `brew install azure-cli`)
- [azcopy](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) (Mac users can use brew to install: `brew install azcopy`)

### Accounts

- [Microsoft Partner Center account](https://learn.microsoft.com/en-us/power-platform/developer/appsource/register-microsoft-partner-network)
- [Azure AD application](https://learn.microsoft.com/en-us/partner-center/marketplace/submission-api-onboard#step-1-complete-prerequisites-for-using-the-partner-center-submission-api) associated with your Partner Center account
- Azure subscription

## Create an Azure Storage account

A storage account is required to store the packages for your offers. If you don't have a storage account, [create one in the Azure portal or the Azure CLI](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal).

Example:

```
az group create --name storage-resource-group --location eastus

az storage account create \
  --name <account-name> \
  --resource-group storage-resource-group \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2
```

## Import the MsIndustryLinks module

```powershell
Import-Module -Name MsIndustryLinks
```

## Create and publish offers

The **MsIndustryLinks** module contains cmdlets to automate some of the steps required to publish an Industry Link with Partner Center. Refer to the documentation for the type of offer you want to publish.

| Offer type | Description          | Documentation                                                         |
| ---------- | -------------------- | --------------------------------------------------------------------- |
| AppSource  | Power Automate Flows | [Publishing to Microsoft AppSource](appsource/AppSourcePublishing.md) |
