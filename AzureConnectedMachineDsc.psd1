@{
RootModule = './AzureConnectedMachineDsc.psm1'

ModuleVersion = '1.2.0'

GUID = '4e7bcccd-6002-47b5-8b9f-fcca5975d445'

Author = 'Michael Greene'

CompanyName = 'Microsoft Corporation'

Copyright = '(c) Microsoft Corporation. All rights reserved.'

Description = 'Installs the Azure Arc agent on a Windows instance and connects to Azure'

FunctionsToExport = 'Get-AzConnectedMachineAgent', 'Connect-AzConnectedMachineAgent', 'Test-AzConnectedMachineAgent', 'Get-AzConnectedMachineAgentConfig','Set-AzConnectedMachineAgentConfig','Test-AzConnectedMachineAgentConfig'

DscResourcesToExport = 'AzureConnectedMachineAgentDsc','AzcmagentConfig'

PrivateData = @{

    PSData = @{

        Tags = @('Azure','AzureArc','Arc','AzureConnectedMachine','DesiredStateConfiguration', 'DSC', 'DSCResource')

        LicenseUri = 'https://raw.githubusercontent.com/Azure/AzureConnectedMachineDsc/master/LICENSE'

        ProjectUri = 'https://github.com/azure/AzureConnectedMachineDsc'

        IconUri = 'https://raw.githubusercontent.com/Azure/AzureConnectedMachineDsc/master/icon.png'

        ReleaseNotes = 'https://raw.githubusercontent.com/Azure/AzureConnectedMachineDsc/master/changelog.md'

        # Prerelease = ''
        
        }
    }
}
