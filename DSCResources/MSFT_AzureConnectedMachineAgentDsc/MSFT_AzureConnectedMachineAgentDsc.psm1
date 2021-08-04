Import-Module $PSScriptRoot\..\Helpers.psm1 -Force

function Get-TargetResource {
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [string]$Tags,

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,

        [bool]$ForceReplaceAgent = $false
    )

    $AzConnectedMachineAgent = Get-AzConnectedMachineAgent
    $code = 'AzureConnectedMachineAgentdsc:AzureConnectedMachineAgentdsc:'

    $reasons = @()

    $TenantId = @{
        code   = $code + 'tenantid'
        phrase = "The Tenant Id returned: $($return.TenantId)"
    }
    $reasons += $TenantId

    $ResourceGroup = @{
        code   = $code + 'subscriptionid'
        phrase = "The Subscription Id returned: $($return.SubscriptionId)"
    }
    $reasons += $ResourceGroup

    $ResourceGroup = @{
        code   = $code + 'resourcegroup'
        phrase = "The Resource Group returned: $($return.ResourceGroup)"
    }
    $reasons += $ResourceGroup

    $Location = @{
        code   = $code + 'location'
        phrase = "The Location returned: $($return.Location)"
    }
    $reasons += $Location

    $Tags = @{
        code   = $code + 'tags'
        phrase = "The Tags returned: $($return.Tags)"
    }
    $reasons += $Tags

    $ConnectionStatus = @{
        code   = $code + 'connectionstatus'
        phrase = "The connection status of the agent returned: $($return.AgentStatus)"
    }
    $reasons += $ConnectionStatus

    $return = @{
        TenantId       = $AzConnectedMachineAgent.TenantId
        SubscriptionId = $AzConnectedMachineAgent.SubscriptionId
        ResourceGroup  = $AzConnectedMachineAgent.ResourceGroup
        Location       = $AzConnectedMachineAgent.Location
        Tags           = $AzConnectedMachineAgent.Tags
        Reasons        = $reasons
    }

    return $return
}

function Set-TargetResource {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [string]$Tags,

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,

        [bool]$ForceReplaceAgent = $false
    )

    Connect-AzConnectedMachineAgent @PSBoundParameters
}

function Test-TargetResource {
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [string]$Tags,

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,

        [bool]$ForceReplaceAgent = $false
    )
    $Params =
    @{
        TenantId       = $TenantId
        SubscriptionId = $SubscriptionId
        ResourceGroup  = $ResourceGroup
        Location       = $Location
        Tags           = $Tags
    }

    Test-AzConnectedMachineAgent @Params
}

Export-ModuleMember -Function *-TargetResource
