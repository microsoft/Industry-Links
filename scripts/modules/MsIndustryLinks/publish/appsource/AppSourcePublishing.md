# Publishing to Microsoft AppSource

The **MsIndustryLinks** module contains commands to automate some of the steps required to publish an Industry Link to AppSource. See [Publishing your app on AppSource](https://learn.microsoft.com/en-us/power-platform/developer/appsource/publish-app) for more information.

Use the following steps to prepare your AppSource package and create an offer:

## Step 1. Create a Partner Center account

See [Create a Microsoft Partner Center account](https://learn.microsoft.com/en-us/power-platform/developer/appsource/register-microsoft-partner-network) to create a Partner Center account.

## Step 2. Associated an Azure AD application with your Partner Center account

### Onboard to the Partner Center API

See [Partner Center submission API onboarding](https://learn.microsoft.com/en-us/partner-center/marketplace/submission-api-onboard) to associate an Azure AD application with your Partner Center account.

### Configure authentication details in config.json

Create a `config.json` file using the [config template](config.json.tmpl). The config file contains the authentication details for the Azure AD application associated with your Partner Center account. All fields are required.

## Step 3. Create a managed solution for your Industry Link

See the cmdlet [New-WorkflowPackage](../../templates/package/New-WorkflowPackage.md) for more information on creating a managed solution for your Industry Link.

## Step 4. Create a new offer for your Industry Link

### Prepare your AppSource package assets

The following files are required in the AppSource package:

- [input.xml](https://learn.microsoft.com/en-us/power-platform/developer/appsource/create-package-app#create-inputxml-file)
- [an icon for your Industry Link](https://learn.microsoft.com/en-us/power-platform/developer/appsource/create-package-app#create-an-icon-for-your-appsource-package)
- [HTML file for license terms](https://learn.microsoft.com/en-us/power-platform/developer/appsource/create-package-app#create-an-html-file-for-license-terms)
- Managed solution (zip) file of your Industry Link

Place all AppSource package asset files in the same folder. See the [assets](assets) folder for examples.

### Prepare your offer marketing assets

To publish an AppSource offer, the following marketing assets are required:

- at least one supporting document
- icons (small, wide and large)
- at least one screenshot of the Industry Link

You can optionally include videos demonstrating your Industry Link. For each video, a thumbnail screenshot is required.

See the [assets/listing](assets/listing) folder as an example of where to place your offer marketing assets.

| Asset Type           | Description                                                                               | Folder        |
| -------------------- | ----------------------------------------------------------------------------------------- | ------------- |
| Supporting documents | At least one supporting document is required. The documents must be in PDF format.        | listing/asset |
| Icons                | Three icon sizes are required: small (48x48), wide (255x115) and large (216x216).         | listing/image |
| Screenshots          | At least one screenshot (size: 1280x720) is required.                                     | listing/image |
| Videos               | Videos are optional. For each video, a thumbnail screenshot (size: 1280x720) is required. | listing/video |

**Important!** Be sure to update the `listingAssets` property in the offer definition file (see next step) to match the names of the asset files you created.

### Configure your offer details

An offer definition file is required to create an offer for your Industry Link. This file contains the details of your offer, including where to list your offer and marketing assets such as logos, screenshots and videos.

The file must be named `offer.json` and placed in same folder as the [AppSource assets](#prepare-your-appsource-package-assets). Use the [template](assets/offer.json.tmpl) provided for an example. See [Create a Dynamics 365 apps on Dataverse and Power Apps offer](https://learn.microsoft.com/en-us/partner-center/marketplace/dynamics-365-customer-engage-offer-setup) for more information.

### Create the AppSource package and offer

Create the AppSource package and offer using the [New-AppSourceOffer](New-AppSourceOffer.md) cmdlet.

| Parameter        | Description                                                                                                                                                   | Required |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| ProviderName     | The name of your organization, for example, Contoso or Microsoft. This should be the same value as the ProviderName element in [input.xml](assets/input.xml). | Yes      |
| ConfigFile       | The path to the config.json file created in [Step 2](#step-2-associated-an-azure-ad-application-with-your-partner-center-account).                            | Yes      |
| SolutionZip      | The path to the managed solution zip file created in [Step 3](#step-3-create-a-managed-solution-for-your-industry-link).                                      | Yes      |
| AppSourceAssets  | The path to the folder containing the AppSource and offer assets.                                                                                             | Yes      |
| StorageAccount   | The name of the Azure storage account used to store AppSource packages.                                                                                       | Yes      |
| StorageContainer | (optional) The name of the Azure storage container used to store AppSource packages. Default: appsource-packages.                                             | No       |

Example:

```powershell
New-AppSourceOffer
    -ProviderName Contoso
    -ConfigFile config.json
    -SolutionZip ContosoIndustryLink.zip
    -AppSourceAssets assets
    -StorageAccount mystorageaccount
    -StorageContainer mypackages
```

### Run AppSource checker

Use [AppSource checker](https://isvstudio.powerapps.com/checker) to check your package against the AppSource certification criteria. Correct any issues flagged as severity ‘High’. Re-run the previous to update your offer with the validated package.

### Add supplemental content to your offer

Browse to your offer in the [Partner Center dashboard](https://partner.microsoft.com/en-us/dashboard) and add a Key Usage Scenario document (PDF). This document will help Microsoft reviewers validate your offer. This information is not shown to the customer. See [Set up Dynamics 365 apps on Dataverse and Power Apps offer supplemental content](https://go.microsoft.com/fwlink/?linkid=2163505) for more information.

🎉 Congratulations! Your offer is now ready for submission to AppSource. 🎉

## Step 5. Submit your offer for preview and publish the offer live

See [Review and publish a Dynamics 365 offer](https://learn.microsoft.com/en-us/partner-center/marketplace/dynamics-365-review-publish) to submit your offer for preview and publish the offer live.
