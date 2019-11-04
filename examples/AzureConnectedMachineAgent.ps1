param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    $Tags,

    [Parameter(Mandatory = $true)]
    [PSCredential]$Credential
)

Configuration AzureConnectedMachineAgent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        $Tags,

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
    )
    Import-DscResource -ModuleName PSDSCResources
    Import-DscResource -Module @{ModuleName = 'AzureConnectedMachineAgentDsc'; ModuleVersion = '1.0.0.0'}

    Node $AllNodes.NodeName
    {
        Package AzureHIMDService
        {
            Name        = 'Azure Connected Machine Agent'
            Ensure      = 'Present'
            ProductId   = '{280B4C5F-FD44-40AE-87B7-CBADDD2A3480}'
            Path        = 'https://download.microsoft.com/download/b/3/a/b3a313c0-855c-40bd-bbc1-2b80ac8a1980/AzureConnectedMachineAgent%20(1).msi'
        }

        Service HIMDS
        {
            Ensure  = 'Present'
            Name    = 'HIMDS'
            State   = 'Running'
        }

        AzureConnectedMachineAgentDsc Connect
        {
            TenantId        = $TenantId
            SubscriptionId  = $SubscriptionId
            ResourceGroup   = $ResourceGroup
            Location        = $Location
            Tags            = $Tags
            Credential      = $Credential
        }
    }
}

. $PSScriptRoot\AzureConnectedMachineAgent.ConfigurationData.ps1

AzureConnectedMachineAgent @psboundparameters -out c:\dsc -configurationdata $configurationData
