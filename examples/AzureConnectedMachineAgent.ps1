Configuration AzureConnectedMachineAgent {
    Import-DscResource -ModuleName PSDSCResources
    Import-DscResource -Module @{ModuleName = 'AzureConnectedMachineDsc'; ModuleVersion = '1.4.0'}

    Node $AllNodes.NodeName
    {
        Package AzureHIMDService
        {
            Name        = 'Azure Connected Machine Agent'
            Ensure      = 'Present'
            ProductId   = '{BC10321B-15F3-4FA2-B1E9-D776C9D70001}'
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
