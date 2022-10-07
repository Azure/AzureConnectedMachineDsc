Configuration AzureConnectedMachineAgent {
    Import-DscResource -ModuleName PSDSCResources
    Import-DscResource -Module @{ModuleName = 'AzureConnectedMachineDsc'; ModuleVersion = '1.2.0'}

    Node $AllNodes.NodeName
    {
        Package AzureHIMDService
        {
            Name        = 'Azure Connected Machine Agent'
            Ensure      = 'Present'
            ProductId   = '{D0AC7A41-6190-4F9C-95B8-2EA8D580FB4A}'
            Path        = 'https://aka.ms/AzureConnectedMachineAgent.msi'
        }

        Service HIMDS
        {
            Ensure  = 'Present'
            Name    = 'HIMDS'
            State   = 'Running'
        }

        AzureConnectedMachineAgentDsc Connect
        {
            TenantId        = $Node.TenantId
            SubscriptionId  = $Node.SubscriptionId
            ResourceGroup   = $Node.ResourceGroup
            Location        = $Node.Location
            Tags            = $Node.Tags
            Credential      = $Node.Credential
        }

        AzcmagentConfig Ports
        {
            IsSingleInstance = 'Yes'
            incomingconnections_ports = '22','2222'
        }
    }
}

. $PSScriptRoot\private.ConfigurationData.ps1

AzureConnectedMachineAgent -out c:\dsc -configurationdata $configurationData
