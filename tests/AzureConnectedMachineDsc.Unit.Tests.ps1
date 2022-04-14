$ModuleManifestName = 'AzureConnectedMachineDsc.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"
Import-Module $ModuleManifestPath

Describe -Tag 'Unit' 'Module Tests' {

    Context 'Module Manifest' {
        It 'passes Test-ModuleManifest' {
            $ModuleManifestName = 'AzureConnectedMachineDsc.psd1'
            $ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"
            Test-ModuleManifest -Path $ModuleManifestPath | Should -Not -BeNullOrEmpty
            $? | Should -BeTrue
        }
    }

    Context 'Agent Desired State Configuration resource' {

        It 'exports a DSC resource' {
            $dsc = Get-DscResource 'AzureConnectedMachineAgentDsc'
            $dsc | ForEach-Object Name | Should -Be 'AzureConnectedMachineAgentDsc'
        }
        It 'has a property named TenantId' {
            $dsc = Get-DscResource 'AzureConnectedMachineAgentDsc'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'TenantId'
        }
        It 'has a property named SubscriptionId' {
            $dsc = Get-DscResource 'AzureConnectedMachineAgentDsc'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'SubscriptionId'
        }
        It 'has a property named ResourceGroup' {
            $dsc = Get-DscResource 'AzureConnectedMachineAgentDsc'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'ResourceGroup'
        }
        It 'has a property named Location' {
            $dsc = Get-DscResource 'AzureConnectedMachineAgentDsc'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'Location'
        }
        It 'has a property named Tags' {
            $dsc = Get-DscResource 'AzureConnectedMachineAgentDsc'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'Tags'
        }
        It 'has a property named Credential' {
            $dsc = Get-DscResource 'AzureConnectedMachineAgentDsc'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'Credential'
        }
    }

    Context 'Agent Config Desired State Configuration resource' {

        It 'exports a DSC resource' {
            $dsc = Get-DscResource 'AzcmagentConfig'
            $dsc | ForEach-Object Name | Should -Be 'AzcmagentConfig'
        }
        It 'has a property named IsSingleInstance' {
            $dsc = Get-DscResource 'AzcmagentConfig'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'IsSingleInstance'
        }
        It 'has a property named incomingconnections_ports' {
            $dsc = Get-DscResource 'AzcmagentConfig'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'incomingconnections_ports'
        }
        It 'has a property named proxy_url' {
            $dsc = Get-DscResource 'AzcmagentConfig'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'proxy_url'
        }
        It 'has a property named extensions_allowlist' {
            $dsc = Get-DscResource 'AzcmagentConfig'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'extensions_allowlist'
        }
        It 'has a property named extensions_blocklist' {
            $dsc = Get-DscResource 'AzcmagentConfig'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'extensions_blocklist'
        }
        It 'has a property named proxy_bypass' {
            $dsc = Get-DscResource 'AzcmagentConfig'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'proxy_bypass'
        }
        It 'has a property named guestconfiguration_enabled' {
            $dsc = Get-DscResource 'AzcmagentConfig'
            $dsc.properties | ForEach-Object { $_.Name } | Should -Contain 'guestconfiguration_enabled'
        }
    }

    Context 'function Connect-AzConnectedMachineAgent' {

        It 'should attempt to connect when the agent is installed but not connected' {
            InModuleScope AzureConnectedMachineDsc {
                $connectParams = @{
                    TenantId       = (new-guid).Guid
                    SubscriptionId = (new-guid).Guid
                    ResourceGroup  = 'resource_group_name'
                    Location       = 'location'
                    Tags           = 'property=value'
                    Credential     = New-Object System.Management.Automation.PSCredential ('appid', ('secret' | ConvertTo-SecureString -AsPlainText -Force))
                }
                function azcmagent {}
                Mock -CommandName azcmagent -MockWith { $Global:LASTEXITCODE = 0 }
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Test-AzConnectedMachineAgentConnection' -MockWith { $false } -Verifiable
                { Connect-AzConnectedMachineAgent @connectParams } | Should -Not -Throw
                Assert-VerifiableMock
            }
        }
        It 'should attempt to disconnect and reconnect when the agent is installed and connected' {
            InModuleScope AzureConnectedMachineDsc {
                $connectParams = @{
                    TenantId       = (new-guid).Guid
                    SubscriptionId = (new-guid).Guid
                    ResourceGroup  = 'resource_group_name'
                    Location       = 'location'
                    Tags           = 'property=value'
                    Credential     = New-Object System.Management.Automation.PSCredential ('appid', ('secret' | ConvertTo-SecureString -AsPlainText -Force))
                }
                function azcmagent {}
                Mock -CommandName azcmagent -MockWith { $Global:LASTEXITCODE = 0 }
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Test-AzConnectedMachineAgentConnection' -MockWith { $true } -Verifiable
                Mock -CommandName 'Restart-Service' -Verifiable
                { Connect-AzConnectedMachineAgent @connectParams } | Should -Not -Throw
                Assert-VerifiableMock
            }
        }
        It 'should return an error if the agent is not installed' {
            InModuleScope AzureConnectedMachineDsc {
                $connectParams = @{
                    TenantId       = (new-guid).Guid
                    SubscriptionId = (new-guid).Guid
                    ResourceGroup  = 'resource_group_name'
                    Location       = 'location'
                    Tags           = 'property=value'
                    Credential     = New-Object System.Management.Automation.PSCredential ('appid', ('secret' | ConvertTo-SecureString -AsPlainText -Force))
                }
                function azcmagent {}
                Mock -CommandName azcmagent -MockWith { $Global:LASTEXITCODE = 0 }
                Mock -CommandName 'Test-Path' -MockWith { $false } -Verifiable
                { Connect-AzConnectedMachineAgent @connectParams } | Should -Throw 'The Hybrid agent is not installed.'
                Assert-VerifiableMock
            }
        }
    }

    Context 'function Get-AzConnectedMachineAgent' {

        It 'should return a hashtable' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-AzConnectedMachineAgentService' -MockWith { $true } -Verifiable
                Mock -CommandName 'Invoke-WebRequest' -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Get-Content' -Verifiable
                Get-AzConnectedMachineAgent | Should -BeOfType 'hashtable'
                Assert-VerifiableMock
            }
        }
        It 'should have a property TenantId' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-AzConnectedMachineAgentService' -MockWith { $true } -Verifiable
                Mock -CommandName 'Invoke-WebRequest' -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Get-Content' -Verifiable
                (Get-AzConnectedMachineAgent).Keys | Should -Contain TenantId
            }
        }
        It 'should have a property SubscriptionId' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-AzConnectedMachineAgentService' -MockWith { $true } -Verifiable
                Mock -CommandName 'Invoke-WebRequest' -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Get-Content' -Verifiable
                (Get-AzConnectedMachineAgent).Keys | Should -Contain SubscriptionId
            }
        }
        It 'should have a property ResourceGroup' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-AzConnectedMachineAgentService' -MockWith { $true } -Verifiable
                Mock -CommandName 'Invoke-WebRequest' -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Get-Content' -Verifiable
                (Get-AzConnectedMachineAgent).Keys | Should -Contain ResourceGroup
            }
        }
        It 'should have a property Location' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-AzConnectedMachineAgentService' -MockWith { $true } -Verifiable
                Mock -CommandName 'Invoke-WebRequest' -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Get-Content' -Verifiable
                (Get-AzConnectedMachineAgent).Keys | Should -Contain Location
            }
        }
        It 'should have a property Tags' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-AzConnectedMachineAgentService' -MockWith { $true } -Verifiable
                Mock -CommandName 'Invoke-WebRequest' -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Get-Content' -Verifiable
                (Get-AzConnectedMachineAgent).Keys | Should -Contain Tags
            }
        }
        It 'should have a property AgentStatus' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-AzConnectedMachineAgentService' -MockWith { $true } -Verifiable
                Mock -CommandName 'Invoke-WebRequest' -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                Mock -CommandName 'Get-Content' -Verifiable
                (Get-AzConnectedMachineAgent).Keys | Should -Contain AgentStatus
            }
        }
    }

    Context 'function Test-AzConnectedMachineAgent' {

        It 'should be false if the node is not connected' {
            InModuleScope AzureConnectedMachineDsc {
                $connectParams = @{
                    TenantId       = (new-guid).Guid
                    SubscriptionId = (new-guid).Guid
                    ResourceGroup  = 'resource_group_name'
                    Location       = 'location'
                    Tags           = 'property=value'
                }
                Mock -CommandName 'Get-AzConnectedMachineAgent' -Verifiable
                Test-AzConnectedMachineAgent @connectParams | Should -BeFalse
                Assert-VerifiableMock
            }
        }

        It 'should be true if the node is connected' {
            InModuleScope AzureConnectedMachineDsc {
                $connectParams = @{
                    TenantId       = (new-guid).Guid
                    SubscriptionId = (new-guid).Guid
                    ResourceGroup  = 'resource_group_name'
                    Location       = 'location'
                    Tags           = 'property=value'
                }
                $get = $connectParams.clone()
                $get.Add('AgentStatus', 'Connected')
                Mock -CommandName 'Get-AzConnectedMachineAgent' -MockWith { $get }
                Test-AzConnectedMachineAgent @connectParams | Should -BeTrue
                Assert-VerifiableMock
            }
        }
    }

    Context 'function Test-AzConnectedMachineAgentConnection' {

        It 'should correctly return when the node is connected to Azure' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName Get-AzConnectedMachineAgent -MockWith { @{AgentStatus = 'Connected' } } -Verifiable
                $TestConnection = Test-AzConnectedMachineAgentConnection
                $TestConnection | Should -BeOfType boolean
                $TestConnection | Should -BeTrue
                Assert-VerifiableMock
            }
        }
        It 'should correctly return when the node is not connected to Azure' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName Get-AzConnectedMachineAgent -MockWith { @{AgentStatus = 'NotConnected' } } -Verifiable
                $TestConnection = Test-AzConnectedMachineAgentConnection
                $TestConnection | Should -BeOfType boolean
                $TestConnection | Should -BeFalse
                Assert-VerifiableMock
            }
        }
    }

    Context 'function Test-AzConnectedMachineAgentService' {

        It 'should return false when the agent service is not running' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName Get-Service -MockWith { New-Object -type PSCustomObject -property @{Name = 'HIMDS'; Status = 'Stopped' } } -Verifiable
                $TestService = Test-AzConnectedMachineAgentService
                $TestService | Should -BeOfType boolean
                $TestService | Should -BeFalse
                Assert-VerifiableMock
            }
        }
        It 'should return true when the agent service is running' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName Get-Service -MockWith { New-Object -type PSCustomObject -property @{Name = 'HIMDS'; Status = 'Running' } } -Verifiable
                Mock -CommandName Invoke-WebRequest -MockWith { New-Object -type PSCustomObject -property @{StatusCode = '200' } } -Verifiable
                $TestService = Test-AzConnectedMachineAgentService
                $TestService | Should -BeOfType boolean
                $TestService | Should -BeTrue
                Assert-VerifiableMock
            }
        }

        It 'should return false when HIMDS is not available' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName Get-Service -MockWith { New-Object -type PSCustomObject -property @{Name = 'HIMDS'; Status = 'Running' } } -Verifiable
                Mock -CommandName Invoke-WebRequest -MockWith { New-Object -type PSCustomObject -property @{StatusCode = '404' } } -Verifiable
                $TestService = Test-AzConnectedMachineAgentService
                $TestService | Should -BeOfType boolean
                $TestService | Should -BeFalse
                Assert-VerifiableMock
            }
        }
    }
    Context 'function Get-AzConnectedMachineAgentConfig' {

        It 'should return a hashtable' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName Get-AzConnectedMachineAgentConfigValues -MockWith { New-Object -type PSCustomObject -property @{incomingconnections_ports = '23'; proxy_url = ''; extensions_allowlist = ''; extensions_blocklist = ''; proxy_bypass = ''; guestconfiguration_enabled = 'true' } } -Verifiable
                Get-AzConnectedMachineAgentConfig | Should -BeOfType 'hashtable'
                Assert-VerifiableMock
            }
        }
        It 'should have a property incomingconnections_ports' {
            InModuleScope AzureConnectedMachineDsc {
                InModuleScope AzureConnectedMachineDsc {
                    Mock -CommandName Get-AzConnectedMachineAgentConfigValues -MockWith { New-Object -type PSCustomObject -property @{incomingconnections_ports = '23'; proxy_url = ''; extensions_allowlist = ''; extensions_blocklist = ''; proxy_bypass = ''; guestconfiguration_enabled = 'true' } } -Verifiable
                    (Get-AzConnectedMachineAgentConfig).Keys | Should -Contain incomingconnections_ports
                    Assert-VerifiableMock
                }
            }
        }
    }
    Context 'function Get-AzConnectedMachineAgentConfigValues' {

        It 'should return an error if the agent is not installed' {
            InModuleScope AzureConnectedMachineDsc {
                function azcmagent {}
                Mock -CommandName azcmagent -MockWith { $Global:LASTEXITCODE = 0 }
                Mock -CommandName 'Test-Path' -MockWith { $false } -Verifiable
                { Get-AzConnectedMachineAgentConfigValues } | Should -Throw 'The Hybrid agent is not installed.'
                Assert-VerifiableMock
            }
        }
        It 'should return an object' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                function azcmagent {}
                Mock -CommandName azcmagent -ParameterFilter {"$args" -match 'config list --json'} -MockWith { '{"LocalSettings":[{"Key":"incomingconnections.ports","Value":[]},{"Key":"proxy.url","Value":""},{"Key":"extensions.allowlist","Value":[]},{"Key":"extensions.blocklist","Value":[]},{"Key":"proxy.bypass","Value":[]},{"Key":"guestconfiguration.enabled","Value":"true"}]}';$Global:LASTEXITCODE = 0 }
                Mock -CommandName azcmagent -ParameterFilter {"$args" -match 'config info --json'} -MockWith { '[{"DisplayName": "incomingconnections.ports","IsRemote": false,"IsLocal": true,"InPreview": true,"Description": {"General": "Comma separated list of ports that the server will be able to listen on.","Example": "22,8080","Default": "Empty, all incoming traffic on all ports blocked","AdditionalInfo": ""}}]';$Global:LASTEXITCODE = 0 }
                Get-AzConnectedMachineAgentConfigValues | Should -BeOfType 'PSObject'
                Assert-VerifiableMock
            }
        }
        It 'should have a property DisplayName' {
            InModuleScope AzureConnectedMachineDsc {
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                function azcmagent {}
                Mock -CommandName azcmagent -ParameterFilter {"$args" -match 'config list --json'} -MockWith { '{"LocalSettings":[{"Key":"incomingconnections.ports","Value":[]},{"Key":"proxy.url","Value":""},{"Key":"extensions.allowlist","Value":[]},{"Key":"extensions.blocklist","Value":[]},{"Key":"proxy.bypass","Value":[]},{"Key":"guestconfiguration.enabled","Value":"true"}]}';$Global:LASTEXITCODE = 0 }
                Mock -CommandName azcmagent -ParameterFilter {"$args" -match 'config info --json'} -MockWith { '[{"DisplayName": "incomingconnections.ports","IsRemote": false,"IsLocal": true,"InPreview": true,"Description": {"General": "Comma separated list of ports that the server will be able to listen on.","Example": "22,8080","Default": "Empty, all incoming traffic on all ports blocked","AdditionalInfo": ""}}]';$Global:LASTEXITCODE = 0 }
                (Get-AzConnectedMachineAgentConfigValues) | Get-Member -MemberType NoteProperty | ForEach-Object {$_.Name} | Should -Contain 'DisplayName'
            }
        }
    }
    Context 'function Set-AzConnectedMachineAgentConfig' {

        It 'should not return an error' {
            InModuleScope AzureConnectedMachineDsc {
                $params = @{
                    incomingconnections_ports  = '22'
                    guestconfiguration_enabled = $true
                }
                Mock -CommandName 'Set-AzConnectedMachineAgentConfigValue' -MockWith { } -Verifiable
                { Set-AzConnectedMachineAgentConfig @params } | Should -Not -Throw
                Assert-VerifiableMock
            }
        }
        It 'should not return an error when a comma seperated value is passed' {
            InModuleScope AzureConnectedMachineDsc {
                $params = @{
                    incomingconnections_ports  = '22,2222'
                    guestconfiguration_enabled = $true
                }
                Mock -CommandName 'Set-AzConnectedMachineAgentConfigValue' -MockWith { } -Verifiable
                { Set-AzConnectedMachineAgentConfig @params } | Should -Not -Throw
                Assert-VerifiableMock
            }
        }
    }
    Context 'function Test-AzConnectedMachineAgentConfig' {

        It 'should return false when a value does not match' {
            InModuleScope AzureConnectedMachineDsc {
                $params = @{
                    incomingconnections_ports  = '22'
                }
                Mock -CommandName Get-AzConnectedMachineAgentConfigValues -MockWith { New-Object -type PSCustomObject -property @{DisplayName = 'incomingconnections.ports'; Value = '23'}} -Verifiable
                $test = Test-AzConnectedMachineAgentConfig @params
                $test | Should -BeOfType boolean
                $test | Should -BeFalse
                Assert-VerifiableMock
            }
        }
        It 'should return true when values match' {
            InModuleScope AzureConnectedMachineDsc {
                $params = @{
                    incomingconnections_ports  = '22'
                }
                Mock -CommandName Get-AzConnectedMachineAgentConfigValues -MockWith { New-Object -type PSCustomObject -property @{DisplayName = 'incomingconnections.ports'; Value = '22'}} -Verifiable
                $test = Test-AzConnectedMachineAgentConfig @params
                $test | Should -BeOfType boolean
                $test | Should -BeTrue
                Assert-VerifiableMock
            }
        }
    }
    Context 'function Set-AzConnectedMachineAgentConfigValue' {

        It 'should not return an error' {
            InModuleScope AzureConnectedMachineDsc {
                $params = @{
                    property = 'incomingconnections_ports'
                    value    = '22'
                }
                Mock -CommandName 'New-ConfigValueValidation' -MockWith { $true } -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                function azcmagent {}
                Mock -CommandName azcmagent -MockWith { $Global:LASTEXITCODE = 0 }
                { Set-AzConnectedMachineAgentConfigValue @params } | Should -Not -Throw
                Assert-VerifiableMock
            }
        }
        It 'should not return an error when an array value is passed' {
            InModuleScope AzureConnectedMachineDsc {
                $params = @{
                    property = 'incomingconnections_ports'
                    value    = @('22','2222')
                }
                Mock -CommandName 'New-ConfigValueValidation' -MockWith { $true } -Verifiable
                Mock -CommandName 'Test-Path' -MockWith { $true } -Verifiable
                function azcmagent {}
                Mock -CommandName azcmagent -MockWith { $Global:LASTEXITCODE = 0 }
                { Set-AzConnectedMachineAgentConfigValue @params } | Should -Not -Throw
                Assert-VerifiableMock
            }
        }
    }
    Context 'function Get-Reasons' {

        It 'should return a reasons object' {
            InModuleScope AzureConnectedMachineDsc {
                $params = @{
                    expectedState = @{incomingconnections_ports = '22'}
                    actualState = @{incomingconnections_ports = '22'}
                    className = 'test'
                }
                $Reasons = Get-Reasons @params
                $Reasons.Code | Should -Be 'test:test:Configuration'
                $Reasons.phrase | Should -Not -BeNullOrEmpty
            }
        }
    }
}
