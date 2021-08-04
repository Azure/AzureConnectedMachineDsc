
$script:himdsServer = 'http://127.0.0.1:40342'
$script:himdsAgentStatus = '/agentstatus'
$script:himdsMetadata = '/metadata/instance'
$script:himdsApiVersion = '2019-08-15'
$script:himdsHeaders = @{Metadata = $true }

$script:microsoftLoginUrl = 'https://login.microsoftonline.com/'
$script:microsoftTokenUrl = '/oauth2/token'

$script:azureSubscriptionsUrl = 'https://management.azure.com/subscriptions/'
$script:azureResourceGroups = '/resourcegroups/'
$script:azureHybridComputeMachines = '/providers/Microsoft.HybridCompute/machines/'
$script:azureApiVersion = '2020-08-02'

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
        [PSCredential]$Credential,

        [bool]$ForceReplaceAgent = $false
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
        } elseif ($ForceReplaceAgent) {
            $params =
            @{
                TenantId       = $TenantId
                Credential     = $Credential
            }

            $authToken = Get-AzureAuthenticationToken @params

            $params =
            @{
                AuthToken      = $authToken
                SubscriptionId = $SubscriptionId
                ResourceGroup  = $ResourceGroup
            }

            if (Test-AzConnectedMachineAgentExistsInAzure @params) {
                Write-Verbose "Machine $env:COMPUTERNAME already exists in azure. Force removing previous instance from Azure before proceeding."
                Disconnect-ExistingAgentFromAzure @params
            } else {
                Write-Verbose "Machine $env:COMPUTERNAME doesn't exist in azure. Can continue to registering the agent."
            }
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

        & azcmagent $agentArgs | Out-Default

        if ($LastExitCode -ne 0) {
            throw "Couldn't connect to Azure ARC."
        }
    }
    else {
        throw 'The Hybrid agent is not installed.'
    }
}

# If a machine with the same name as this is already present in Azure ARC force a delete of the old one
# before we connect.
function Disconnect-ExistingAgentFromAzure {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AuthToken,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup
    )

    $azureArcMachineUri = $script:azureSubscriptionsUrl + $SubscriptionId + $script:azureResourceGroups + $ResourceGroup + $script:azureHybridComputeMachines + $env:COMPUTERNAME + '?api-version=' + $script:azureApiVersion
    Invoke-WebRequest -UseBasicParsing -Uri $azureArcMachineUri -Method 'Delete' -Headers @{ Authorization = "Bearer $authToken" }
}

function Get-AzConnectedMachineAgent {
    if (Test-AzConnectedMachineAgentService) {
        $agentstatusuri = $script:himdsServer + $script:himdsAgentStatus + '?api-version=' + $script:himdsApiVersion
        $agentStatus = Invoke-WebRequest -UseBasicParsing -Uri $agentstatusuri -Headers $script:himdsHeaders | ForEach-Object { $_.Content } | ConvertFrom-Json

        if ('' -ne $agentStatus.lastHeartBeat) {
            $metadataUri = $script:himdsServer + $script:himdsMetadata + '?api-version=' + $script:himdsApiVersion
            $metadataInstance = Invoke-WebRequest -UseBasicParsing -Uri $metadataUri -Headers $script:himdsHeaders | ForEach-Object { $_.Content } | ConvertFrom-Json | ForEach-Object { $_.compute }
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

function Get-AzureAuthenticationToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
    )

    $azureAuthUri = $script:microsoftLoginUrl + $TenantId + $script:microsoftTokenUrl
    $authBody = 'grant_type=client_credentials&client_id=' + $Credential.UserName + '&client_secret=' + $Credential.GetNetworkCredential().Password + '&resource=https%3A%2F%2Fmanagement.azure.com%2F'
    $authToken = Invoke-WebRequest -UseBasicParsing -Uri $azureAuthUri -Method 'POST' -Body $authBody | ForEach-Object { $_.Content } | ConvertFrom-Json | ForEach-Object { $_.access_token }

    return $authToken
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
        $HIMDSuri = $script:himdsServer + $script:himdsAgentStatus + '?api-version=' + $script:himdsApiVersion
        $HIMDS = Invoke-WebRequest -UseBasicParsing -Uri $HIMDSuri -Headers $script:himdsHeaders | ForEach-Object { $_.StatusCode }
        if ('200' -eq $HIMDS) {
            return $true
        }
        else { return $false }
    }
    else { return $false }
}

function Test-AzConnectedMachineAgentExistsInAzure {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AuthToken,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup
    )

    $azureArcMachineUri = $script:azureSubscriptionsUrl + $SubscriptionId + $script:azureResourceGroups + $ResourceGroup + $script:azureHybridComputeMachines + $env:COMPUTERNAME + '?api-version=' + $script:azureApiVersion
    $response = try {
        Invoke-WebRequest -UseBasicParsing -Uri $azureArcMachineUri -Headers @{ Authorization = "Bearer $AuthToken" }
    } catch [System.Net.WebException] {
        if ($_.Exception.Response.StatusCode -eq 404) {
            return $false
        }
    }

    return $true
}
