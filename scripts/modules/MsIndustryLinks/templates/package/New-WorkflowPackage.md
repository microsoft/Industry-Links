# New-WorkflowPackage

Module: [MsIndustryLinks](../../README.md)

Packages a directory of workflow templates into a Power Platform solution deployable zip file. Supports Power Automate Flows.

## Syntax

```powershell
New-WorkflowPackage
    -BaseTemplate <String>
    -WorkflowAssetsPath <String>
    -OutputDirectory <String>
    -ParametersFile <String>
```

## Description

Creates and configures Power Automate solution assets using a directory of workflow templates. It is then packaged into a solution deployable zip file.

## Examples

### Example 1: Package a directory of workflow templates into a Power Platform solution deployable zip file

```powershell
New-WorkflowPackage
    -BaseTemplate "Flow"
    -WorkflowAssetsPath output
    -OutputDirectory output/solution
    -ParametersFile parameters.json
```

## Parameters

### -BaseTemplate

The base template to use for generating the customized workflow.

|                  |                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:            | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Accepted values: | Flow                                                                                                                  |
| Default value:   | None                                                                                                                  |

### -WorkflowAssetsPath

The path to the workflow templates required for your Industry Link. This should contain at least one workflow template.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -ParametersFile

The path to the parameters file (JSON) that will be used to customize the solution.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -OutputDirectory

The directory where the solution assets will be saved.

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
