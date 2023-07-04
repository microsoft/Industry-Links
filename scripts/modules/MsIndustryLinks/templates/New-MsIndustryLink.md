# New-MsIndustryLink

Module: [MsIndustryLinks](../README.md)

Generates a deployable package that contains a set of workflows that retrieves data from a source and ingests it into Dataverse.

## Syntax

```powershell
New-MsIndustryLink
    -BaseTemplate <String>
    -WorkflowConfigFile <String>
    -OutputDirectory <String>
    -PackageParametersFile <String>
    [-AuthConfigFile] <String>
```

## Description

Generates a set of workflow templates that will insert or upsert data into a Dataverse table. For Flows, the templates are packaged into a Power Platform solution that can be imported into your Dataverse environment or used for publishing to AppSource.

## Examples

### Example 1: Generate an Industry Link package with a certified custom connector as the data source

```powershell
New-MsIndustryLink
    -BaseTemplate Flow
    -WorkflowConfigFile workflow.json
    -OutputDirectory output
    -PackageParametersFile package.parameters.json
```

### Example 2: Generate an Industry Link package with Azure Blob Storage as the data source

```powershell
New-MsIndustryLink
    -BaseTemplate Flow
    -WorkflowConfigFile workflow.json
    -OutputDirectory output
    -PackageParametersFile package.parameters.json
```

## Parameters

### -BaseTemplate

The base template to use for generating the customized workflow.

|                  |                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:            | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Accepted values: | Flow, LogicApp                                                                                                        |
| Default value:   | None                                                                                                                  |

### -WorkflowConfigFile

The workflow configuration file that defines the trigger, the data source, the data sink and any transformations that will be applied. See [flow_workflow.json.tmpl](flow_workflow.json.tmpl) and [logicapp_workflow.json.tmpl](logicapp_workflow.json.tmpl) for examples of the workflow configuration file.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -OutputDirectory

The directory where the generated deployable package will be saved. If it doesn't exist, it will be created.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -PackageParametersFile

The path to the parameters file (JSON) that will be used to customize the solution.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -AuthConfigFile

The path to the authentication configuration JSON file. This file is only required if the data source is a non-certified custom connector. Provide the tenantId, clientId, clientSecret, and orgWebApiUrl for the service principal that will be used to authenticate with the Dataverse API.

|                  |                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:            | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Accepted values: | Manual, Scheduled                                                                                                     |
| Default value:   | Manual                                                                                                                |

## Inputs

**None**

This cmdlet accepts no input.

## Outputs

**None**

This cmdlet returns no output.
