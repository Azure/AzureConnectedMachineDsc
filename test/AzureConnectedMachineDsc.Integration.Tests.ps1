$ModuleManifestName = 'AzureConnectedMachineDsc.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"
Import-Module $ModuleManifestPath -Force
Import-Module $PSScriptRoot\..\DscResources\Helpers.psm1 -Force

Describe 'Module Manifest Tests' -Tag 'Integration' {

    Context 'Load Configuration' {

        if (test-path '.\examples\private.configurationdata.ps1' -ErrorAction SilentlyContinue)
        {
            . .\examples\private.configurationdata.ps1
        } else {
            $test_params = @{
                TenantId = (new-guid).guid
                SubscriptionId = (new-guid).guid
                ResourceGroup = 'resourcegroup'
                Location = 'westus2'
                Credential = New-Object System.Management.Automation.PSCredential ('testappid', ('testsecret' | ConvertTo-SecureString -AsPlainText -Force))
            } }

        It 'runs the example script without error' {
            { . $PSScriptRoot\..\examples\AzureConnectedMachineAgent.ps1 @test_params} | Should -Not -Throw
        }
        It 'produces a connfiguration named AzureConnectedMachineAgent' {
            . $PSScriptRoot\..\examples\AzureConnectedMachineAgent.ps1 @test_params
            Get-Command -Type 'Configuration' | ForEach-Object { $_.Name } | Should -Contain 'AzureConnectedMachineAgent'
        }
        It 'produces a mof file' {
            Test-Path c:\dsc\localhost.mof | Should -BeTrue
        }
    }

    Context 'Apply Configuration' {
        It 'applies the mof file without error' {
            { Start-dscconfiguration -Wait -Force -Path c:\dsc -Verbose } | Should -Not -Throw
        }
    }
}
