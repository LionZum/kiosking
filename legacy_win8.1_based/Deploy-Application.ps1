 <#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
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
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$SingleMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false,
	[Parameter(Mandatory=$false)]
	[string]$scriptdir = 'c:\programdata\mmsmoa\script'
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'MMSMOA'
	[string]$appName = 'Enable Windows Lockdown Features'
	[string]$appVersion = '1'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.1'
	[string]$appScriptDate = ''
	[string]$appScriptAuthor = ''
	##*===============================================
    ## Versions
    ## 1.0.0 - Default working copy
    ## 1.0.1 - Added new enverments for Welcome Kiosk _ AS
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.9'
	[string]$deployAppScriptDate = '02/12/2017'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		
		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Installation tasks here>
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}
		
		## <Perform Installation tasks here>
		Get-WindowsOptionalFeature -Online -FeatureName client-* | Where-object State -ne "Enabled" | Enable-WindowsOptionalFeature -online -NoRestart
		
		If ($SingleMode){
			$reg = Get-childitem -Path "HKLM:\SOFTWARE\Microsoft\Windows Embedded\Shell Launcher" -Exclude S-1-5-32-544
			ForEach ($item in $reg){Remove-RegistryKey -Key $item.Name -Recurse -ErrorAction SilentlyContinue}
			If (!(test-path $scriptdir)){
				New-Folder -Path $scriptdir
			}
			Copy-File -Path "$dirFiles\LoadCitrix.ps1" -Destination "$scriptdir\LoadCitrix.ps1"
			Add-Shell "" "powershell.exe -windowstyle hidden -noexit -executionpolicy bypass -file `"$scriptdir\LoadCitrix.ps1`""
			Set-CustomActions "" @(0) @(0)
			Set-ForceOffAccessibility $true

			#Set-BreakoutKey "91"
			$output = & {net group /domain }
			
			
			#Clear-Shells
			Enable-ShellLauncher $true
			#Set-DefaultShell "c:\windows\system32\cmd.exe" 0
			Set-DefaultShell "c:\windows\explorer.exe" 0
			Set-WriteFilterDriver $False
			Allow-CustomKey "F1"

			Clear-AllConfigs
			Enable-AppLauncher $false
			Enable-KioskMode $false
			Set-FatalErrorAction 4
		} Else {
        #cleanup old possible error kiosks
		$reg = Get-childitem -Path "HKLM:\SOFTWARE\Microsoft\Windows Embedded\Shell Launcher" -Exclude S-1-5-32-544
        ForEach ($item in $reg){Remove-RegistryKey -Key $item.Name -Recurse -ErrorAction SilentlyContinue}
		
		
		#Begin regular actions
		Block-PredefinedKey "LShift+LAlt+NumLock"
		Block-PredefinedKey "LShift+LAlt+PrintScrn"
		Block-PredefinedKey "Win+U"
		Block-PredefinedKey "Alt+F4"
		Allow-PredefinedKey "Ctrl+F4"
		Block-PredefinedKey "Win+F1"
		Block-PredefinedKey "Escape"
		Block-PredefinedKey "Application"
		Block-PredefinedKey "Alt+Space"
		Block-PredefinedKey "Ctrl+Esc"
		Block-PredefinedKey "Ctrl+Win+F"
		Block-PredefinedKey "Win+Break"
		Block-PredefinedKey "Win+E"
		Block-PredefinedKey "Win+F"
		Block-PredefinedKey "Win+P"
		Block-PredefinedKey "Win+R"
		Block-PredefinedKey "Alt+Tab"
		Block-PredefinedKey "Ctrl+Tab"
		Block-PredefinedKey "Win+Tab"
		Block-PredefinedKey "Win+D"
		Block-PredefinedKey "Win+M"
		Block-PredefinedKey "Win+Home"
		Block-PredefinedKey "Win+T"
		Block-PredefinedKey "Win+B"
		Block-PredefinedKey "Win+-"
		Block-PredefinedKey "Win++"
		Block-PredefinedKey "Win+Esc"
		Block-PredefinedKey "Win+Down"
		Block-PredefinedKey "Win+Left"
		Block-PredefinedKey "Win+Up"
		Block-PredefinedKey "Win+Right"
		Block-PredefinedKey "Win+Shift+Down"
		Block-PredefinedKey "Win+Shift+Left"
		Block-PredefinedKey "Win+Shift+Up"
		Block-PredefinedKey "Win+Shift+Right"
		Block-PredefinedKey "Win+Space"
		Block-PredefinedKey "Win+O"
		Block-PredefinedKey "Win+Enter"
		Block-PredefinedKey "Win+PageUp"
		Block-PredefinedKey "Win+PageDown"
		Block-PredefinedKey "Win+."
		Block-PredefinedKey "Win+C"
		Block-PredefinedKey "Win+I"
		Block-PredefinedKey "Win+K"
		Block-PredefinedKey "Win+H"
		Block-PredefinedKey "Win+Q"
		Block-PredefinedKey "Win+V"
		Block-PredefinedKey "Win+W"
		Block-PredefinedKey "Win+Z"
		Block-PredefinedKey "Win+/"
		Block-PredefinedKey "Win+J"
		Block-PredefinedKey "Win+,"
		Allow-PredefinedKey "Alt"
		Allow-PredefinedKey "Ctrl"
		Allow-PredefinedKey "Shift"
		Block-PredefinedKey "Windows"
		Allow-PredefinedKey "Ctrl+Alt+Del"
		Block-PredefinedKey "Shift+Ctrl+Esc"
		Block-PredefinedKey "Win+L"
		Block-PredefinedKey "LaunchMail"
		Block-PredefinedKey "LaunchMediaSelect"
		Block-PredefinedKey "LaunchApp1"
		Block-PredefinedKey "LaunchApp2"
		Allow-PredefinedKey "BrowserStop"
		Block-PredefinedKey "BrowserFavorites"
		Allow-PredefinedKey "BrowserHome"
		Allow-PredefinedKey "BrowserBack"
		Allow-PredefinedKey "BrowserForward"
		Allow-PredefinedKey "BrowserRefresh"
		Block-PredefinedKey "BrowserSearch"
		Block-PredefinedKey "VolumeMute"
		Block-PredefinedKey "VolumeUp"
		Block-PredefinedKey "VolumeDown"
		Block-PredefinedKey "MediaNext"
		Block-PredefinedKey "MediaPrev"
		Block-PredefinedKey "MediaStop"
		Block-PredefinedKey "MediaPlayPause"

		Clear-CustomFilters

		Block-CustomKey "F12"
		Block-CustomKey "F11"
		Block-CustomKey "F10"
		Block-CustomKey "F9"
		Block-CustomKey "F1"
		Block-Scancode "Ctrl+Alt" 72
		Block-Scancode "Ctrl+Alt" 75
		Block-Scancode "Ctrl+Alt" 77
		Block-Scancode "Ctrl+Alt" 80

		Set-DisableKeyboardFilterForAdministrators $true

		Set-ForceOffAccessibility $true

		#Set-BreakoutKey "91"
        $output = & {net group /domain }
		
		
		#Clear-Shells
		Enable-ShellLauncher $true
		#Set-DefaultShell "c:\windows\system32\cmd.exe" 0
		Set-DefaultShell "c:\windows\explorer.exe" 0

		$Browser = "c:\Program Files\internet explorer\iexplore.exe"
		$Chrome = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
		$Edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

		#region Administrators Start
		Add-Shell "Administrators" "c:\windows\explorer.exe"
		Set-CustomActions "Administrators"
		#endregion Administrators End

		#region MMSMoa
        Add-Shell "ksk-mmsmoa1" "$edge --kiosk `"https://mms2024atmoa.sched.com/`" --edge-kiosk-type=fullscreen"
        Set-CustomActions "ksk-mmsmoa1" @(0) @(0)
        #endregion MMSMoa
		
		#region MMSMoa
        Add-Shell "ksk-mmsmoa2" "$edge --kiosk `"https://learn.microsoft.com`" --edge-kiosk-type=fullscreen"
        Set-CustomActions "ksk-mmsmoa2" @(0) @(0)
        #endregion MMSMoa
		
		Set-WriteFilterDriver $False

		Clear-AllConfigs
		Enable-AppLauncher $false
		Enable-KioskMode $false
		Set-FatalErrorAction 4

        }
		##Documentation links
        
        #keyboard filter https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/customize/keyboardfilter
        #Allow-PredefinedKey
		#Block-PredefinedKey
        #Clear-CustomFilters
		#Block-CustomKey
		#Block-Scancode
        
        #Shell Launcher https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/customize/shell-launcher
        #Add-Shell
        #Set-CustomActions
        #Enable-ShellLauncher
		#Set-DefaultShell

        
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		#Execute-Process -Path "powershell.exe" -Parameters "-executionpolicy bypass -file $dirFiles\Kiosk_LockDownW10.ps1"
		## Display a message at the end of the install
		If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		
		# <Perform Uninstallation tasks here>
		
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		
		
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}