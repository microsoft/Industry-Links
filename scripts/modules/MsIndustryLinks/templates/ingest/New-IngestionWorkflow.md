# New-IngestionWorkflow

Module: [MsIndustryLinks](../../README.md)

Generates an ingestion workflow template. Supports Logic Apps and Power Automate Flows.

## Syntax

```powershell
New-IngestionWorkflow
    -BaseTemplate <String>
    -ParametersFile <String>
    -MappingDefinitionFile <String>
    -OutputDirectory <String>
    [-UseUpsert] <Boolean>
```

## Description

Generates an ingestion workflow template that will insert or upsert data into a Dataverse table. This cmdlet will generate a Logic App or Power Automate Flow template.

## Examples

### Example 1: Generate a Power Automate workflow template to upsert data

```powershell
New-IngestionWorkflow
    -BaseTemplate Flow
    -ParametersFile parameters.json
    -MappingDefinitionFile mapping.json
    -OutputDirectory output
```

### Example 2: Generate a Logic App workflow template to insert data

```powershell
New-IngestionWorkflow
    -BaseTemplate LogicApp
    -ParametersFile parameters.json
    -MappingDefinitionFile mapping.json
    -OutputDirectory output
    -UseUpsert $false
```

## Parameters

### -BaseTemplate

The base template to use for generating the customized workflow.

|                  |                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:            | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Accepted values: | Flow, LogicApp                                                                                                        |
| Default value:   | None                                                                                                                  |

### -ParametersFile

The path to the parameters file (JSON) that will be used to customize the parameters in the template.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -MappingDefinitionFile

The path to the mapping definition file (JSON) that will be used to customize the mapping between your source data and Dataverse table.

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

### -UseUpsert

If set to true, the workflow will upsert records. Otherwise, it will insert records.

|                  |                                                                                                                        |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Type:            | [Boolean](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#421-boolean) |
| Accepted values: | False, True                                                                                                            |
| Default value:   | True                                                                                                                   |

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
