<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
    Toolkit Exit Code Ranges:
    60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
    69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'1.5.0'
[string]$appDeployExtScriptDate = '02/12/2017'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

# <Your custom functions go here>
function Get-UsernameSID($AccountName) {

    $NTUserObject = New-Object System.Security.Principal.NTAccount($AccountName)
    $NTUserSID = $NTUserObject.Translate([System.Security.Principal.SecurityIdentifier])


    return $NTUserSID.Value

}

$CommonArgs = @{"namespace"="root\standardcimv2\embedded"}
$CommonArgs += $PSBoundParameters

function Clear-ProtectedProcesses() {
    <#
    .Synopsis
        Removes all processes from the protected application list
    .Description
        Removes all processes from the protected application list.  Be sure not to 
        enable default action to close or no window will be allowed
    #>

    Get-WMIObject -class WEDF_ProtectedProcess @CommonArgs |
        foreach {
            $_.Delete() | Out-Null;
            Write-Host "Deleted $_.Id"
        }
}

function Clear-BlockedWindows() {
    <#
    .Synopsis
        Removes all blocked windows
    .Description
        Removes all blocked windows
    #>

    Get-WMIObject -class WEDF_BlockedWindow @CommonArgs |
        foreach {
            $_.Delete() | Out-Null;
            Write-Host "Deleted $_.Id"
        }
}

function Add-ProtectedProcess($processPath) {
    <#
    .Synopsis
        Add a protected process
    .Description
        Add a protected process
    .Example
        Add-ProtectedProcess "c:\windows\system32\cmd.exe"
    #>

    Set-WMIInstance -class WEDF_ProtectedProcess -argument @{processName="$processPath"} @CommonArgs | Out-Null
        
    Write-Host "Added protected process $processPath";
}

function Add-BlockedWindow($titleBar, $processName, $actionList, $action, $controlType, $controlName) {
    <#
    .Synopsis
        Adds a new blocked window.  This window will perform the specified action when created
    .Description
        Adds a new blocked window.  This window will perform the specified action when created.
        controlType refers to UI Automation IDs as integers.
    .Example
        Set-BlockedWindow "Run..." "Explorer.exe", @{"OK", "Cancel", "Maximize", "Minimize", "Close"} @{10000, 10001} @{"Open", "" } 
        Set-BlockedWindow "Run..." "Explorer.exe", @{"OK", "Cancel", "Maximize", "Minimize", "Close"}
    #>

    Set-WMIInstance -class WEDF_BlockedWindow -argument @{title="$titleBar";processName="$processName";actionList=$actionList;action="$action";controlType=$controlType;controlName=$controlName } @CommonArgs | Out-Null
        
    Write-Host "Added blocked window $titleBar in $processName";
}

function Set-DefaultAction($action) {
    <#
    .Synopsis
        Sets default action performed when a window is created
    .Description
        Sets default action performed when a window is created
    .Parameters
        0 = Close - all windows are closed unless they belong to a protected process
        1 = Show - no action is performed on windows not blocked
    .Example
        Set-DefaultAction 1
    #>

    $defaultAction = Get-WmiObject -List @CommonArgs | where { $_.Name -eq "WEDF_DefaultAction" };
    $defaultAction.UpdateDefaultAction($action);
    Write-Host "Set default action to $action.";
}

function Block-Gesture([String] $Name) {
    <#
    .Synopsis
        Block a Gesture Filter
    .Description
        This function sets a gesture to be blocked by Gesture Filter. To view the 
        gesture names, enumerate the GF_Config class. Changes take place immediately.
    .Parameter Id
        A string that represents the gesture to be blocked.
    .Example
        Block-Gesture
    #>
    $config = Get-WMIObject -class GF_Config @CommonArgs |
        where {
            $_.Id -eq "GF_Config"
        };

    if ($config) {
        $config.$Name = $TRUE;
        $config.Put() | Out-Null;
        Write-Host "Blocking $Name"
    } else {
        Write-Error "$Name is not a valid gesture"
    }
}

function Allow-Gesture([String] $Name) {
    <#
    .Synopsis
        Allow a Gesture Filter
    .Description
        This function sets a gesture to be allowed by Gesture Filter. To view the 
        gesture names, enumerate the GF_Config class. Changes take place immediately.
    .Parameter Id
        A string that represents the gesture to be allowed.
    .Example
        Allow-Gesture 
    #>
    $config = Get-WMIObject -class GF_Config @CommonArgs |
        where {
            $_.Id -eq "GF_Config"
        };

    if ($config) {
        $config.$Name = $FALSE;
        $config.Put() | Out-Null;
        Write-Host "Allowing $Name"
    } else {
        Write-Error "$Name is not a valid gesture"
    }
}

function Set-IsGestureFilterEnabled([Bool] $Value) {
    <#
    .Synopsis
        Set the IsGestureFilterEnabled setting to true or false.
    .Description
        Enables or disables Gesture Filter.
    .Parameter Value
        A boolean value that represents the new IsGestureFilterEnabled setting value.
    #>

    $config = Get-WMIObject -class GF_Config @CommonArgs |
        where {
            $_.Id -eq "GF_Config"
        };

    if ($config) {   
        $config.IsGestureFilterEnabled = $Value;
        $config.Put() | Out-Null;
        Write-Host ("Set IsGestureFilterEnabled to {0}" -f $Value)
    } else {
        Write-Error "Unable to find IsGestureFilterEnabled setting";
    }
}
function Block-PredefinedKey($Id) {
    <#
    .Synopsis
        Block a Predefine Key Filter
    .Description
        This function sets a predefined key to be blocked by Keyboard Filter. To view the 
        predefined key combination names, enumerate the WEKF_CustomKey class. Changes 
        take place immediately.
    .Parameter Id
        A string that represents the predefined key combination to be blocked.
    .Example
        Block-Predefined-Key "Ctrl+Alt+Del"
    #>
    $predefined = Get-WMIObject -class WEKF_PredefinedKey @CommonArgs |
        where {
            $_.Id -eq "$Id"
        };

    if ($predefined) {
        $predefined.Enabled = 1;
        $predefined.Put() | Out-Null;
        Write-Host "Blocking $Id"
    } else {
        Write-Error "$Id is not a valid predefined key"
    }
}

function Allow-PredefinedKey($Id) {
    <#
    .Synopsis
        Allow a Predefine Key Filter
    .Description
        This function sets a predefined key to be allowed by Keyboard Filter. To view 
        the predefined key combination names, enumerate the WEKF_CustomKey class. 
        Changes take place immediately.
    .Parameter Id
        A string that represents the predefined key combination to be allowed.
    .Example
        Allow-Predefined-Key "Ctrl+Alt+Del"    
    #>
    $predefined = Get-WMIObject -class WEKF_PredefinedKey @CommonArgs |
        where {
            $_.Id -eq "$Id"
        };

    if ($predefined) {
        $predefined.Enabled = 0;
        $predefined.Put() | Out-Null;
        Write-Host "Allowing $Id"
    } else {
        Write-Error "$Id is not a valid predefined key"
    }
}

function Block-CustomKey($Id) {
    <#
    .Synopsis
        Enable a custom defined key combination to be blocked by Keyboard Filter.
    .Description
        This function sets a custom defined key combination to be blocked by Keyboard 
        Filter. If the key combination does not already exist, this function creates a 
        new WEKF_CustomKey instance to represent the custom defined key combination, and sets 
        the key combination to be blocked. Changes take place immediately.
    .Parameter Id
        A string that represents the custom key combination to be blocked. A custom key 
        combination consists of zero or more modifier keys, separated by a plus (+) sign, 
        and a key name. The key combination must use the English names for the keys.
    .Example
        Block-CustomKey "Ctrl+V"
        Block-CustomKey "LCtrl+RAlt+F1"
    #>

    $custom = Get-WMIObject -class WEKF_CustomKey @CommonArgs |
        where {
            $_.Id -eq "$Id"
        };

    if ($custom) {
        # Rule exists.  Just enable it.
        $custom.Enabled = 1;
        $custom.Put() | Out-Null;
        Write-Host "Blocking Custom Filter $Id.";

    } else {
        Set-WMIInstance `
            -class WEKF_CustomKey `
            -argument @{Id="$Id"} `
            @CommonArgs | Out-Null
        
        Write-Host "Added Custom Filter $Id.";
    }
}

function Block-ScanCode($Modifiers, [int]$Code) {
    <#
    .Synopsis
        Enable a scan code key combination to blocked by Keyboard Filter.
    .Description
        This function sets a scan code key combination to be blocked by Keyboard 
        Filter. If the scan code key combination does not already exist, this function 
        creates a new WEKF_ScanCode instance to represent the scan code key combination, 
        and sets the scan code key combination to be blocked. Changes take place immediately.
    .Parameter Modifiers
        A string that represents zero or more modifier keys in the scan code key combination 
        to be blocked. Modifier keys must be separated by a plus (+) sign, and use the English 
        names for the keys.
    .Parameter Code
        An integer that represents the scan code part of the key combination to be blocked.

    .Example
        Block-Scancode "Ctrl" 34
        Block-Scancode "LAlt+RCtrl" 34
    #>

    $ScanCode =
        Get-WMIObject -class WEKF_ScanCode @CommonArgs |
            where {
                ($_.Modifiers -eq $Modifiers) -and ($_.ScanCode -eq $Code)
            }

    if($ScanCode) {
        $ScanCode.Enabled = 1
        $ScanCode.Put() | Out-Null
        Write-Host ("Blocking Custom ScanCode {0}+{1:X4}" -f $Modifiers, $Code)
    } else {
        Set-WMIInstance `
            -class WEKF_ScanCode `
            -argument @{Modifiers="$Modifiers"; ScanCode=$Code; Enabled = 1} `
            @CommonArgs | Out-Null
 
        Write-Host ("Added Custom ScanCode {0}+{1:X4}" -f $Modifiers, $Code)
    }
}

function Allow-CustomKey($Id) {
    <#
    .Synopsis
        Disable a custom defined key combination from being blocked by Keyboard Filter.
    .Description
        This function sets an existing custom defined key combination rule to be allowed 
        by Keyboard Filter. The custom key combination rule is disabled, but not deleted. 
        Changes take place immediately.
    .Parameter Id
        A string that represents the custom key combination to be allowed. A custom key 
        combination consists of zero or more modifier keys, separated by a plus (+) sign, 
        and a key name. The key combination must use the English names for the keys.
    .Example
        Allow-CustomKey "Ctrl+V"
        Allow-CustomKey "LCtrl+RAlt+F1"
    #>

    $custom = Get-WMIObject -class WEKF_CustomKey @CommonArgs |
        where {
            $_.Id -eq "$Id"
        };

    if ($custom) {
        # Rule exists.  Just disable it.
        $custom.Enabled = 0;
        $custom.Put() | Out-Null;
        Write-Host "Allowing Custom Filter $Id.";
    } else {
        Set-WMIInstance `
            -class WEKF_CustomKey `
            -argument @{Id="$Id"; Enabled=0} `
            @CommonArgs | Out-Null
 
        Write-Host "Allowing Custom Filter $Id."
    }
}

function Allow-ScanCode($Modifiers, [int]$Code) {
    <#
    .Synopsis
        Disable a scan code key combination from being blocked by Keyboard Filter.
    .Description
        This function sets an existing scan code key combination rule to be allowed by 
        Keyboard Filter. The scan code key combination rule is disabled, but not deleted. 
        Changes take place immediately.
    .Parameter Modifiers
        A string that represents zero or more modifier keys in the scan code key combination 
        to be allowed. Modifier keys must be separated by a plus (+) sign, and use the 
        English names for the keys.
    .Parameter Code
        An integer that represents the scan code part of the key combination to be allowed.
    .Example
        Allow-ScanCode "Ctrl" 34
        Allow-ScanCode "LAlt+RCtrl" 34
    #>

    $scanCode =
        Get-WMIObject -class WEKF_ScanCode @CommonArgs |
            where {
                ($_.Modifiers -eq $Modifiers) -and ($_.ScanCode -eq $Code)
            }

    if($ScanCode) {
        $ScanCode.Enabled = 0
        $ScanCode.Put() | Out-Null
        Write-Host ("Disabled Custom ScanCode {0}+{1:X4}" -f $Modifiers, $Code)
    } else {
        Set-WMIInstance `
            -class WEKF_ScanCode `
            -argument @{Modifiers="$Modifiers"; ScanCode=$Code; Enabled = 0} `
            @CommonArgs | Out-Null
 
        Write-Host ("Added Custom ScanCode {0}+{1:X4}" -f $Modifiers, $Code)
    }
}

function Get-KeyboardFilterSetting([String] $Name) {
    <#
    .Synopsis
        Retrieve a specific Keyboard Filter setting WMIObject.
    .Parameter Name
        A string that represents the name of the Keyboard Filter setting to retrieve.
    #>
    $Entry = Get-WMIObject -class WEKF_Settings @CommonArgs |
        where {
            $_.Name -eq $Name
        }

    return $Entry
}

function Set-DisableKeyboardFilterForAdministrators([Bool] $Value) {
    <#
    .Synopsis
        Set the DisableKeyboardFilterForAdministrators setting to true or false.
    .Description
        Enables or disables Keyboard Filter from blocking keys when a user is logged 
        in on an Administrator account.
    .Parameter Value
        A boolean value that represents the new DisableKeyboardFilterForAdministrators setting value.
    #>

    $Setting = Get-KeyboardFilterSetting("DisableKeyboardFilterForAdministrators")
    if ($Setting) {
        if ($Value) {
            $Setting.Value = "true" 
        } else {
            $Setting.Value = "false"
        }
        $Setting.Put() | Out-Null;
        Write-Host ("Set DisableKeyboardFilterForAdministrators to {0}" -f $Value)
    } else {
        Write-Error "Unable to find DisableKeyboardFilterForAdministrators setting";
    }
}

function Set-ForceOffAccessibility([Bool] $Value) {
    <#
    .Synopsis
        Set the ForceOffAccessibility setting to true or false.
    .Description
        Enables or disables Keyboard Filter from disabling accessibility
    .Parameter Value
        A boolean value that represents the new ForceOffAccessibility setting value.
    #>

    $Setting = Get-KeyboardFilterSetting("ForceOffAccessibility")
    if ($Setting) {
        if ($Value) {
            $Setting.Value = "true" 
        } else {
            $Setting.Value = "false"
        }
        $Setting.Put() | Out-Null;
        Write-Host ("Set ForceOffAccessibility to {0}" -f $Value)
    } else {
        Write-Error "Unable to find ForceOffAccessibility setting";
    }
}

function Set-BreakoutKey([String] $ScanCode) {
    <#
    .Synopsis
        Set the Breakout Key setting to a particular scan code
    .Description
        Sets the Breakout Key, which allows you to disconnect a user session
    .Parameter Value
        A scan code value that represents the new Breakout Key.
    #>

    $Setting = Get-KeyboardFilterSetting("BreakoutKeyScanCode")
    if ($Setting) {
        if ($ScanCode) {
            $Setting.Value = $ScanCode
            $Setting.Put() | Out-Null;
            Write-Host "Set BreakoutKeyScanCode to $ScanCode"
        } else {
            Write-Error "BreakoutKeyScanCode cannot be set to null";
        }
    } else {
        Write-Error "Unable to find BreakoutKeyScanCode setting";
    }
}

function Clear-CustomFilters() {
    <#
    .Synopsis
        Removes all custom filters and scan codes
    .Description
        This function deletes all custom defined key combination rules and scan 
        code key combination rules. It does not affect predefined key combination 
        rules.
    #>

    Get-WMIObject -class WEKF_CustomKey @CommonArgs |
        foreach {
            if ($_.Enabled) {
                $_.Enabled = 0;
                $_.Delete() | Out-Null;
                Write-Host "Deleted $_.Id"
            }
        }

    Get-WMIObject -class WEKF_ScanCode @CommonArgs |
        foreach {
            if ($_.Enabled) {
                $_.Enabled = 0;
                $_.Delete() | Out-Null;
                Write-Host ("Deleted {0}+{1:X4}" -f $_.Modifiers,$_.ScanCode)
            }
        }
}
function Clear-Shells() {
    <#
    .Synopsis
        Removes all custom shell entries
    .Description
        Removes all filters
    #>

    Get-WMIObject -class WESL_UserSetting @CommonArgs |
        foreach {
            $_.Delete() | Out-Null;
            Write-Host "Deleted $_.Id"
        }
}

function Add-Shell($UserGroup, $Shell) {
    <#
    .Synopsis
        Add a shell
    .Description
        Adds a new user or group entry with a shell.  If the account already exists,
        the shell executable is updated.
    .Example
        Add-Shell "localUser" "c:\windows\system32\cmd.exe"
        Add-Shell "localGroup" "c:\windows\system32\cmd.exe"
        Add-Shell "domain\user" "c:\windows\system32\cmd.exe"
    #>

    $objUser = New-Object System.Security.Principal.NTAccount($UserGroup)
    $stringSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])

    $custom = Get-WMIObject -class WESL_UserSetting @CommonArgs |
        where {
            $_.Sid -eq "$stringSID"
        };

    if ($custom) {
        # Entry exists.  Just update it.
        $custom.Shell = $Shell;
        $custom.Put() | Out-Null;
        Write-Host "Updated shell $UserGroup ($stringSID) to $shell.";

    } else {
        Set-WMIInstance -class WESL_UserSetting -argument @{Sid="$stringSID";Shell="$Shell"} @CommonArgs | Out-Null
        
        Write-Host "Added shell $UserGroup ($stringSID) to $shell.";
    }
}

function Set-CustomActions($UserGroup, $returnCodes, $actions) {
    <#
    .Synopsis
        sets custom actions and return codes
    .Description
        sets custom actions and return codes.  
            0 = Restart shell
            1 = Restart system
            2 = Shut down
            3 = Do nothing
    .Example
        Set-Custom-Actions "localUser" @{1,2} @{0,1}
    #>

    $objUser = New-Object System.Security.Principal.NTAccount($UserGroup)
    $stringSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])

    $custom = Get-WMIObject -class WESL_UserSetting @CommonArgs |
        where {
            $_.Sid -eq "$stringSID"
        };

    if ($custom) {
        # Entry exists.  Just update it.
        $custom.CustomReturnCodes = $returnCodes;
        $custom.CustomReturnCodesAction = $actions;
        $custom.Put() | Out-Null;
        Write-Host "Updated shell $UserGroup ($stringSID) actions.";
    }
}

function Set-DefaultShell($Shell, $action) {
    <#
    .Synopsis
        Sets default shell
    .Description
        the shell executable is updated.
    .Example
        Set-Default-Shell "c:\windows\system32\cmd.exe"
    #>

    $setting = Get-WmiObject -List @CommonArgs | where { $_.Name -eq "WESL_UserSetting" };
    $setting.SetDefaultShell($Shell, $action);
    Write-Host "Set default shell $Shell.";
}

function Enable-ShellLauncher($Enabled) {
    <#
    .Synopsis
        Sets Settings
    .Description
        Enables/disables Shell Launcher.
    #>

    $setting = Get-WmiObject -List @CommonArgs | where { $_.Name -eq "WESL_UserSetting" };
	if ($setting)
	{
	    if ($Enabled -eq $TRUE)
	    {
	        $appLauncher = Get-WmiObject -class WEMSAL_Setting @CommonArgs;
		    if ($appLauncher)
		    {
		        if ($appLauncher.Enabled -eq $TRUE)
			    {
			        $appLauncher.Enabled = $FALSE;
				    $appLauncher.Put() | Out-Null;
				    Write-Host "Disabled App Launcher";
			    }
		    }
	    }
		try
		{
            $setting.SetEnabled($Enabled);
		    Write-Host "Updated Set-enabled to $Enabled";
	    }
		catch 
		{
		    Write-Error "Cannot enable/disable Shell Launcher";
		}
	}
	else
	{
	    Write-Error "Cannot find Shell Launcher WMI";
	}
}
# ----------Predefined helper functions-----------
# You can use the following helper functions to help easily configure USB Filter. 
# We recommend that you do not modify these functions unless necessary.
# To customize this script for advanced configuration, make changes to the
# Configuration Section below.

function Clear-PermissionList() {
    <#
    .Synopsis
        Removes all permission entries
    .Description
        This function removes all USBF_PermissionEntries.
    #>

    $config = Get-WMIObject -class USBF_Filter @CommonArgs |
        where {
            $_.Id -eq "USBF_Filter"
        };

    if ($config) {   
        $result = $config.ResetPermissionList()
        if($result.ReturnValue -eq 0)
        {
            Write-Host "Reset Permission List" 
        } else {
            Write-Error "Reset Permission List failed"
        }
    } else {
        Write-Error "Unable to find USBF_Filter"
    }
}

function Add-PermissionEntry([String] $PortLocationPath, [uint32] $PermissionLevel, [uint32] $DeviceClassID, [uint32] $DeviceVendorID, [uint32] $DeviceProductID) {
    <#
    .Synopsis
        Add a permission entry
    .Description
        This function adds a permission entry to USB Filter to allow USB devices. To view the 
        permission entires, enumerate the USBF_PermissionEntry class. Changes take place immediately.
    .Parameter PortLocationPath
        The location path of a port.
    .Parameter PermissionLevel
        Value that determines if DeviceClassId, DeviceVendorId, and DeviceProductId are used to filter USB devices.
    .Parameter DeviceClassId
        The class id of a device. Takes effect with PermissionLevels 1 and 2
    .Parameter DeviceVendorId
        The vendor id of a device. Takes effect with PermissionLevel 2
    .Parameter DeviceProductId
        The product id of a device. Takes effect with PermissionLevel 2
    #>

    #Add new permission
    Set-WMIInstance -class USBF_PermissionEntry -argument @{PortLocationPath="$PortLocationPath";PermissionLevel="$PermissionLevel";DeviceClassID=$DeviceClassID;DeviceVendorID="$DeviceVendorID";DeviceProductID=$DeviceProductID} @CommonArgs | Out-Null;

    Write-Host "Permission entry added for PortLocationPath: $PortLocationPath"
}

function Set-USBFilterEnabled([Bool] $Value) {
    <#
    .Synopsis
        Turn USB Filter on or off
    .Description
        This function enables and disables the USB Filter feature.
    #>

    $config = Get-WMIObject -class USBF_Filter @CommonArgs |
        where {
            $_.Id -eq "USBF_Filter"
        };

    if ($config) { 
        if($Value)
        {  
            $result = $config.Enable()
            if($result.ReturnValue -eq 0)
            {
                Write-Host "USB Filter enabled"
            } else {
                Write-Error "USB Filter failed to enable"
            }
        } else {
            $result = $config.Disable()
            if($result.ReturnValue -eq 0)
            {
                Write-Host "USB Filter disabled"
            } else {
                Write-Error "USB Filter failed to disable"
            }
        }
    } else {
        Write-Error "Unable to find USBF_Filter"
    }
}

# ----------Configuration Section----------
# This section of the script uses the predefined helper functions
# to apply the USB Filter configuration to the device.
# You can customize this script here to modify the USB Filter
# configuration of the device.
 
# To allow all USB devices of a specific class on a port, add a
# line below that follows the format below:
# Add-PermissionEntry "<port location path>" 1 <class id> 0 0
function Set-WriteFilterDriver([Bool] $Enabled) {
    <#
    .Synopsis
        Enable or disable write filter driver
    .Description
        Enable or disable write filter driver.  If it is set to disabled (false),
        no more interactions may be made.  A reboot is required to apply this change.
    .Parameter Value
        Enabled = true, disabled = false
    #>

    $driverConfig = Get-WMIObject -class UWF_Filter @CommonArgs;

    if ($driverConfig) {
        if ($Enabled -eq $true) {
            $driverConfig.Enable() | Out-Null;
        } else {
            $driverConfig.Disable() | Out-Null;
        }
        Write-Host ("Set Write Filter Enabled to {0}" -f $Enabled)
    }
}

function Set-WriteFilterHORM([Bool] $Enabled) {
    <#
    .Synopsis
        Enable or disable write filter driver
    .Description
        Enable or disable write filter's HORM feature. To be enabled,
        all volumes must be protected, no write filter changes pending,
        and must have no file or registry exclusions. No reboot is required
        for this change to take place, but it must be hibernated to create
        the hibernation file that will be used in further reboots.
    .Parameter Value
        Enabled = true, disabled = false
    #>

    $driverConfig = Get-WMIObject -class UWF_Filter @CommonArgs;

    if ($driverConfig) {
        if ($Enabled -eq $true) {
            $driverConfig.EnableHORM() | Out-Null;
        } else {
            $driverConfig.DisableHORM() | Out-Null;
        }
        Write-Host ("Set Write Filter HORM Enabled to {0}" -f $Enabled)
    }
}

function Set-OverlayConfiguration([UInt32] $size, $overlayType) {
    <#
    .Synopsis
        Sets the overlay storage configuration
    .Description
        Sets the size of the storage medium
        that file and registry changes are redirected to.  Changes made
        to this require a reboot to take affect.
    .Parameter Value
        size - size in MB of the overlay size
    #>

    $nextConfig = Get-WMIObject -class UWF_OverlayConfig -Filter "CurrentSession = false" @CommonArgs;

    if ($nextConfig) {
        if ($overlayType -eq "Memory") {
            $nextConfig.SetType(0) | Out-Null;
            Write-Host "Set Maximum Overlay size to use Memory"
        }
        elseif ($overlayType -eq "Disk") {
            $nextConfig.SetType(1) | Out-Null;
            Write-Host "Set Maximum Overlay size to use Disk"
        }
        else {
            Write-Error ("{0} is not a valid overlay type, must be Disk or Memory" -f $overlayType);
            return;
        }
        
        $nextConfig.SetMaximumSize($size) | Out-Null;
        Write-Host ("Set Maximum Overlay size to {0}" -f $size)
    }
}

function Set-ProtectVolume($driveLetter, [bool] $enabled) {
    <#
    .Synopsis
        Enables or disables protection of a volume by drive letter
    .Description
        Enables or disables protection of a volume by drive letter.  Note that only
        volumes that have a drive letter are exported since the volumeName is unique
        to the computer. 
    .Parameter Value
        driveLetter - drive letter formatted as "C:"
        enabled - true = after reboot, all changes will be redirected to temporary space
    #>

    $nextConfig = Get-WMIObject -class UWF_Volume @CommonArgs |
        where {
            $_.DriveLetter -eq "$driveLetter" -and $_.CurrentSession -eq $false
        };

    if ($nextConfig) {

        if ($Enabled -eq $true) {
            $nextConfig.Protect() | Out-Null;
        } else {
            $nextConfig.Unprotect() | Out-Null;
        }
        Write-Host "Setting drive protection on $driveLetter to $enabled"
    }
    else {
        Set-WMIInstance -class UWF_Volume -argument @{CurrentSession=$false;DriveLetter="$driveLetter";Protected=$enabled } @CommonArgs | Out-Null
        Write-Host "Adding drive protection on $driveLetter and setting to $enabled"
    }
}

function Clear-FileExclusions($driveLetter) {
    <#
    .Synopsis
        Deletes all file exclusions for a drive
    .Description
        UWF cannot immediately delete a file exclusion but will mark them as deleted.
        Files that are marked as added however will be deleted as an undo.
    .Parameter Value
        driveLetter - drive letter formatted as "C:"
    #>

    $nextConfig = Get-WMIObject -class UWF_Volume @CommonArgs |
        where {
            $_.DriveLetter -eq "$driveLetter" -and $_.CurrentSession -eq $false
        };

    if ($nextConfig) {
        $nextConfig.RemoveAllExclusions() | Out-Null;
        Write-Host "Cleared all exclusions for $driveLetter";
    }
    else {
        Write-Error "Could not clear exclusions for unprotected drive $driveLetter";
    }
}

function Add-FileExclusion($driveLetter, $exclusion) {
    <#
    .Synopsis
        Adds a file exclusion entry a drive
    .Description
        Adds a single entry.  If the entry was marked as deleted, the delete
        flag will be cleared.  Otherwise, it will be marked as added. All changes are
        applied after reboot.
    .Parameter Value
        driveLetter - drive letter formatted as "C:"
        exclusion - a file or directory to exclude
    #>

    $nextConfig = Get-WMIObject -class UWF_Volume @CommonArgs |
        where {
            $_.DriveLetter -eq "$driveLetter" -and $_.CurrentSession -eq $false
        };

    if ($nextConfig) {
        $nextConfig.AddExclusion($exclusion) | Out-Null;
        Write-Host "Added exclusion $exclusion for $driveLetter";
    }
    else {
        Write-Error "Could not add exclusion for unprotected drive $driveLetter";
    }
}

function Clear-RegistryExclusions() {
    <#
    .Synopsis
        Deletes all registry exclusions 
    .Description
        UWF cannot immediately delete a registry exclusion but will mark them as deleted.
        Entries that are marked as added however will be deleted as an undo.
    #>

    $nextConfig = Get-WMIObject -class UWF_RegistryFilter @CommonArgs |
        where {
            $_.CurrentSession -eq $false;
        };
    if ($nextConfig) {
        $InArgs = $nextConfig.GetMethodParameters("GetExclusions")
        
        $outArgs = $nextConfig.InvokeMethod("GetExclusions", $InArgs, $Null)

        foreach($key in $outArgs.ExcludedKeys) {
            Write-Host "Clearing key $key.RegistryKey"
            $removeOutput = $nextConfig.RemoveExclusion($key.RegistryKey)
        }
    }
}

function Add-RegistryExclusion($exclusion) {
    <#
    .Synopsis
        Adds a registry exclusion entry a drive
    .Description
        Adds a single entry.  If the entry was marked as deleted, the delete
        flag will be cleared.  Otherwise, it will be marked as added. All changes are
        applied after reboot.
    .Parameter Value
        exclusion - a file or directory to exclude
    #>

    $nextConfig = Get-WMIObject -class UWF_RegistryFilter @CommonArgs |
        where {
            $_.CurrentSession -eq $false;
        };

    if ($nextConfig) {
        $nextConfig.AddExclusion($exclusion) | Out-Null;
        Write-Host "Added exclusion $exclusion";
    }
    else {
        Write-Error "Could not add exclusion for unprotected drive $driveLetter";
    }
}
function Clear-AllConfigs() {
    <#
    .Synopsis
        Removes all app entries
    .Description
        Removes all filters
    #>

    Get-WMIObject -class WEMSAL_GlobalSetting @CommonArgs |
        foreach {
            $_.Delete() | Out-Null;
            Write-Host "Deleted $_.Id"
        }
    Get-WMIObject -class WEMSAL_UserSetting @CommonArgs |
        foreach {
            $_.Delete() | Out-Null;
            Write-Host "Deleted $_.Id"
        }
}

function Add-UserConfig($UserGroup, $AppId, $defaultExit) {
    <#
    .Synopsis
        Add an app
    .Description
        Adds a new user or group entry with a app.  If the account already exists,
        the app id is updated.
    .Example
        Add-UserConfig "domain\user" "winstore_cw5n1h2txyewy!Windows.Store" 4
    #>

	if ($AppId) {
        $objUser = New-Object System.Security.Principal.NTAccount($UserGroup)
        $stringSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        $isKioskEnabled = $FALSE
            if ($defaultExit -eq 3) {
                $settings = Get-WmiObject -class WEMSAL_Setting @CommonArgs | where { $_.KioskMode }
                if ($settings) {
                    Write-Error "User configuration actions incompatible to Kiosk Mode";
                    $isKioskEnabled = $TRUE;
                }
            }

        $custom = Get-WMIObject -class WEMSAL_UserSetting @CommonArgs |
            where {
                $_.Sid -eq "$stringSID"
            };

        if ($custom) {
            # Entry exists.  Just update it.
            $custom.AppUserModelId = $AppId;
            if (!$isKioskEnabled) {
                $custom.DefaultReturnCodeAction = $defaultExit;
            }
            $custom.Put() | Out-Null;
            Write-Host "Updated configuration for $UserGroup ($stringSID) to $AppId.";
			
        } else {
	        if (!$isKioskEnabled) {
                Set-WMIInstance -class WEMSAL_UserSetting -argument @{Sid="$stringSID";AppUserModelId="$AppId";DefaultReturnCodeAction="$defaultExit"} @CommonArgs | Out-Null
            } else {
                Set-WMIInstance -class WEMSAL_UserSetting -argument @{Sid="$stringSID";AppUserModelId="$AppId"} @CommonArgs | Out-Null
            }
        
            Write-Host "Configured an application $AppId for $UserGroup ($stringSID).";
        }
	}
}

function Set-UserCustomActions($UserGroup, $returnCodes, $actions) {
    <#
    .Synopsis
        sets custom actions and return codes
    .Description
        sets custom actions and return codes.  
            0 = Restart app
            1 = Restart system
            2 = Shut down
            3 = Close App Launcher
            4 = Shut down
    .Example
        Set-UserCustomActions "localUser" @{1,2} @{0,1}
    #>

    $objUser = New-Object System.Security.Principal.NTAccount($UserGroup)
    $stringSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])

    $custom = Get-WMIObject -class WEMSAL_UserSetting @CommonArgs |
        where {
            $_.Sid -eq "$stringSID"
        };

    if ($custom) {
        # Entry exists.  Just update it.
        if ($actions -contains 3) {
            $settings = Get-WmiObject -class WEMSAL_Setting @CommonArgs | where { $_.KioskMode }
            if ($settings) {
                Write-Error "Cannot update custom actions due to Kiosk Mode";
                return;
            }
        }
        $custom.CustomReturnCodes = $returnCodes;
        $custom.CustomReturnCodesAction = $actions;
        $custom.Put() | Out-Null;
        Write-Host "Updated application launcher custom actions for $UserGroup ($stringSID).";
    }
}

function Set-GlobalConfig($AppId, $defaultExit) {
    <#
    .Synopsis
        Sets default app
    .Description
        the app id is updated or added.
    .Example
        Set-GlobalConfig "winstore_cw5n1h2txyewy!Windows.Store" 1
    #>
	if ($AppId) {
        $isKioskEnabled = $FALSE;
        if ($defaultExit -eq 3) {
            $settings = Get-WmiObject -class WEMSAL_Setting @CommonArgs | where { $_.KioskMode }
            if ($settings) {
                Write-Error "Global configuration actions incompatible to Kiosk Mode";
                $isKioskEnabled = $TRUE;
            }
        }
        $global = Get-WmiObject -class WEMSAL_GlobalSetting @CommonArgs; 
        if ($global) {
            # Entry exists. Update it.
            $global.AppUserModelId = $AppId;
            if (!$isKioskEnabled) {
                $global.DefaultReturnCodeAction = $defaultExit;
            }        
            $global.Put() | Out-Null;
            Write-Host "Updated global configuration to $AppId.";
        } else {
	        if (!$isKioskEnabled) {
                Set-WMIInstance -class WEMSAL_GlobalSetting -argument @{InstanceName="WEMSAL_GlobalSetting";AppUserModelId="$AppId";DefaultReturnCodeAction="$defaultExit"} @CommonArgs | Out-Null
	        } else {
		        Set-WMIInstance -class WEMSAL_GlobalSetting -argument @{InstanceName="WEMSAL_GlobalSetting";AppUserModelId="$AppId"} @CommonArgs | Out-Null
		    }        
            Write-Host "Added global configuration $AppId.";
        }
	}
}

function Set-GlobalCustomActions($returnCodes, $actions) {
    <#
    .Synopsis
        sets custom actions and return codes
    .Description
        sets custom actions and return codes.  
            0 = Restart app
            1 = Restart system
            2 = Shut down
            3 = Close App Launcher
            4 = Shut down
    .Example
        Set-GlobalCustomActions @{1,2} @{0,1}
    #>

    $global = Get-WmiObject -class WEMSAL_GlobalSetting @CommonArgs; 
    if ($global) {
        # Entry exists. Update it after checking for kioskmode
        if ($actions -contains 3) {
            $settings = Get-WmiObject -class WEMSAL_Setting @CommonArgs | where { $_.KioskMode }
            if ($settings) {
                Write-Error "Cannot update global actions due to Kiosk Mode";
                return;
            }
        }
        $global.CustomReturnCodes = $returnCodes;
        $global.CustomReturnCodesAction = $actions;
        $global.Put() | Out-Null;
        Write-Host "Updated global configuration custom actions.";
    }
}

function Enable-AppLauncher([Bool] $enabled) {
    <#
    .Synopsis
        sets settings 
    .Description
        Enables/disables app launcher
    #>

    $settings = Get-WmiObject -class WEMSAL_Setting @CommonArgs; 
    if ($settings) {
        # Entry exists. Update it.
        if ($enabled) {
            $settings.Enabled = $TRUE;
        } else {
            $settings.Enabled = $FALSE;
        }
        $settings.Put() | Out-Null;
        Write-Host "Updated Enable-AppLauncher to $enabled.";
    }
}

function Enable-KioskMode([Bool] $enabled) {
    <#
    .Synopsis
        sets settings 
    .Description
        Enables/disables Kiosk Mode
    #>

    $settings = Get-WmiObject -class WEMSAL_Setting @CommonArgs; 
    if ($settings) {
        # Entry exists. Update it.
        if ($enabled) {
            $shouldEnable = $TRUE;
            $valueExitAl = 3;
            # check for correct conditions
            if ($settings.FatalErrorAction -eq $valueExitAl ) {
                $shouldEnable = $FALSE;
            }
            else {            
                $global = Get-WmiObject -class WEMSAL_GlobalSetting @CommonArgs |
                          where { $_.DefaultReturnCodeAction -eq $valueExitAl  -or $_.CustomReturnCodesAction -contains $valueExitAl }
                if ($global) {
                    $shouldEnable = $FALSE;   
                }
                else {
                    $user = Get-WmiObject -class WEMSAL_UserSetting @CommonArgs | 
                            where { $_.DefaultReturnCodeAction -eq $valueExitAl  -or $_.CustomReturnCodesAction -contains $valueExitAl }
                    if ($user) {
                        $shouldEnable = $FALSE;
                    }
                }
            }
            if ($shouldEnable) {
                $settings.KioskMode = $TRUE;
            }
            else {
                Write-Error "Incompatible action codes; cannot enable KioskMode.";
				return;
            }
        } else {
            $settings.KioskMode = $FALSE;
        }
        $settings.Put() | Out-Null;
        Write-Host "Updated KioskMode to $enabled.";
    }
}

function Set-FatalErrorAction($action) {
    <#
    .Synopsis
        sets settings 
    .Description
        Sets fatal error action
    #>
    $settings = Get-WmiObject -class WEMSAL_Setting @CommonArgs; 
    if ($settings) {
        # Entry exists. Update it.
        $settings.FatalErrorAction = $action;
        $settings.Put() | Out-Null;
        Write-Host "Updated FatalErrorAction to $action.";
    }
}
##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
Else {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================