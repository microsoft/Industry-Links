# Modules

| Module                                       | Description                                    |
| -------------------------------------------- | ---------------------------------------------- |
| [MsIndustryLinks](MsIndustryLinks/README.md) | Generate and publish a Microsoft Industry Link |

## Build Modules

Auto-generate module file from all the `.psm1` files in a module's directory. The script will combine the content from each `.psm1` into a single file.

Example:

```powershell
./BuildModule.ps1 -ModuleDirectory ./MsIndustryLinks
```

## Import and Remove Modules

To import a module:

```powershell
Import-Module -Name <Module Directory>

# Example
Import-Module -Name MsIndustryLinks
```

To remove a module:

```powershell
Remove-Module -Name <Module Name>

# Example
Remove-Module -Name MsIndustryLinks
```
