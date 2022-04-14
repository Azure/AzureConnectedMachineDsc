
$script:httpserver = 'http://127.0.0.1:40342'
$script:agentstatus = '/agentstatus'
$script:metadata = '/metadata/instance'
$script:apiversion = '2019-08-15'
$script:headers = @{ Metadata = $true }
$env:PATH = $env:PATH + ";$env:ProgramFiles\AzureConnectedMachineAgent\"
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
            $disconnect = & azcmagent disconnect `
                --service-principal-id $Credential.UserName `
                --service-principal-secret $Credential.GetNetworkCredential().Password #`
            #--json
            
            #$disconnect = $disconnect | ConvertFrom-Json
            
            if ($LastExitCode -ne 0) {
                throw 'The disconnect command failed.' #$disconnect.error.message
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

        $connect = & azcmagent $agentArgs #--json
        #$connect = $connect | ConvertFrom-Json

        if ($LastExitCode -ne 0) {
            throw 'The connection failed. Verify network, name resolution, and that an existing resource with the same name does not exist.' #$connect.error.message
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

function Get-AzConnectedMachineAgentConfig {
    $data = Get-AzConnectedMachineAgentConfigValues
    return @{
        incomingconnections_ports  = $data | Where-Object {$_.DisplayName -eq 'incomingconnections.ports'} | ForEach-Object {$_.value}
        proxy_url                  = $data | Where-Object {$_.DisplayName -eq 'proxy.url'} | ForEach-Object {$_.value}
        extensions_allowlist       = $data | Where-Object {$_.DisplayName -eq 'extensions.allowlist'} | ForEach-Object {$_.value}
        extensions_blocklist       = $data | Where-Object {$_.DisplayName -eq 'extensions.blocklist'} | ForEach-Object {$_.value}
        proxy_bypass               = $data | Where-Object {$_.DisplayName -eq 'proxy.bypass'} | ForEach-Object {$_.value}
        guestconfiguration_enabled = $data | Where-Object {$_.DisplayName -eq 'guestconfiguration.enabled'} | ForEach-Object {$_.value}
    }
}

function Get-AzConnectedMachineAgentConfigValues {
    if (Test-Path "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe") {
        Write-Verbose 'Running azcmagent config list and get to retrieve current values; return object.'

        $list = New-Object -TypeName 'PSObject'
        & azcmagent config list --json | ConvertFrom-Json | ForEach-Object { $_.LocalSettings } | ForEach-Object { Add-Member -InputObject $list -MemberType NoteProperty -Name $_.Key -Value $_.Value }

        $info = & azcmagent config info --json | ConvertFrom-Json
        for ($i = 0; $i -lt $info.Count; $i++) {
            $value = $list.($info[$i].DisplayName)
            $info[$i] | Add-Member -MemberType NoteProperty -Name 'Value' -Value $value -Force
            if (@('true', 'false') -contains $value) { $type = 'Boolean' } else {
                $type = $list.($info[$i].DisplayName).gettype().Name
            }    
            $info[$i] | Add-Member -MemberType NoteProperty -Name 'Type' -Value $type -Force
        }

        if ($LastExitCode -ne 0) {
            throw 'An error occured when getting values from azcmagent.'
        }

        return $info
    }
    else {
        throw 'The Hybrid agent is not installed.'
    }
}

function Set-AzConnectedMachineAgentConfig {
    param(
        [string] $incomingconnections_ports,
        [string] $proxy_url,
        [string] $extensions_allowlist,
        [string] $extensions_blocklist,
        [string] $proxy_bypass,
        [boolean] $guestconfiguration_enabled
    )
    $incomingconnections_ports = $incomingconnections_ports.split(',')
    $extensions_allowlist      = $extensions_allowlist.split(',')
    $extensions_blocklist      = $extensions_blocklist.split(',')
    $proxy_bypass              = $proxy_bypass.split(',')
    foreach ($parameterName in $PSBoundParameters.Keys) {
        Set-AzConnectedMachineAgentConfigValue -property ($parameterName -replace '_','.') -value $PSBoundParameters[$parameterName]
    }
}

function Set-AzConnectedMachineAgentConfigValue {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({ New-ConfigPropertyCompleter @args })]
        [String] $property,
        $value
    )
    if (New-ConfigValueValidation -property $property -value $value) {
        if (Test-Path "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe") {
            Write-Verbose "Setting $property to $value."

            $config = & azcmagent config set $property $value --json

            if ($config.status -eq 'error') {
                throw $config.status.message
            }

            return $list
        }
        else {
            throw 'The Hybrid agent is not installed.'
        }
    }
}

function Test-AzConnectedMachineAgentConfig {
    param(
        [string[]] $incomingconnections_ports,
        [string] $proxy_url,
        [string[]] $extensions_allowlist,
        [string[]] $extensions_blocklist,
        [string[]] $proxy_bypass,
        [boolean] $guestconfiguration_enabled
    )
    $return = $true
    foreach ($setting in (Get-AzConnectedMachineAgentConfigValues)) {
        $name = $setting.DisplayName -replace '\.','_'
        $paramValue = $PSBoundParameters["$name"]
        $value = $setting.value
        if (!$value) {$value = '[not configured]'}
        if (!$paramValue) {$paramValue = '[not configured]'}
        $verbose = "Test $name value of $value should equal $paramValue"
        Write-Verbose $verbose
        if ($setting.value -ne $paramValue) {$return = $false}
    }
    return $return
}

function New-ConfigPropertyCompleter {
    param ( $property,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters )

    $possibleValues = (Get-AzConnectedMachineAgentConfig).DisplayName

    if ($fakeBoundParameters) {
        $return = $possibleValues | Where-Object { $_ -like "$wordToComplete*" }
    }
    else {
        $return = $possibleValues | ForEach-Object { $_ }
    }
    return $return
}

function New-ConfigValueValidation {
    param(
        [Parameter(Mandatory)]
        [string]
        $property,
        $value
    )

    $typeName = Get-AzConnectedMachineAgentConfigValues | Where-Object { $_.DisplayName -eq $property } | ForEach-Object { $_.Type }
    $return = ($value.GetType().Name -eq $typeName) -or ('Object[]' -eq $typeName -and 'String' -eq $value.GetType().Name)
    if ($false -eq $return) {
        throw "The property $property requires a value of type $typeName."
    }
    return $return
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

    [DscProperty(NotConfigurable)]
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

[DscResource()]
class AzcmagentConfig {

    [DscProperty(Key)]
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$IsSingleInstance

    [DscProperty()]
    [string[]] $incomingconnections_ports

    [DscProperty()]
    [string] $proxy_url

    [DscProperty()]
    [string[]] $extensions_allowlist

    [DscProperty()]
    [string[]] $extensions_blocklist

    [DscProperty()]
    [string[]] $proxy_bypass

    [DscProperty()]
    [boolean] $guestconfiguration_enabled

    [DscProperty(NotConfigurable)]
    [Reason[]]$Reasons

    [AzcmagentConfig] Get() {
        $get = Get-AzConnectedMachineAgentConfig
        $expectedState = @{}; foreach ($param in ($this | Get-Member -type 'Properties' | ForEach-Object { $_.Name })) { if ('Reasons' -ne $param) { $expectedState.add($param, $this.$param) } }
        $get.Add('Reasons', (Get-Reasons -expectedState $expectedState -actualState $get -className $this.GetType().Name))
        return $get
    }

    [void] Set() {
        Set-AzConnectedMachineAgentConfig @PSBoundParameters
    }

    [bool] Test() {
        $test = Test-AzConnectedMachineAgentConfig @PSBoundParameters
        return $test
    }
}
