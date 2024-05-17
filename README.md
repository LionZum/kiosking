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

Modify the `Installation` section to meet your needs.

### Quick Start

Modify the existing `Add-Shell` and `Set-CustomActions` to meet your needs. Add a domain or local group and an application to launch.

### Fine Tune Setting

- Review the [Keyboard filters](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/customize/predefined-key-combinations) starting at line 177
- Consider blocking or using [scancodes](https://www.lookuptables.com/coding/keyboard-scan-codes) as well
- NOTE: ctrl+alt+del is not disabled by default. plan to mitigate task manager as appropriate. 