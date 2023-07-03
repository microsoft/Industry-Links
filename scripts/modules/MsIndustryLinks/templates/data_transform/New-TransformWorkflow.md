# New-TransformWorkflow

Module: [MsIndustryLinks](../../README.md)

Generates a transform workflow template. Supports Logic Apps and Power Automate Flows.

## Syntax

```powershell
New-TransformWorkflow
    -WorkflowConfigFile <String>
    -OutputDirectory <String>
```

## Description

Generates a transform workflow template that will transform content into a JSON array of objects. This cmdlet will generate a Logic App or Power Automate Flow template. Specify the workflow type (Flow or LogicApp) in the workflow configuration file.

## Examples

### Example 1: Generate a workflow template to transform data

```powershell
New-TransformWorkflow
    -WorkflowConfigFile workflow.json
    -OutputDirectory output
```

## Parameters

### -WorkflowConfigFile

The workflow configuration file that defines the trigger, the data source, the data sink and any transformations that will be applied. See [flow_workflow.json.tmpl](../flow_workflow.json.tmpl) and [logicapp_workflow.json.tmpl](../logicapp_workflow.json.tmpl) for examples of the workflow configuration file.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -OutputDirectory

The directory where the transform workflow template will be saved. If it doesn't exist, it will be created.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

## Inputs

**None**

This cmdlet accepts no input.

## Outputs

**[Hashtable](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#433-hashtables)**

This cmdlet returns a Hashtable containing the name and GUID of the workflow.

|      |                          |
| ---- | ------------------------ |
| name | The name of the workflow |
| guid | The GUID of the workflow |
