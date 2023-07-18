# Publishing Azure Application Offer to Azure Marketplace

The **MsIndustryLinks** module contains commands to automate some of the steps required to publish a Logic App-based Industry Link to Azure Marketplace.

Use the following steps to prepare your Azure Marketplace package and create an offer:

## Step 1. Create a Partner Center account

See [Create a Microsoft Partner Center account](https://learn.microsoft.com/en-us/power-platform/developer/appsource/register-microsoft-partner-network) to create a Partner Center account.

## Step 2. Install Required Tools

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Azure Partner Center CLI](https://github.com/microsoft/az-partner-center-cli)

## Step 3. Associated an Azure AD application with your Partner Center account

### Onboard to the Partner Center API

See [Partner Center submission API onboarding](https://learn.microsoft.com/en-us/partner-center/marketplace/submission-api-onboard) to associate an Azure AD application with your Partner Center account.

### Login to Azure as the Azure AD application

```
az login --service-principal -u <CLIENT-ID> -p <CLIENT-SECRET> --tenant <TENANT-ID>
```

## Step 4. Generate the offer package for the Industry Link

See the cmdlet [New-AzureDeploymentPackage](../../package/azureDeploymentPackage/New-AzureDeploymentPackage.md) for more information on generating the offer package from the Industry Link Logic App workflow templates.

Example:

```powershell
New-AzureDeploymentPackage
    -WorkflowConfigFile workflow.json
    -TemplateDirectory templates
    -OutputDirectory output
```

## Step 5. Create a new offer for your Industry Link

### Prepare your Azure Application package assets

The `New-AzureDeploymentPackage` cmdlet will generate the ARM templates and portal user interface file required to create an offer. You have the option to customize the portal user interface file to fit your needs. Simply unzip the `marketplacePackage.zip` file and edit the `createUiDefinition.json` file.

The createUiDefinition.json file specifies the portal user interface that is displayed to the customer when deploying your Industry Link. Once you have finished editing, test the portal interface using the [Create UI Definition Sandbox](https://portal.azure.com/?feature.customPortal=false&#blade/Microsoft_Azure_CreateUIDef/SandboxBlade) and replace the empty definition with the contents of your createUiDefinition.json file. Select Preview and the form you created is displayed.

Please refer to [CreateUiDefinition.json for Azure managed application's create experience](https://learn.microsoft.com/en-us/azure/azure-resource-manager/managed-applications/create-uidefinition-overview) for more information on customizing the portal user interface.

Once you have finished editing the createUiDefinition.json file, zip the contents of the `marketplacePackage` folder into a file named `marketplacePackage.zip`.

```powershell
Compress-Archive -Path "marketplacePackage\*" -DestinationPath "marketplacePackage.zip" -Force
```

### Prepare your offer assets

Create a folder that will store the marketing assets (logos), listing configuration (listing_config.json) and manifest file (manifest.yml).

To publish an offer, the following marketing assets are required:

- icons (small, medium, wide and large)

See the [assets](assets) folder for examples. The names of the icons must match the names in the [listing_config.json](assets/listing_config.json) file.

### Configure your offer details

An offer definition file is required to create an offer for your Industry Link. This file contains the details of your offer, including marketing assets such as logos. The file must be named `listing_config.json` and placed in same folder as the [marketing assets](#prepare-your-offer-marketing-assets) and manifest file. Use the [template](assets/listing_config.json) provided for an example.

### Create the offer

Create the Azure Application offer using the [New-AzureApplicationOffer](New-AzureApplicationOffer.md) cmdlet.

| Parameter                 | Description                                                                                | Required |
| ------------------------- | ------------------------------------------------------------------------------------------ | -------- |
| AssetsDirectory           | The path to the folder containing the manifest.yml, marketing assets, listing_config.json. | Yes      |
| MarketplacePackageZipFile | The zip file containing the ARM templates and portal user interface file.                  | Yes      |
| OfferId                   | The ID of the offer. Example: contoso-industry-link.                                       | Yes      |
| PlanId                    | The ID of the plan. Example: contoso-industry-link                                         | Yes      |

Example:

```powershell
New-AzureApplicationOffer
    -AssetsDirectory listingAssets
    -MarketplacePackageZipFile marketplacePackage.zip
    -OfferId contoso-industry-link
    -PlanId contoso-industry-link
```

Once the offer is created, you can view the offer in the [Partner Center dashboard](https://partner.microsoft.com/en-us/dashboard/marketplace-offers/overview) and make any additional changes as needed.

🎉 Congratulations! Your offer is now ready for submission to Azure Marketplace. 🎉

## Step 6. Submit your offer for preview and publish the offer live

See [Test and publish an Azure application offer](https://learn.microsoft.com/en-us/partner-center/marketplace/azure-app-test-publish) to submit your offer for preview and publish the offer live.
