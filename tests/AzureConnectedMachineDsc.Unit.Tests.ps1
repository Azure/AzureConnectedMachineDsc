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

    Context 'Desired State Configuration' {

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
}
