
$script:httpserver = 'http://127.0.0.1:40342'
$script:agentstatus = '/agentstatus'
$script:metadata = '/metadata/instance'
$script:apiversion = '2019-08-15'
$script:headers = @{Metadata = $true }

$env:PATH = $env:PATH+";$env:ProgramFiles\AzureConnectedMachineAgent\"

function Connect-AzConnectedMachineAgent {
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

    if (Test-Path "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe") {
        if (Test-AzConnectedMachineAgentConnection) {
            Write-Verbose "Machine $env:COMPUTERNAME is already onboarded.  Disconnecting, restarting service, and reconnecting."
            & azcmagent disconnect `
                --resource-name $env:COMPUTERNAME `
                --tenant-id $TenantId `
                --subscription-id $SubscriptionId `
                --resource-group $ResourceGroup `
                --service-principal-id $Credential.UserName `
                --service-principal-secret $Credential.GetNetworkCredential().Password
            Restart-Service 'HIMDS' -Force
        }

        if ($null -ne $Tags) {
            Write-Verbose 'Attempting to register machine.'
            & azcmagent connect `
                --tenant-id $TenantId `
                --subscription-id $SubscriptionId `
                --resource-group $ResourceGroup `
                --location $Location `
                --service-principal-id $Credential.UserName `
                --service-principal-secret $Credential.GetNetworkCredential().Password `
                --tags $Tags
        }
        else {
            Write-Verbose 'Attempting to register machine.  No Tags were specified.'
            & azcmagent connect `
                --tenant-id $TenantId `
                --subscription-id $SubscriptionId `
                --resource-group $ResourceGroup `
                --location $Location `
                --service-principal-id $Credential.UserName `
                --service-principal-secret $Credential.GetNetworkCredential().Password
        }
    }
    else {
        throw 'The Hybrid agent is not installed.'
    }
}

function Get-AzConnectedMachineAgent {
    if (Test-AzConnectedMachineAgentService) {
        $agentstatusuri = $script:httpserver + $script:agentstatus + '?api-version=' + $script:apiversion
        $agentStatus = Invoke-WebRequest -UseBasicParsing -Uri $agentstatusuri -Headers $script:headers | ForEach-Object { $_.Content } | ConvertFrom-Json

        if ('' -ne $agentStatus.lastHeartBeat) {
            $metadataUri = $script:httpserver + $script:metadata + '?api-version=' + $script:apiversion
            $metadataInstance = Invoke-WebRequest -UseBasicParsing -Uri $metadataUri -Headers $script:headers | ForEach-Object { $_.Content } | ConvertFrom-Json | ForEach-Object { $_.compute }
        }

        if (Test-Path "$env:PROGRAMDATA\AzureConnectedMachineAgent\Config\agentconfig.json") {
            $agentConfig = Get-Content "$env:PROGRAMDATA\AzureConnectedMachineAgent\Config\agentconfig.json" | ConvertFrom-Json
        }

        $return = @{
            TenantId       = $agentConfig.TenantId
            SubscriptionID = $agentConfig.Subscriptionid
            ResourceGroup  = $agentConfig.resourceGroup
            Location       = $agentConfig.Location
            Tags           = $metadataInstance.Tags
            AgentStatus    = $agentStatus.Status
        }
        return $return
    }
    else {
        throw 'The Azure Hybrid Agent service is not running.'
    }
}

function Test-AzConnectedMachineAgent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        $Tags
    )

    $return = $true
    $AzConnectedMachineAgent = Get-AzConnectedMachineAgent

    if ($TenantId -ne $AzConnectedMachineAgent.TenantId) {
        Write-Verbose "Expected Tenant ID $TenantID but found $($AzConnectedMachineAgent.TenantId)"
        $return = $false
    }
    if ($SubscriptionId -ne $AzConnectedMachineAgent.SubscriptionId) {
        Write-Verbose "Expected Subscription ID $SubscriptionID but found $($AzConnectedMachineAgent.SubscriptionId)"
        $return = $false
    }
    if ($ResourceGroup -ne $AzConnectedMachineAgent.ResourceGroup) {
        Write-Verbose "Expected Resource Group $ResourceGroup but found $($AzConnectedMachineAgent.ResourceGroup)"
        $return = $false
    }
    if ($Location -ne $AzConnectedMachineAgent.Location) {
        Write-Verbose "Expected Location $Location but found $($AzConnectedMachineAgent.Location)"
        $return = $false
    }
    <# Tags are not implemeted yet in HIMDS
    if ($Tags -ne $AzConnectedMachineAgent.Tags) {
        Write-Verbose "Expected Tags value to be $Tags but found value $($AzConnectedMachineAgent.Tags)"
        $return = $false
    }
    #>
    if ('Connected' -ne $AzConnectedMachineAgent.AgentStatus) {
        Write-Verbose "Expected agent status to be Connected but found $($AzConnectedMachineAgent.AgentStatus)"
        $return = $false
    }

    return $return
}

function Test-AzConnectedMachineAgentConnection {
    'Connected' -eq (Get-AzConnectedMachineAgent).AgentStatus
}

function Test-AzConnectedMachineAgentService {
    If ('Running' -eq (Get-Service | Where-Object { $_.Name -eq 'HIMDS' } | ForEach-Object { $_.Status })) {
        $HIMDSuri = $script:httpserver + $script:agentstatus + '?api-version=' + $script:apiversion
        $HIMDS = Invoke-WebRequest -UseBasicParsing -Uri $HIMDSuri -Headers $script:headers | ForEach-Object { $_.StatusCode }
        if ('200' -eq $HIMDS) {
            return $true
        }
        else { return $false }
    }
    else { return $false }
}
