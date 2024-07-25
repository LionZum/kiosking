# Kiosking

Use this as a framework for getting started with your own single app mode kiosk situations.

## Table of Contents

- [Kiosking](#kiosking)
  - [Table of Contents](#table-of-contents)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Quick Start](#quick-start)
    - [Fine Tune Setting](#fine-tune-setting)
    - [References](#references)

## Requirements

- Licensing:
  - Enterprise
  - Education
  - LTSC
  - IoT
- Windows 10/11

## Installation

To get started:

1. Download the latest copy of [PSADT](https://psappdeploytoolkit.com/) or use your standard package.
2. Merge or copy AppDeployToolkitExtensions.ps1 to `Toolkit\AppDeployToolkit`
3. Merge or copy Deploy-Application.ps1 to `Toolkit`

## Usage

Modify the `Installation` section to meet your needs. This is a starting point for adding multiple shells. Add multiple pairs of `Add-Shell` and `Set-CustomActions` for each shell scenario. Shells are assigned to the user. Keyboard filters are assigned to all users except administrators. `Set-DefaultShell` sets the shell for all users except administrators.

### Quick Start

Modify the existing `Add-Shell` and `Set-CustomActions` to meet your needs. Add a domain or local group and an application to launch.

***Note: I found issues with the clear-shells function. Do Not use at this time***

### Fine Tune Setting

- Review the [Keyboard filters](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/customize/predefined-key-combinations) starting at line 177 in `Deploy-Applications.ps1`
- [Microsoft Keyboard Shortcuts Recommendation](https://learn.microsoft.com/en-us/windows/configuration/assigned-access/recommendations#keyboard-shortcuts)
- Consider blocking or using [scancodes](https://www.lookuptables.com/coding/keyboard-scan-codes) as well
- NOTE: ctrl+alt+del is not disabled by default. plan to mitigate task manager as appropriate.

### References

- [Set-CustomActions](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/customize/wesl-usersettingsetcustomshell) Use the table for value to enter into the shell.
- [Breakout Key](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/customize/keyboardfilter#keyboard-breakout)
- [Use Shell V2 if you need to use Entra groups](https://learn.microsoft.com/en-us/windows/configuration/assigned-access/shell-launcher/quickstart-kiosk?tabs=ps)
- [Edge kiosk browser launch settings](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-configure-kiosk-mode)
- [Shell V2 Reference](https://learn.microsoft.com/en-us/windows/configuration/assigned-access/shell-launcher/configuration-file)