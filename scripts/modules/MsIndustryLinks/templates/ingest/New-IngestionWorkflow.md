# New-IngestionWorkflow

Module: [MsIndustryLinks](../../README.md)

Generates an ingestion workflow template. Supports Logic Apps and Power Automate Flows.

## Syntax

```powershell
New-IngestionWorkflow
    -WorkflowConfigFile <String>
    -OutputDirectory <String>
```

## Description

Generates an ingestion workflow template that defines the data sink. This cmdlet will generate a Logic App or Power Automate Flow template. Specify the workflow type (Flow or LogicApp) in the workflow configuration file.

## Examples

### Example 1: Generate a workflow template with Dataverse as the data sink

```powershell
New-IngestionWorkflow
    -WorkflowConfigFile workflow.json
    -OutputDirectory output
```

### Example 2: Generate a workflow template with a non-certified custom connector as the data sink

```powershell
New-IngestionWorkflow
    -WorkflowConfigFile workflow.json
    -OutputDirectory output
    -AuthConfigFile auth.json
```

## Parameters

### -WorkflowConfigFile

The workflow configuration file that defines the trigger, the data source, the data sink and any transformations that will be applied. See [flow_workflow.json.tmpl](../flow_workflow.json.tmpl) and [logicapp_workflow.json.tmpl](../logicapp_workflow.json.tmpl) for examples of the workflow configuration file.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -OutputDirectory

The directory where the ingestion workflow template will be saved. If it doesn't exist, it will be created.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -AuthConfigFile

The path to the authentication configuration JSON file. This file is only required if the data source is a non-certified custom connector. Provide the tenantId, clientId, clientSecret, and orgWebApiUrl for the service principal that will be used to authenticate with the Dataverse API.

See [auth.json.tmpl](../auth.json.tmpl) for an example.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None

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
