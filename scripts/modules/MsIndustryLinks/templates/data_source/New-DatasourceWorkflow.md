# New-DatasourceWorkflow

Module: [MsIndustryLinks](../../README.md)

Generates a workflow template that defines the trigger, the data source and any workflows called by this workflow. Supports Power Automate Flows.

## Syntax

```powershell
New-DatasourceWorkflow
    -DataSource <String>
    -BaseTemplate <String>
    -IngestionWorkflowGuid <String>
    -ParametersFile <String>
    -OutputDirectory <String>
    -TriggerType <String>
    [-TransformWorkflowGuid] <String>
```

## Description

Generates a workflow template that defines the trigger, the data source and any workflows called by this workflow. This cmdlet will generate a Power Automate Flow template.

## Examples

### Example 1: Generate a workflow template with an API as the data source

```powershell
New-DatasourceWorkflow
    -DataSource CustomConnector
    -BaseTemplate Flow
    -IngestionWorkflowGuid "41e38419-3821-4686-ae88-ec3400668513"
    -ParametersFile parameters.json
    -OutputDirectory output
    -TriggerType Scheduled
```

### Example 2: Generate a workflow template with Azure Blob Storage as the data source

```powershell
New-DatasourceWorkflow
    -DataSource AzureBlobStorage
    -BaseTemplate Flow
    -IngestionWorkflowGuid "41e38419-3821-4686-ae88-ec3400668513"
    -TransformWorkflowGuid "9bd420a7-5ad4-440f-807c-e5b0f479dc58"
    -ParametersFile parameters.json
    -OutputDirectory output
    -TriggerType Scheduled
```

## Parameters

### -DataSource

The data source of the workflow.

|                  |                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:            | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Accepted values: | CustomConnector, AzureBlobStorage                                                                                     |
| Default value:   | None                                                                                                                  |

### -BaseTemplate

The base template to use for generating the customized workflow.

|                  |                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:            | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Accepted values: | Flow                                                                                                                  |
| Default value:   | None                                                                                                                  |

### -IngestionWorkflowGuid

The GUID of the ingestion workflow that will be used to ingest data into Dataverse. This is returned by the New-IngestionWorkflow cmdlet but can also be found in the `name` attribute of the ingestion workflow template.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -TransformWorkflowGuid

The GUID of the transformation workflow that will be used to transform data into a JSON array. This is returned by the New-TransformWorkflow cmdlet but can also be found in the `name` attribute of the transformation workflow template. If not provided, the transformation workflow will not be included.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -OutputDirectory

The directory where the data source workflow template will be saved. If it doesn't exist, it will be created.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -ParametersFile

The path to the parameters file (JSON) that will be used to customize the data source parameters in the template.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -TriggerType

The type of trigger to use for the Industry Link.

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
