# New-DataSourceWorkflow

Module: [MsIndustryLinks](../../README.md)

Generates a workflow template that defines the trigger, the data source and any workflows called by this workflow. Supports Power Automate Flows.

## Syntax

```powershell
New-DataSourceWorkflow
    -WorkflowConfigFile <String>
    -TemplateDirectory <String>
    [-WorkflowGuids] <Hashtable>
    [-AuthConfigFile] <String>
```

## Description

Generates a workflow template that defines the trigger, the data source and any workflows called by this workflow. This cmdlet will generate a Power Automate Flow template.

## Examples

### Example 1: Generate a workflow template with Azure Blob Storage as the data source

```powershell
New-DataSourceWorkflow
    -WorkflowConfigFile workflow.json
    -TemplateDirectory templates
```

### Example 2: Generate a workflow template with a non-certified custom connector as the data source.

```powershell
New-DataSourceWorkflow
    -WorkflowConfigFile workflow.json
    -TemplateDirectory templates
    -AuthConfigFile auth.json
```

## Parameters

### -WorkflowConfigFile

The workflow configuration file that defines the trigger, the data source, the data sink and any transformations that will be applied.

See [workflow.json.tmpl](../workflow.json.tmpl) for an example.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -TemplateDirectory

The directory containing the workflow templates and where the data source workflow template will be saved.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -WorkflowGuids

The mapping of workflow templates to GUIDs. If not provided, the workflow GUIDs will be retrieved from each workflow template in the template directory.

|                |                                                                                                                             |
| -------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Type:          | [Hashtable](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#433-hashtables) |
| Default value: | None                                                                                                                        |

### -AuthConfigFile

The path to the authentication configuration JSON file. This file is only required if the data source is a non-certified custom connector. Provide the tenantId, clientId, clientSecret, and orgWebApiUrl for the service principal that will be used to authenticate with the Dataverse API.

See [auth.json.tmpl](../auth.json.tmpl) for an example.

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
