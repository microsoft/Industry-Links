# New-WorkflowPackage

Module: [MsIndustryLinks](../../README.md)

Packages a directory of workflow templates into a Power Platform solution deployable zip file. Supports Power Automate Flows only.

## Syntax

```powershell
New-WorkflowPackage
    -ParametersFile <String>
    -TemplateDirectory <String>
    -OutputDirectory <String>
```

## Description

Creates and configures Power Automate solution assets using a directory of workflow templates. It is then packaged into a solution deployable zip file.

## Examples

### Example 1: Package a directory of workflow templates into a Power Platform solution deployable zip file

```powershell
New-WorkflowPackage
    -ParametersFile parameters.json
    -TemplateDirectory templates
    -OutputDirectory output
```

## Parameters

### -ParametersFile

The path to the parameters file (JSON) that will be used to customize the solution.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -TemplateDirectory

The path to the workflow templates required for your Industry Link. This should contain at least one workflow template.

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
