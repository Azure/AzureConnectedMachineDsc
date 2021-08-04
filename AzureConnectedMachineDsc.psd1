#
# Module manifest for module 'AzureConnectedMachineDsc'
#
# Generated by: Michael Greene
#
# Generated on: 10/23/2019
#

@{

# Version number of this module.
ModuleVersion = '1.1.0.0'

# ID used to uniquely identify this module
GUID = '4e7bcccd-6002-47b5-8b9f-fcca5975d445'

# Author of this module
Author = 'Michael Greene'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Installs the Azure Arc agent on a Windows instance and connects to Azure'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = ''

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = ''

# Variables to export from this module
VariablesToExport = ''

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = ''

# DSC resources to export from this module
DscResourcesToExport = 'MSFT_AzureConnectedMachineAgentDsc'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Azure','AzureArc','Arc','AzureConnectedMachine','DesiredStateConfiguration', 'DSC', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://raw.githubusercontent.com/Azure/AzureConnectedMachineDsc/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/azure/AzureConnectedMachineDsc'

        # A URL to an icon representing this module.
        IconUri = 'https://raw.githubusercontent.com/Azure/AzureConnectedMachineDsc/master/icon.png'

        # ReleaseNotes of this module
        ReleaseNotes = 'https://raw.githubusercontent.com/Azure/AzureConnectedMachineDsc/master/changelog.md'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        RequireLicenseAcceptance = $false

    } # End of PSData hashtable

} # End of PrivateData hashtable

}

