# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

################################################################################
# BuildModule.ps1                                                              #
# Generates a single module file from all files with *.psm1 extension in the   #
# specified directory.                                                         #
#                                                                              #
# Usage:                                                                       #
# ./BuildModule.ps1 -ModuleDirectory <path>                                    #
################################################################################
Param (
    [Parameter(Mandatory = $True, HelpMessage = "Module directory to search for *.psm1 files.")]
    [string] $ModuleDirectory
)

try {
    $moduleName = Split-Path -Path $ModuleDirectory -Leaf
    $moduleFile = "$moduleName.psm1"
    $moduleFilePath = New-Item -Path $ModuleDirectory -Name $moduleFile -ItemType "file" -Force

    # Recursively find all files ending with *.psm1 in current directory
    Write-Output "Generating module, $moduleName, in $moduleFile..."
    Add-Content -Path $moduleFilePath -Value "## THIS FILE IS AUTO-GENERATED. DO NOT EDIT. ##"

    $files = Get-ChildItem -Path $ModuleDirectory -Recurse -Include *.psm1
    foreach ($file in $files) {
        $fileName = $file.Name
        if ($fileName -eq $moduleFile) {
            continue
        }
        else {
            $fileContent = Get-Content $file.FullName
            Add-Content -Path $moduleFilePath -Value "`r`n"
            Add-Content -Path $moduleFilePath -Value "## $fileName ##"
            Add-Content -Path $moduleFilePath -Value $fileContent
        }
    }

    Write-Output "Module, $moduleName, generated successfully."
}
catch {
    Write-Error $_.Exception.Message
}
