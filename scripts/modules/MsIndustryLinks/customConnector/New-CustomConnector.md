# New-CustomConnector

Module: [MsIndustryLinks](../README.md)

Creates Power Platform custom connector to use as a data source for your Industry Link.

## Syntax

```powershell
New-CustomConnector
    -CustomConnectorAssets <String>
```

## Description

Creates Power Platform custom connector to use as a data source for your Industry Link.
The connector will be created in the environment of your currently active Power Platform CLI auth profile.

## Examples

### Example 1: Create a custom connector

```powershell
New-CustomConnector
    -CustomConnectorAssets ContosoCustomConnector
```

## Parameters

### -CustomConnectorAssets

The path to the folder containing assets for the custom connector such as the icon, API definition file, API properties file and the settings.json file.

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
