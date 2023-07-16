# New-AzureDeploymentPackage

Module: [MsIndustryLinks](../README.md)

Generates ARM templates that deploys the Azure resources required for an Industry Link.

## Syntax

```powershell
New-AzureDeploymentPackage
    -WorkflowConfigFile <String>
    -TemplateDirectory <String>
    -OutputDirectory <String>
    [-ApiDefinitionFile] <String>
```

## Description

Generates ARM templates that deploys the Azure resources such as storage account, event hub, connections and Logic Apps required for an Industry Link.

## Examples

### Example 1: Generate ARM templates from Logic App workflow templates

```powershell
New-AzureDeploymentPackage
    -WorkflowConfigFile workflow.json
    -TemplateDirectory templates
    -OutputDirectory output
```

### Example 2: Generate ARM templates from Logic App workflow templates that uses a non-verified custom connector as a source or sink

```powershell
New-AzureDeploymentPackage
    -WorkflowConfigFile workflow.json
    -TemplateDirectory templates
    -OutputDirectory output
    -ApiDefinitionFile api.swagger.json
```

## Parameters

### -WorkflowConfigFile

The workflow configuration file that defines the trigger, the data source, the data sink and any transformations that will be applied. See [logicapp_workflow.json.tmpl](../templates/logicapp_workflow.json.tmpl) for an example of the workflow configuration file.

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

The directory path where the ARM templates will be saved.

|                |                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Type:          | [String](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-04?view=powershell-7.3#431-strings) |
| Default value: | None                                                                                                                  |

### -ApiDefinitionFile

The path to the custom connector Swagger API definition file. This is the API definition file required to deploy a non-verified custom connector for your API. Support authentication types: API Key.

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
