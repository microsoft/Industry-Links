# New-CustomConnectorConfig

Module: [MsIndustryLinks](../README.md)

Creates Power Platform custom connector asset configuration files to use as a data source for your Industry Link.

## Syntax

```powershell
New-CustomConnectorConfig
    -ConfigFile <String>
    -OutputDirectory <String>
```

## Description

Creates Power Platform custom connector asset configuration files which can be deployed to use as a data source for your Industry Link.
The custom connector assets include the API definition file, API properties file, settings.json file, the icon and the custom script file (if required).

## Examples

### Example 1: Create a custom connector

```powershell
New-CustomConnectorConfig
    -ConfigFile config.json
    -OutputDirectory ./output
```

## Parameters

### -ConfigFile

The configuration file that defines the location of the required files to create the custom connector and the configuration for OAuth 2.0 authentication.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -OutputDirectory

The directory where the generated custom connector assets will be saved. If it doesn't exist, it will be created.

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
