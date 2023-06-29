# New-TransformWorkflow

Module: [MsIndustryLinks](../../README.md)

Generates a transform workflow template. Supports Logic Apps and Power Automate Flows.

## Syntax

```powershell
New-TransformWorkflow
    -BaseTemplate <String>
    -SourceFormat <String>
    -OutputDirectory <String>
```

## Description

Generates a transform workflow template that will transform content into a JSON array of objects. This cmdlet will generate a Logic App or Power Automate Flow template.

## Examples

### Example 1: Generate a Power Automate workflow template to transform data

```powershell
New-TransformWorkflow
    -BaseTemplate Flow
    -SourceFormat CSV
    -OutputDirectory output
```

### Example 2: Generate a Logic App workflow template to transform data

```powershell
New-TransformWorkflow
    -BaseTemplate LogicApp
    -SourceFormat CSV
    -OutputDirectory output
```

## Parameters

### -BaseTemplate

The base template to use for generating the customized workflow.

|                  |                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:            | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Accepted values: | Flow, LogicApp                                                                                                        |
| Default value:   | None                                                                                                                  |

### -SourceFormat

The file format of the source content.

|                  |                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:            | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Accepted values: | CSV                                                                                                                   |
| Default value:   | None                                                                                                                  |

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

**[Guid](https://learn.microsoft.com/en-us/dotnet/api/system.guid)**

This cmdlet returns a GUID.
