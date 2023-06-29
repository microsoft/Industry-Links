# New-AppSourcePackage

Module: [MsIndustryLinks](../README.md)

Generates an App Source package for publishing.

## Syntax

```powershell
New-AppSourcePackage
    -ProviderName <String>
    -SolutionZip <String>
    -AppSourceAssets <String>
```

## Description

Generates an App Source package for the Industry Link that is ready for publishing.

## Examples

### Example 1: Generate an AppSource package from managed solution

```powershell
New-AppSourcePackage
    -ProviderName Contoso
    -SolutionZip ContosoIndustryLink.zip
    -AppSourceAssets assets
```

## Parameters

### -ProviderName

Name of the managed solution provider.

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

## Inputs

**None**

This cmdlet accepts no input.

## Outputs

**None**

This cmdlet returns no output.
