Describe  -Tag 'Integration' 'Module Manifest Tests' {

    Context 'Load Configuration' {

        if (test-path '.\examples\private.ConfigurationData.ps1' -ErrorAction SilentlyContinue)
        {
            . .\examples\private.ConfigurationData.ps1
        } else {
            $test_params = @{
                TenantId = (new-guid).guid
                SubscriptionId = (new-guid).guid
                ResourceGroup = 'resourcegroup'
                Location = 'westus2'
                Credential = New-Object System.Management.Automation.PSCredential ('testappid', ('testsecret' | ConvertTo-SecureString -AsPlainText -Force))
            } }

        It 'runs the example script without error' {
            { . $PSScriptRoot\..\examples\AzureConnectedMachineAgent.ps1} | Should -Not -Throw
        }
        It 'produces a connfiguration named AzureConnectedMachineAgent' {
            . $PSScriptRoot\..\examples\AzureConnectedMachineAgent.ps1
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
