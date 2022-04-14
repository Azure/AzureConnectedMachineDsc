# Azure Connected Machine module for Windows PowerShell DSC

This repository contains the module for Windows PowerShell Desired State Configuration to install
and configure the Azure Connected Machine Agent.

## Contents

The files and folders in this repo include:

| File/folder                     | Description                                  |
|---------------------------------|----------------------------------------------|
| `examples`                      | Folder containing configuration examples     |
| `test`                          | Folder containing unit and integration tests |
| `AzureConnectedMachineDsc.psd1` | Module manifest                              |
| `AzureConnectedMachineDsc.psm1` | PowerShell module                            |
| `CHANGELOG.md`                  | List of changes to the sample                |
| `CODE_OF_CONDUCT.md`            | Code of conduct for project contribution     |
| `README.md`                     | This README file                             |
| `LICENSE`                       | The license for the project                  |

## Resources included in this module

- **AzureConnectedMachineAgentDsc**: Used to automate configuration of the Azure Connected Machine Agent including validation of the connection to Azure and the metadata such as the Resource Group and Tags information.
- **AzcmagentConfig**: Used to configure settings on the Azure Connected Machine Agent.

## Requirements

The minimum PowerShell version required is 5.1.

## Setup

To manually install the module, download the source code and unzip the contents
of the project directory to the
`$env:ProgramFiles\WindowsPowerShell\Modules folder`.

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

    Find-Module -Name AzureConnectedMachineDsc -Repository PSGallery | Install-Module

To confirm installation, run the below command and ensure you see the
Azure Connected Machine DSC resoures available:

    Get-DscResource -Module AzureConnectedMachineDsc

## Examples

The resources in this module are intended to manage the Azure Connected Machine Agent configuration. A complete example is provided that also uses community resources to download and install the agent,
and to verify the state of the agent service.

PowerShell script:

```powershell
& .\examples\AzureConnectedMachineAgent.ps1
```

The Azure Connected Machine Agent supports connecting through an http proxy service.  The
proxy details are provided to the agent using envionment variables, which could also be managed by
DSC using the ComputeManagementDsc module.  For more information on the proxy details, see the
documentation for Azure Connect Machine Agent.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
