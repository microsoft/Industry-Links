# New-AppSourceOffer

Module: [MsIndustryLinks](../../README.md)

Generates an App Source package and creates an offer for the Industry Link.

## Syntax

```powershell
New-AppSourceOffer
    -ProviderName <String>
    -ConfigFile <String>
    -SolutionZip <String>
    -AppSourceAssets <String>
    -StorageAccount <String>
    -StorageContainer <String>
```

## Description

Generates an App Source package and creates an Industry Link offer that is ready for publishing.

## Examples

### Example 1: Generate an AppSource package and create offer for the Industry Link

```powershell
New-AppSourceOffer
    -ProviderName Contoso
    -ConfigFile config.json
    -SolutionZip ContosoIndustryLink.zip
    -AppSourceAssets assets
    -StorageAccount mystorageaccount
    -StorageContainer mypackages
```

## Parameters

### -ProviderName

Name of the managed solution provider.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -ConfigFile

The configuration file containing settings for Partner Center API authentication and creating the AppSource offer.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -SolutionZip

The managed solution package file (zip) containing the Industry Link components such as Power Automate Flows.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -AppSourceAssets

The path to the folder containing assets for the AppSource package such as the icon, input.xml file and terms of use HTML file.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -StorageAccount

Name of the Azure Storage account where the AppSource package will be uploaded. A SAS URI will be generated for the uploaded package and used to create the offer.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -StorageContainer

Name of the storage container where the AppSource package will be uploaded.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | appsource-packages                                                                                                    |

## Inputs

**None**

This cmdlet accepts no input.

## Outputs

**None**

This cmdlet returns no output.
