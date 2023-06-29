# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script creates a custom connector using the PAC CLI using the custom connector generated in #
# the ./generateCustomConnectorConfig.ps1 script.                                                  #
####################################################################################################

Param (
    [Parameter(Mandatory=$true, HelpMessage="The path to the custom connector config files")]
    [string]$connectorPath
)

try {
    Write-Output "Create custom connector and add it to the solution"
    pac connector create --settings-file "$connectorPath/settings.json"
}
catch {
    Write-Error "An error occurred while creating the custom connector: " + $_.Exception.Message
    Exit 1
}
