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
    Import-DscResource -Module @{ModuleName = 'AzureConnectedMachineDsc'; ModuleVersion = '1.0.0.0'}

    Node $AllNodes.NodeName
    {
        Package AzureHIMDService
        {
            Name        = 'Azure Connected Machine Agent'
            Ensure      = 'Present'
            ProductId   = '{05B61BA8-2735-4B94-900D-C9C7C90EA198}'
            Path        = 'https://download.microsoft.com/download/4/c/2/4c287d81-6657-4cd8-9254-881ae6a2d1f4/AzureConnectedMachineAgent.msi'
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
