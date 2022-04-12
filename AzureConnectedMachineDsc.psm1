
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
                --service-principal-id $Credential.UserName `
                --service-principal-secret $Credential.GetNetworkCredential().Password | Out-Default
            
            if ($LastExitCode -ne 0) {
                throw "Couldn't disconnect from Azure ARC."
            }

            Restart-Service 'HIMDS' -Force
        }
        
        $agentArgs = New-Object System.Collections.ArrayList
        $agentArgs.AddRange(@(
                "connect",
                "--tenant-id", $TenantId,
                "--subscription-id", $SubscriptionId,
                "--resource-group", $ResourceGroup
                "--location", $Location
                "--service-principal-id", $Credential.UserName
                "--service-principal-secret", $Credential.GetNetworkCredential().Password
            ))

        if ($null -ne $Tags) {
            Write-Verbose 'Attempting to register machine.'
            $agentArgs.AddRange(@("--tags", $Tags))
        }
        else {
            Write-Verbose 'Attempting to register machine.  No Tags were specified.'
        }

        & azcmagent $agentArgs

        if ($LastExitCode -ne 0) {
            throw "Couldn't connect to Azure ARC."
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

function Get-Reasons {
    param(
        [Parameter(Mandatory)]
        [Hashtable]
        $expectedState,
        [Parameter(Mandatory)]
        [Hashtable]
        $actualState,
        [Parameter(Mandatory)]
        [String]
        $className,
        [String]
        $reasonCode = 'Configuration'
    )
    $Reasons = @()
    foreach ($key in $expectedState.Keys) {
        if ($expectedState.$key -eq $actualState.$key) {
            $state0 += "`t`t[+] $key" + ':' + "`n`t`t`tExpected value to be `"$($expectedState.$key)`"`n`t`t`tActual value was `"$($actualState.$key)`"`n"
        }
        else {
            $state1 += "`t`t[-] $key" + ':' + "`n`t`t`tExpected value to be `"$($expectedState.$key)`"`n`t`t`tActual value was `"$($actualState.$key)`"`n"
        }
    }

    $Reason = [reason]::new()
    $Reason.code = $className + ':' + $className + ':' + $reasonCode
    $phrase = "The machine returned the following configuration details.`n"
    $phrase += "`tSettings in desired state:`n$state0"
    $phrase += "`tSettings not in desired state:`n$state1"
    $Reason.phrase = $phrase
    $Reasons += $Reason
    return $Reasons
}

class Reason {
    [DscProperty()]
    [string] $Code

    [DscProperty()]
    [string] $Phrase
}

[DscResource()]
class AzureConnectedMachineAgentDsc {

    [DscProperty(Key)]
    [Parameter(Mandatory = $true)]
    [string]$TenantId

    [DscProperty()]
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId

    [DscProperty()]
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup

    [DscProperty()]
    [Parameter(Mandatory = $true)]
    [string]$Location

    [DscProperty()]
    [string]$Tags

    [DscProperty()]
    [Parameter(Mandatory = $true)]
    [PSCredential]$Credential

    [DscProperty()]
    [Reason[]]$Reasons

    [AzureConnectedMachineAgentDsc] Get() {
        $get = Get-AzConnectedMachineAgent
        $expectedState = @{}; foreach ($param in ($this | Get-Member -type 'Properties' | ForEach-Object { $_.Name })) { if ('Reasons' -ne $param) { $expectedState.add($param, $this.$param) } }
        $get.Add('Reasons', (Get-Reasons -expectedState $expectedState -actualState $get -className $this.GetType().Name))
        return $get
    }

    [void] Set() {
        Connect-AzConnectedMachineAgent -TenantId $this.TenantId -SubscriptionId $this.SubscriptionId -ResourceGroup $this.ResourceGroup -Location $this.Location -Tags $this.Tags -Credential $this.Credential
    }

    [bool] Test() {
        $test = Test-AzConnectedMachineAgent -TenantId $this.TenantId -SubscriptionId $this.SubscriptionId -ResourceGroup $this.ResourceGroup -Location $this.Location -Tags $this.Tags
        return $test
    }
}
