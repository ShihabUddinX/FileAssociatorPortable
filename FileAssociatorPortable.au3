#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=..\..\App\AppInfo\appicon.ico
#AutoIt3Wrapper_outfile=..\..\FileAssociatorPortable.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Res_Comment=Create custom portable file associations and context menus.
#AutoIt3Wrapper_Res_Description=FileAssociatorPortable
#AutoIt3Wrapper_Res_ProductName=FileAssociatorPortable
#AutoIt3Wrapper_Res_CompanyName=ShihabUddinX
#AutoIt3Wrapper_Res_Fileversion=3.0.0.5
#AutoIt3Wrapper_Res_ProductVersion=3.0.0.5
#AutoIt3Wrapper_Res_LegalCopyright=Copyright (c) ShihabUddinX. Original work by Erik Pilsits
#AutoIt3Wrapper_Res_LegalTrademarks=ShihabUddinX
#AutoIt3Wrapper_Res_Field=Owner|ShihabUddinX
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=n
#AutoIt3Wrapper_Res_Field=ProductName|FileAssociatorPortable
#AutoIt3Wrapper_Res_Field=InternalName|FileAssociatorPortable
#AutoIt3Wrapper_Res_Field=OriginalFilename|FileAssociatorPortable.exe
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
#AutoIt3Wrapper_Run_Obfuscator=y
#Obfuscator_Parameters=/sf=1 /sv=1 /om /cs=0 /cn=0
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; File properties (Details tab of the exe).  The #pragma lines work with Aut2Exe too, the AutoIt3Wrapper lines above only with SciTE4AutoIt.
#pragma compile(FileVersion, 3.0.0.5)
#pragma compile(ProductVersion, 3.0.0.5)
#pragma compile(FileDescription, FileAssociatorPortable)
#pragma compile(ProductName, FileAssociatorPortable)
#pragma compile(InternalName, FileAssociatorPortable)
#pragma compile(OriginalFilename, FileAssociatorPortable.exe)
#pragma compile(CompanyName, ShihabUddinX)
#pragma compile(LegalCopyright, Copyright ShihabUddinX. Original work by Erik Pilsits)
#pragma compile(LegalTrademarks, ShihabUddinX)
#pragma compile(Comments, Create custom portable file associations and context menus.)

#include <_RegFunc.au3>
#include <_SplashData.au3>
#include <Constants.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>
#include <GuiToolbar.au3>
#include <EditConstants.au3>
#include <UpDownConstants.au3>
#include <ComboConstants.au3>
#include <ListBoxConstants.au3>
#include <StaticConstants.au3>
#include <Process.au3>
#include <WinAPI.au3>
#include <GuiMenu.au3>
#include <String.au3>
#include <GDIPlus.au3>

Opt("GUIOnEventMode", 1) ; enable GUI events
Opt("GUIEventOptions", 1) ; minimize only sends notification
Opt("TrayMenuMode", 3) ; no tray menu, no auto-check/uncheck on user items
Opt("TrayOnEventMode", 1) ; enable tray events
Opt("MustDeclareVars", 1) ; must declare variables before use
Opt("WinTitleMatchMode", 3) ; exact title match

Global Const $version = "3.0.0.5"
; update checker (see "Update checker" region)
Global Const $UPDATE_VERSION_URL = "https://raw.githubusercontent.com/ShihabUddinX/PortableFileAssociator/main/.github/version.pfa"
Global Const $UPDATE_RELEASE_URL = "https://github.com/ShihabUddinX/PortableFileAssociator/releases/tag/"
Global Const $UPDATE_API_URL = "https://api.github.com/repos/ShihabUddinX/PortableFileAssociator/contents/.github/version.pfa?ref=main"
Global $oUpdate = 0, $hUpdateTimer = 0, $fUpdateManual = False, $iUpdateComErr = 0, $iUpdateStage = 0, $trayupdate

#Region Commandline
Global $wndMSG, $wndMSG_msg = -1

; multi-file launcher: started by Explorer for commands that use %%1 (see "Multi-file launcher" region)
If $CmdLine[0] > 1 Then
	If $CmdLine[1] = "multi_open" Or $CmdLine[1] = "multi_open_admin" Then
		_MultiOpen($CmdLine[1] = "multi_open_admin")
		Exit
	EndIf
	If $CmdLine[1] = "bg_open" Or $CmdLine[1] = "bg_open_admin" Then
		_BgOpen($CmdLine[1] = "bg_open_admin")
		Exit
	EndIf
EndIf

$wndMSG = _WinAPI_RegisterWindowMessage("PFA_CustomWindowMessage")

If _CreateMutex() <> 0 Then
	; second instance = commandline mode
	If $CmdLine[0] > 0 Then
		Switch $CmdLine[1]
			Case "exit"
				$wndMSG_msg = 0
		EndSwitch
		If $wndMSG_msg <> -1 Then _SendMessage(WinGetHandle("FileAssociatorPortable"), $wndMSG, $wndMSG_msg, 0)
	EndIf
	Exit
EndIf
#EndRegion Commandline
#Region Init
Global Const $blacklist[7] = ["drives", "files", "folders", "recycle", "exe", "com", ""]
Global Const $aProfileINIs[4] = ["_assoc.ini", "_state.ini", "_types.ini", "_sendto.ini"]
Global Const $settingsdir = @ScriptDir & "\Data\settings"
Global $state, $iconchange, $rebuild, $onclose, $aMouse

Global $contextGUI, $nGUI, $Button1, $Button2, $Button3, $Button4, $Button6, $Button8
Global $nProfile, $nNew, $nClone, $nRename, $nRemove
Global $aProfIcons[5][2], $fGDIP = False ; action icon bitmaps (profile buttons + Settings): [n][0] = normal, [n][1] = disabled
Global $iThemeMode = 0, $fDark = False ; theme: 0 = system, 1 = light, 2 = dark
Global $iBgCol = 0xF0F0F0, $iCtrlCol = 0xFFFFFF, $iTextCol = 0x000000, $iLightBg = 0xF0F0F0
Global $rdGUI, $rdEdit, $rdClose, $fReadmeLoaded = False ; embedded Readme window
Global $nSettings, $stGUI, $stTheme, $stAddStart, $stRemoveExit, $stCheckUpd, $stStartMin, $stNoSplash, $stCloseTray, $stDone
Global $fSetAddStart = False, $fSetRemoveExit = True, $fSetCheckUpd = True, $fSetStartMin = False, $fSetCloseTray = False ; Settings (settings.ini)
Global $aMutedLbl[5][3] ; muted labels: [n][0] = ctrl id, [n][1] = light colour, [n][2] = dark colour
Global Const $aProfIconNames[5] = ["New_Profile", "Clone_Profile", "Rename_Profile", "Remove_Profile", "Settings"]
Global $refreshnow, $trayexit
Global $aGUI, $lSec, $iSec, $iMode, $iTitle, $iCommand, $dChk, $disChk, $singleChk, $chkFiles, $chkFolders, $chkDrives, $chkRecycle, $chkBackground, $iDriveCmd, $bBtnDrive, $iFolderCmd, $bBtnFolder, $runAdminChk, $cBtn, $sBtn, $delBtn, $dBtn, $hBtn, $bBtn
Global $iAssocIcon, $iAssocIconBrowse, $iAssocIconIndex, $iAssocIconPreview
Global $tGUI, $icondisplay, $ftypelist, $ftypeAssocFilter, $defassoclist, $hideext, $copyhost, $hostoverride, $ftypeicon, $iconbrowse, $iconindex, $indexupdown, $savetypes, $donetypes
Global $showNewMenu, $newMenuName, $useTemplate, $templateFile
Global $sGUI, $hsLV, $sAdd, $sRemove, $sClear, $sSave, $sDone, $sDummy, $pWndProc = 0, $oldWndProc = 0, $sChanges

Global $aDefaultAssociations[1] = [0], $aDropFiles[1] = [0]

Global Const $PFA_MAX_PATH = 260
Global Const $PFA_SPI_SETNONCLIENTMETRICS = 42
Global Const $PFA_WM_SETTINGCHANGE = 0x1A
Global Const $PFA_WM_DROPFILES = 0x233
Global Const $PFA_HWND_BROADCAST = 0xFFFF
Global Const $PFA_SHCNE_ASSOCCHANGED = 0x8000000
Global Const $PFA_SHCNF_FLUSH = 0x1000
Global Const $PFA_SHCNF_IDLIST = 0x0

Global Const $drive = StringLeft(@ScriptDir, 2) ; get portable drive letter
; get some version info
Global $fVistaOrBetter = False, $fXPOrBetter = False
_OSVersion()

GUIRegisterMsg($WM_COMMAND, "_MY_WM_COMMAND")
GUIRegisterMsg($wndMSG, "_MY_CUSTOM_MSG")
GUIRegisterMsg(0x16, "_MY_WM_ENDSESSION") ; WM_ENDSESSION

; create missing directories
If Not FileExists(@ScriptDir & "\Data\settings") Then DirCreate(@ScriptDir & "\Data\settings")
If Not FileExists(@ScriptDir & "\Data\newitems") Then DirCreate(@ScriptDir & "\Data\newitems")

; convert old INIs
If FileExists($settingsdir & "\assoc.ini") Then
	FileMove($settingsdir & "\assoc.ini", $settingsdir & "\default_assoc.ini")
	FileMove($settingsdir & "\state.ini", $settingsdir & "\default_state.ini")
	FileMove($settingsdir & "\icons.ini", $settingsdir & "\default_types.ini")
EndIf

; get current profile and set active (create a default if missing)
Global Const $profileini = $settingsdir & "\profile.ini"
Global Const $settingsini = $settingsdir & "\settings.ini"
_ExeIniMigrateOldName() ; the app used to be called PortableFileAssociator: take over its .ini
_SettingsMigrate() ; first start of this version: take over the old settings (profile.ini, state ini, exe ini)
_SettingsLoad()
Global $curProfile = IniRead($profileini, "profile", "active", "__error__")
If $curProfile = "__error__" Or Not FileExists($settingsdir & "\" & $curProfile & "_assoc.ini") Then $curProfile = _GetNextProfile()
Global $associni, $stateini, $typesini, $sendtoini
_SetProfile($curProfile)

FileChangeDir(@ScriptDir) ; set working directory

; operating mode
_OperatingMode()
#EndRegion Init
; GUI loop
While 1
	If IsObj($oUpdate) Then ; update check running: look at it often
		Sleep(150)
		_UpdatePoll()
	Else
		Sleep(1000)
	EndIf
WEnd

#Region Misc Functions
;=======================================================================================
; Misc Functions
;=======================================================================================

Func _OperatingMode()
	Local $arg1 = "", $arg2 = "", $iArg

	If $CmdLine[0] = 0 Then
		; no arguments: the Settings decide (Add associations on start, Start minimized)
	Else ; commandline args:  <mode> [profile name]   (a profile name with spaces can be written with or without "quotes")
		$arg1 = $CmdLine[1]
		For $iArg = 2 To $CmdLine[0]
			If $arg2 <> "" Then $arg2 &= " "
			$arg2 &= $CmdLine[$iArg]
		Next
	EndIf
	If $arg1 Then
		If $arg2 And Not FileExists($settingsdir & "\" & $arg2 & "_assoc.ini") Then
			; passed invalid profile
			MsgBox(16, "Error", "Invalid profile.")
			Exit
		EndIf
		Switch $arg1
			Case "add_gui"
				If $arg2 Then _SetProfile($arg2)
				_InitAllGUIs("add_gui")
			Case "add"
				If $arg2 Then _SetProfile($arg2)
				_FileAssociations("add")
				Exit
			Case "remove"
				_FileAssociations("remove")
				Exit
			Case Else
				MsgBox(16, "Error", "Invalid command.")
				Exit
		EndSwitch
	Else
		; if no arguments, start GUI
		_InitAllGUIs()
	EndIf
EndFunc

Func _CreateMutex()
	DllCall("kernel32.dll", "int", "CreateMutex", _
							"ptr", 0, _
							"int", 0, _
							"str", @ScriptName _
							)
	Local $ret = DllCall("kernel32.dll", "int", "GetLastError")
	Return $ret[0]
EndFunc

Func _MY_CUSTOM_MSG($hWnd, $Msg, $wParam, $lParam)
	#forceref $hWnd, $lParam
	Switch $Msg
		Case $wndMSG
			Switch $wParam
				Case 0
					_Exit()
			EndSwitch
	EndSwitch
EndFunc

Func _ReadINISections()
	Local $section = IniReadSectionNames($associni) ; get sections, INI must have at least 1 section
	If @error Then
		MsgBox(0, "Error", "Error reading INI file.")
		_Exit()
	Else
		Return $section
	EndIf
EndFunc

Func _ReadStateINI()
	; get current state, 0 = not installed
	$state = Number(IniRead($stateini, "state", "state", "-1"))
	If $state = -1 Then
		IniWrite($stateini, "state", "state", "0")
		$state = 0
	EndIf
	; get icon refresh setting, 0 = do not refresh (default)
	$rebuild = Number(IniRead($stateini, "state", "refresh", "-1"))
	If $rebuild = -1 Then
		IniWrite($stateini, "state", "refresh", "0")
		$rebuild = 0
	EndIf
	; OnClose: global setting "Remove associations on exit" (settings.ini), 1 = remove associations on exit (default)
	$onclose = Number($fSetRemoveExit)
EndFunc

Func _PDRIVEToDrive($path)
	Return StringReplace($path, "PDRIVE", $drive, 0, 1)
EndFunc

Func _GetExePath($command)
	Local $exepath

	If StringLeft($command, 1) = '"' Then ; first character is a quote
		$exepath = StringLeft($command, StringInStr($command, '"', 0, 2))
	Else ; first whitespace is end of command
		$exepath = StringLeft($command, StringInStr($command, ' ', 0, 1) - 1)
		If $exepath = "" Then ; no spaces = no extra args
			$exepath = $command
		EndIf
	EndIf
	Return $exepath
EndFunc

Func _GetExeName($command)
	Local $exename

	$exename = _GetExePath($command) ; get EXE path
	$exename = StringReplace($exename, '"', '') ; remove any quotes
	$exename = StringTrimLeft($exename, StringInStr($exename, "\", 0, -1)) ; get EXE name
	Return $exename
EndFunc

Func _PathGetRelative2($sFrom, $sTo)
	Local $asFrom, $asTo, $iDiff, $sRelPath, $i

	If StringRight($sFrom, 1) <> "\" Then $sFrom &= "\" ; add missing trailing \ to $sFrom path
	If StringRight($sTo, 1) <> "\" Then $sTo &= "\" ; add trailing \ to $sTo
	If $sFrom = $sTo Then Return SetError(1, 0, StringTrimRight($sTo, 1)) ; $sFrom equals $sTo
	$asFrom = StringSplit($sFrom, "\")
	$asTo = StringSplit($sTo, "\")
	If $asFrom[1] <> $asTo[1] Then Return SetError(2, 0, StringTrimRight($sTo, 1)) ; drives are different, rel path not possible
	; create rel path
	$i = 2
	$iDiff = 1
	While 1
		If $asFrom[$i] <> $asTo[$i] Then
			$iDiff = $i
			ExitLoop
		EndIf
		$i += 1
	WEnd
	$i = 1
	$sRelPath = ""
	For $j = 1 To $asTo[0]
		If $i >= $iDiff Then
			$sRelPath &= "\" & $asTo[$i]
		EndIf
		$i += 1
	Next
	$sRelPath = StringTrimLeft($sRelPath, 1)
	$i = 1
	For $j = 1 To $asFrom[0]
		If $i > $iDiff Then
			$sRelPath = "..\" & $sRelPath
		EndIf
		$i += 1
	Next
	If StringRight($sRelPath, 1) = "\" Then $sRelPath = StringTrimRight($sRelPath, 1) ; remove trailing \
	If StringLeft($sRelPath, 3) <> "..\" Then $sRelPath = ".\" & $sRelPath
	Return $sRelPath
EndFunc ;  ==> _PathGetRelative2

Func _PathFull2($sRelativePath, $sBasePath = @WorkingDir)
	If Not $sRelativePath Or $sRelativePath = "." Then Return $sBasePath

	; Normalize slash direction.
	Local $sFullPath = StringReplace($sRelativePath, "/", "\") ; Holds the full path (later, minus the root)
	Local Const $sFullPathConst = $sFullPath ; Holds a constant version of the full path.
	Local $sPath ; Holds the root drive/server
	Local $bRootOnly = StringLeft($sFullPath, 1) = "\" And StringMid($sFullPath, 2, 1) <> "\"

	; Check for UNC paths or local drives.  We run this twice at most.  The
	; first time, we check if the relative path is absolute.  If it's not, then
	; we use the base path which should be absolute.
	For $i = 1 To 2
		$sPath = StringLeft($sFullPath, 2)
		If $sPath = "\\" Then
			$sFullPath = StringTrimLeft($sFullPath, 2)
			$sPath &= StringLeft($sFullPath, StringInStr($sFullPath, "\") - 1)
			ExitLoop
		ElseIf StringRight($sPath, 1) = ":" Then
			$sFullPath = StringTrimLeft($sFullPath, 2)
			ExitLoop
		Else
			$sFullPath = $sBasePath & "\" & $sFullPath
		EndIf
	Next

	; If this happens, we've found a funky path and don't know what to do
	; except for get out as fast as possible.  We've also screwed up our
	; variables so we definitely need to quit.
	If $i = 3 Then Return ""

	; Build an array of the path parts we want to use.
	Local $aTemp = StringSplit($sFullPath, "\")
	Local $aPathParts[$aTemp[0]], $j = 0
	For $i = 2 To $aTemp[0]
		If $aTemp[$i] = ".." Then
			If $j Then $j -= 1
		ElseIf Not ($aTemp[$i] = "" And $i <> $aTemp[0]) And $aTemp[$i] <> "." Then
			$aPathParts[$j] = $aTemp[$i]
			$j += 1
		EndIf
	Next

	; Here we re-build the path from the parts above.  We skip the
	; loop if we are only returning the root.
	$sFullPath = $sPath
	If Not $bRootOnly Then
		For $i = 0 To $j - 1
			$sFullPath &= "\" & $aPathParts[$i]
		Next
	Else
		$sFullPath &= $sFullPathConst
		; If we detect more relative parts, remove them by calling ourself recursively.
		If StringInStr($sFullPath, "..") Then $sFullPath = _PathFull2($sFullPath)
	EndIf

	; Clean up the path.
	While StringInStr($sFullPath, ".\")
		$sFullPath = StringReplace($sFullPath, ".\", "\")
	WEnd
	Return $sFullPath
EndFunc   ;==>_PathFull2

Func _ConvertPaths()
	Local $i, $sections, $command

	$sections = _ReadINISections()
	If IsArray($sections) Then
		; remove old keys, convert paths
		For $i = 1 To $sections[0]
			; remove 'default' key from _assoc.ini
			IniDelete($associni, $sections[$i], "default")
			; convert PDRIVE tokens and relative paths
			$command = IniRead($associni, $sections[$i], "command", "")
			If StringInStr($command, "PDRIVE", 1) Then
				$command = _PDRIVEToDrive($command)
				$command = _GetRelCommand($command)
				IniWrite($associni, $sections[$i], "command", "'" & $command & "'")
			EndIf
		Next
	EndIf
EndFunc

Func _CommandSplit($command)
	Local $asCmd[2]

	$asCmd[0] = _GetExePath($command)
	$asCmd[1] = StringTrimLeft($command, StringLen($asCmd[0]) + 1)
	Return $asCmd
EndFunc

Func _GetRelCommand($command)
	Local $aCmd[1]

	$aCmd = _CommandSplit($command)
	$aCmd[0] = StringReplace($aCmd[0], '"', '')
	If StringInStr($aCmd[0], ":\") Then
		; full path, get relative path
		$aCmd[0] = _PathGetRelative2(@ScriptDir, $aCmd[0])
	; else not a full path
	EndIf
	If StringInStr($aCmd[0], ' ') Then $aCmd[0] = '"' & $aCmd[0] & '"'
	$command = $aCmd[0]
	If $aCmd[1] <> "" Then $command &= ' ' & $aCmd[1]
	Return $command
EndFunc

Func _GetFullCommand($command)
	Local $aCmd[2]

	$aCmd = _CommandSplit($command)
	$aCmd[0] = StringReplace($aCmd[0], '"', '')
	If StringInStr($aCmd[0], ".\") Then
		; relative path
		$aCmd[0] = _PathFull2(@ScriptDir & "\" & $aCmd[0])
	; else full path, leave as is
	EndIf
	If StringInStr($aCmd[0], ' ') Then $aCmd[0] = '"' & $aCmd[0] & '"'
	$command = $aCmd[0]
	If $aCmd[1] <> "" Then $command &= ' ' & $aCmd[1]
	Return $command
EndFunc

Func _GetFullIcon($icon)
	Local $aIcon[2]

	$aIcon = StringSplit(StringReplace($icon, '"', ''), ",") ; remove quotes and split
	If StringInStr($aIcon[1], ".\") Then
		; relative path
		$aIcon[1] = _PathFull2(@ScriptDir & "\" & $aIcon[1])
	; else full path, leave as is
	EndIf
	$icon = $aIcon[1]
	If $aIcon[0] > 1 Then $icon &= "," & $aIcon[2]
	Return $icon
EndFunc

Func _SetForegroundWindow($hwnd)
	DllCall("user32.dll", "int", "SetForegroundWindow", "hwnd", $hwnd)
EndFunc

Func _OSVersion()
	Local $OSVERSIONINFOEXW = "dword dwOSVersionInfoSize;dword dwMajorVersion;dword dwMinorVersion;dword dwBuildNumber;dword dwPlatformId;" & _
								"wchar szCSDVersion[128];ushort wServicePackMajor;ushort wServicePackMinor;ushort wSuiteMask;byte wProductType;byte wReserved"
	Local $OSVI = DllStructCreate($OSVERSIONINFOEXW)
	DllStructSetData($OSVI, "dwOSVersionInfoSize", DllStructGetSize($OSVI))
	DllCall("kernel32.dll", "int", "GetVersionExW", "ptr", DllStructGetPtr($OSVI))
	If (DllStructGetData($OSVI, "dwMajorVersion") >= 6) Then $fVistaOrBetter = True
	If (DllStructGetData($OSVI, "dwMajorVersion") >= 5) And (DllStructGetData($OSVI, "dwMinorVersion") >= 1) Then $fXPOrBetter = True
EndFunc

Func _VersionCheckInternal($ver, $fOlder = False)
	; check if internal version against var
	Local $aInternal = StringSplit($version, ".")
	Local $aVer = StringSplit($ver, ".")
	ReDim $aVer[$aInternal[0] + 1] ; make sure they are the same length
	If $fOlder Then
		; check internal version is older
		For $i = 1 To $aInternal[0]
			If Number($aInternal[$i]) < Number($aVer[$i]) Then Return True
		Next
	Else
		; check internal version is newer
		For $i = 1 To $aInternal[0]
			If Number($aInternal[$i]) > Number($aVer[$i]) Then Return True
		Next
	EndIf
	Return False
EndFunc


Func _WinAPI_SHGetFolderPath($nFolder, $dwFlags = 0) ; $SHGFP_TYPE_CURRENT
	Local $path = DllStructCreate("wchar[260]")
	Local $folder = DllCall("shell32.dll", "int", "SHGetFolderPathW", _
											"hwnd", 0, _
											"int", $nFolder, _
											"ptr", 0, _
											"dword", $dwFlags, _
											"ptr", DllStructGetPtr($path) _
											)
	If $folder[0] < 0 Then Return SetError(1, "", "")
	Return DllStructGetData($path, 1)
EndFunc
#EndRegion Misc Functions
#Region GUI Creation Functions (all GUIs)
;=======================================================================================
; GUI Creation Functions (all GUIs)
;=======================================================================================

Func _InitAllGUIs($guimode = "")
	Local $hSplash = 0, $hSplashTimer = 0
	If $guimode = "" Or $guimode = "add_gui" Then $hSplash = _SplashShow($hSplashTimer) ; splash screen (also while "add on start" adds the associations)
	If $fSetCheckUpd Then _UpdateCheckStart(False) ; update check on start (Settings), in the background
	_ThemeLoad() ; read theme setting (system / light / dark)
	TraySetClick(8) ; show menu only on right-click
	TraySetState(1) ; show tray icon

	If $state = 1 Then
		TraySetToolTip("FileAssociatorPortable (enabled)" & @CRLF & "Profile:  " & $curProfile)
	Else
		TraySetToolTip("FileAssociatorPortable (disabled)")
	EndIf

	; ===== message GUI for context menu, active but off screen
	$contextGUI = GUICreate("", 1, 1, -1000, 0, -1, $WS_EX_TOOLWINDOW)
	GUISetState()
#Region	===== main GUI & tray
	; Main window: wider layout with clearer grouping and more comfortable spacing.
	$nGUI = GUICreate("FileAssociatorPortable", 310, 545, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_MINIMIZEBOX))
	GUISetFont(9, 400, 0, "Segoe UI", $nGUI)

	; Primary actions
	$Button1 = GUICtrlCreateButton("Add File Associations", 16, 14, 278, 42)
	$Button2 = GUICtrlCreateButton("Remove File Associations", 16, 64, 278, 42)

	; Configuration shortcuts
	GUICtrlCreateGroup(" Configuration ", 16, 122, 278, 112)
	$Button3 = GUICtrlCreateButton("Associations", 28, 151, 82,  34)
	$Button6 = GUICtrlCreateButton("File Types", 114, 151, 82,  34)
	$Button8 = GUICtrlCreateButton("SendTo", 200, 151, 82,  34)
	GUICtrlCreateGroup ("",-99,-99,1,1)  ;close group

	; System restore
	GUICtrlCreateGroup(" System Restore ", 16, 250, 278, 76)
	$Button4 = GUICtrlCreateButton("Create System Restore Point", 30, 275, 250, 34)
	GUICtrlSetTip(-1, "Create a System Restore Point.")
	GUICtrlCreateGroup ("",-99,-99,1,1)  ;close group

	; Profile management
	GUICtrlCreateGroup(" Profile ", 16, 342, 278, 142)
	$nProfile = GUICtrlCreateCombo("", 30, 366, 250, 28, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	$nNew = GUICtrlCreatePic("", 51, 413, 32, 32)
	GUICtrlSetTip(-1, "New profile")
	GUICtrlSetCursor(-1, 0)
	$nClone = GUICtrlCreatePic("", 108, 413, 32, 32)
	GUICtrlSetTip(-1, "Clone profile")
	GUICtrlSetCursor(-1, 0)
	$nRename = GUICtrlCreatePic("", 165, 413, 32, 32)
	GUICtrlSetTip(-1, "Rename profile")
	GUICtrlSetCursor(-1, 0)
	$nRemove = GUICtrlCreatePic("", 222, 413, 32, 32)
	GUICtrlSetTip(-1, "Remove profile")
	GUICtrlSetCursor(-1, 0)
	GUICtrlCreateGroup ("",-99,-99,1,1)  ;close group
	$aMutedLbl[0][0] = GUICtrlCreateLabel("Profile actions", 30, 450, 250, 18)
	$aMutedLbl[0][1] = 0x666666
	GUICtrlSetFont(-1, 8.5, 400, 0, "Segoe UI")
	GUICtrlSetColor(-1, 0x666666)

	$aMutedLbl[1][0] = GUICtrlCreateLabel("v" & $version, 16, 510)
	$aMutedLbl[1][1] = 0x777777
	GUICtrlSetFont(-1, 8.5)
	GUICtrlSetColor(-1, 0x777777)

	; settings icon (opens the Settings window: theme, start / exit options, ...)
	$nSettings = GUICtrlCreatePic("", 262, 498, 32, 32)
	GUICtrlSetTip(-1, "Settings")
	GUICtrlSetCursor(-1, 0)

	; GUI events
	GUISetOnEvent($GUI_EVENT_CLOSE, "_MainClose") ; exit, or minimize to the tray (Settings)
	GUISetOnEvent($GUI_EVENT_MINIMIZE, "_HideMainGUI")
	GUISetOnEvent($GUI_EVENT_RESTORE, "_RestoreMainGUI")

	; tray menu
	$refreshnow = TrayCreateItem("Refresh icons now")
	$trayupdate = TrayCreateItem("Check for updates")
	TrayCreateItem("")
	$trayexit = TrayCreateItem("Exit")

	; tray events
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "_RestoreMainGUI")
	TrayItemSetOnEvent($refreshnow, "_RefreshNow")
	TrayItemSetOnEvent($trayupdate, "_UpdateCheckManual")
	TrayItemSetOnEvent($trayexit, "_Exit")

	; control events
	GUICtrlSetOnEvent($Button1, "_AddAssociations")
	GUICtrlSetOnEvent($Button2, "_RemoveAssociations")
	GUICtrlSetOnEvent($Button3, "_EditAssocINI")
	GUICtrlSetOnEvent($Button4, "_CreateRestorePoint")
	GUICtrlSetOnEvent($Button6, "_TypesEditGUI")
	GUICtrlSetOnEvent($Button8, "_SendToGUI")
	GUICtrlSetOnEvent($nProfile, "_SetProfileEvent")
	GUICtrlSetOnEvent($nNew, "_NewProfile")
	GUICtrlSetOnEvent($nClone, "_CloneProfile")
	GUICtrlSetOnEvent($nRename, "_RenameProfile")
	GUICtrlSetOnEvent($nRemove, "_RemoveProfile")
	GUICtrlSetOnEvent($nSettings, "_SettingsGUI")

	; set button states
	_ActionButtonsState() ; action buttons
#EndRegion ===== main GUI & tray
#Region	===== association GUI
	$aGUI = GUICreate("Edit Associations", 550, 490, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOOLWINDOW, $nGUI)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_aGUIClose") ; close button (X) = Done
	; association list and editor labels
	$lSec = GUICtrlCreateList("", 10, 34, 108, 430, BitOR($LBS_SORT, $WS_HSCROLL, $WS_VSCROLL))
	GUICtrlCreateLabel("Associations", 10, 12, 100, 18)
	GUICtrlCreateLabel("Association Name", 136, 66, 110, 18)
	GUICtrlCreateLabel("Associated Types (extensions)", 286, 66, 235, 18)
	GUICtrlCreateLabel("Also add to", 136, 118, 200, 18)
	GUICtrlCreateLabel("Context-menu title", 136, 192, 140, 18)
	GUICtrlCreateLabel("Context-menu icon", 136, 244, 140, 18)
	GUICtrlCreateLabel("Icon index", 458, 244, 70, 18)
	GUICtrlCreateLabel("Command", 136, 299, 70, 18)
	GUICtrlCreateLabel("Drive Command", 136, 349, 110, 18)
	GUICtrlCreateLabel("Folder Command", 136, 399, 110, 18)
	$aMutedLbl[2][0] = GUICtrlCreateLabel("%1 = one file, %%1 = all selected files, %V = current folder (background).", 136, 448, 400, 16)
	$aMutedLbl[2][1] = 0x666666
	GUICtrlSetFont(-1, 8, 400, 2)
	GUICtrlSetColor(-1, 0x666666)
	; editor inputs
	$iSec = GUICtrlCreateInput("", 136, 86, 130, 23)
	GUICtrlSetTip(-1, "Internal association name. Cannot include ',' or '*'.")
	$iMode = GUICtrlCreateInput("", 286, 86, 235, 23)
	GUICtrlSetTip(-1, "File extensions only, separated by | (for example: txt|md|log)." & @CRLF & _
		"Files, folders, drives, recycle bin and background are the tick boxes below." & @CRLF & _
		"Disabled while ""Files"" is ticked (all files).")
	; special targets (tick boxes)
	$chkFiles = GUICtrlCreateCheckbox("Files", 136, 136, 56, 20)
	GUICtrlSetTip(-1, "All files (wildcard *). The extension list is not needed and is disabled.")
	$chkFolders = GUICtrlCreateCheckbox("Folders", 193, 136, 68, 20)
	GUICtrlSetTip(-1, "All folders.")
	$chkDrives = GUICtrlCreateCheckbox("Drives", 263, 136, 62, 20)
	GUICtrlSetTip(-1, "All drives. Drives have their own ""Drive Command"".")
	$chkRecycle = GUICtrlCreateCheckbox("Recycle Bin", 327, 136, 95, 20)
	GUICtrlSetTip(-1, "The Recycle Bin.")
	$chkBackground = GUICtrlCreateCheckbox("Background", 424, 136, 98, 20)
	GUICtrlSetTip(-1, "Empty space of a folder window and of the desktop (like ""Open Terminal here"")." & @CRLF & "Use %V for the folder, e.g.  wt.exe -d ""%V"".")
	$disChk = GUICtrlCreateCheckbox("Disabled", 136, 164, 90, 20)
	GUICtrlSetTip(-1, "Disable this association without deleting its settings.")
	$singleChk = GUICtrlCreateCheckbox("Single file type", 236, 164, 135, 20)
	GUICtrlSetTip(-1, "Show this association only when ONE item is selected (hidden when several are selected)." & @CRLF & "Applies to Files, Folders, Drives and extension types (e.g. iso).")
	$iTitle = GUICtrlCreateInput("", 136, 212, 385, 23)
	GUICtrlSetTip(-1, "Text displayed in the Windows context menu.")
	$iAssocIcon = GUICtrlCreateInput("", 136, 264, 250, 23)
	GUICtrlSetTip(-1, "Optional icon file. Supports ICO, EXE and DLL files; relative paths are portable.")
	$iAssocIconBrowse = GUICtrlCreateButton("Browse...", 392, 263, 60, 25)
	$iAssocIconIndex = GUICtrlCreateInput("0", 458, 264, 42, 23)
	GUICtrlSetTip(-1, "Icon resource index. Usually 0 for ICO files.")
	$iAssocIconPreview = GUICtrlCreateIcon("", "", 506, 260, 32, 32)
	$iCommand = GUICtrlCreateInput("", 136, 319, 385, 23)
	GUICtrlSetTip(-1, "%1 = selected file, folder or drive (one run per item)." & @CRLF & "%%1 = ALL selected items in one run, e.g.  FastCopy.exe %%1  ->  FastCopy.exe ""file1"" ""file2"" ""file3""" & @CRLF & "%V = current folder (background).")
	$bBtn = GUICtrlCreateButton("...", 526, 319, 20, 23)
	$iDriveCmd = GUICtrlCreateInput("", 136, 369, 385, 23)
	GUICtrlSetTip(-1, "Command used for drives (only available when ""Drives"" is ticked)." & @CRLF & "Use %1 or %V WITHOUT quotes: a drive path like E:\ ends with a backslash." & @CRLF & "Example:  E:\PortableApps\Terminal\Terminal.exe -d %1" & @CRLF & "If empty, the Command is used for drives too.")
	$bBtnDrive = GUICtrlCreateButton("...", 526, 369, 20, 23)
	$iFolderCmd = GUICtrlCreateInput("", 136, 419, 385, 23)
	GUICtrlSetTip(-1, "Command used for folders (only available when ""Folders"" is ticked)." & @CRLF & "Use %1 for the folder, e.g.  FastCopy.exe ""%1""   or  %%1 for all selected folders in one run." & @CRLF & "If empty, the Command is used for folders too (when the association also has other targets).")
	$bBtnFolder = GUICtrlCreateButton("...", 526, 419, 20, 23)
	$runAdminChk = GUICtrlCreateCheckbox("Run as Admin", 376, 164, 145, 20)
	GUICtrlSetTip(-1, "Run the command with administrator rights (UAC prompt)." & @CRLF & "Use this for programs that need admin access. Not used for the Recycle Bin.")
	; action buttons
	$cBtn = GUICtrlCreateButton("Clear", 136, 24, 55, 27)
	$sBtn = GUICtrlCreateButton("Save", 202, 24, 55, 27)
	$delBtn = GUICtrlCreateButton("Delete", 268, 24, 55, 27)
	$dBtn = GUICtrlCreateButton("Done", 456, 24, 65, 27)
	$hBtn = GUICtrlCreateButton("?", 510, 8, 20, 18)
	GUICtrlSetCursor(-1, 4)

	; control events
	GUICtrlSetOnEvent($lSec, "_GetAssocInfo") ; click a list item
	GUICtrlSetOnEvent($cBtn, "_RefreshAssocGUI") ; clear button
	GUICtrlSetOnEvent($sBtn, "_SaveAssocSection") ; save button
	GUICtrlSetOnEvent($delBtn, "_DeleteAssocSection") ; delete button
	GUICtrlSetOnEvent($dBtn, "_aGUIClose") ; done button
	GUICtrlSetOnEvent($hBtn, "_AssocHelp") ; help button
	GUICtrlSetOnEvent($bBtn, "_BrowseCommand") ; browse command target
	GUICtrlSetOnEvent($bBtnDrive, "_BrowseDriveCommand")
	GUICtrlSetOnEvent($bBtnFolder, "_BrowseFolderCommand") ; browse drive command target
	GUICtrlSetOnEvent($iAssocIconBrowse, "_BrowseAssocIcon") ; browse context-menu icon
	GUICtrlSetOnEvent($chkFiles, "_AssocUpdateControls") ; target tick boxes enable / disable inputs
	GUICtrlSetOnEvent($chkFolders, "_AssocUpdateControls")
	GUICtrlSetOnEvent($chkDrives, "_AssocUpdateControls")
	GUICtrlSetOnEvent($chkRecycle, "_AssocUpdateControls")
	GUICtrlSetOnEvent($chkBackground, "_AssocUpdateControls")
	_AssocUpdateControls()
#EndRegion ===== association GUI
#Region	===== types GUI
	$tGUI = GUICreate("Configure File Types", 465, 340, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOOLWINDOW, $nGUI)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_tGUIClose") ; close button (X) = Done

	GUICtrlCreateLabel("Association:", 10, 13)
	$ftypeAssocFilter = GUICtrlCreateCombo("", 78, 8, 180, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	GUICtrlSetTip(-1, "Filter the file types by their association name. Choose All to show every extension.")
	GUICtrlCreateLabel("File Type:", 10, 48)
	$ftypelist = GUICtrlCreateCombo("", 62, 43, 78, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	GUICtrlCreateLabel("Default PFA Association:", 10, 93)
	$defassoclist = GUICtrlCreateCombo("", 10, 113, 200, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	GUICtrlSetTip(-1, "Default PFA association for the selected extension (dbl-click action).")
	$hideext = GUICtrlCreateCheckbox("Hide extension", 160, 40)
	GUICtrlSetTip(-1, "Prevent this extension from displaying in Explorer.")
	$copyhost = GUICtrlCreateCheckbox("Copy Host Associations", 160, 60)
	GUICtrlSetTip(-1, "Copy any associations present on the Host computer for this extension.")
	$hostoverride = GUICtrlCreateCheckbox("Host Precedence", 180, 80)
	GUICtrlSetTip(-1, "If host default association exists, it will take precedence over the PFA default.")
	GUICtrlCreateLabel("", 312, 38, 52, 52, $SS_BLACKFRAME) ; icon frame
	$icondisplay = GUICtrlCreateIcon("", "", 314, 40, 48, 48)
	GUICtrlCreateLabel("Index:", 379, 47)
	$iconindex = GUICtrlCreateInput("0", 379, 67, 55, 23)
	$indexupdown = GUICtrlCreateUpdown($iconindex, BitOR($UDS_ALIGNRIGHT, $UDS_NOTHOUSANDS))
	GUICtrlSetTip(-1, "Icon index in a multi-icon file (exe or dll).")
	GUICtrlSetLimit(-1, 0, -10000)
	GUICtrlCreateLabel("Iconfile (exe, dll, or ico):", 10, 146)
	$ftypeicon = GUICtrlCreateInput("", 10, 166, 400, 20)
	GUICtrlSetTip(-1, "Icon to display when a Host computer association is not the default action.")
	$iconbrowse = GUICtrlCreateButton("...", 415, 170, 20, 16)
	$showNewMenu = GUICtrlCreateCheckbox("Show in New menu in context menu", 10, 196, 245, 20)
	GUICtrlSetTip(-1, "Add this file type to Explorer right-click > New submenu.")
	GUICtrlCreateLabel("New menu name:", 10, 223)
	$newMenuName = GUICtrlCreateInput("", 105, 219, 345, 22)
	GUICtrlSetTip(-1, "Display name shown under right-click > New. Default: PFA_<extension> File.")
	$useTemplate = GUICtrlCreateCheckbox("Use template file", 10, 253, 150, 20)
	GUICtrlSetTip(-1, "Use Data\newitems\{UPPERCASE_EXTENSION}.{extension}. No custom template selection.")
	$templateFile = GUICtrlCreateInput("", 10, 278, 440, 22, $ES_READONLY)
	GUICtrlSetTip(-1, "PFA automatically looks for this exact filename inside Data\newitems.")
	$savetypes = GUICtrlCreateButton("Save File Type", 117, 307, 105, 25)
	$donetypes = GUICtrlCreateButton("Done", 243, 307, 75, 25)
	; control events
	GUICtrlSetOnEvent($ftypeAssocFilter, "_FtypeAssocFilterChange")
	GUICtrlSetOnEvent($ftypelist, "_FtypeChange")
	GUICtrlSetOnEvent($copyhost, "_CopyHostToggle")
	GUICtrlSetOnEvent($iconbrowse, "_BrowseIcon")
	GUICtrlSetOnEvent($savetypes, "_SaveTypes")
	GUICtrlSetOnEvent($donetypes, "_tGUIClose")
	GUICtrlSetOnEvent($showNewMenu, "_ShowNewToggle")
	GUICtrlSetOnEvent($useTemplate, "_TemplateToggle")
	GUICtrlSetOnEvent($indexupdown, "_GetIcon")
#EndRegion ===== types GUI
#Region ===== SendTo GUI
	$sGUI = GUICreate("SendTo Configuration", 600, 315, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOOLWINDOW, $nGUI)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_sCloseGUI") ; close button (X) = Done
	$hsLV = _GUICtrlListView_Create($sGUI, "Shortcut Name|Path", 5, 5, 590, 250, BitOR($WS_BORDER, $LVS_NOSORTHEADER, $LVS_REPORT, $LVS_SHOWSELALWAYS), _
																					$WS_EX_ACCEPTFILES)
	_GUICtrlListView_SetExtendedListViewStyle($hsLV, BitOR($LVS_EX_DOUBLEBUFFER, $LVS_EX_FULLROWSELECT), BitOR($LVS_EX_DOUBLEBUFFER, $LVS_EX_FULLROWSELECT))
	_GUICtrlListView_SetColumnWidth($hsLV, 0, 130)
	_GUICtrlListView_SetColumnWidth($hsLV, 1, $LVSCW_AUTOSIZE_USEHEADER)
	; subclass the control so we can get our dropfiles message
	$pWndProc = DllCallbackRegister("_MY_WINDOW_PROC", "int", "hwnd;uint;wparam;lparam")
	$oldWndProc = _WinAPI_SetWindowLong($hsLV, $GWL_WNDPROC, DllCallbackGetPtr($pWndProc))
	$aMutedLbl[3][0] = GUICtrlCreateLabel("Click Add... or drag-and-drop to add SendTo targets.", 6, 260)
	$aMutedLbl[3][1] = 0x555555
	GUICtrlSetFont(-1, 8, 400, 2)
	GUICtrlSetColor(-1, 0x555555)
	$sAdd = GUICtrlCreateButton("Add...", 5, 285, 50, 25)
	$sRemove = GUICtrlCreateButton("Remove", 60, 285, 50, 25)
	$sClear = GUICtrlCreateButton("Clear", 115, 285, 50, 25)
	$sSave = GUICtrlCreateButton("Save", 490, 285, 50, 25)
	$sDone = GUICtrlCreateButton("Done", 545, 285, 50, 25)
	$sDummy = GUICtrlCreateDummy()

	GUICtrlSetOnEvent($sAdd, "_AddSendTo")
	GUICtrlSetOnEvent($sClear, "_ClearSendTo")
	GUICtrlSetOnEvent($sRemove, "_RemoveSendTo")
	GUICtrlSetOnEvent($sSave, "_SaveSendTo")
	GUICtrlSetOnEvent($sDummy, "_sDropAction")
	GUICtrlSetOnEvent($sDone, "_sCloseGUI")
#EndRegion ===== SendTo GUI

#Region	===== Settings GUI
	$stGUI = GUICreate("Settings", 360, 340, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOOLWINDOW, $nGUI)
	GUISetFont(9, 400, 0, "Segoe UI", $stGUI)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_SettingsClose") ; close button (X) = Done
	GUICtrlCreateLabel("Theme:", 20, 22, 60, 20)
	$stTheme = GUICtrlCreateCombo("", 84, 18, 140, 24, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	GUICtrlSetTip(-1, "System follows the Windows app theme.")
	$stAddStart = GUICtrlCreateCheckbox("Add associations on start", 20, 62, 320, 22)
	GUICtrlSetTip(-1, "Add the associations of the active profile automatically when PFA starts.")
	$stRemoveExit = GUICtrlCreateCheckbox("Remove associations on exit", 20, 90, 320, 22)
	GUICtrlSetTip(-1, "Remove the associations again when PFA is closed.")
	$stCheckUpd = GUICtrlCreateCheckbox("Check for updates on startup", 20, 118, 320, 22)
	GUICtrlSetTip(-1, "Look for a newer version in the background each time PFA starts.")
	$stStartMin = GUICtrlCreateCheckbox("Start minimized (to the tray)", 20, 146, 320, 22)
	GUICtrlSetTip(-1, "Off: the main window is shown when PFA starts.")
	$stNoSplash = GUICtrlCreateCheckbox("Disable splash screen", 20, 174, 320, 22)
	GUICtrlSetTip(-1, "Saved as DisableSplash=true in FileAssociatorPortable.ini (next to the exe).")
	$stCloseTray = GUICtrlCreateCheckbox("Close button (X) minimizes to the tray", 20, 202, 320, 22)
	GUICtrlSetTip(-1, "Off: the close button exits PFA.")
	$aMutedLbl[4][0] = GUICtrlCreateLabel("Settings are saved at once in Data\settings\settings.ini (the splash setting in FileAssociatorPortable.ini, next to the exe). Profiles keep their own files.", 20, 244, 320, 48)
	$aMutedLbl[4][1] = 0x666666
	GUICtrlSetFont(-1, 8, 400, 2)
	GUICtrlSetColor(-1, 0x666666)
	$stDone = GUICtrlCreateButton("Done", 265, 300, 75, 28)
	GUICtrlSetOnEvent($stTheme, "_ThemeEvent")
	GUICtrlSetOnEvent($stAddStart, "_SettingsApply")
	GUICtrlSetOnEvent($stRemoveExit, "_SettingsApply")
	GUICtrlSetOnEvent($stCheckUpd, "_SettingsApply")
	GUICtrlSetOnEvent($stStartMin, "_SettingsApply")
	GUICtrlSetOnEvent($stNoSplash, "_SettingsApply")
	GUICtrlSetOnEvent($stCloseTray, "_SettingsApply")
	GUICtrlSetOnEvent($stDone, "_SettingsClose")
	_SettingsSync()
#EndRegion ===== Settings GUI
#Region	===== Readme GUI
	; the Readme is built into the program (see _ReadmeText), it is shown in this window, no file is written or opened
	$rdGUI = GUICreate("Readme", 940, 600, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOOLWINDOW, $nGUI)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_ReadmeClose") ; close button (X) = Close
	$rdEdit = GUICtrlCreateEdit("", 10, 10, 920, 545, BitOR($ES_READONLY, $ES_AUTOVSCROLL, $ES_AUTOHSCROLL, $WS_VSCROLL, $WS_HSCROLL))
	GUICtrlSetFont(-1, 9, 400, 0, "Consolas")
	GUICtrlSetLimit(-1, 2000000)
	$rdClose = GUICtrlCreateButton("Close", 855, 562, 75, 28)
	GUICtrlSetOnEvent($rdClose, "_ReadmeClose")
#EndRegion ===== Readme GUI

	_ThemeApply() ; apply light / dark theme to all GUIs

	; populate profile list
	_PopulateProfiles()

	GUISwitch($nGUI) ; switch to main GUI
	; add_gui (command line) = add the associations and start minimized.  Without arguments the Settings decide.
	Local $fAddNow = ($guimode = "add_gui" Or ($guimode = "" And $fSetAddStart))
	Local $fMinNow = ($guimode = "add_gui" Or ($guimode = "" And $fSetStartMin))
	If $fAddNow Then _AddAssociations() ; add the associations while the splash screen is shown (no extra waiting time)
	_SplashHide($hSplash, $hSplashTimer)
	If $fMinNow Then
		GUISetState(@SW_SHOWMINNOACTIVE)
	Else
		GUISetState(@SW_SHOW) ; show main GUI
	EndIf
EndFunc
#EndRegion GUI Creation Functions (all GUIs)
#Region Main GUI Functions
Func _PopulateProfiles()
	Local $search = FileFindFirstFile($settingsdir & "\*_assoc.ini")
	If $search = -1 Then Return

	Local $profiles = ""
	While 1
		Local $item = FileFindNextFile($search)
		If @error Then ExitLoop

		Local $str = StringLeft($item, StringInStr($item, "_", 0, -1) - 1)
		If $str <> "" Then $profiles &= "|" & $str
	WEnd
	FileClose($search)
	GUICtrlSetData($nProfile, $profiles, $curProfile)
EndFunc

Func _SetProfileEvent()
	_SetProfile()
EndFunc

Func _SetProfile($profile = "")
	; sets the active profile, creates one if it doesn't exist
	If $profile = "" Then
		$curProfile = GUICtrlRead($nProfile) ; read profile
	Else
		$curProfile = $profile
	EndIf

	; set INIs
	IniWrite($profileini, "profile", "active", $curProfile)
	$stateini = $settingsdir & "\" & $curProfile & "_state.ini"
	$associni = $settingsdir & "\" & $curProfile & "_assoc.ini"
	$typesini = $settingsdir & "\" & $curProfile & "_types.ini"
	$sendtoini = $settingsdir & "\" & $curProfile & "_sendto.ini"

	; create new profile INI files
	If Not FileExists($associni) Then
		IniWrite($associni, "Default", "mode", "txt")
		IniWrite($associni, "Default", "title", "|| Open with Notepad")
		IniWrite($associni, "Default", "command", '''notepad.exe "%1"''')
		IniWrite($associni, "Default", "disabled", $GUI_UNCHECKED)
	EndIf
	_MigrateAssocINI() ; older INI: drives / files / folders / recycle / background moved from "mode" to tick boxes
	_MigrateFolderCmd() ; older INI: folders-only command moved to its own Folder Command
	If Not FileExists($stateini) Then
		IniWrite($stateini, "state", "state", "0")
		IniWrite($stateini, "state", "version", $version)
	EndIf

	; version checks and upgrades for existing profiles
	If _VersionCheckInternal(IniRead($stateini, "state", "version", "0.0.0.0")) Then
		; set current version
		IniWrite($stateini, "state", "version", $version)
		; fix my mistake
		For $i = 0 To UBound($blacklist) - 1
			IniDelete($typesini, $blacklist[$i])
			RegDelete("HKCU\Software\Classes\PortableFileAssoc_" & $blacklist[$i])
		Next
		; remove pending entry
		IniDelete($stateini, "state", "pending")
		; rename old _icons.ini
		FileMove($settingsdir & "\" & $curProfile & "_icons.ini", $typesini)
		; convert PDRIVE tokens in old command paths and create relative paths, remove 'default' key from _assoc.ini
		_ConvertPaths()
	EndIf

	; refresh everything
	_InitTypesINI()
	_ReadStateINI()
EndFunc

Func _NewProfile()
	Local $newname = _GetNewProfileName()
	If $newname <> "" Then
		_SetProfile($newname)
		_PopulateProfiles()
	EndIf
EndFunc

Func _CloneProfile()
	Local $newname = _GetNewProfileName()
	If $newname <> "" Then
		For $i = 0 To UBound($aProfileINIs) - 1
			FileCopy($associni, $settingsdir & "\" & $newname & $aProfileINIs[$i])
		Next
		_SetProfile($newname)
		_PopulateProfiles()
	EndIf
EndFunc

Func _GetNewProfileName()
	Local $i = 1
	Local $newname = "New" & $i
	While FileExists($settingsdir & "\" & $newname & "_assoc.ini")
		$i += 1
		$newname = "New" & $i
	WEnd
	Return _VerifyProfileName($newname)
EndFunc

Func _VerifyProfileName($newname)
	While 1
		$newname = StringStripWS(InputBox("Profiles...", "Enter new profile name:", $newname, "", 220, 130, Default, Default, 0, $nGUI), 3) ; spaces inside the name are kept
		If StringRegExp($newname, '[\\/:*?"<>|]') Then
			MsgBox(48, "Error", "Name cannot contain illegal characters:" & @CRLF & @TAB & '\ / : * ? " < > |', 0, $nGUI)
		ElseIf FileExists($settingsdir & "\" & $newname & "_assoc.ini") Then
			MsgBox(48, "Error", "Profile already exists.", 0, $nGUI)
		Else
			ExitLoop
		EndIf
	WEnd
	Return $newname
EndFunc

Func _RenameProfile()
	Local $newname = _VerifyProfileName(GUICtrlRead($nProfile))
	If $newname <> "" Then
		For $i = 0 To UBound($aProfileINIs) - 1
			FileMove($associni, $settingsdir & "\" & $newname & $aProfileINIs[$i])
		Next
		_SetProfile($newname)
		_PopulateProfiles()
	EndIf
EndFunc

Func _RemoveProfile()
	If 7 = MsgBox(4 + 32, "Profiles...", "Really remove profile '" & GUICtrlRead($nProfile) & "'?" & @CRLF & _
					"This operation cannot be undone.", 0, $nGUI) Then Return
	FileDelete($settingsdir & "\" & GUICtrlRead($nProfile) & "_*.ini")
	_SetProfile(_GetNextProfile())
	_PopulateProfiles()
EndFunc

Func _GetNextProfile()
	Local $profile, $search = FileFindFirstFile($settingsdir & "\*_assoc.ini")
	If $search = -1 Then
		$profile = "default"
	Else
		Local $item = FileFindNextFile($search)
		$profile = StringLeft($item, StringInStr($item, "_", 0, -1) - 1)
		FileClose($search)
	EndIf
	Return $profile
EndFunc

Func _ActionButtonsState()
	If $state = 0 Then
		GUICtrlSetState($Button1, $GUI_ENABLE)
		GUICtrlSetState($Button2, $GUI_DISABLE) ; disable remove button
		GUICtrlSetState($Button3, $GUI_ENABLE)
		GUICtrlSetState($nProfile, $GUI_ENABLE)
		GUICtrlSetState($nNew, $GUI_ENABLE)
		GUICtrlSetState($nClone, $GUI_ENABLE)
		GUICtrlSetState($nRename, $GUI_ENABLE)
		GUICtrlSetState($nRemove, $GUI_ENABLE)
		_ProfileIconsSet(True)
	Else
		GUICtrlSetState($Button1, $GUI_DISABLE) ; disable add button
		GUICtrlSetState($Button2, $GUI_ENABLE)
		GUICtrlSetState($Button3, $GUI_DISABLE) ; disable edit button
		GUICtrlSetState($nProfile, $GUI_DISABLE) ; disable profile controls
		GUICtrlSetState($nNew, $GUI_DISABLE)
		GUICtrlSetState($nClone, $GUI_DISABLE)
		GUICtrlSetState($nRename, $GUI_DISABLE)
		GUICtrlSetState($nRemove, $GUI_DISABLE)
		_ProfileIconsSet(False)
	EndIf
EndFunc

Func _AddAssociations()
	_FileAssociations("add")
	_ActionButtonsState() ; set button states
	TraySetToolTip("FileAssociatorPortable (enabled)" & @CRLF & "Profile:  " & $curProfile) ; set tooltip
EndFunc

Func _RemoveAssociations()
	_FileAssociations("remove")
	_ActionButtonsState() ; set button states
	TraySetToolTip("FileAssociatorPortable (disabled)") ; set tooltip
EndFunc

Func _MainClose()
	If $fSetCloseTray Then
		_HideMainGUI() ; close button minimizes to the tray (Settings)
	Else
		_Exit()
	EndIf
EndFunc

Func _HideMainGUI()
	GUISetState(@SW_MINIMIZE, $nGUI)
	GUISetState(@SW_HIDE, $nGUI)
EndFunc

Func _RestoreMainGUI()
	GUISetState(@SW_SHOW, $nGUI)
	GUISetState(@SW_RESTORE, $nGUI)
EndFunc
#EndRegion Main GUI Functions
#Region System Restore functions
Func _CreateRestorePoint()
	Local $name = InputBox("System Restore", "Enter a name for this restore point:", "", " M", 275, 140, Default, Default, 0, $nGUI)
	If $name <> "" Then
		Local $objSR = ObjGet("winmgmts:{impersonationLevel=impersonate}!root/default:SystemRestore")
		If Not IsObj($objSR) Then
			MsgBox(48, "Error", "Could not access System Restore.", 0, $nGUI)
			Return
		EndIf
		GUISetCursor(15, 1, $nGUI)
		Local $ret = $objSR.CreateRestorePoint($name, 12, 100) ; APPLICATION_INSTALL, BEGIN_SYSTEM_CHANGE
		GUISetCursor()
		If $ret Then MsgBox(48, "Error", "Error creating Restore Point.", 0, $nGUI)
		$objSR = 0
	EndIf
EndFunc
#EndRegion System Restore functions
#Region Association GUI Functions
;=======================================================================================
; Association GUI Functions
;=======================================================================================

Func _EditAssocINI()
	_RefreshAssocGUI()
	GUISetState(@SW_DISABLE, $nGUI) ; disable main GUI
	WinSetTitle($aGUI, "", "Edit Associations - " & $curProfile)
	GUISetState(@SW_SHOW, $aGUI) ; show assoc GUI
EndFunc

Func _RefreshAssocGUI()
	Local $section, $aListdata[1] = [0], $i

	$section = _ReadINISections() ; get sections
	For $i = 1 To $section[0]
		_ArrayAdd($aListdata, $section[$i])
		If Number(IniRead($associni, $section[$i], "disabled", $GUI_UNCHECKED)) = $GUI_CHECKED Then $aListdata[$i] &= " **" ; mark disabled associations
	Next
	_ArraySort($aListdata, 0, 1)
	GUICtrlSetData($lSec, "|" & _ArrayToString($aListdata, "|", 1)) ; set control data
	GUICtrlSetData($iSec, "")
	GUICtrlSetData($iMode, "")
	GUICtrlSetData($iTitle, "")
	GUICtrlSetData($iCommand, "")
	GUICtrlSetData($iDriveCmd, "")
	GUICtrlSetData($iFolderCmd, "")
	GUICtrlSetData($iAssocIcon, "")
	GUICtrlSetData($iAssocIconIndex, "0")
	GUICtrlSetImage($iAssocIconPreview, "", 0)
	GUICtrlSetState($disChk, $GUI_UNCHECKED)
	GUICtrlSetState($singleChk, $GUI_UNCHECKED)
	GUICtrlSetState($chkFiles, $GUI_UNCHECKED)
	GUICtrlSetState($chkFolders, $GUI_UNCHECKED)
	GUICtrlSetState($chkDrives, $GUI_UNCHECKED)
	GUICtrlSetState($chkRecycle, $GUI_UNCHECKED)
	GUICtrlSetState($chkBackground, $GUI_UNCHECKED)
	GUICtrlSetState($runAdminChk, $GUI_UNCHECKED)
	_AssocUpdateControls()
EndFunc

Func _GetAssocInfo()
	Local $tSec, $tMode, $tTitle, $tCommand, $tDrive, $tFolder, $sDisabled, $sIcon, $aIcon, $sRaw

	$tSec = StringReplace(GUICtrlRead($lSec), ' **', '') ; get selection, remove ' **'
	$tMode = IniRead($associni, $tSec, "mode", "") ; read INI data
	$tTitle = IniRead($associni, $tSec, "title", "")
	$tCommand = ""
	$sRaw = IniRead($associni, $tSec, "command", "")
	If $sRaw <> "" Then $tCommand = _GetFullCommand($sRaw)
	$tDrive = ""
	$sRaw = IniRead($associni, $tSec, "drivecommand", "")
	If $sRaw <> "" Then $tDrive = _GetFullCommand($sRaw)
	$tFolder = ""
	$sRaw = IniRead($associni, $tSec, "foldercommand", "")
	If $sRaw <> "" Then $tFolder = _GetFullCommand($sRaw)
	$sIcon = IniRead($associni, $tSec, "icon", "")
	$sDisabled = Number(IniRead($associni, $tSec, "disabled", $GUI_UNCHECKED)) ; 4 = unchecked
	GUICtrlSetData($iSec, $tSec) ; set control data
	GUICtrlSetData($iMode, $tMode)
	GUICtrlSetData($iTitle, $tTitle)
	GUICtrlSetData($iCommand, $tCommand)
	GUICtrlSetData($iDriveCmd, $tDrive)
	GUICtrlSetData($iFolderCmd, $tFolder)
	$aIcon = _ParseAssocIcon($sIcon)
	GUICtrlSetData($iAssocIcon, $aIcon[0])
	GUICtrlSetData($iAssocIconIndex, $aIcon[1])
	_UpdateAssocIconPreview()
	GUICtrlSetState($disChk, $sDisabled)
	_AssocSetChk($singleChk, Number(IniRead($associni, $tSec, "single", 0)) = 1)
	_AssocSetChk($chkFiles, _AssocFlag($tSec, "files"))
	_AssocSetChk($chkFolders, _AssocFlag($tSec, "folders"))
	_AssocSetChk($chkDrives, _AssocFlag($tSec, "drives"))
	_AssocSetChk($chkRecycle, _AssocFlag($tSec, "recycle"))
	_AssocSetChk($chkBackground, _AssocFlag($tSec, "background"))
	_AssocSetChk($runAdminChk, _AssocFlag($tSec, "admin"))
	_AssocUpdateControls()
EndFunc

Func _SaveAssocSection()
	Local $tSec, $tMode, $tTitle, $tCommand, $tDrive, $tFolder, $sDisabled, $atCommand[1], $sIcon, $i, $aChk
	Local $bFiles, $bFolders, $bDrives, $bRecycle, $bBackground, $bOther, $bDriveOnly, $bUsesMain

	$tSec = StringStripWS(GUICtrlRead($iSec), 8) ; get section to save, no spaces
	If $tSec = "" Then
		MsgBox(0 + 48, "Error", "Association Name cannot be blank.", 0, $aGUI)
		Return
	EndIf
	If StringInStr($tSec, '*') Or StringInStr($tSec, ',') Then
		MsgBox(0 + 48, "Error", "Association Name cannot contain ',' or '*' characters.", 0, $aGUI)
		Return
	EndIf

	; targets: tick boxes + file extensions
	$bFiles = _IsChk($chkFiles)
	$bFolders = _IsChk($chkFolders)
	$bDrives = _IsChk($chkDrives)
	$bRecycle = _IsChk($chkRecycle)
	$bBackground = _IsChk($chkBackground)
	$tMode = StringStripWS(GUICtrlRead($iMode), 8) ; extensions, no spaces
	If $bFiles Then $tMode = "" ; "Files" = every file (* wildcard), extensions are not needed
	$aChk = _SplitAssociationModes($tMode)
	For $i = 1 To $aChk[0]
		Switch StringLower($aChk[$i])
			Case "file", "files", "folder", "folders", "drive", "drives", "recycle", "background"
				MsgBox(0 + 48, "Error", "'" & $aChk[$i] & "' is not a file extension." & @CRLF & _
						"Use the tick boxes (Files, Folders, Drives, Recycle Bin, Background) for these targets.", 0, $aGUI)
				Return
		EndSwitch
	Next
	$bUsesMain = ($bFiles Or $bRecycle Or $bBackground Or $tMode <> "") ; targets that use the main Command
	If Not $bUsesMain And Not $bFolders And Not $bDrives Then
		MsgBox(0 + 48, "Error", "Select at least one target: enter file extensions or tick Files, Folders, Drives, Recycle Bin or Background.", 0, $aGUI)
		Return
	EndIf

	$tCommand = GUICtrlRead($iCommand)
	$tDrive = GUICtrlRead($iDriveCmd)
	$tFolder = GUICtrlRead($iFolderCmd)
	If Not $bDrives Then $tDrive = ""
	If Not $bFolders Then $tFolder = ""
	If StringStripWS($tDrive, 8) = "" Then $tDrive = ""
	If StringStripWS($tFolder, 8) = "" Then $tFolder = ""
	If Not $bUsesMain Then
		$tCommand = "" ; only folders / drives: they use their own commands
		If $bDrives And $tDrive = "" Then
			MsgBox(0 + 48, "Error", "Drive Command cannot be blank when the association is only for drives (and folders).", 0, $aGUI)
			Return
		EndIf
		If $bFolders And $tFolder = "" Then
			MsgBox(0 + 48, "Error", "Folder Command cannot be blank when the association is only for folders (and drives).", 0, $aGUI)
			Return
		EndIf
	ElseIf StringStripWS($tCommand, 8) = "" Then
		MsgBox(0 + 48, "Error", "Command cannot be blank.", 0, $aGUI)
		Return
	EndIf

	IniReadSection($associni, $tSec) ; check if section exists and warn
	If Not @error Then
		If 7 = MsgBox(4 + 32 + 256, "Save INI Section", "Section exists.  Overwrite?", 0, $aGUI) Then Return
	EndIf

	$tTitle = GUICtrlRead($iTitle)
	If GUICtrlRead($iAssocIcon) <> "" And Not FileExists(GUICtrlRead($iAssocIcon)) Then
		MsgBox(48, "Context-menu icon", "The selected icon file does not exist:" & @CRLF & GUICtrlRead($iAssocIcon), 0, $aGUI)
		Return
	EndIf
	If $tCommand <> "" Then
		$atCommand = _CommandSplit($tCommand)
		If StringInStr($atCommand[0], "%") Then
			MsgBox(0 + 48, "Error", "Command cannot use environment variables.", 0, $aGUI)
			Return
		EndIf
	EndIf
	If $tDrive <> "" Then
		$atCommand = _CommandSplit($tDrive)
		If StringInStr($atCommand[0], "%") Then
			MsgBox(0 + 48, "Error", "Drive Command cannot use environment variables.", 0, $aGUI)
			Return
		EndIf
	EndIf
	If $tFolder <> "" Then
		$atCommand = _CommandSplit($tFolder)
		If StringInStr($atCommand[0], "%") Then
			MsgBox(0 + 48, "Error", "Folder Command cannot use environment variables.", 0, $aGUI)
			Return
		EndIf
	EndIf
	If BitAND(GUICtrlRead($disChk), $GUI_CHECKED) Then
		$sDisabled = $GUI_CHECKED
	Else
		$sDisabled = $GUI_UNCHECKED
	EndIf

	IniWrite($associni, $tSec, "mode", $tMode) ; write INI data (extensions only)
	IniWrite($associni, $tSec, "title", $tTitle)
	If $tCommand = "" Then
		IniDelete($associni, $tSec, "command")
	Else
		IniWrite($associni, $tSec, "command", "'" & _GetRelCommand($tCommand) & "'")
	EndIf
	If $tDrive = "" Then
		IniDelete($associni, $tSec, "drivecommand")
	Else
		IniWrite($associni, $tSec, "drivecommand", "'" & _GetRelCommand($tDrive) & "'")
	EndIf
	If $tFolder = "" Then
		IniDelete($associni, $tSec, "foldercommand")
	Else
		IniWrite($associni, $tSec, "foldercommand", "'" & _GetRelCommand($tFolder) & "'")
	EndIf
	_AssocWriteFlag($tSec, "files", $bFiles)
	_AssocWriteFlag($tSec, "folders", $bFolders)
	_AssocWriteFlag($tSec, "drives", $bDrives)
	_AssocWriteFlag($tSec, "recycle", $bRecycle)
	_AssocWriteFlag($tSec, "background", $bBackground)
	$sIcon = _GetRelAssocIcon(GUICtrlRead($iAssocIcon), Number(GUICtrlRead($iAssocIconIndex)))
	If $sIcon = "" Then
		IniDelete($associni, $tSec, "icon")
	Else
		IniWrite($associni, $tSec, "icon", $sIcon)
	EndIf
	IniWrite($associni, $tSec, "disabled", $sDisabled) ; 1 = checked, 4 = unchecked
	_AssocWriteFlag($tSec, "single", _IsChk($singleChk))
	_AssocWriteFlag($tSec, "admin", _IsChk($runAdminChk)) ; run as administrator ; single selected item only
	_RefreshAssocGUI()
EndFunc

Func _ParseAssocIcon($sIcon)
	Local $aResult[2] = ["", "0"], $iComma
	$sIcon = StringReplace($sIcon, '"', '')
	$iComma = StringInStr($sIcon, ",", 0, -1)
	If $iComma > 0 Then
		$aResult[0] = StringLeft($sIcon, $iComma - 1)
		$aResult[1] = StringTrimLeft($sIcon, $iComma)
	Else
		$aResult[0] = $sIcon
	EndIf
	If Not StringIsInt($aResult[1]) Then $aResult[1] = "0"
	If Number($aResult[1]) <> 0 Then $aResult[1] = _WindowsIndexToAITIndex(Number($aResult[1]))
	If $aResult[0] <> "" Then $aResult[0] = _GetFullIcon($aResult[0])
	Return $aResult
EndFunc

Func _GetRelAssocIcon($sPath, $iIndex = 0)
	$sPath = StringStripWS(StringReplace($sPath, '"', ''), 3)
	If $sPath = "" Then Return ""
	If Not FileExists($sPath) Then Return SetError(1, 0, "")
	If StringInStr($sPath, ":\") Then $sPath = _PathGetRelative2(@ScriptDir, $sPath)
	If $iIndex <> 0 Then $sPath &= "," & _AITIndexToWindowsIndex($iIndex)
	Return $sPath
EndFunc

Func _UpdateAssocIconPreview()
	Local $sPath = GUICtrlRead($iAssocIcon)
	Local $iIndex = Number(GUICtrlRead($iAssocIconIndex))
	If $sPath <> "" And FileExists($sPath) Then
		GUICtrlSetImage($iAssocIconPreview, $sPath, $iIndex)
	Else
		GUICtrlSetImage($iAssocIconPreview, "", 0)
	EndIf
EndFunc

Func _BrowseAssocIcon()
	Local $sPath = GUICtrlRead($iAssocIcon)
	Local $sInitial = @ScriptDir
	If $sPath <> "" Then
		If StringInStr($sPath, ",") Then $sPath = StringLeft($sPath, StringInStr($sPath, ",", 0, -1) - 1)
		If FileExists($sPath) Then $sInitial = $sPath
	EndIf
	$sPath = FileOpenDialog("Choose context-menu icon", $sInitial, "Icon and resource files (*.ico;*.exe;*.dll)|All files (*.*)", 1, "", $aGUI)
	If @error Then Return
	GUICtrlSetData($iAssocIcon, $sPath)
	_UpdateAssocIconPreview()
EndFunc

Func _DeleteAssocSection()
	Local $tSec = StringReplace(GUICtrlRead($lSec), ' **', '') ; get selection, remove ' **'
	If $tSec = "" Then Return ; no selection

	Local $sections = _ReadINISections()
	If $sections[0] = 1 Then ; last section, do not allow deletion
		MsgBox(0 + 48, "Error", "You cannot delete the last file association." & @CRLF & _
								"Please add another association before deleting this one.", 0, $aGUI)
		Return
	EndIf

	If 7 = MsgBox(4 + 32 + 256, "Delete INI Section", "Are you sure?", 0, $aGUI) Then Return ; confirmation
	IniDelete($associni, $tSec) ; delete INI section
	_RefreshAssocGUI()
EndFunc

Func _AssocHelp() ; help: the Readme is embedded in this program (_ReadmeText), shown in its own window
	If Not $fReadmeLoaded Then
		GUICtrlSetData($rdEdit, _ReadmeText())
		GUICtrlSendMsg($rdEdit, 0xB1, 0, 0) ; EM_SETSEL: nothing selected
		$fReadmeLoaded = True
	EndIf
	GUISetState(@SW_DISABLE, $aGUI)
	GUISetState(@SW_SHOW, $rdGUI)
EndFunc

Func _ReadmeClose()
	GUISetState(@SW_HIDE, $rdGUI)
	GUISetState(@SW_ENABLE, $aGUI)
	WinActivate($aGUI)
EndFunc

Func _BrowseCommand()
	_BrowseCommandFor($iCommand, False)
EndFunc

Func _BrowseDriveCommand()
	_BrowseCommandFor($iDriveCmd, True)
EndFunc

Func _BrowseFolderCommand()
	_BrowseCommandFor($iFolderCmd, False)
EndFunc

Func _BrowseCommandFor($idInput, $bDrive)
	Local $path, $bBackgroundOnly

	$path = StringReplace(_GetExePath(GUICtrlRead($idInput)), '"', '') ; remove quotes
	$path = StringLeft($path, StringInStr($path, "\", 0, -1)) ; get path
	$path = FileOpenDialog("Browse for Command target...", $path, "All (*.*)", 1 + 3)
	If Not @error Then
		If StringInStr($path, ' ') Then $path = '"' & $path & '"'
		$bBackgroundOnly = (_IsChk($chkBackground) And Not (_IsChk($chkFiles) Or _IsChk($chkFolders) Or _IsChk($chkRecycle) Or _IsChk($chkDrives) Or StringStripWS(GUICtrlRead($iMode), 8) <> ""))
		If $bDrive Then
			$path &= ' %1' ; drive paths end with \, so no quotes
		ElseIf $bBackgroundOnly Then
			$path &= ' "%V"' ; background = current folder
		Else
			$path &= ' "%1"'
		EndIf
		GUICtrlSetData($idInput, $path)
	EndIf
EndFunc

Func _aGUIClose()
	_InitTypesINI() ; refresh types INI
	GUISetState(@SW_HIDE, $aGUI) ; hide assoc GUI
	GUISetState(@SW_ENABLE, $nGUI) ; enable main GUI
	WinActivate($nGUI) ; bring to front
EndFunc
#EndRegion Association GUI Functions
#Region Types GUI Functions
;=======================================================================================
; Types GUI Functions
;=======================================================================================

Func _InitTypesINI()
	Local $iniftypes, $ftypes, $i, $icon, $aIcon[1]

	$ftypes = _FtypeToArray(_ReadINISections())
	; clear unused types sections
	$iniftypes = IniReadSectionNames($typesini)
	If IsArray($iniftypes) Then
		For $i = 1 To $iniftypes[0]
			_ArraySearch($ftypes, $iniftypes[$i]) ; search active ftypes array for icon ftype
			If @error Then ; ftype not active
				IniDelete($typesini, $iniftypes[$i])
			EndIf
		Next
	EndIf
	; convert old icon paths, write new or empty icons
	For $i = 1 To $ftypes[0]
		$icon = IniRead($typesini, $ftypes[$i], "icon", "")
		; convert old icon paths
		If StringInStr($icon, "PDRIVE", 1) Then
			$aIcon = StringSplit($icon, ",")
			$icon = _PathGetRelative2(@ScriptDir, _PDRIVEToDrive($aIcon[1]))
			If $aIcon[0] > 1 Then $icon &= "," & $aIcon[2]
			IniWrite($typesini, $ftypes[$i], "icon", $icon)
		EndIf
		If $icon = "" Then ; no icon set, use associated program
			$icon = _FtypeToEXE($ftypes[$i])
			IniWrite($typesini, $ftypes[$i], "icon", $icon)
		EndIf
	Next
EndFunc

Func _TypesEditGUI()
	; Reset editor controls before populating the association/file-type selectors.
	GUICtrlSetData($defassoclist, "")
	GUICtrlSetState($hideext, $GUI_UNCHECKED)
	GUICtrlSetState($copyhost, $GUI_UNCHECKED)
	GUICtrlSetState($hostoverride, BitOR($GUI_UNCHECKED, $GUI_DISABLE))
	GUICtrlSetData($ftypeicon, "")
	GUICtrlSetData($iconindex, "")
	GUICtrlSetState($showNewMenu, $GUI_UNCHECKED)
	GUICtrlSetData($newMenuName, "")
	GUICtrlSetState($useTemplate, BitOR($GUI_UNCHECKED, $GUI_DISABLE))
	GUICtrlSetData($templateFile, "")
	GUICtrlSetState($templateFile, $GUI_DISABLE)
	_PopulateFtypeAssociationFilter()
	_GetIcon()
	GUISetState(@SW_DISABLE, $nGUI)
	WinSetTitle($tGUI, "", "Configure File Types - " & $curProfile)
	GUISetState(@SW_SHOW, $tGUI)
EndFunc

Func _PopulateFtypeAssociationFilter()
	Local $aSections = _ReadINISections(), $aNames[1] = [0]
	; Only show associations that contain at least one real file extension.
	; Associations made exclusively of special shell targets are not file-type groups.
	For $i = 1 To $aSections[0]
		If Not _AssociationHasFileTypes($aSections[$i]) Then ContinueLoop
		$aNames[0] += 1
		_ArrayAdd($aNames, $aSections[$i])
	Next
	If $aNames[0] > 1 Then _ArraySort($aNames, 0, 1)
	GUICtrlSetData($ftypeAssocFilter, "|(All associations)|" & _ArrayToString($aNames, "|", 1), "(All associations)")
	_PopulateFtypeListForAssociation("(All associations)")
EndFunc

Func _FtypeAssocFilterChange()
	_PopulateFtypeListForAssociation(GUICtrlRead($ftypeAssocFilter))
EndFunc

Func _SplitAssociationModes($sMode)
	; StringSplit sets @error when a single mode has no delimiter.
	; Treat that value as a one-item mode list instead of dropping the association.
	Local $aModes = StringSplit($sMode, "|")
	If @error Then
		Local $aSingle[2] = [1, StringStripWS($sMode, 3)]
		Return $aSingle
	EndIf
	Return $aModes
EndFunc

Func _IsSpecialFtypeMode($sMode)
	$sMode = StringLower(StringStripWS($sMode, 3))
	Switch $sMode
		Case "", "exe", "com"
			Return True
	EndSwitch
	Return False
EndFunc

Func _AssociationHasFileTypes($sAssocName)
	Local $i, $aModes = _SplitAssociationModes(IniRead($associni, $sAssocName, "mode", ""))
	If $aModes[0] = 0 Then Return False
	For $i = 1 To $aModes[0]
		If Not _IsSpecialFtypeMode($aModes[$i]) Then Return True
	Next
	Return False
EndFunc

Func _AddUniqueFtype(ByRef $aFtypes, $sFtype)
	Local $i
	If _IsSpecialFtypeMode($sFtype) Then Return
	For $i = 1 To $aFtypes[0]
		If StringLower($aFtypes[$i]) = StringLower($sFtype) Then Return
	Next
	$aFtypes[0] += 1
	_ArrayAdd($aFtypes, $sFtype)
EndFunc

Func _PopulateFtypeListForAssociation($sAssocName)
	Local $aFtypes[1] = [0], $aSections, $aModes
	If $sAssocName = "" Or $sAssocName = "(All associations)" Then
		$aSections = _ReadINISections()
		For $i = 1 To $aSections[0]
			$aModes = _SplitAssociationModes(IniRead($associni, $aSections[$i], "mode", ""))
			If $aModes[0] = 0 Then ContinueLoop
			For $j = 1 To $aModes[0]
				_AddUniqueFtype($aFtypes, $aModes[$j])
			Next
		Next
	ElseIf _AssociationHasFileTypes($sAssocName) Then
		$aModes = _SplitAssociationModes(IniRead($associni, $sAssocName, "mode", ""))
		For $i = 1 To $aModes[0]
			_AddUniqueFtype($aFtypes, $aModes[$i])
		Next
	EndIf
	If $aFtypes[0] > 1 Then _ArraySort($aFtypes, 0, 1)
	GUICtrlSetData($ftypelist, "|" & _ArrayToString($aFtypes, "|", 1))
	; Clear stale editor values until an extension from this group is selected.
	GUICtrlSetData($defassoclist, "")
	GUICtrlSetData($ftypeicon, "")
	GUICtrlSetData($iconindex, "0")
	GUICtrlSetState($hideext, $GUI_UNCHECKED)
	GUICtrlSetState($copyhost, $GUI_UNCHECKED)
	GUICtrlSetState($hostoverride, BitOR($GUI_UNCHECKED, $GUI_DISABLE))
	GUICtrlSetState($showNewMenu, $GUI_UNCHECKED)
	GUICtrlSetData($newMenuName, "")
	GUICtrlSetState($useTemplate, BitOR($GUI_UNCHECKED, $GUI_DISABLE))
	GUICtrlSetData($templateFile, "")
	GUICtrlSetState($templateFile, $GUI_DISABLE)
	If $aFtypes[0] > 0 Then
		GUICtrlSetData($ftypelist, "|" & _ArrayToString($aFtypes, "|", 1), $aFtypes[1])
		_FtypeChange()
	Else
		GUICtrlSetData($ftypelist, "")
	EndIf
EndFunc

Func _RefreshNow()
	_SHChangeNotify() ; send system change notification
	If $fVistaOrBetter Then
		Return ; do not refresh on Vista
	ElseIf $rebuild = 1 Then
		_RebuildIcons()
	EndIf
EndFunc

Func _SHChangeNotify()
	DllCall("shell32.dll", "none", "SHChangeNotify", _
						"long", $PFA_SHCNE_ASSOCCHANGED, _
						"uint", BitOR($PFA_SHCNF_IDLIST, $PFA_SHCNF_FLUSH), _
						"ptr", 0, _
						"ptr", 0 _
						)
EndFunc

Func _RebuildIcons()
	Local $icon_pos, $lg_icon_sz, $sm_icon_sz

	$icon_pos = _SaveIconPos()

	$lg_icon_sz = RegRead("HKCU\Control Panel\Desktop\WindowMetrics", "Shell Icon Size")
	If $lg_icon_sz <> "" Then _
		RegWrite("HKCU\Control Panel\Desktop\WindowMetrics", "Shell Icon Size", "REG_SZ", $lg_icon_sz + 1)

	$sm_icon_sz = RegRead("HKCU\Control Panel\Desktop\WindowMetrics", "Shell Icon BPP")
	If $sm_icon_sz <> "" Then _
		RegWrite("HKCU\Control Panel\Desktop\WindowMetrics", "Shell Icon BPP", "REG_SZ", $sm_icon_sz + 1)

	_SystemBroadcast()
	_FileIconInit()

	If $lg_icon_sz <> "" Then _
		RegWrite("HKCU\Control Panel\Desktop\WindowMetrics", "Shell Icon Size", "REG_SZ", $lg_icon_sz)
	If $sm_icon_sz <> "" Then _
		RegWrite("HKCU\Control Panel\Desktop\WindowMetrics", "Shell Icon BPP", "REG_SZ", $sm_icon_sz)

	_SystemBroadcast()
	_FileIconInit()

	_RestoreIconPos($icon_pos)
EndFunc

Func _SystemBroadcast()
	Local $ret

	$ret = DllCall("user32.dll", "int", "SendMessage", _
									"hwnd", $PFA_HWND_BROADCAST, _
									"uint", $PFA_WM_SETTINGCHANGE, _
									"wparam", $PFA_SPI_SETNONCLIENTMETRICS, _
									"str", "WindowMetrics" _
								)
	If Not @Compiled Then ConsoleWrite("Broadcast return: " & $ret[0] & @CRLF)
EndFunc

Func _FileIconInit()
	Local $ret

	; 660 = ordinal for FileIconInit function
	$ret = DllCall("shell32.dll", "int", 660, _
									"int", 1 _
									)
	If Not @Compiled Then ConsoleWrite("Icon return: " & $ret[0] & @CRLF)
EndFunc

Func _SaveIconPos()
	Local $iconArray[1][3] = [[0, 0, 0]], $desktop, $items, $i, $tempName, $tempArray

	$desktop = ControlGetHandle("[TITLE:Program Manager; CLASS:Progman]", "", 1) ; get desktop handle
	If Not IsHWnd($desktop) Then Return SetError(1)
	$items = _GUICtrlListView_GetItemCount($desktop)
	$iconArray[0][0] = $items ; icon count
	For $i = 0 To $items - 1
		$tempName = _GUICtrlListView_GetItemText($desktop, $i)
		$tempArray = _GUICtrlListView_GetItemPosition($desktop, $i)
		ReDim $iconArray[UBound($iconArray) + 1][3] ; increase rows of array
		$iconArray[UBound($iconArray) - 1][0] = $tempName ; icon name
		$iconArray[UBound($iconArray) - 1][1] = $tempArray[0] ; icon X coord
		$iconArray[UBound($iconArray) - 1][2] = $tempArray[1] ; icon Y coord
		; array = [0][1][2] = [name][x][y]
	Next
	Return $iconArray
EndFunc

Func _RestoreIconPos($iconArray)
	Local $desktop, $items, $i, $found, $tempName

	$desktop = ControlGetHandle("[TITLE:Program Manager; CLASS:Progman]", "", 1) ; get desktop handle
	If Not IsHWnd($desktop) Then Return SetError(1)
	$items = _GUICtrlListView_GetItemCount($desktop)
	For $i = 1 To $items
		; search array
		$found = 0 ; reset search
		$tempName = _GUICtrlListView_GetItemText($desktop, $i - 1)
		For $j = 1 To $iconArray[0][0]
			If $tempName = $iconArray[$j][0] Then
				$found = 1
				ExitLoop
			EndIf
		Next
		If Not $found Then ContinueLoop
		_GUICtrlListView_SetItemPosition($desktop, $i - 1, $iconArray[$j][1], $iconArray[$j][2]) ; move icons
	Next
EndFunc

Func _MY_WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
	#forceref $Msg, $lParam
	Local $message, $ctrlid

	If $hWnd = $tGUI Or $hWnd = $aGUI Then
		$message = BitShift($wParam, 16) ; high word of $wParam = notification msg
		$ctrlid = BitAnd($wParam, 0x0000FFFF) ; low word of $wParam = ctrlid
		If $message = $EN_CHANGE Then
			If $hWnd = $tGUI Then
				If $ctrlid = $ftypeicon Then
					GUICtrlSetData($iconindex, "0")
					_GetIcon()
				ElseIf $ctrlid = $iconindex Then
					_GetIcon()
				EndIf
			ElseIf $ctrlid = $iAssocIcon Or $ctrlid = $iAssocIconIndex Then
				_UpdateAssocIconPreview()
			ElseIf $ctrlid = $iMode Then
				_AssocUpdateControls() ; extensions typed / removed: update Command / Drive Command
			EndIf
		EndIf
	EndIf
EndFunc

Func _MY_WM_ENDSESSION($hWnd, $Msg, $wParam, $lParam)
	#forceref $hWnd, $Msg, $lParam
	If $wParam = 1 Then
		$onclose = 1 ; remove associations in exit func
		_Exit()
	EndIf
	Return 0 ; always return 0
EndFunc

Func _GetIcon()
	Local $icon, $index

	$icon = GUICtrlRead($ftypeicon)
	$index = Number(GUICtrlRead($iconindex))
	GUICtrlSetImage($icondisplay, $icon, $index)
EndFunc

Func _BrowseIcon()
	Local $file, $index, $newicon

	If GUICtrlRead($ftypeicon) = "" Then Return

	$file = GUICtrlRead($ftypeicon)
	$index = _AITIndexToWindowsIndex(Number(GUICtrlRead($iconindex)))

	$newicon = DllCall("shell32.dll", "int", 62, _ ; 62 = ordinal for IconPickDlg()
										"hwnd", $tGUI, _
										"wstr", $file, _
										"int", $PFA_MAX_PATH, _
										"int*", $index _
										)
	If $newicon[0] = 0 Then
		Return ; user cancelled dialog
	Else
		GUICtrlSetData($ftypeicon, $newicon[2])
		GUICtrlSetData($iconindex, _WindowsIndexToAITIndex($newicon[4]))
		_GetIcon()
	EndIf
EndFunc

Func _GetNewItemsTemplatePath($sExtension)
	Local $sExt = StringRegExpReplace(StringStripWS($sExtension, 3), "^\.", "")
	If $sExt = "" Then Return ""
	Return @ScriptDir & "\Data\newitems\" & StringUpper($sExt) & "." & $sExt
EndFunc

Func _UpdateTemplateControls()
	Local $fShowNew = (BitAND(GUICtrlRead($showNewMenu), $GUI_CHECKED) = $GUI_CHECKED)
	Local $fUseTemplate = (BitAND(GUICtrlRead($useTemplate), $GUI_CHECKED) = $GUI_CHECKED)
	Local $sExt = GUICtrlRead($ftypelist)
	Local $sTemplate = _GetNewItemsTemplatePath($sExt)
	GUICtrlSetState($useTemplate, $fShowNew ? $GUI_ENABLE : BitOR($GUI_UNCHECKED, $GUI_DISABLE))
	If Not $fShowNew Then
		GUICtrlSetState($templateFile, $GUI_DISABLE)
	Else
		GUICtrlSetState($templateFile, ($fUseTemplate ? $GUI_ENABLE : $GUI_DISABLE))
	EndIf
	GUICtrlSetData($templateFile, $sTemplate = "" ? "" : "Data\newitems\" & StringUpper($sExt) & "." & $sExt)
EndFunc

Func _ShowNewToggle()
	If BitAND(GUICtrlRead($showNewMenu), $GUI_CHECKED) <> $GUI_CHECKED Then
		GUICtrlSetState($useTemplate, BitOR($GUI_UNCHECKED, $GUI_DISABLE))
	EndIf
	_UpdateTemplateControls()
EndFunc

Func _TemplateToggle()
	_UpdateTemplateControls()
EndFunc

Func _SaveTypes()
	Local $index, $hide, $host, $hostover

	Local $ext = GUICtrlRead($ftypelist)
	If $ext = "" Then Return
	; pending
	If $state = 1 Then $iconchange = True ; only pending if associations currently active
	; index
	$index = Number(GUICtrlRead($iconindex))
	If $index = 0 Then
		$index = ""
	Else
		$index = "," & _AITIndexToWindowsIndex($index)
	EndIf
	; hidden
	If BitAND(GUICtrlRead($hideext), $GUI_CHECKED) Then
		$hide = $GUI_CHECKED
	Else
		$hide = $GUI_UNCHECKED
	EndIf
	; copy host
	If BitAND(GUICtrlRead($copyhost), $GUI_CHECKED) Then
		$host = $GUI_CHECKED
	Else
		$host = $GUI_UNCHECKED
	EndIf
	; host override
	If $host = $GUI_CHECKED And BitAND(GUICtrlRead($hostoverride), $GUI_CHECKED) Then
		$hostover = $GUI_CHECKED
	Else
		$hostover = $GUI_UNCHECKED
	EndIf
	IniWrite($typesini, $ext, "icon", _PathGetRelative2(@ScriptDir, GUICtrlRead($ftypeicon)) & $index)
	IniWrite($typesini, $ext, "hide", $hide) ; 1 = checked, 4 = unchecked
	IniWrite($typesini, $ext, "copyhost", $host)
	IniWrite($typesini, $ext, "hostoverride", $hostover)
	IniWrite($typesini, $ext, "default", GUICtrlRead($defassoclist))
	IniWrite($typesini, $ext, "shownew", BitAND(GUICtrlRead($showNewMenu), $GUI_CHECKED) ? $GUI_CHECKED : $GUI_UNCHECKED)
	IniWrite($typesini, $ext, "newname", StringStripWS(GUICtrlRead($newMenuName), 3))
	Local $fShowNew = (BitAND(GUICtrlRead($showNewMenu), $GUI_CHECKED) = $GUI_CHECKED)
	Local $fUseTemplate = ($fShowNew And BitAND(GUICtrlRead($useTemplate), $GUI_CHECKED) = $GUI_CHECKED)
	IniWrite($typesini, $ext, "usetemplate", $fUseTemplate ? $GUI_CHECKED : $GUI_UNCHECKED)
	; Legacy custom template paths are intentionally cleared: PFA now uses a fixed filename in Data\newitems.
	IniWrite($typesini, $ext, "template", "")
	If $fUseTemplate Then
		Local $sExpected = _GetNewItemsTemplatePath($ext)
		If Not FileExists($sExpected) Then
			MsgBox(48, "File Types - Template Missing", "Please add the file with this name:" & @CRLF & @CRLF & _
				StringUpper($ext) & "." & $ext & @CRLF & @CRLF & "Folder: Data\newitems", 0, $tGUI)
			Return
		EndIf
	EndIf
	MsgBox(0 + 64, "File Types", "Settings for '." & $ext & "' saved.", 0, $tGUI)
EndFunc

Func _FtypeChange()
	Local $ftype, $icon, $index, $path, $aIcon[1]

	$ftype = GUICtrlRead($ftypelist)
	Local $fShowNew = (Number(IniRead($typesini, $ftype, "shownew", $GUI_UNCHECKED)) = $GUI_CHECKED)
	GUICtrlSetState($showNewMenu, $fShowNew ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($newMenuName, IniRead($typesini, $ftype, "newname", "PFA_" & $ftype & " File"))
	Local $fUseTemplate = ($fShowNew And Number(IniRead($typesini, $ftype, "usetemplate", $GUI_UNCHECKED)) = $GUI_CHECKED)
	GUICtrlSetState($useTemplate, $fUseTemplate ? $GUI_CHECKED : $GUI_UNCHECKED)
	_UpdateTemplateControls()
	; default association
	Local $defassoc = IniRead($typesini, $ftype, "default", "(no default)")
	Local $aDefAssoc = _DefAssocToArray($ftype)
	GUICtrlSetData($defassoclist, "|(no default)|" & _ArrayToString($aDefAssoc, "|", 1), $defassoc)
	; icon
	$icon = IniRead($typesini, $ftype, "icon", "")
	If $icon = "" Then ; no icon set, use associated program
		$icon = _FtypeToEXE($ftype)
		IniWrite($typesini, $ftype, "icon", $icon) ; set INI value
		$path = $icon
		$index = 0
	Else ; separate icon and index
		$aIcon = StringSplit($icon, ",")
		$path = $aIcon[1]
		If $aIcon[0] > 1 Then
			$index = _WindowsIndexToAITIndex(Number($aIcon[2]))
		Else
			$index = 0
		EndIf
	EndIf
	Local $iCopyhost = Number(IniRead($typesini, $ftype, "copyhost", $GUI_UNCHECKED))
	GUICtrlSetState($hideext, Number(IniRead($typesini, $ftype, "hide", $GUI_UNCHECKED)))
	GUICtrlSetState($copyhost, $iCopyhost)
	If $iCopyhost = $GUI_CHECKED Then
		GUICtrlSetState($hostoverride, BitOR($GUI_ENABLE, Number(IniRead($typesini, $ftype, "hostoverride", $GUI_UNCHECKED))))
	Else
		GUICtrlSetState($hostoverride, BitOR($GUI_UNCHECKED, $GUI_DISABLE))
	EndIf
	GUICtrlSetData($ftypeicon, _GetFullIcon($path))
	GUICtrlSetData($iconindex, $index)
	_GetIcon()
EndFunc

Func _DefAssocToArray($ftype)
	Local $aAssoc[1] = [0], $sections = _ReadINISections()
	For $i = 1 To $sections[0]
		; if association is disabled, skip it
		If Number(IniRead($associni, $sections[$i], "disabled", $GUI_UNCHECKED)) = $GUI_CHECKED Then ContinueLoop
		; read modes from each associations and add matching ftype sections to array
		Local $aSplit = StringSplit(IniRead($associni, $sections[$i], "mode", ""), "|")
		_ArraySearch($aSplit, $ftype, 1)
		If Not @error Then ; ftype found in section
			$aAssoc[0] += 1
			_ArrayAdd($aAssoc, $sections[$i])
		EndIf
	Next
	Return $aAssoc
EndFunc

Func _AITIndexToWindowsIndex($index)
	If $index > 0 Then
		$index = ($index * -1)
	ElseIf $index < 0 Then
		$index = ($index * -1) - 1
	EndIf
	Return $index
EndFunc

Func _WindowsIndexToAITIndex($index)
	If $index > 0 Then
		$index = ($index + 1) * -1
	ElseIf $index < 0 Then
		$index = ($index * -1)
	EndIf
	Return $index
EndFunc

Func _FtypeToEXE($ftype)
	Local $sections, $i, $modearray, $j

	$sections = _ReadINISections()

	For $i = 1 To $sections[0]
		$modearray = StringSplit(IniRead($associni, $sections[$i], "mode", ""), "|")
		For $j = 1 To $modearray[0]
			If $modearray[$j] = $ftype Then
				Return _GetExePath(IniRead($associni, $sections[$i], "command", ""))
			EndIf
		Next
	Next
EndFunc

Func _FtypeToArray($sections)
	Local $modearray[1] = [0], $i, $j, $modes
	For $i = 1 To $sections[0]
		$modes = _SplitAssociationModes(IniRead($associni, $sections[$i], "mode", ""))
		If $modes[0] = 0 Then ContinueLoop
		For $j = 1 To $modes[0]
			_AddUniqueFtype($modearray, $modes[$j])
		Next
	Next
	Return $modearray ; contains only unique, configurable file extensions
EndFunc

Func _CopyHostToggle()
	If BitAND(GUICtrlRead($copyhost), $GUI_CHECKED) Then
		GUICtrlSetState($hostoverride, $GUI_ENABLE)
	Else
		GUICtrlSetState($hostoverride, BitOR($GUI_UNCHECKED, $GUI_DISABLE))
	EndIf
EndFunc

Func _tGUIClose()
	If $iconchange And $state = 1 Then ; if icons changed and active
		If 6 = MsgBox(4 + 32, "File Types", "Changes have been made while associations are active" & @CRLF & "and will be applied now.  Continue?", 0, $tGUI) Then
			$iconchange = False
			_RemoveFtypeSettings()
			_WriteFtypeSettings()
			_RefreshNow()
		Else
			Return
		EndIf
	EndIf
	GUISetState(@SW_HIDE, $tGUI)
	GUISetState(@SW_ENABLE, $nGUI)
	WinActivate($nGUI) ; bring to front
EndFunc
#EndRegion Types GUI Functions
#Region SendTo GUI Functions
Func _SendToGUI()
	$sChanges = False
	; empty listview
	_GUICtrlListView_DeleteAllItems($hsLV)
	; get listview items from ini
	Local $aItems = IniReadSection($sendtoini, "sendto")
	If IsArray($aItems) Then
		For $i = 1 To $aItems[0][0]
			_GUICtrlListView_AddSubItem($hsLV, _GUICtrlListView_AddItem($hsLV, $aItems[$i][0]), _GetFullCommand($aItems[$i][1]), 1)
		Next
	EndIf
	GUISetState(@SW_DISABLE, $nGUI)
	GUISetState(@SW_SHOW, $sGUI)
EndFunc

Func _MY_WINDOW_PROC($hWnd, $Msg, $wParam, $lParam)
	#forceref $lParam
	Switch $hWnd
		Case $hsLV
			Switch $Msg
				Case $PFA_WM_DROPFILES
					WinActivate($sGUI)
					Dim $aDropFiles[1] = [0]
					; string buffer for file path
					Local $tDrop = DllStructCreate("char[260]")
					; get file count
					Local $aRet = DllCall("shell32.dll", "int", "DragQueryFile", _
												"ptr", $wParam, _
												"uint", -1, _
												"ptr", DllStructGetPtr($tDrop), _
												"int", DllStructGetSize($tDrop) _
												)
					Local $iCount = $aRet[0]

					; get file paths
					For $i = 0 To $iCount - 1
						$aRet = DllCall("shell32.dll", "int", "DragQueryFile", _
												"ptr", $wParam, _
												"uint", $i, _
												"ptr", DllStructGetPtr($tDrop), _
												"int", DllStructGetSize($tDrop) _
												)
						; add dropped file path to array
						$aDropFiles[0] += 1
						_ArrayAdd($aDropFiles, DllStructGetData($tDrop, 1))
					Next
					; set the event for the drop action
					GUICtrlSendToDummy($sDummy)
					; finalize
					DllCall("shell32.dll", "int", "DragFinish", "hwnd", $wParam)

					Return 0
			EndSwitch
	EndSwitch

	Return _WinAPI_CallWindowProc($oldWndProc, $hWnd, $Msg, $wParam, $lParam)
EndFunc

Func _sDropAction()
	If $aDropFiles[0] < 1 Then Return
	GUISetState(@SW_DISABLE, $sGUI)
	; change to MSG mode and create our GUI
	Opt("GUIOnEventMode", 0)

	Local $gui = GUICreate("Shortcut Name", 418, 174, -1, -1, $WS_CAPTION, $WS_EX_TOOLWINDOW, $sGUI)
	GUICtrlCreateLabel("Enter a name for this shortcut and any optional parameters:", 8, 8, 402, 17)
	Local $scLabel = GUICtrlCreateLabel("", 20, 36, 402, 17)
	GUICtrlCreateLabel("Shortcut Name:", 8, 84, 78, 17)
	GUICtrlCreateLabel("Parameters (optional):", 8, 116, 106, 17)
	Local $scName = GUICtrlCreateInput("New Shortcut", 96, 78, 313, 21)
	Local $scParams = GUICtrlCreateInput("", 120, 110, 289, 21)
	Local $scOK = GUICtrlCreateButton("Ok", 152, 140, 49, 25)
	Local $scCancel = GUICtrlCreateButton("Cancel", 216, 140, 49, 25)
	_ThemeApply($gui)

	GUISetState()

	Local $msg, $path, $err, $name, $file, $param

	For $i = 1 To $aDropFiles[0]
		$file = $aDropFiles[$i]
		$path = DllCall("shlwapi.dll", "int", "PathCompactPathW", "hwnd", 0, "wstr", $file, "uint", 525)
		$path = $path[2]
		GUICtrlSetData($scLabel, $path)
		GUICtrlSetData($scName, "New Shortcut")
		GUICtrlSetData($scParams, "")

		While 1
			$msg = GUIGetMsg()
			Switch $msg
				Case $scOK
					$name = GUICtrlRead($scName)
					If $name <> "" Then
						; check if the name exists
						$err = 0 ; reset err condition
						For $j = 0 To _GUICtrlListView_GetItemCount($hsLV) - 1
							If $name = _GUICtrlListView_GetItemText($hsLV, $j) Then
								MsgBox(48, "Error", "This shortcut name already exists." & @CRLF & "Please choose another name.", 0, $sGUI)
								$err = 1
								ExitLoop ; exit for loop
							EndIf
						Next
						If Not $err Then
							; create the listview item and move to next item in array
							If StringInStr($file, ' ') Then $file = '"' & $file & '"'
							$param = GUICtrlRead($scParams)
							If $param <> "" Then
								$file &= " " & $param
							EndIf
							_GUICtrlListView_AddSubItem($hsLV, _GUICtrlListView_AddItem($hsLV, $name), $file, 1)
							$sChanges = True
							ExitLoop ; exit while loop, next item
						EndIf
					EndIf
				Case $scCancel
					ExitLoop 2 ; exit main for loop
			EndSwitch
		WEnd
	Next

	GUIDelete($gui)
	; return to OnEvent mode
	Opt("GUIOnEventMode", 1)
	_GUICtrlListView_SetColumnWidth($hsLV, 1, $LVSCW_AUTOSIZE_USEHEADER)
	GUISetState(@SW_ENABLE, $sGUI)
	WinActivate($sGUI)
EndFunc

Func _AddSendTo()
	Local $sFile = FileOpenDialog("Add File", @WorkingDir, "All Files (*.*)", 3, "", $sGUI)
	If @error Then Return
	Dim $aDropFiles[2] = [1, $sFile]
	_sDropAction()
EndFunc

Func _ClearSendTo()
	_GUICtrlListView_DeleteAllItems($hsLV)
	$sChanges = True
EndFunc

Func _RemoveSendTo()
	_GUICtrlListView_DeleteItemsSelected($hsLV)
	$sChanges = True
EndFunc

Func _SaveSendTo()
	; check for state
	If $state = 1 Then
		; running
		If 6 = MsgBox(4 + 32, "SendTo", "Saving while associations are active will immediately apply" & @CRLF & "the new settings.  Continue?", 0, $sGUI) Then
			; remove current shortcuts
			_DoSendToShortcuts(False)
		Else
			Return False ; don't close the dialog from close func
		EndIf
	EndIf
	; remove old INI section
	IniDelete($sendtoini, "sendto")
	; write new section
	For $i = 0 To _GUICtrlListView_GetItemCount($hsLV) - 1
		IniWrite($sendtoini, "sendto", _GUICtrlListView_GetItemText($hsLV, $i), _GetRelCommand(_GUICtrlListView_GetItemText($hsLV, $i, 1)))
	Next
	$sChanges = False
	If $state = 1 Then _DoSendToShortcuts() ; apply new shortcuts
	MsgBox(64, "SendTo", "Saved.", 0, $sGUI)
	Return True ; close the dialog from close func
EndFunc

Func _sCloseGUI()
	If $sChanges Then
		If 6 = MsgBox(4 + 32, "SendTo", "Save changes before closing?", 0, $sGUI) Then
			If Not _SaveSendTo() Then Return ; don't close if we canceled applying settings
		EndIf
	EndIf
	$sChanges = False
	GUISetState(@SW_HIDE, $sGUI)
	GUISetState(@SW_ENABLE, $nGUI)
	WinActivate($nGUI)
EndFunc
#EndRegion SendTo GUI Functions
#Region Main Functions
;=======================================================================================
; Main Functions
;=======================================================================================

Func _ConfigureShellNew($sExtension, $fEnable, $sTemplate = "")
	Local $sExtKey = "HKCU\Software\Classes\." & $sExtension
	Local $sShellNew = $sExtKey & "\ShellNew"
	Local $sBackup = $sExtKey & "\ShellNew_PFA_BACKUP"
	Local $sMarker = RegRead($sExtKey, "_PFA_ShellNewBackup")

	If $fEnable Then
		; Back up the host ShellNew key only once, so disabling PFA can restore it.
		If $sMarker = "" Then
			If _RegKeyExists($sShellNew) Then
				_RegCopyKey($sShellNew, $sBackup)
				RegWrite($sExtKey, "_PFA_ShellNewBackup", "REG_SZ", "1")
			Else
				RegWrite($sExtKey, "_PFA_ShellNewBackup", "REG_SZ", "0")
			EndIf
		EndIf
		If $sTemplate <> "" And FileExists($sTemplate) Then
			RegDelete($sShellNew, "NullFile")
			RegWrite($sShellNew, "FileName", "REG_SZ", $sTemplate)
		Else
			RegDelete($sShellNew, "FileName")
			RegWrite($sShellNew, "NullFile", "REG_SZ", "")
		EndIf
	Else
		_RestoreShellNew($sExtension)
	EndIf
EndFunc

Func _RestoreShellNew($sExtension)
	Local $sExtKey = "HKCU\Software\Classes\." & $sExtension
	Local $sShellNew = $sExtKey & "\ShellNew"
	Local $sBackup = $sExtKey & "\ShellNew_PFA_BACKUP"
	Local $sMarker = RegRead($sExtKey, "_PFA_ShellNewBackup")

	If $sMarker = "" Then Return
	RegDelete($sShellNew)
	If $sMarker = "1" And _RegKeyExists($sBackup) Then _RegCopyKey($sBackup, $sShellNew)
	RegDelete($sBackup)
	RegDelete($sExtKey, "_PFA_ShellNewBackup")
EndFunc

Func _RegRenameKey($sKey, $sNewName)
	; Renames the last part of an HKCU key, e.g. _RegRenameKey("HKCU\...\FileExts\.zip", ".zip_PFA").
	; Unlike copy + delete this keeps every subkey, value and last-write time as it is.  Returns True on success.
	Local $iPos = StringInStr($sKey, "\", 0, -1)
	If $iPos = 0 Or StringLeft($sKey, 5) <> "HKCU\" Then Return SetError(1, 0, False)
	Local $sParent = StringMid($sKey, 6, $iPos - 6)
	Local $sOld = StringTrimLeft($sKey, $iPos)
	Local $aOpen = DllCall("advapi32.dll", "long", "RegOpenKeyExW", "handle", 0x80000001, "wstr", $sParent, "dword", 0, "dword", 0xF003F, "handle*", 0) ; HKCU, KEY_ALL_ACCESS
	If @error Or $aOpen[0] <> 0 Then Return SetError(2, 0, False)
	Local $hParent = $aOpen[5], $iErr = 1
	Local $aRen = DllCall("advapi32.dll", "long", "RegRenameKey", "handle", $hParent, "wstr", $sOld, "wstr", $sNewName)
	If Not @error Then $iErr = $aRen[0]
	DllCall("advapi32.dll", "long", "RegCloseKey", "handle", $hParent)
	If $iErr <> 0 Then Return SetError(3, $iErr, False)
	Return True
EndFunc

Func _WriteFtypeSettings()
	Local $aExts = IniReadSectionNames($typesini)
	If IsArray($aExts) Then
		For $i = 1 To $aExts[0]
			If $aExts[$i] = "exe" Or $aExts[$i] = "com" Or $aExts[$i] = "" Then ContinueLoop
			Local $icon = _GetFullIcon(IniRead($typesini, $aExts[$i], "icon", "")) ; get icon
			Local $fHide = (Number(IniRead($typesini, $aExts[$i], "hide", $GUI_UNCHECKED)) = $GUI_CHECKED)
			Local $fCopyhost = (Number(IniRead($typesini, $aExts[$i], "copyhost", $GUI_UNCHECKED)) = $GUI_CHECKED)
			Local $fHostoverride = (Number(IniRead($typesini, $aExts[$i], "hostoverride", $GUI_UNCHECKED)) = $GUI_CHECKED)
			Local $ftype = "PortableFileAssoc_" & $aExts[$i]
			Local $origftype = RegRead("HKCR\." & $aExts[$i], "")
			Local $origdefaultassoc = RegRead("HKCR\" & $origftype & "\shell", "")
			Local $defPFAassoc = IniRead($typesini, $aExts[$i], "default", "(no default)")
			; Windows' own default app for the extension is stored in FileExts\.ext\UserChoice.  It is protected by a hash that
			; includes the key's last write time, so a key that is deleted and written back later is rejected by Windows and the
			; default app is reset (ie WinRAR is no longer the default for zip after Remove).  UserChoice is therefore left
			; untouched unless a PFA default association must take over the double-click action of this extension.
			Local $bHostDef = ($fCopyhost And ($origdefaultassoc <> "" Or ($origftype <> "" And _RegKeyExists("HKCR\" & $origftype & "\shell\open"))))
			Local $bPFAdefault = ($defPFAassoc <> "(no default)" And Not ($fHostoverride And $bHostDef))
			Local $bKeepUC = (Not $bPFAdefault And _RegKeyExists("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "\UserChoice"))
			; Extensions that already have an entry in Explorer's "New" menu (docx, xlsx, pptx, zip, rar, txt, ...) lose or break that
			; entry when their file type is replaced by PortableFileAssoc_<ext>: Office entries disappear, others get a wrong icon
			; or name.  Such an extension is therefore left alone (the context-menu entries are still added, see _FileAssociations)
			; unless a setting of the File Types dialog needs the file type: PFA default association, Hide extension,
			; Copy Host Associations or Show in New menu.
			Local $bWantNew = (Number(IniRead($typesini, $aExts[$i], "shownew", $GUI_UNCHECKED)) = $GUI_CHECKED)
			Local $bHostNew = (_RegKeyExists("HKCR\." & $aExts[$i] & "\ShellNew") Or _
					($origftype <> "" And _RegKeyExists("HKCR\." & $aExts[$i] & "\" & $origftype & "\ShellNew")))
			If $bHostNew And Not ($bPFAdefault Or $fHide Or $fCopyhost Or $bWantNew) Then ContinueLoop
			; write extension data
			If _RegKeyExists("HKCU\Software\Classes\." & $aExts[$i]) Then
				; extension exists
				If _RegValueExists("HKCU\Software\Classes\." & $aExts[$i], "") Then
					; default value exists (original file type), back up first
					_RegMoveValue("HKCU\Software\Classes\." & $aExts[$i], "", "HKCU\Software\Classes\." & $aExts[$i], "_old_default_")
				Else
					; no default value, set flag
					RegWrite("HKCU\Software\Classes\." & $aExts[$i], "_old_default_", "REG_SZ", "_none_")
				EndIf
			Else
				; extension does not exist, set _delete_ flag
				RegWrite("HKCU\Software\Classes\." & $aExts[$i], "_delete_", "REG_SZ", "")
			EndIf
			; set extension ftype
			RegWrite("HKCU\Software\Classes\." & $aExts[$i], "", "REG_SZ", $ftype)
			; Optional Explorer > New submenu entry (creates an empty file).
			Local $fShowNew = (Number(IniRead($typesini, $aExts[$i], "shownew", $GUI_UNCHECKED)) = $GUI_CHECKED)
			; Set the file type display name.  Explorer's New menu shows this name for every ShellNew entry that the host already has
			; for the extension (ie zip, rar), so the "PFA_<ext> File" name is only used when "Show in New menu" is ticked.
			; Otherwise the display name of the original (host) file type is kept.
			Local $newDisplayName = "", $sFriendly = ""
			If $fShowNew Then
				$newDisplayName = StringStripWS(IniRead($typesini, $aExts[$i], "newname", ""), 3)
				If $newDisplayName = "" Then $newDisplayName = "PFA_" & $aExts[$i] & " File"
			Else
				If $origftype <> "" And StringLeft($origftype, 17) <> "PortableFileAssoc" Then
					$newDisplayName = RegRead("HKCR\" & $origftype, "")
					$sFriendly = RegRead("HKCR\" & $origftype, "FriendlyTypeName")
				EndIf
				If $newDisplayName = "" Then $newDisplayName = StringUpper($aExts[$i]) & " File"
			EndIf
			RegWrite("HKCU\Software\Classes\" & $ftype, "", "REG_SZ", $newDisplayName)
			If $sFriendly <> "" Then RegWrite("HKCU\Software\Classes\" & $ftype, "FriendlyTypeName", "REG_SZ", $sFriendly)
			Local $fUseTemplate = ($fShowNew And Number(IniRead($typesini, $aExts[$i], "usetemplate", $GUI_UNCHECKED)) = $GUI_CHECKED)
			Local $sTemplate = ""
			If $fUseTemplate Then
				$sTemplate = _GetNewItemsTemplatePath($aExts[$i])
				If Not FileExists($sTemplate) Then
					MsgBox(48, "File Types - Template Missing", "Please add the file with this name:" & @CRLF & @CRLF & _
						StringUpper($aExts[$i]) & "." & $aExts[$i] & @CRLF & @CRLF & "Folder: Data\newitems")
					; Keep the rest of this extension's association setup intact, but do not add it to New.
					_RestoreShellNew($aExts[$i])
					$fShowNew = False
				EndIf
			EndIf
			_ConfigureShellNew($aExts[$i], $fShowNew, $sTemplate)
			; the host's New-menu entry of this extension is stored below its file type (ie .docx\Word.Document.12\ShellNew) and is only
			; used while that file type is the extension's file type: copy it to the PFA file type so the entry stays in the New menu
			If Not $fShowNew And $origftype <> "" And StringLeft($origftype, 17) <> "PortableFileAssoc" And _
					_RegKeyExists("HKCR\." & $aExts[$i] & "\" & $origftype & "\ShellNew") Then _
				_RegCopyKey("HKCR\." & $aExts[$i] & "\" & $origftype & "\ShellNew", "HKCU\Software\Classes\." & $aExts[$i] & "\" & $ftype & "\ShellNew")
			; backup FileExts key
			Local $sFE = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i]
			Local $fFeDone = True
			If $bKeepUC Then
				; keep Windows' default app (UserChoice) as it is: nothing to back up, nothing to restore on remove
			ElseIf _RegKeyExists("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i]) Then ; key exists
				; backup
				If _RegKeyExists($sFE & "\UserChoice") Or _RegKeyExists($sFE & "\UserChoiceLatest") Then
					; the PFA default association takes over this extension.  Windows' own default app (UserChoice) is protected by a hash
					; that includes the key's last write time, so a COPY of it is rejected when it is put back on Remove (the default app,
					; ie WinRAR for zip, is lost).  The key is therefore RENAMED, its subkeys keep their data and time.
					; If Windows does not allow the rename, the user's choice is left untouched (the PFA default may then not take effect).
					$fFeDone = _RegRenameKey($sFE, "." & $aExts[$i] & "_PFA")
				Else
					_RegMoveKey($sFE, $sFE & "_PFA")
				EndIf
				If $fFeDone Then
					; don't copy any defaut "Open With..." settings
					_RegCopyKey($sFE & "_PFA\OpenWithList", $sFE & "\OpenWithList")
					_RegCopyKey($sFE & "_PFA\OpenWithProgids", $sFE & "\OpenWithProgids")
				EndIf
			Else
				; fake backup
				RegWrite("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_none")
			EndIf
			; copy host associations if checked and they exist
			If $fCopyhost And $origftype <> "" Then
				Local $j = 1, $key, $displayname
				While 1
					; loop all keys
					$key = RegEnumKey("HKCR\" & $origftype & "\shell", $j)
					If @error Then ExitLoop
					; copy key to new ftype
					_RegCopyKey("HKCR\" & $origftype & "\shell\" & $key, "HKCU\Software\Classes\" & $ftype & "\shell\Host_" & $key)
					; rename display value
					$displayname = RegRead("HKCU\Software\Classes\" & $ftype & "\shell\Host_" & $key, "")
					If $displayname = "" Then
						$displayname = "HOST: " & _StringProper($key)
					Else
						$displayname = "HOST: " & _StringProper($displayname)
					EndIf
					RegWrite("HKCU\Software\Classes\" & $ftype & "\shell\Host_" & $key, "", "REG_SZ", $displayname)
					$j += 1
				WEnd
			EndIf
			; default association value
			If $defPFAassoc = "(no default)" Or $fHostoverride Then
				; try host default first
				If $fCopyhost And $origdefaultassoc <> "" Then
					; write default host association
					RegWrite("HKCU\Software\Classes\" & $ftype & "\shell", "", "REG_SZ", "Host_" & $origdefaultassoc)
				ElseIf $fCopyhost Then
					; try to use open verb for host default
					If _RegKeyExists("HKCR\" & $origftype & "\shell\open") Then _
						RegWrite("HKCU\Software\Classes\" & $ftype & "\shell", "", "REG_SZ", "Host_open")
				EndIf
			EndIf
			; host override true if originally true and successfully set a host default association
			$fHostoverride = $fHostoverride And (RegRead("HKCU\Software\Classes\" & $ftype & "\shell", "") <> "")
			; set PFA default if not empty and host did not override
			If $defPFAassoc <> "(no default)" And Not $fHostoverride Then
				; write default PFA association
				For $j = 1 To $aDefaultAssociations[0]
					Local $aSplit = StringSplit($aDefaultAssociations[$j], ",")
					; aSplit: [1] = extension, [2] = association name, [3] = association command
					If $aExts[$i] = $aSplit[1] And $defPFAassoc = $aSplit[2] Then
						; extension and association match, write command
						RegWrite("HKCU\Software\Classes\" & $ftype & "\shell", "", "REG_SZ", $aSplit[3])
						ExitLoop
					EndIf
				Next
			EndIf
			; create 'open' key for XP 'New' menu hack if there is a 'ShellNew' key for the extension
			If Not $fVistaOrBetter And _RegKeyExists("HKCR\." & $aExts[$i] & "\ShellNew") Then
				; find a suitable open default
				Local $opencmd
				; if default exists
				Local $openverb = RegRead("HKCU\Software\Classes\" & $ftype & "\shell", "")
				If $openverb <> "" Then
					$opencmd = RegRead("HKCU\Software\Classes\" & $ftype & "\shell\" & $openverb & "\command", "")
				Else
					; we have to write something, so use PFA's first association
					Local $sections = _ReadINISections()
					For $k = 1 To $sections[0]
						; search mode array of each section for matching filetype, use that command
						Local $aMode = StringSplit(IniRead($associni, $sections[$k], "mode", "none"), "|")
						_ArraySearch($aMode, $aExts[$i])
						If Not @error Then
							$opencmd = _GetFullCommand(IniRead($associni, $sections[$k], "command", "none"))
							ExitLoop
						EndIf
					Next
				EndIf
				; write default command if found
				If $opencmd <> "" And $opencmd <> "none" Then RegWrite("HKCU\Software\Classes\" & $ftype & "\shell\open\command", "", "REG_SZ", _RegCommand($opencmd))
			EndIf
			; write icon
			Local $failover = False
			; PFA default association overrides host icon, if host doesn't take precedence
			; if host associations are active and no PFA default set or host takes precedence, use host icon if it exists, otherwise failover to PFA icon
			If $fCopyhost And ($fHostoverride Or $defPFAassoc = "(no default)") Then
				If _RegKeyExists("HKCR\" & $origftype & "\DefaultIcon") Then
					_RegCopyKey("HKCR\" & $origftype & "\DefaultIcon", "HKCU\Software\Classes\" & $ftype & "\DefaultIcon")
				Else
					$failover = True
				EndIf
			EndIf
			; write PFA icon if it exists and host associations are not active, there is a PFA default association, or the host icon was not found
			If $icon <> "" And (Not $fCopyhost Or ($defPFAassoc <> "(no default)" And Not $fHostoverride) Or $failover) Then _
				RegWrite("HKCU\Software\Classes\" & $ftype & "\DefaultIcon", "", "REG_SZ", $icon)
			; write NeverShowExt value
			If $fHide Then RegWrite("HKCU\Software\Classes\" & $ftype, "NeverShowExt", "REG_SZ", "")
			; special key for URL filetype (always exists by default)
			If StringUpper($aExts[$i]) = "URL" Then _
				RegWrite("HKCU\Software\Classes\" & $ftype & "\shellex\IconHandler", "", "REG_SZ", "{FBF23B40-E3F0-101B-8488-00AA003E56F8}")
		Next
	EndIf
EndFunc

Func _RemoveFtypeSettings($fFinal = False)
	Local $i, $ftype, $j, $key

	Local $aExts = IniReadSectionNames($typesini)
	If IsArray($aExts) Then
		For $i = 1 To $aExts[0]
			If $aExts[$i] = "exe" Or $aExts[$i] = "com" Or $aExts[$i] = "" Then ContinueLoop
			$ftype = "PortableFileAssoc_" & $aExts[$i]
			If $fFinal Then
				;; ====== do these only on final removal
				; remove PFA New-menu registration value and file type
				_RestoreShellNew($aExts[$i])
				RegDelete("HKCU\Software\Classes\" & $ftype)
				RegDelete("HKCU\Software\Classes\." & $aExts[$i] & "\" & $ftype) ; copy of the host's New-menu entry
				If _RegValueExists("HKCU\Software\Classes\." & $aExts[$i], "_delete_") Then
					; delete extension
					RegDelete("HKCU\Software\Classes\." & $aExts[$i])
				EndIf
			Else
				;; ====== do these only on ftype settings changes
				_RestoreShellNew($aExts[$i])
				; remove host associations
				$j = 1
				While 1
					$key = RegEnumKey("HKCU\Software\Classes\" & $ftype & "\shell", $j)
					If @error Then ExitLoop
					; check for Host_ key
					If StringLeft($key, 5) = "Host_" Then RegDelete("HKCU\Software\Classes\" & $ftype & "\shell\" & $key)
					$j += 1
				WEnd
				; remove default value
				RegDelete("HKCU\Software\Classes\" & $ftype & "\shell", "")
				; remove DefaultIcon setting
				RegDelete("HKCU\Software\Classes\" & $ftype & "\DefaultIcon")
				; remove NeverShowExt setting
				RegDelete("HKCU\Software\Classes\" & $ftype, "NeverShowExt")
			EndIf
			;; ====== do these every time
			; restore default value
			If _RegKeyExists("HKCU\Software\Classes\." & $aExts[$i]) Then
				If RegRead("HKCU\Software\Classes\." & $aExts[$i], "_old_default_") = "_none_" Then
					RegDelete("HKCU\Software\Classes\." & $aExts[$i], "")
					RegDelete("HKCU\Software\Classes\." & $aExts[$i], "_old_default_")
				Else
					_RegMoveValue("HKCU\Software\Classes\." & $aExts[$i], "_old_default_", "HKCU\Software\Classes\." & $aExts[$i], "")
				EndIf
			EndIf
			; restore FileExts key
			If _RegKeyExists("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_none") Then ; fake key exists
				; delete .ext and fake
				RegDelete("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i])
				RegDelete("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_none")
			; fake key does not exist, restore backup if it exists
			ElseIf _RegKeyExists("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_PFA") Then ; key exists
				RegDelete("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i]) ; PFA's temporary .ext key
				; rename the original key back (keeps UserChoice valid), copy only if the rename is not possible
				If Not _RegRenameKey("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_PFA", "." & $aExts[$i]) Then _
						_RegMoveKey("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_PFA", _
								"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i])
			; else already in original state
			EndIf
		Next
	EndIf
EndFunc

Func _DoSendToShortcuts($fAdd = True)
	Local $aSplit
	Local Const $CSIDL_SENDTO = 0x0009
	Local Const $CSIDL_FLAG_NO_ALIAS = 0x1000
	Local Const $SHGFP_TYPE_CURRENT = 0x0000
	Local $aItems = IniReadSection($sendtoini, "sendto")
	If IsArray($aItems) Then
		Local $SendTo = _WinAPI_SHGetFolderPath(BitOR($CSIDL_FLAG_NO_ALIAS, $CSIDL_SENDTO), $SHGFP_TYPE_CURRENT)
		If @error Then Return ; some error getting SendTo location
		For $i = 1 To $aItems[0][0]
			If $fAdd Then
				; [0] = exe path, [1] = args
				$aSplit = _CommandSplit(_GetFullCommand($aItems[$i][1]))
				FileCreateShortcut($aSplit[0], $SendTo & "\" & $aItems[$i][0] & " PFA.lnk", "", $aSplit[1])
			Else
				FileDelete($SendTo & "\" & $aItems[$i][0] & " PFA.lnk")
			EndIf
		Next
	EndIf
EndFunc

Func _FileAssociations($work)
	Local $section, $mode, $title, $cmdRaw, $cmdDrive, $command, $bSingle, $j, $icon, $verbKey, $targetClass, $sRaw, $sBase
	Local $bFiles, $bFolders, $bDrives, $bRecycle, $bBackground, $bExt, $bNeedMain, $cmdFolder, $bAdmin

	Switch $work
		Case "add" ; add context menu entries
			If $state = 1 Then Return ; don't do anything if already installed
			; write state data and set variable
			IniWrite($stateini, "state", "state", "1")
			$state = 1
			$section = _ReadINISections()
			For $i = 1 To $section[0]
				If Number(IniRead($associni, $section[$i], "disabled", $GUI_UNCHECKED)) = $GUI_CHECKED Then ContinueLoop ; disabled association
				$mode = _SplitAssociationModes(IniRead($associni, $section[$i], "mode", "")) ; file extensions
				$title = IniRead($associni, $section[$i], "title", "none")
				$cmdRaw = ""
				$sRaw = IniRead($associni, $section[$i], "command", "")
				If $sRaw <> "" Then $cmdRaw = _GetFullCommand($sRaw) ; resolve relative path
				$cmdDrive = ""
				$sRaw = IniRead($associni, $section[$i], "drivecommand", "")
				If $sRaw <> "" Then $cmdDrive = _GetFullCommand($sRaw)
				If $cmdDrive = "" Then $cmdDrive = $cmdRaw ; drives use the Command when there is no Drive Command
				$cmdFolder = ""
				$sRaw = IniRead($associni, $section[$i], "foldercommand", "")
				If $sRaw <> "" Then $cmdFolder = _GetFullCommand($sRaw)
				If $cmdFolder = "" Then $cmdFolder = $cmdRaw ; folders use the Command when there is no Folder Command
				$icon = _GetFullIcon(IniRead($associni, $section[$i], "icon", ""))
				$bFiles = _AssocFlag($section[$i], "files")
				$bFolders = _AssocFlag($section[$i], "folders")
				$bDrives = _AssocFlag($section[$i], "drives")
				$bRecycle = _AssocFlag($section[$i], "recycle")
				$bBackground = _AssocFlag($section[$i], "background")
				$bExt = _AssocHasExt($mode)
				$bNeedMain = ($bFiles Or $bRecycle Or $bBackground Or $bExt) ; targets that use the Command
				If $section[$i] = "" Or $title = "none" Or Not ($bNeedMain Or $bDrives Or $bFolders) Or _
						($bNeedMain And $cmdRaw = "") Or ($bDrives And $cmdDrive = "") Or ($bFolders And $cmdFolder = "") Then ; if any errors reading INI, goto next section
					MsgBox(0, "Error", "Error reading INI section." & @CRLF & "Section = `" & $section[$i] & "`")
					ContinueLoop
				EndIf
				$bAdmin = _AssocFlag($section[$i], "admin") ; run as administrator
				$bSingle = _AssocFlag($section[$i], "single") ; single selected item only (files, folders, drives, extensions)
				$command = _RegCommandFor($cmdRaw, $bAdmin) ; commands with %%1 get the multi-file launcher
				$sBase = "HKCU\Software\Classes\"
				; special targets
				If $bFiles Then _WriteVerb($sBase & "*\shell\PortableFileAssoc_" & $section[$i], $title, $command, $icon, $bSingle)
				If $bFolders Then _WriteVerb($sBase & "Directory\shell\PortableFileAssoc_" & $section[$i], $title, _RegCommandFor($cmdFolder, $bAdmin), $icon, $bSingle)
				If $bDrives Then _WriteVerb($sBase & "Drive\shell\PortableFileAssoc_" & $section[$i], $title, _RegCommandFor($cmdDrive, $bAdmin), $icon, $bSingle)
				If $bBackground Then _WriteVerb($sBase & "Directory\Background\shell\PortableFileAssoc_" & $section[$i], $title, _RegCommandBg($cmdRaw, $bAdmin), $icon)
				If $bRecycle Then _WriteVerb($sBase & "CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\shell\" & $title, $title, _RegCommand($cmdRaw), $icon)
				; file extensions
				For $j = 1 To $mode[0]
					If $mode[$j] = "" Then ContinueLoop ; no blank extension
					; EXE/COM get a context-menu verb on their existing Windows class.
					; This does not replace or modify their default open action.
					Switch StringLower($mode[$j])
						Case "exe"
							$targetClass = "exefile"
						Case "com"
							$targetClass = "comfile"
						Case Else
							$targetClass = "PortableFileAssoc_" & $mode[$j]
					EndSwitch
					; write association data
					$verbKey = $sBase & $targetClass & "\shell\PFA_" & $i & "_" & $j
					_WriteVerb($verbKey, $title, $command, $icon, $bSingle)
					; Also write the same verb to SystemFileAssociations\.ext.  Windows ignores the .ext -> PortableFileAssoc_ext
					; link when the user has a default app chosen (FileExts\.ext\UserChoice, usual for mp3, mp4, ...), so the verb
					; in the PortableFileAssoc_ext class would not be shown.  SystemFileAssociations is always merged into the menu.
					If StringLower($mode[$j]) <> "exe" And StringLower($mode[$j]) <> "com" Then _
						_WriteVerb($sBase & "SystemFileAssociations\." & $mode[$j] & "\shell\PFA_" & $i & "_" & $j, $title, $command, $icon, $bSingle)
					; Only normal extensions are listed as configurable PFA file types.
					If StringLower($mode[$j]) <> "exe" And StringLower($mode[$j]) <> "com" Then
						$aDefaultAssociations[0] += 1
						_ArrayAdd($aDefaultAssociations, $mode[$j] & "," & $section[$i] & ",PFA_" & $i & "_" & $j)
					EndIf
				Next
				; backup Applications keys
				If $cmdRaw <> "" Then _AppKeyBackup(_GetExeName($cmdRaw))
				If $bDrives And $cmdDrive <> $cmdRaw Then _AppKeyBackup(_GetExeName($cmdDrive))
				If $bFolders And $cmdFolder <> $cmdRaw Then _AppKeyBackup(_GetExeName($cmdFolder))
			Next
			_WriteFtypeSettings()
			_RefreshNow()
			_DoSendToShortcuts()
		Case "remove" ; remove context menu entries
			If $state = 0 Then Return ; don't do anything if not installed
			; change state status
			IniWrite($stateini, "state", "state", "0")
			$state = 0
			$section = _ReadINISections()
			For $i = 1 To $section[0]
				If Number(IniRead($associni, $section[$i], "disabled", $GUI_UNCHECKED)) = $GUI_CHECKED Then ContinueLoop ; disabled association
				$mode = _SplitAssociationModes(IniRead($associni, $section[$i], "mode", "")) ; file extensions
				$title = IniRead($associni, $section[$i], "title", "none")
				If $section[$i] = "" Or $title = "none" Then ContinueLoop ; if any errors reading INI, goto next section
				$cmdRaw = ""
				$sRaw = IniRead($associni, $section[$i], "command", "")
				If $sRaw <> "" Then $cmdRaw = _GetFullCommand($sRaw)
				$cmdDrive = ""
				$sRaw = IniRead($associni, $section[$i], "drivecommand", "")
				If $sRaw <> "" Then $cmdDrive = _GetFullCommand($sRaw)
				If $cmdDrive = "" Then $cmdDrive = $cmdRaw
				$cmdFolder = ""
				$sRaw = IniRead($associni, $section[$i], "foldercommand", "")
				If $sRaw <> "" Then $cmdFolder = _GetFullCommand($sRaw)
				If $cmdFolder = "" Then $cmdFolder = $cmdRaw
				$sBase = "HKCU\Software\Classes\"
				If _AssocFlag($section[$i], "files") Then _RegDeleteVerb($sBase & "*\shell\PortableFileAssoc_" & $section[$i], $sBase & "*")
				If _AssocFlag($section[$i], "folders") Then _RegDeleteVerb($sBase & "Directory\shell\PortableFileAssoc_" & $section[$i], $sBase & "Directory")
				If _AssocFlag($section[$i], "drives") Then _RegDeleteVerb($sBase & "Drive\shell\PortableFileAssoc_" & $section[$i], $sBase & "Drive")
				If _AssocFlag($section[$i], "background") Then _RegDeleteVerb($sBase & "Directory\Background\shell\PortableFileAssoc_" & $section[$i], $sBase & "Directory")
				If _AssocFlag($section[$i], "recycle") Then _
						_RegDeleteVerb($sBase & "CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\shell\" & $title, $sBase & "CLSID")
				For $j = 1 To $mode[0]
					If $mode[$j] = "" Then ContinueLoop
					Switch StringLower($mode[$j])
						Case "exe"
							$targetClass = "exefile"
						Case "com"
							$targetClass = "comfile"
						Case Else
							$targetClass = "PortableFileAssoc_" & $mode[$j]
					EndSwitch
					RegDelete($sBase & $targetClass & "\shell\PFA_" & $i & "_" & $j)
					If StringLower($mode[$j]) <> "exe" And StringLower($mode[$j]) <> "com" Then _
						_RegDeleteVerb($sBase & "SystemFileAssociations\." & $mode[$j] & "\shell\PFA_" & $i & "_" & $j, _
								$sBase & "SystemFileAssociations\." & $mode[$j]) ; also removes the empty parent keys
				Next
				; reset default association array
				Dim $aDefaultAssociations[1] = [0]
				; restore Applications keys
				If $cmdRaw <> "" Then _AppKeyRestore(_GetExeName($cmdRaw))
				If _AssocFlag($section[$i], "drives") And $cmdDrive <> $cmdRaw Then _AppKeyRestore(_GetExeName($cmdDrive))
				If _AssocFlag($section[$i], "folders") And $cmdFolder <> $cmdRaw Then _AppKeyRestore(_GetExeName($cmdFolder))
			Next
			_RemoveFtypeSettings(True)
			_RefreshNow()
			_DoSendToShortcuts(False)
		Case Else ; invalid commandline
			MsgBox(16, "Error", "Invalid argument.")
			Exit
	EndSwitch
EndFunc

Func _Exit()
	If $onclose = 1 Then _FileAssociations("remove") ; remove entries
	; reset original listview window procedure and free the callback
	If $oldWndProc Then _WinAPI_SetWindowLong($hsLV, $GWL_WNDPROC, $oldWndProc)
	If $pWndProc Then DllCallbackFree($pWndProc)
	_ProfileIconsFree()
	Exit
EndFunc
#EndRegion Main Functions

#Region Association targets (tick boxes, Drive Command)
;=======================================================================================
; Special targets are stored as flags in the association INI section (1 = on):
;   files, folders, drives, recycle, background      (+ single = single selected item only)
; "mode" only holds file extensions.  "drivecommand" is the command for drives (empty = use "command").
;=======================================================================================
Func _IsChk($idCtrl)
	Return BitAND(GUICtrlRead($idCtrl), $GUI_CHECKED) = $GUI_CHECKED
EndFunc

Func _AssocSetChk($idCtrl, $bOn)
	If $bOn Then
		GUICtrlSetState($idCtrl, $GUI_CHECKED)
	Else
		GUICtrlSetState($idCtrl, $GUI_UNCHECKED)
	EndIf
EndFunc

Func _AssocFlag($sSection, $sKey)
	Return Number(IniRead($associni, $sSection, $sKey, 0)) = 1
EndFunc

Func _AssocWriteFlag($sSection, $sKey, $bOn)
	If $bOn Then
		IniWrite($associni, $sSection, $sKey, "1")
	Else
		IniDelete($associni, $sSection, $sKey)
	EndIf
EndFunc

Func _AssocHasExt($aMode) ; $aMode = _SplitAssociationModes() array
	Local $k
	For $k = 1 To $aMode[0]
		If StringStripWS($aMode[$k], 3) <> "" Then Return True
	Next
	Return False
EndFunc

Func _AssocUpdateControls()
	; Files = every file (* wildcard): no extensions needed.
	; Drives and Folders have their own command. Only folders / drives: the main Command is not needed.
	Local $bFiles = _IsChk($chkFiles), $bFolders = _IsChk($chkFolders), $bDrives = _IsChk($chkDrives)
	Local $bRecycle = _IsChk($chkRecycle), $bBackground = _IsChk($chkBackground)
	Local $bUsesMain = ($bFiles Or $bRecycle Or $bBackground Or StringStripWS(GUICtrlRead($iMode), 8) <> "")
	Local $iState

	If $bFiles Then
		GUICtrlSetState($iMode, $GUI_DISABLE)
	Else
		GUICtrlSetState($iMode, $GUI_ENABLE)
	EndIf

	$iState = $GUI_DISABLE
	If $bDrives Then $iState = $GUI_ENABLE
	GUICtrlSetState($iDriveCmd, $iState)
	GUICtrlSetState($bBtnDrive, $iState)

	$iState = $GUI_DISABLE
	If $bFolders Then $iState = $GUI_ENABLE
	GUICtrlSetState($iFolderCmd, $iState)
	GUICtrlSetState($bBtnFolder, $iState)

	$iState = $GUI_ENABLE
	If Not $bUsesMain And ($bDrives Or $bFolders) Then $iState = $GUI_DISABLE
	GUICtrlSetState($iCommand, $iState)
	GUICtrlSetState($bBtn, $iState)
EndFunc

Func _MigrateAssocINI()
	; older INI files kept drives / files / folders / recycle / background in "mode":  convert them to the flags
	Local $aSec = IniReadSectionNames($associni), $i, $j, $aMode, $sKeep, $sTok, $aFlag[5], $bAny, $sCmd
	If @error Then Return
	For $i = 1 To $aSec[0]
		$aMode = _SplitAssociationModes(IniRead($associni, $aSec[$i], "mode", ""))
		$sKeep = ""
		$bAny = False
		For $j = 0 To 4
			$aFlag[$j] = 0
		Next
		For $j = 1 To $aMode[0]
			$sTok = StringStripWS($aMode[$j], 3)
			Switch StringLower($sTok)
				Case "file", "files"
					$aFlag[0] = 1
					$bAny = True
				Case "folder", "folders"
					$aFlag[1] = 1
					$bAny = True
				Case "drive", "drives"
					$aFlag[2] = 1
					$bAny = True
				Case "recycle"
					$aFlag[3] = 1
					$bAny = True
				Case "background"
					$aFlag[4] = 1
					$bAny = True
				Case ""
					; skip
				Case Else
					If $sKeep <> "" Then $sKeep &= "|"
					$sKeep &= $sTok
			EndSwitch
		Next
		If Not $bAny Then ContinueLoop
		If $aFlag[0] Then $sKeep = "" ; "files" = every file, extensions are not needed
		IniWrite($associni, $aSec[$i], "mode", $sKeep)
		_AssocWriteFlag($aSec[$i], "files", $aFlag[0])
		_AssocWriteFlag($aSec[$i], "folders", $aFlag[1])
		_AssocWriteFlag($aSec[$i], "drives", $aFlag[2])
		_AssocWriteFlag($aSec[$i], "recycle", $aFlag[3])
		_AssocWriteFlag($aSec[$i], "background", $aFlag[4])
		; only for drives: the old command becomes the Drive Command
		If $aFlag[2] And Not $aFlag[0] And Not $aFlag[1] And Not $aFlag[3] And Not $aFlag[4] And $sKeep = "" Then
			$sCmd = IniRead($associni, $aSec[$i], "command", "")
			If $sCmd <> "" Then IniWrite($associni, $aSec[$i], "drivecommand", "'" & $sCmd & "'")
			IniDelete($associni, $aSec[$i], "command")
		EndIf
	Next
EndFunc

Func _MigrateFolderCmd()
	; older INI: a folders-only association used "command"; folders now have their own "foldercommand"
	Local $aSec = IniReadSectionNames($associni), $i, $sCmd, $sMode
	If @error Then Return
	For $i = 1 To $aSec[0]
		If Not _AssocFlag($aSec[$i], "folders") Then ContinueLoop
		If IniRead($associni, $aSec[$i], "foldercommand", "") <> "" Then ContinueLoop
		If _AssocFlag($aSec[$i], "files") Or _AssocFlag($aSec[$i], "recycle") Or _AssocFlag($aSec[$i], "background") Then ContinueLoop
		$sMode = StringStripWS(IniRead($associni, $aSec[$i], "mode", ""), 8)
		If $sMode <> "" Then ContinueLoop
		$sCmd = IniRead($associni, $aSec[$i], "command", "")
		If $sCmd = "" Then ContinueLoop
		IniWrite($associni, $aSec[$i], "foldercommand", "'" & $sCmd & "'")
		If _AssocFlag($aSec[$i], "drives") And IniRead($associni, $aSec[$i], "drivecommand", "") = "" Then _
			IniWrite($associni, $aSec[$i], "drivecommand", "'" & $sCmd & "'")
		IniDelete($associni, $aSec[$i], "command")
	Next
EndFunc

Func _WriteVerb($verbKey, $title, $command, $icon, $bSingleOnly = False)
	RegWrite($verbKey, "", "REG_SZ", $title)
	If $bSingleOnly Then
		RegWrite($verbKey, "MultiSelectModel", "REG_SZ", "Single") ; hidden when several items are selected
	Else
		RegDelete($verbKey, "MultiSelectModel")
	EndIf
	RegWrite($verbKey & "\command", "", "REG_SZ", $command)
	; Windows shell verbs support an Icon value on the verb key.
	If $icon <> "" Then
		RegWrite($verbKey, "Icon", "REG_SZ", $icon)
	Else
		RegDelete($verbKey, "Icon")
	EndIf
EndFunc

Func _RegDeleteVerb($sVerbKey, $sStopKey)
	; delete the verb key, then delete empty parent keys up to (and including) $sStopKey
	Local $sKey = $sVerbKey, $iPos
	RegDelete($sVerbKey)
	While 1
		$iPos = StringInStr($sKey, "\", 0, -1)
		If $iPos = 0 Then ExitLoop
		$sKey = StringLeft($sKey, $iPos - 1)
		If Not _RegKeyEmpty($sKey) Then ExitLoop
		RegDelete($sKey)
		If $sKey = $sStopKey Then ExitLoop
	WEnd
EndFunc

Func _AppKeyBackup($exename)
	If $exename = "" Then Return
	; if key and fake do not exist, backup original if it exists
	If Not _RegKeyExists("HKCU\Software\Classes\Applications\" & $exename & "_PFA") And _
			Not _RegKeyExists("HKCU\Software\Classes\Applications\" & $exename & "_none") Then
		If _RegKeyExists("HKCU\Software\Classes\Applications\" & $exename) Then ; key exists
			_RegMoveKey("HKCU\Software\Classes\Applications\" & $exename, _
					"HKCU\Software\Classes\Applications\" & $exename & "_PFA")
		Else
			; fake backup
			RegWrite("HKCU\Software\Classes\Applications\" & $exename & "_none")
		EndIf
	; else already backed up, leave it alone
	EndIf
	If IsAdmin() Then ; admin account
		If Not _RegKeyExists("HKLM\Software\Classes\Applications\" & $exename & "_PFA") And _
				Not _RegKeyExists("HKLM\Software\Classes\Applications\" & $exename & "_none") Then
			If _RegKeyExists("HKLM\Software\Classes\Applications\" & $exename) Then ; key exists
				_RegMoveKey("HKLM\Software\Classes\Applications\" & $exename, _
						"HKLM\Software\Classes\Applications\" & $exename & "_PFA")
			Else
				; fake backup
				RegWrite("HKLM\Software\Classes\Applications\" & $exename & "_none")
			EndIf
		; else already backed up, leave it alone
		EndIf
	EndIf
EndFunc

Func _AppKeyRestore($exename)
	If $exename = "" Then Return
	If _RegKeyExists("HKCU\Software\Classes\Applications\" & $exename & "_none") Then ; fake key exists
		; delete key and fake
		RegDelete("HKCU\Software\Classes\Applications\" & $exename)
		RegDelete("HKCU\Software\Classes\Applications\" & $exename & "_none")
	; fake key does not exist, restore backup if it exists
	ElseIf _RegKeyExists("HKCU\Software\Classes\Applications\" & $exename & "_PFA") Then ; key exists
		RegDelete("HKCU\Software\Classes\Applications\" & $exename)
		_RegMoveKey("HKCU\Software\Classes\Applications\" & $exename & "_PFA", _
				"HKCU\Software\Classes\Applications\" & $exename)
	; else already in original state
	EndIf
	If IsAdmin() Then ; admin account
		If _RegKeyExists("HKLM\Software\Classes\Applications\" & $exename & "_none") Then ; fake key exists
			; delete key and fake
			RegDelete("HKLM\Software\Classes\Applications\" & $exename)
			RegDelete("HKLM\Software\Classes\Applications\" & $exename & "_none")
		; fake key does not exist, restore backup if it exists
		ElseIf _RegKeyExists("HKLM\Software\Classes\Applications\" & $exename & "_PFA") Then ; key exists
			RegDelete("HKLM\Software\Classes\Applications\" & $exename)
			_RegMoveKey("HKLM\Software\Classes\Applications\" & $exename & "_PFA", _
					"HKLM\Software\Classes\Applications\" & $exename)
		; else already in original state
		EndIf
	EndIf
EndFunc
#EndRegion Association targets (tick boxes, Drive Command)

#Region Multi-file launcher (%%1)
;=======================================================================================
; A command that contains %%1 receives ALL selected files in ONE run:
;     "FastCopy.exe" %%1      ->      FastCopy.exe "file1" "file2" "file3"
; Explorer starts one process per selected file, so for such commands the registry entry is a small
; wrapper:  PFA.exe multi_open <hex command> "%1"
; The wrapper processes pool their files (temp queue files); the first one starts the real command.
; Files are passed in name order (same as Explorer's default sort).
;=======================================================================================
Func _RegCommand($command, $bAdmin = False)
	If Not StringInStr($command, "%%1") Then Return $command
	Local $sSelf = '"' & @ScriptFullPath & '"', $sMode = "multi_open"
	If Not @Compiled Then $sSelf = '"' & @AutoItExe & '" ' & $sSelf
	If $bAdmin Then $sMode = "multi_open_admin"
	; "%1." : the added dot keeps a drive root like E:\ from ending in \" (read as an escaped quote); the launcher removes it again
	Return $sSelf & " " & $sMode & " " & StringTrimLeft(StringToBinary($command, 4), 2) & ' "%1."'
EndFunc

Func _RegCommandFor($command, $bAdmin = False)
	; %%1 -> multi-file launcher, Run as Admin -> launcher with elevation, otherwise the plain command
	If StringInStr($command, "%%1") Then Return _RegCommand($command, $bAdmin)
	If $bAdmin Then Return _RegCommandBg($command, True, '"%1."')
	Return $command
EndFunc

Func _Launch($sCmd, $sWork, $bAdmin = False)
	; ShellExecute (not Run): programs that need administrator rights cannot be started by Run(),
	; ShellExecute shows the UAC prompt for them.  "runas" = always elevated.
	Local $aCmd = _CommandSplit($sCmd), $sVerb = "", $iRet
	Local $sExe = StringReplace($aCmd[0], '"', '')
	If $bAdmin Then $sVerb = "runas"
	$iRet = ShellExecute($sExe, $aCmd[1], $sWork, $sVerb)
	If Not $iRet And Not $bAdmin Then Run($sCmd, $sWork)
	Return $iRet
EndFunc

Func _MultiStamp() ; seconds counter, good enough to age out stale queue files
	Return @YEAR * 31622400 + @YDAY * 86400 + @HOUR * 3600 + @MIN * 60 + @SEC
EndFunc

Func _MultiHash($s)
	Local $h = 5381, $i
	For $i = 1 To StringLen($s)
		$h = Mod($h * 33 + Asc(StringMid($s, $i, 1)), 4294967291)
	Next
	Return Hex($h, 8)
EndFunc

Func _MultiCount($sBase)
	Local $hS = FileFindFirstFile($sBase & "*.q"), $n = 0
	If $hS = -1 Then Return 0
	While 1
		FileFindNextFile($hS)
		If @error Then ExitLoop
		$n += 1
	WEnd
	FileClose($hS)
	Return $n
EndFunc

Func _MultiCollect($sBase) ; read + delete all queue files, return sorted paths: [0] = count
	Local $aOut[64], $iN = 0, $hS, $hF, $sName, $sFile, $sData, $aLines, $i, $k, $lo, $hi, $mid, $r, $iNow = _MultiStamp()
	Local $aEmpty[1] = [0]
	$hS = FileFindFirstFile($sBase & "*.q")
	If $hS = -1 Then Return $aEmpty
	While 1
		$sName = FileFindNextFile($hS)
		If @error Then ExitLoop
		$sFile = @TempDir & "\" & $sName
		$hF = FileOpen($sFile, 128) ; UTF-8
		$sData = ""
		If $hF <> -1 Then
			$sData = FileRead($hF)
			FileClose($hF)
		EndIf
		FileDelete($sFile)
		$aLines = StringSplit(StringStripCR($sData), @LF, 2)
		If UBound($aLines) < 2 Then ContinueLoop
		If Number($aLines[0]) < $iNow - 60 Then ContinueLoop ; stale file from an old run
		For $i = 1 To UBound($aLines) - 1
			If $aLines[$i] = "" Then ContinueLoop
			If $iN >= UBound($aOut) Then ReDim $aOut[UBound($aOut) * 2]
			; binary insertion = natural name order
			$lo = 0
			$hi = $iN - 1
			While $lo <= $hi
				$mid = Int(($lo + $hi) / 2)
				$r = DllCall("shlwapi.dll", "int", "StrCmpLogicalW", "wstr", $aLines[$i], "wstr", $aOut[$mid])
				If @error Then ExitLoop
				If $r[0] < 0 Then
					$hi = $mid - 1
				Else
					$lo = $mid + 1
				EndIf
			WEnd
			For $k = $iN To $lo + 1 Step -1
				$aOut[$k] = $aOut[$k - 1]
			Next
			$aOut[$lo] = $aLines[$i]
			$iN += 1
		Next
	WEnd
	FileClose($hS)
	Local $aRes[$iN + 1]
	$aRes[0] = $iN
	For $i = 0 To $iN - 1
		$aRes[$i + 1] = $aOut[$i]
	Next
	Return $aRes
EndFunc

Func _MultiRun($sTemplate, $aPaths, $bAdmin = False)
	; replace %%1 with "file1" "file2" ... (split into several runs if the command line would get too long)
	Local $sWork = @WorkingDir, $i, $sList = "", $sItem, $iPos
	$sTemplate = StringReplace($sTemplate, '"%%1"', "%%1") ; "%%1" and %%1 mean the same
	$iPos = StringInStr($aPaths[1], "\", 0, -1)
	If $iPos >= 3 And FileExists(StringLeft($aPaths[1], $iPos)) Then $sWork = StringLeft($aPaths[1], $iPos)
	For $i = 1 To $aPaths[0]
		$sItem = $aPaths[$i]
		If StringRight($sItem, 1) = "\" Then $sItem &= "\" ; drive root E:\ must not escape the closing quote
		$sItem = '"' & $sItem & '"'
		If $sList <> "" And StringLen($sTemplate) + StringLen($sList) + StringLen($sItem) > 30000 Then
			_Launch(StringReplace($sTemplate, "%%1", $sList), $sWork, $bAdmin)
			$sList = ""
		EndIf
		If $sList <> "" Then $sList &= " "
		$sList &= $sItem
	Next
	If $sList <> "" Then _Launch(StringReplace($sTemplate, "%%1", $sList), $sWork, $bAdmin)
EndFunc

Func _MultiOpen($bAdmin = False)
	; $CmdLine: [1] = "multi_open", [2] = hex encoded command template, [3...] = selected path(s) + "."
	Local $sTemplate = BinaryToString(Binary("0x" & $CmdLine[2]), 4)
	If $sTemplate = "" Or Not StringInStr($sTemplate, "%%1") Then Return
	Local $sKey = _MultiHash($CmdLine[2])
	Local $sBase = @TempDir & "\PFA_multi_" & $sKey & "_"
	Local $sMine = $sBase & @AutoItPID
	Local $i, $sList = "", $sArg, $hFile, $aErr, $iLast, $iCount, $hQuiet, $hTotal, $aPaths

	For $i = 3 To $CmdLine[0]
		$sArg = $CmdLine[$i]
		If StringRight($sArg, 1) = "." Then $sArg = StringTrimRight($sArg, 1) ; remove the protective dot
		If $sArg <> "" Then $sList &= $sArg & @LF
	Next
	If $sList = "" Then Return

	; publish this process' path(s)
	$hFile = FileOpen($sMine & ".tmp", 2 + 128)
	If $hFile = -1 Then Return
	FileWrite($hFile, _MultiStamp() & @LF & $sList)
	FileClose($hFile)
	FileMove($sMine & ".tmp", $sMine & ".q", 1)

	; only the first process (mutex owner) collects the files and starts the command
	DllCall("kernel32.dll", "handle", "CreateMutexW", "ptr", 0, "bool", False, "wstr", "PFA_multi_" & $sKey)
	$aErr = DllCall("kernel32.dll", "dword", "GetLastError")
	If Not @error And $aErr[0] = 183 Then Return ; ERROR_ALREADY_EXISTS: another process is collecting

	While 1
		; wait until no new file has been published for 1500 ms (max 30 s)
		$iLast = -1
		$hQuiet = TimerInit()
		$hTotal = TimerInit()
		While TimerDiff($hTotal) < 30000
			$iCount = _MultiCount($sBase)
			If $iCount <> $iLast Then
				$iLast = $iCount
				$hQuiet = TimerInit()
			ElseIf TimerDiff($hQuiet) >= 1500 Then
				ExitLoop
			EndIf
			Sleep(50)
		WEnd
		$aPaths = _MultiCollect($sBase)
		If $aPaths[0] = 0 Then ExitLoop
		_MultiRun($sTemplate, $aPaths, $bAdmin)
	WEnd
EndFunc
#EndRegion Multi-file launcher (%%1)

#Region Background launcher (%V)
;=======================================================================================
; "background" = empty space of a folder window / the desktop (like "Open Terminal here").
; The command gets the current folder through %V, e.g.   "wt.exe" -d "%V"   or   cmd.exe /k cd /d "%V"
; Registry entry:  PFA.exe bg_open <hex command> "%V."   (the added dot keeps a drive root like C:\ from
; ending in \" which most programs read as an escaped quote). The launcher removes the dot again,
; starts the command in that folder and passes the path safely quoted (C:\ becomes "C:\\").
;=======================================================================================
Func _RegCommandBg($command, $bAdmin = False, $sArg = '"%V."')
	Local $sSelf = '"' & @ScriptFullPath & '"', $sMode = "bg_open"
	If Not @Compiled Then $sSelf = '"' & @AutoItExe & '" ' & $sSelf
	If $bAdmin Then $sMode = "bg_open_admin"
	Return $sSelf & " " & $sMode & " " & StringTrimLeft(StringToBinary($command, 4), 2) & " " & $sArg
EndFunc

Func _BgOpen($bAdmin = False)
	; $CmdLine: [1] = "bg_open", [2] = hex encoded command template, [3...] = path + "."
	Local $sTemplate = BinaryToString(Binary("0x" & $CmdLine[2]), 4)
	Local $sPath = "", $sWork = @WorkingDir, $sQ, $i, $iP
	If $sTemplate = "" Then Return
	For $i = 3 To $CmdLine[0] ; join, in case the path was split at spaces
		If $sPath <> "" Then $sPath &= " "
		$sPath &= $CmdLine[$i]
	Next
	$sPath = StringReplace($sPath, '"', "")
	If StringRight($sPath, 1) = "." Then $sPath = StringTrimRight($sPath, 1) ; remove the protective dot
	If $sPath <> "" And FileExists($sPath) Then
		If StringInStr(FileGetAttrib($sPath), "D") Then
			$sWork = $sPath
		Else ; a file: work in its folder
			$iP = StringInStr($sPath, "\", 0, -1)
			If $iP > 2 Then $sWork = StringLeft($sPath, $iP)
		EndIf
	EndIf
	If $sPath = "" Then $sPath = $sWork
	; path as one quoted argument; a trailing \ is doubled so it cannot escape the closing quote
	$sQ = $sPath
	If StringRight($sQ, 1) = "\" Then $sQ &= "\"
	$sQ = '"' & $sQ & '"'
	; %V, %1 and %%1 all mean "this item", with or without quotes
	$sTemplate = StringReplace($sTemplate, '"%V"', "%V")
	$sTemplate = StringReplace($sTemplate, '"%%1"', "%V")
	$sTemplate = StringReplace($sTemplate, '"%1"', "%V")
	$sTemplate = StringReplace($sTemplate, "%%1", "%V")
	$sTemplate = StringReplace($sTemplate, "%1", "%V")
	_Launch(StringReplace($sTemplate, "%V", $sQ), $sWork, $bAdmin)
EndFunc
#EndRegion Background launcher (%V)

#Region Theme (light / dark)
;=======================================================================================
; Theme: System / Light / Dark. Saved in Data\settings\profile.ini ([profile] theme=system|light|dark)
;=======================================================================================
Func _ThemeModeName()
	Switch $iThemeMode
		Case 1
			Return "light"
		Case 2
			Return "dark"
	EndSwitch
	Return "system"
EndFunc

Func _BGR($iRGB) ; swap RGB <-> BGR (COLORREF)
	Return BitOR(BitShift(BitAND($iRGB, 0xFF), -16), BitAND($iRGB, 0xFF00), BitShift(BitAND($iRGB, 0xFF0000), 16))
EndFunc

Func _ThemeLoad()
	Local $s = IniRead($settingsini, "settings", "theme", "system"), $aRet, $v, $i
	Switch $s
		Case "light"
			$iThemeMode = 1
		Case "dark"
			$iThemeMode = 2
		Case Else
			$iThemeMode = 0
	EndSwitch
	; current system dialog colour (used for light mode)
	$aRet = DllCall("user32.dll", "int", "GetSysColor", "int", 15) ; COLOR_3DFACE
	If Not @error Then $iLightBg = _BGR($aRet[0])
	$fDark = ($iThemeMode = 2)
	If $iThemeMode = 0 Then
		$v = RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
		If Not @error And $v = 0 Then $fDark = True
	EndIf
	If $fDark Then
		$iBgCol = 0x202020
		$iCtrlCol = 0x2B2B2B
		$iTextCol = 0xF0F0F0
	Else
		$iBgCol = $iLightBg
		$iCtrlCol = 0xFFFFFF
		$iTextCol = 0x000000
	EndIf
	For $i = 0 To UBound($aMutedLbl) - 1
		$aMutedLbl[$i][2] = 0xA0A0A0 ; muted label colour in dark mode
	Next
EndFunc

Func _ThemeEvent()
	Local $m = "system"
	Switch GUICtrlRead($stTheme)
		Case "Light"
			$m = "light"
		Case "Dark"
			$m = "dark"
	EndSwitch
	IniWrite($settingsini, "settings", "theme", $m)
	_ThemeLoad()
	_ThemeApply()
EndFunc

Func _OSBuildAtLeast($iBuild)
	; Windows 10 / 11 build number check (Windows 7 = 7601, Windows 10 1903 = 18362)
	Return (Number(@OSBuild) >= $iBuild)
EndFunc

Func _ThemeClass($h)
	Local $tBuf = DllStructCreate("wchar[64]")
	Local $a = DllCall("user32.dll", "int", "GetClassNameW", "hwnd", $h, "struct*", $tBuf, "int", 64)
	If @error Or $a[0] = 0 Then Return ""
	Return DllStructGetData($tBuf, 1)
EndFunc

Func _ThemeSetWT($h, $sTheme)
	; $sTheme: "" = default visual style, "classic" = no visual style, otherwise a theme name
	If $sTheme = "" Then
		DllCall("uxtheme.dll", "long", "SetWindowTheme", "hwnd", $h, "ptr", 0, "ptr", 0)
	ElseIf $sTheme = "classic" Then
		DllCall("uxtheme.dll", "long", "SetWindowTheme", "hwnd", $h, "wstr", "", "wstr", "")
	Else
		DllCall("uxtheme.dll", "long", "SetWindowTheme", "hwnd", $h, "wstr", $sTheme, "ptr", 0)
	EndIf
EndFunc

Func _ThemeApply($hOnly = 0)
	; $hOnly = 0: all main GUIs (+ tray/menus, SendTo list, icons); otherwise only the given GUI (e.g. a dialog)
	Local $aTargets[6] = [$nGUI, $aGUI, $tGUI, $sGUI, $stGUI, $rdGUI], $iCount = 6
	Local $sBtn = "", $sEdit = "", $sList = "", $sClassic = ""
	Local $id, $iMax, $h, $sClass, $iStyle, $iType, $j, $aRet, $bMuted, $iBk, $iVal = 0, $hHdr
	If $hOnly Then
		$aTargets[0] = $hOnly
		$iCount = 1
	EndIf
	If $fDark Then
		$sBtn = "DarkMode_Explorer"
		$sEdit = "DarkMode_CFD"
		$sList = "DarkMode_Explorer"
		$sClassic = "classic"
		$iVal = 1
	EndIf

	If Not $hOnly Then
		; dark popup / tray menus (uxtheme ordinals: 135 = SetPreferredAppMode, 136 = FlushMenuThemes).
		; These ordinals only exist as such in Windows 10 1903 (build 18362) and newer.  On older Windows (Windows 7 ...) the same
		; ordinals are other functions, calling them crashes the program (APPCRASH), so they are skipped there.
		If _OSBuildAtLeast(18362) Then
			If $fDark Then
				DllCall("uxtheme.dll", "int", 135, "int", 2)
			Else
				DllCall("uxtheme.dll", "int", 135, "int", 0)
			EndIf
			DllCall("uxtheme.dll", "none", 136)
		EndIf
	EndIf

	; window background + title bar
	For $j = 0 To $iCount - 1
		GUISetBkColor($iBgCol, $aTargets[$j])
		If _OSBuildAtLeast(17763) Then ; dark title bar attributes exist since Windows 10 1809
			DllCall("dwmapi.dll", "long", "DwmSetWindowAttribute", "hwnd", $aTargets[$j], "dword", 20, "int*", $iVal, "dword", 4)
			DllCall("dwmapi.dll", "long", "DwmSetWindowAttribute", "hwnd", $aTargets[$j], "dword", 19, "int*", $iVal, "dword", 4)
		EndIf
	Next

	; controls
	$iMax = GUICtrlCreateDummy()
	GUICtrlDelete($iMax)
	For $id = 3 To $iMax
		$h = GUICtrlGetHandle($id)
		If Not $h Then ContinueLoop
		If $hOnly Then
			$aRet = DllCall("user32.dll", "hwnd", "GetAncestor", "hwnd", $h, "uint", 2) ; GA_ROOT
			If @error Or $aRet[0] <> $hOnly Then ContinueLoop
		EndIf
		$sClass = _ThemeClass($h)
		If $sClass = "" Then ContinueLoop
		$aRet = DllCall("user32.dll", "long", "GetWindowLongW", "hwnd", $h, "int", -16) ; GWL_STYLE
		If @error Then ContinueLoop
		$iStyle = $aRet[0]
		Switch $sClass
			Case "Button"
				$iType = BitAND($iStyle, 0xF)
				Switch $iType
					Case 0, 1 ; push button
						_ThemeSetWT($h, $sBtn)
					Case 2, 3, 4, 5, 6, 7, 9 ; checkbox, radio, group box
						_ThemeSetWT($h, $sClassic)
						GUICtrlSetColor($id, $iTextCol)
				EndSwitch
			Case "Edit", "ComboBox"
				_ThemeSetWT($h, $sEdit)
				$iBk = $iCtrlCol
				If Not $fDark And BitAND($iStyle, 0x800) Then $iBk = $iLightBg ; read-only edit keeps its grey
				GUICtrlSetBkColor($id, $iBk)
				GUICtrlSetColor($id, $iTextCol)
			Case "ListBox"
				_ThemeSetWT($h, $sList)
				GUICtrlSetBkColor($id, $iCtrlCol)
				GUICtrlSetColor($id, $iTextCol)
			Case "msctls_updown32"
				_ThemeSetWT($h, $sBtn)
			Case "Static"
				$iType = BitAND($iStyle, 0x1F)
				If $iType <= 2 Then ; text labels only (skip icons, bitmaps and frames)
					$bMuted = False
					For $j = 0 To UBound($aMutedLbl) - 1
						If $aMutedLbl[$j][0] = $id Then $bMuted = True
					Next
					If Not $bMuted Then GUICtrlSetColor($id, $iTextCol)
				EndIf
		EndSwitch
	Next

	If Not $hOnly Then
		; muted labels
		For $j = 0 To UBound($aMutedLbl) - 1
			If $fDark Then
				GUICtrlSetColor($aMutedLbl[$j][0], $aMutedLbl[$j][2])
			Else
				GUICtrlSetColor($aMutedLbl[$j][0], $aMutedLbl[$j][1])
			EndIf
		Next
		; SendTo list view (not an AutoIt control)
		If $fDark Then
			_ThemeSetWT($hsLV, "DarkMode_Explorer")
		Else
			_ThemeSetWT($hsLV, "")
		EndIf
		$hHdr = _GUICtrlListView_GetHeader($hsLV)
		If $hHdr Then
			If $fDark Then
				_ThemeSetWT($hHdr, "DarkMode_ItemsView")
			Else
				_ThemeSetWT($hHdr, "ItemsView")
			EndIf
		EndIf
		DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hsLV, "uint", 0x1001, "wparam", 0, "lparam", _BGR($iCtrlCol)) ; LVM_SETBKCOLOR
		DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hsLV, "uint", 0x1026, "wparam", 0, "lparam", _BGR($iCtrlCol)) ; LVM_SETTEXTBKCOLOR
		DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hsLV, "uint", 0x1024, "wparam", 0, "lparam", _BGR($iTextCol)) ; LVM_SETTEXTCOLOR
		; profile action icons in the matching colour (black on light, white on dark)
		_ProfileIconsReload()
	EndIf

	; repaint (RDW_INVALIDATE | RDW_ERASE | RDW_FRAME | RDW_ALLCHILDREN | RDW_UPDATENOW)
	For $j = 0 To $iCount - 1
		DllCall("user32.dll", "bool", "RedrawWindow", "hwnd", $aTargets[$j], "ptr", 0, "ptr", 0, "uint", 0x585)
	Next
EndFunc
#EndRegion Theme (light / dark)

#Region Settings (Data\settings\settings.ini)
;=======================================================================================
; Settings window (gear icon).  Saved in Data\settings\settings.ini, section [settings]:
;     theme=system | light | dark
;     addassociationonstart=true / false     add the associations when PFA starts (without command line arguments)
;     removeonexit=true / false              remove the associations when PFA is closed
;     checkupdateonstartup=true / false      look for a new version in the background when PFA starts
;     startminimized=true / false            true = start minimized to the tray, false = show the main window
;     closetotray=true / false               true = the close button (X) minimizes to the tray
; (true, 1, yes, on = on;  false, 0, blank = off).  Only the splash setting is in <exe name>.ini next to the exe
; (DisableSplash=true).  profile.ini only keeps profile data ([profile] active=<last profile>).
;=======================================================================================
Func _SettingGet($sKey, $bDefault)
	Local $s = IniRead($settingsini, "settings", $sKey, "__none__")
	If $s = "__none__" Then Return $bDefault
	$s = StringLower(StringStripWS($s, 8))
	Return ($s = "true" Or $s = "1" Or $s = "yes" Or $s = "on")
EndFunc

Func _SettingSet($sKey, $bOn)
	If $bOn Then
		IniWrite($settingsini, "settings", $sKey, "true")
	Else
		IniWrite($settingsini, "settings", $sKey, "false")
	EndIf
EndFunc

Func _SettingsLoad()
	$fSetAddStart = _SettingGet("addassociationonstart", False)
	$fSetRemoveExit = _SettingGet("removeonexit", True)
	$fSetCheckUpd = _SettingGet("checkupdateonstartup", True)
	$fSetStartMin = _SettingGet("startminimized", False)
	$fSetCloseTray = _SettingGet("closetotray", False)
	$onclose = Number($fSetRemoveExit)
EndFunc

Func _SettingsMigrate()
	; First start with settings.ini: take over the settings of older versions so nothing is lost by the update.
	;   profile.ini  [profile] theme=            -> theme
	;   profile.ini  [profile] commandline=add_gui [profile]  -> addassociationonstart + startminimized (+ active profile)
	;   <profile>_state.ini [state] onclose=     -> removeonexit   (it used to be saved per profile)
	;   <exe name>.ini DisableUpdateCheck=true   -> checkupdateonstartup=false
	; The old commandline / theme lines are removed from profile.ini.
	If FileExists($settingsini) Then Return
	Local $sTheme = IniRead($profileini, "profile", "theme", "system")
	Local $sCmd = StringStripWS(IniRead($profileini, "profile", "commandline", ""), 3)
	Local $sProf = IniRead($profileini, "profile", "active", "")
	Local $bAdd = False, $bMin = False, $bRemove = True, $bUpd = True, $sMode = $sCmd, $sArg = "", $iSp, $iOld
	If $sCmd <> "" Then
		$iSp = StringInStr($sCmd, " ")
		If $iSp > 0 Then
			$sMode = StringLeft($sCmd, $iSp - 1)
			$sArg = StringStripWS(StringReplace(StringTrimLeft($sCmd, $iSp), '"', ""), 3)
		EndIf
		If $sMode = "add_gui" Then
			$bAdd = True
			$bMin = True
			If $sArg <> "" And FileExists($settingsdir & "\" & $sArg & "_assoc.ini") Then
				IniWrite($profileini, "profile", "active", $sArg) ; add_gui <profile>: that profile is the active one
				$sProf = $sArg
			EndIf
		EndIf
	EndIf
	If $sProf <> "" Then
		$iOld = Number(IniRead($settingsdir & "\" & $sProf & "_state.ini", "state", "onclose", "-1"))
		If $iOld = 0 Then $bRemove = False
	EndIf
	If _ExeIniFlag("DisableUpdateCheck") Then $bUpd = False
	If $sTheme <> "light" And $sTheme <> "dark" Then $sTheme = "system"
	IniWrite($settingsini, "settings", "theme", $sTheme)
	_SettingSet("addassociationonstart", $bAdd)
	_SettingSet("removeonexit", $bRemove)
	_SettingSet("checkupdateonstartup", $bUpd)
	_SettingSet("startminimized", $bMin)
	_SettingSet("closetotray", False)
	IniDelete($profileini, "profile", "commandline")
	IniDelete($profileini, "profile", "theme")
EndFunc

Func _SettingsSync()
	; show the current settings in the Settings window
	GUICtrlSetData($stTheme, "") ; clear first: GUICtrlSetData adds to the list of a combo
	GUICtrlSetData($stTheme, "System|Light|Dark", StringUpper(StringLeft(_ThemeModeName(), 1)) & StringTrimLeft(_ThemeModeName(), 1))
	_AssocSetChk($stAddStart, $fSetAddStart)
	_AssocSetChk($stRemoveExit, $fSetRemoveExit)
	_AssocSetChk($stCheckUpd, $fSetCheckUpd)
	_AssocSetChk($stStartMin, $fSetStartMin)
	_AssocSetChk($stNoSplash, _ExeIniFlag("DisableSplash"))
	_AssocSetChk($stCloseTray, $fSetCloseTray)
EndFunc

Func _SettingsApply()
	; every tick box is saved as soon as it is clicked
	$fSetAddStart = _IsChk($stAddStart)
	$fSetRemoveExit = _IsChk($stRemoveExit)
	$fSetCheckUpd = _IsChk($stCheckUpd)
	$fSetStartMin = _IsChk($stStartMin)
	$fSetCloseTray = _IsChk($stCloseTray)
	_SettingSet("addassociationonstart", $fSetAddStart)
	_SettingSet("removeonexit", $fSetRemoveExit)
	_SettingSet("checkupdateonstartup", $fSetCheckUpd)
	_SettingSet("startminimized", $fSetStartMin)
	_SettingSet("closetotray", $fSetCloseTray)
	$onclose = Number($fSetRemoveExit)
	If _IsChk($stNoSplash) <> _ExeIniFlag("DisableSplash") Then _ExeIniSet("DisableSplash", _IsChk($stNoSplash))
EndFunc

Func _SettingsGUI()
	_SettingsSync()
	GUISetState(@SW_DISABLE, $nGUI) ; disable main GUI
	GUISetState(@SW_SHOW, $stGUI)
EndFunc

Func _SettingsClose()
	GUISetState(@SW_HIDE, $stGUI)
	GUISetState(@SW_ENABLE, $nGUI)
	WinActivate($nGUI)
EndFunc

Func _ExeIniMigrateOldName()
	; The program was called PortableFileAssociator before: copy its PortableFileAssociator.ini (DisableSplash,
	; DisableUpdateCheck) to the new <exe name>.ini once, so these settings are not lost by the rename.
	Local $sOld = @ScriptDir & "\PortableFileAssociator.ini", $sNew = _ExeIniPath()
	If FileExists($sOld) And Not FileExists($sNew) And StringLower($sOld) <> StringLower($sNew) Then FileCopy($sOld, $sNew)
EndFunc

Func _ExeIniPath()
	; <exe name>.ini in the folder of the exe (ie FileAssociatorPortable.ini), see _ExeIniFlag
	Return @ScriptDir & "\" & StringRegExpReplace(@ScriptName, "\.[^.]*$", "") & ".ini"
EndFunc

Func _ExeIniSet($sKey, $bOn)
	; writes  <key>=true / false  into <exe name>.ini (changes an existing line, otherwise adds it)
	Local $sIni = _ExeIniPath(), $sTxt = "", $sVal = "false", $iEnc = 0, $hFile
	If $bOn Then $sVal = "true"
	If FileExists($sIni) Then
		$iEnc = FileGetEncoding($sIni)
		If $iEnc < 0 Then $iEnc = 0
		$sTxt = FileRead($sIni)
		If StringRegExp($sTxt, "(?im)^\s*" & $sKey & "\s*=") Then
			$sTxt = StringRegExpReplace($sTxt, "(?im)^(\s*" & $sKey & "\s*=)[^\r\n]*", "\1" & $sVal)
		Else
			If $sTxt <> "" And Not (StringRight($sTxt, 1) = @LF) Then $sTxt &= @CRLF
			$sTxt &= $sKey & "=" & $sVal & @CRLF
		EndIf
	Else
		If Not $bOn Then Return ; nothing to disable, no file needed
		$sTxt = "[FileAssociatorPortable]" & @CRLF & $sKey & "=" & $sVal & @CRLF
	EndIf
	$hFile = FileOpen($sIni, 2 + $iEnc) ; overwrite, keep the encoding
	If $hFile = -1 Then
		MsgBox(48, "Settings", "Could not write " & $sIni)
		Return
	EndIf
	FileWrite($hFile, $sTxt)
	FileClose($hFile)
EndFunc
#EndRegion Settings (Data\settings\settings.ini)

#Region Profile action icons
; Icons converted from the SVG files: New_Profile.svg, Clone_Profile.svg, Rename_Profile.svg, Remove_Profile.svg, Settings.svg
; Embedded as 32x32 PNG (base64), no extra files needed. Variants per icon:
;   <Name>               black   (light theme)        <Name>_Disabled        grey (light theme, disabled)
;   <Name>_Dark          white   (dark theme)         <Name>_Dark_Disabled   grey (dark theme, disabled)

Func _ProfileIconsReload()
	Local $i, $j, $sName, $bBin, $hBmp, $hHBmp, $iBg, $sSuffix = ""
	If Not $fGDIP Then $fGDIP = _GDIPlus_Startup()
	If Not $fGDIP Then Return
	Local $aOld = $aProfIcons
	$iBg = BitOR(0xFF000000, $iBgCol) ; blend transparent PNG with the current window colour
	If $fDark Then $sSuffix = "_Dark"
	For $i = 0 To 4
		For $j = 0 To 1
			$aProfIcons[$i][$j] = 0
			$sName = $aProfIconNames[$i] & $sSuffix
			If $j = 1 Then $sName &= "_Disabled"
			$bBin = _B64ToBinary(_ProfileIconData($sName))
			If @error Then ContinueLoop
			$hBmp = _GDIPlus_BitmapCreateFromMemory($bBin)
			If $hBmp = 0 Then ContinueLoop
			$hHBmp = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBmp, $iBg)
			_GDIPlus_BitmapDispose($hBmp)
			$aProfIcons[$i][$j] = $hHBmp
		Next
	Next
	_ProfileIconsSet($state = 0)
	If $aProfIcons[4][0] Then GUICtrlSendMsg($nSettings, 0x0172, 0, $aProfIcons[4][0]) ; Settings icon is always enabled
	; free the previous bitmaps after the controls switched to the new ones
	For $i = 0 To 4
		For $j = 0 To 1
			If $aOld[$i][$j] Then DllCall("gdi32.dll", "bool", "DeleteObject", "handle", $aOld[$i][$j])
		Next
	Next
EndFunc

Func _ProfileIconsSet($bEnabled)
	Local $aCtrl[4] = [$nNew, $nClone, $nRename, $nRemove], $i, $h, $iIdx = 1
	If $bEnabled Then $iIdx = 0
	For $i = 0 To 3
		$h = $aProfIcons[$i][$iIdx]
		If $h Then GUICtrlSendMsg($aCtrl[$i], 0x0172, 0, $h) ; STM_SETIMAGE, IMAGE_BITMAP
	Next
EndFunc

Func _ProfileIconsFree()
	Local $i, $j
	For $i = 0 To 4
		For $j = 0 To 1
			If $aProfIcons[$i][$j] Then DllCall("gdi32.dll", "bool", "DeleteObject", "handle", $aProfIcons[$i][$j])
			$aProfIcons[$i][$j] = 0
		Next
	Next
	If $fGDIP Then _GDIPlus_Shutdown()
	$fGDIP = False
EndFunc

#Region Update checker
;=======================================================================================
; Update checker.  Reads the latest version from .github/version.pfa (GitHub, main branch), the file only contains the
; version number (ie 3.0.0.5).  If it is newer than the running version, a message offers the release page
;   https://github.com/ShihabUddinX/PortableFileAssociator/releases/tag/<version>
; Source 1 is the GitHub API (changes show up within seconds), source 2 is raw.githubusercontent.com (fallback, GitHub
; caches that for about 5 minutes).  The request is asynchronous (the program does not wait for the network), the main
; loop polls it (_UpdatePoll).
;=======================================================================================
Func _UpdateComErr($oErr)
	$iUpdateComErr = $oErr.number
EndFunc

Func _UpdateCheckManual()
	TrayTip("FileAssociatorPortable", "Checking for updates...", 3)
	_UpdateCheckStart(True)
EndFunc

Func _UpdateCheckStart($fManual = False)
	If $fManual Then $fUpdateManual = True ; show "up to date" / error messages too
	If IsObj($oUpdate) Then Return ; a check is already running
	ObjEvent("AutoIt.Error", "_UpdateComErr")
	$iUpdateStage = 1
	If Not _UpdateSend(1) Then _UpdateFail()
EndFunc

Func _UpdateSend($iStage)
	; starts the request of source 1 (GitHub API) or 2 (raw file), True = started
	Local $sUrl, $sStamp = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & @MSEC
	$iUpdateComErr = 0
	$oUpdate = ObjCreate("MSXML2.XMLHTTP.6.0")
	If Not IsObj($oUpdate) Then $oUpdate = ObjCreate("MSXML2.XMLHTTP")
	If Not IsObj($oUpdate) Then
		$oUpdate = 0
		Return False
	EndIf
	If $iStage = 1 Then
		$sUrl = $UPDATE_API_URL & "&t=" & $sStamp
	Else
		$sUrl = $UPDATE_VERSION_URL & "?t=" & $sStamp
	EndIf
	$oUpdate.open("GET", $sUrl, True)
	$oUpdate.setRequestHeader("Cache-Control", "no-cache, no-store")
	$oUpdate.setRequestHeader("Pragma", "no-cache")
	$oUpdate.setRequestHeader("User-Agent", "FileAssociatorPortable/" & $version)
	If $iStage = 1 Then $oUpdate.setRequestHeader("Accept", "application/vnd.github.raw+json") ; file content as plain text
	$oUpdate.send()
	If $iUpdateComErr Then
		$oUpdate = 0
		Return False
	EndIf
	$hUpdateTimer = TimerInit()
	Return True
EndFunc

Func _UpdateFail()
	; source 1 failed -> try source 2, otherwise the check failed
	$oUpdate = 0
	If $iUpdateStage = 1 Then
		$iUpdateStage = 2
		If _UpdateSend(2) Then Return
	EndIf
	$iUpdateStage = 0
	_UpdateFinish(False, "")
EndFunc

Func _UpdatePoll()
	If Not IsObj($oUpdate) Then Return
	Local $iState = $oUpdate.readyState, $iStatus = 0, $sText = ""
	If $iUpdateComErr Then
		_UpdateFail()
		Return
	EndIf
	If $iState <> 4 Then ; not finished yet
		If TimerDiff($hUpdateTimer) > 8000 Then ; give up this source after 8 seconds
			$oUpdate.abort()
			_UpdateFail()
		EndIf
		Return
	EndIf
	$iStatus = $oUpdate.status
	If $iStatus = 200 And Not $iUpdateComErr Then $sText = $oUpdate.responseText
	If $iStatus <> 200 Or $iUpdateComErr Then
		_UpdateFail()
		Return
	EndIf
	; the file only contains the version number: first line, no BOM / spaces
	$sText = StringStripWS(StringReplace($sText, ChrW(0xFEFF), ""), 3)
	$sText = StringStripWS(StringRegExpReplace($sText, "(?s)[\r\n].*$", ""), 3)
	If Not StringRegExp($sText, "^\d+(\.\d+){1,3}$") Then
		_UpdateFail()
		Return
	EndIf
	$oUpdate = 0
	$iUpdateStage = 0
	_UpdateFinish(True, $sText)
EndFunc

Func _UpdateFinish($bOK, $sLatest)
	Local $fManual = $fUpdateManual
	$fUpdateManual = False
	If Not $bOK Then
		If $fManual Then MsgBox(48 + 262144, "Check For Update", "Could not check for updates." & @CRLF & "Please check your internet connection and try again.")
		Return
	EndIf
	If _VersionIsNewer($sLatest, $version) Then
		If 1 = MsgBox(1 + 64 + 262144, "Update available", "A new version of FileAssociatorPortable is available." & @CRLF & @CRLF & _
				"Installed version:  " & $version & @CRLF & "Latest version:  " & $sLatest & @CRLF & @CRLF & _
				"Click OK to open the download page, or Cancel to close.") Then ShellExecute($UPDATE_RELEASE_URL & $sLatest)
	ElseIf $fManual Then
		MsgBox(64 + 262144, "Check For Update", "You are running the latest version (" & $version & ").")
	EndIf
EndFunc

Func _VersionIsNewer($sNew, $sCur)
	; True if version $sNew (ie 3.0.0.5) is higher than $sCur, compared number by number
	Local $a = StringSplit($sNew, "."), $b = StringSplit($sCur, "."), $i, $x, $y
	For $i = 1 To 4
		$x = 0
		$y = 0
		If $i <= $a[0] Then $x = Number($a[$i])
		If $i <= $b[0] Then $y = Number($b[$i])
		If $x > $y Then Return True
		If $x < $y Then Return False
	Next
	Return False
EndFunc
#EndRegion Update checker

Func _SplashDisabledByINI()
	Return _ExeIniFlag("DisableSplash")
EndFunc

Func _ExeIniFlag($sKey)
	; <exe name>.ini in the folder of the exe (ie FileAssociatorPortable.ini), optional, no section needed:
	;    DisableSplash=true        -> no splash screen
	;    DisableUpdateCheck=true   -> only read once, to take it over into Settings > Check for updates on startup
	; (missing file, missing key or any other value = False; true, 1, yes, on = True)
	Local $sIni = @ScriptDir & "\" & StringRegExpReplace(@ScriptName, "\.[^.]*$", "") & ".ini"
	If Not FileExists($sIni) Then Return False
	Local $sTxt = FileRead($sIni)
	If @error Or $sTxt = "" Then Return False
	Local $aM = StringRegExp($sTxt, "(?im)^\s*" & $sKey & "\s*=\s*([^\r\n;#]*)", 3)
	If @error Then Return False
	Local $sVal = StringLower(StringStripWS(StringReplace($aM[0], '"', ""), 8))
	Return ($sVal = "true" Or $sVal = "1" Or $sVal = "yes" Or $sVal = "on")
EndFunc

Func _SplashShow(ByRef $hTimer)
	; shows the embedded splash image (_SplashData.au3) in its own borderless window, returns the window handle (0 = no splash)
	Local $sFile = @TempDir & "\PFA_splash_" & @AutoItPID & ".jpg", $bData, $hFile, $hGUI, $idPic
	If _SplashDisabledByINI() Then Return 0
	$bData = _B64ToBinary(_SplashJpgBase64())
	If @error Or BinaryLen($bData) = 0 Then Return 0
	$hFile = FileOpen($sFile, 2 + 16) ; overwrite, binary
	If $hFile = -1 Then Return 0
	FileWrite($hFile, $bData)
	FileClose($hFile)
	$hGUI = GUICreate("FileAssociatorPortable splash", 416, 249, -1, -1, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
	$idPic = GUICtrlCreatePic($sFile, 0, 0, 416, 249) ; the image is loaded here, the file is not needed afterwards
	FileDelete($sFile)
	If $idPic = 0 Then
		GUIDelete($hGUI)
		Return 0
	EndIf
	GUISetState(@SW_SHOW, $hGUI)
	Sleep(50) ; let Windows draw the window before the work starts
	$hTimer = TimerInit()
	Return $hGUI
EndFunc

Func _SplashHide($hGUI, $hTimer)
	If Not $hGUI Then Return
	Local $iLeft = 2000 - TimerDiff($hTimer) ; show it for at least 2 seconds
	If $iLeft > 0 Then Sleep($iLeft)
	GUIDelete($hGUI)
EndFunc

Func _B64ToBinary($sB64)
	; CRYPT_STRING_BASE64 = 1
	Local $aRet = DllCall("crypt32.dll", "bool", "CryptStringToBinaryA", "str", $sB64, "dword", 0, "dword", 1, "ptr", 0, "dword*", 0, "ptr", 0, "ptr", 0)
	If @error Or Not $aRet[0] Then Return SetError(1, 0, Binary(""))
	Local $iSize = $aRet[5]
	Local $tBuf = DllStructCreate("byte[" & $iSize & "]")
	$aRet = DllCall("crypt32.dll", "bool", "CryptStringToBinaryA", "str", $sB64, "dword", 0, "dword", 1, "struct*", $tBuf, "dword*", $iSize, "ptr", 0, "ptr", 0)
	If @error Or Not $aRet[0] Then Return SetError(2, 0, Binary(""))
	Return DllStructGetData($tBuf, 1)
EndFunc

Func _ProfileIconData($sName)
	Local $s = ""
	Switch $sName
		Case "New_Profile"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABnklEQVR42u2VwStEURTGfzNMY4NS"
			$s &= "LJSMBSuhLLCws7Ing1KyGGoWZsNO/gF/AQtLUxNWlkgyNVmxV0iSDSILM8/mm7o9b2bem5lH6n11"
			$s &= "O7d77jn33HPudy4ECBCgMhqAJHAFfAF5zZNA+DcOzwBWiZHxO4gVHfQGLAItQCuwpDULSFTwkda+"
			$s &= "qWoCuJTxsoMuIV3OzwA+ZNzhoGuX7r2WACrVryAZctBFJPO11Lixgv4aGAHmgC2bLm7ssd/YxJjk"
			$s &= "qi0LWQefP7Cg9H0Ca0AM6AHWtWYB8zYby+VIl0qtiRCwLQY4YUeMMGGvdQoY1W2zxvo9cOG2VLPA"
			$s &= "CfCkcWyUAD9ZUA/UxALfUY4FncAkMA70A91As27zCtyKAWfAEfBQwk+x7nduAmoS5U7VA9y+6ILe"
			$s &= "SByIVpuNCUVZdPooBswAg0Cbmk9E8yEFuws8G3Y3yponxIzP5RyYNjqdG0TVD3Ly8QJ0eQlgU4YH"
			$s &= "LnpDOYSBQ/nacGsA0Cu5L+NqUQD2NO/zwoKiHKhDwxi2fVaeaJj6qz6Q9cF3lgAB/gO+AaHmeT4m"
			$s &= "/oNbAAAAAElFTkSuQmCC"
		Case "New_Profile_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACq0lEQVR42u1VMWgUURB9b3eDBgwK"
			$s &= "doeojUI02CjEFLESCwXByEVUELxjd8EiYgrrtZFUBwb0vF3PAwmRrCRBEGysDEh6o7Zi5IJVjhhI"
			$s &= "5G7/2PyE88xl94xRwXvV3z9//rydeTMfaKON/x2MOxCGoVmpVG6IiEOyGwBF5D1Jv1wu3/c8T20b"
			$s &= "gTAMzcXFxZDkwEZ2EZlaWFhIb4WEsZmxUqm4OvgygOzq6upuEdkjIjaAZZIDqVTK2eyOIAhC3/el"
			$s &= "UCikN7JbMQSz+k9vu677uG7/ke/7FoA8ySyAh9uSAQDdAKCUmvyJuWVNanJHtqKBOAJKB+MG9e/Q"
			$s &= "y2grBOJKMAegV0SuAsjVG2q12mWSIDnXWPMGon0AYBjGrSAI0nX7s47j5DYlICJ5kr0A7vq+3xFF"
			$s &= "0YRlWVRKXSLp6WMPGnzSTe7q+6H9yPgMOI7zJAiCUwAyAEZM0xwRkXVnAEXbtscaAg02BBoGcBJA"
			$s &= "TkRm12ur1OdEgwgACoXCFZIOgDXBvSPp27b9NM43CIJQRNIiMui67rNWNQAAcF13HMD4doxiA38Z"
			$s &= "TTNQLBZTtVrtLMl+AD0kD4hIFwABsATgk+6AGcMwXmaz2XIT8c3qbpmPfQtKpdLOarV6kaQjIv1J"
			$s &= "NaJJvSZZWFlZmRoaGvrW8mPk+/5pACUA+/TWFwAvALxSSn2wLGs+iqKvAGCaZpdSaj+AowDOkDwn"
			$s &= "Inu130eS12zbnklMIJ/PHzRN8y2AXQDeALgnItOu61aTXDI6Orqjs7MzDeCmiJwAsGRZVk8mk5lP"
			$s &= "pAHTNK/r4M9t275AUloRkk75mOd546lUahrA+SiKMgDuJO2CQ1ow060Gr4fneUpEJvTn4cRdQNLS"
			$s &= "E+5Ys3c7sajI43rZ8SttOFw3Zv/cHFjr1d+J+rnfRhv/NL4DOg4dyBbi9bcAAAAASUVORK5CYII="
		Case "New_Profile_Dark"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABwUlEQVR42u2VP0scURTFz1UX05jA"
			$s &= "loGgKRQSJAoWSYrtrOyVbFYIiIURLLKN6YJfwE+ghaULS2JlqSLiwJIq6QMqIsHG2FjE/dnchXHY"
			$s &= "zezMugZhDjzuzP33Dve++56UIUOGGAC9wBLwA/gLXPv3EtBzH5tXaY1qV0kAi77RJTAHPAaeAPOu"
			$s &= "A1iIyVFxv+k0BL578McmtgW31TohEFe+Fy6rTWwN3ctOqhxHoO7SmthyLq87IdAXY/8p6bWkkqTV"
			$s &= "iK0Y8rlV8ojfW5efIm0IzGw17gx88P5dAcvAEPAc+Ow6gNlITLuotCptOJlJWpM018Jl3czmIzHR"
			$s &= "w1aW9MYrGIT0J2Z22O40vAd2gd++doBim7Hpx/CO7pKOxrDr6PsH86eSpiQVJI1KGpQ0IAlJfyQd"
			$s &= "+QTsS9o2s9MWqRp9P26nXI+AErAH1BOc6LqfkSLQn7ZXk8BxKOkZsAa8A8aAPJDzlQfGnewGcB6K"
			$s &= "+wUUkm4+FHpcDoAZIJcgvh+YBWqe4wJ4loTAigd+89lPW8UeYMtzfUnyFgy7/GpmpCVgZnVJm/47"
			$s &= "kmQKGvLVHVwYE5HHKtEYlv/XPRB0IXegDBkeAm4A0d4OcMsYRqoAAAAASUVORK5CYII="
		Case "New_Profile_Dark_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACoElEQVR42u2VO2gUURSGv3NnQoS4"
			$s &= "aGKVRdRGwQc2CmqhlVgoCEYmooJEgxEkMxstrMdGrBZmJhpdfIBIxEgSBMHGSkG2N2orRgSLpFAD"
			$s &= "K9mdY3OFZUmyE0MUMX9zH+eec37O68IKVvC/Q5o98DzP6ezsvAj0AVutzjug1NHRcSMMw3TZCHie"
			$s &= "5+Tz+RFV7ZpTWWSsvb3dWwoJs5Awn89fsM6/q2qvqq6pVCprgfP2rmt6erpvIRtBEIwEQaCFQsGb"
			$s &= "S+4upJymaa+IoKpXkiS5Vye6EwSBCwyJSC9wa1kiICJbAWZnZ0cbZao6atdtS6kB00SeArS2tsoc"
			$s &= "BFrstrYUAm4T+QSwR1VPA8V6geM4J1UVVZ1ozHmDjX02nZeCIKivg3Icx8VmBIaAPcA13/dbHMd5"
			$s &= "XK1WxXGcE6oaAhhjbjY2zzzp3LfoCMRx/CAIggPAORG5nqbpdWMMqvrryd0oih42OOpuSNVlYC9Q"
			$s &= "FJFy3btPmQYRQKFQOKWqfcA2a/QtUEqS5FEzXZsST0S6oyh6stgaACCKomFgeDlGseEvY94I9Pf3"
			$s &= "540xh1V1P7BDRDYCOUCBr8BHYEJEXtVqteeDg4Of5zFVtl0w2fQv6OnpWZXL5Y6LSB+wP2uNWFIv"
			$s &= "VfU2MJYkyY9Ff0a+7x8UkfvAenv1BXgGvFDV967rTs7MzHwDaGtry6nqhlqtth04JCJHgHVW74Oq"
			$s &= "nkmS5FVmAgMDA5vSNH0DrAZeA1GlUhkvlUqzWYz4vt9qjPGAgqruBr66rrujWCxOZqoBVT1rnT+N"
			$s &= "4/iYDWlm2JA/DMNweGpqalxEjlar1XPA1axdsNmu44t1Xo8wDFNjzGN73JK5C1T1VzfsnO/fzgpV"
			$s &= "3WW3Lb/ThpfrxuwfnQPlZbBdZgUr+BfwE+xdCffNcQG0AAAAAElFTkSuQmCC"
		Case "Clone_Profile"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAByklEQVR42u3WTYhOURgH8J+vyIym"
			$s &= "JhkyhIUaSiyUUPK1sMFGsrBUFlY29hZWs7FhMSkpC9SUopiwUGY1pRBRpHmVhpop34sxbJ6p03Vv"
			$s &= "73vf3vui3n+dzr3nPvf5/5/znPOcQwcd/KeY8zdId+IOvuIX3uMC+tpBfhzTQZxt77CmSvJV+B5k"
			$s &= "l+J9AXbgSYzfr1LAmSC5l5P71fgS39c243xuAzYD0Q8HUYpxjMXzhqoEzEQ/r+D7/Oh/VpWC0xH5"
			$s &= "oxzB65P10V+VgGX4FCTD2BxjB/E6xm8m9ktxJbbpC5xsRd04hB8F2/AllidpGs2xOdGKmdiEq7Hw"
			$s &= "JvEUZ9GT2GwtEPm4XdVyb4GAt+0S0IOPOQIuNutwEQ5gMApRLRbkTKThFc5l/tmHDwn5SCZNDWE7"
			$s &= "LicHT1F7nizAFN1RqgfK7oC+iHSW4Btu4RR2BVlX2C6M1tJz/QF2xx4+j6GY6kZ9bcGeKMvdEcA4"
			$s &= "3uBu+C3Exoj6M1aUDOQontVJ1zSuYV2Rk8NheLsk+ZE6xHn3h8XZg0Sc8dAbTuvhISZwrKTglXG7"
			$s &= "GskKmMU2XG/A0f4QsKTJevHHDNRwo4STiWQmpkoKqHXu9R38M/gNFDSTCuZAD3YAAAAASUVORK5C"
			$s &= "YII="
		Case "Clone_Profile_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAC50lEQVR42u2WT2hcVRTGf+e+0Skx"
			$s &= "sSi2LopdFKzYLvwHpZaItDXrrlItxSzC+0McyFYUhagbV0oDIbw7mKxa2lRbdKNtsYt021Ub/IdU"
			$s &= "adAmIM0E24q8zPvcvEBIJslMyICFnM273HO453v3+845F7Zsyx5Gk2SbdVbTB6Vp2m1mHwCvAR1m"
			$s &= "NgNcBD6Komi2rQC8928D40DQwP1HvV7vHhgY+H0jANx6AWNjY88Avkg+ViqVdkt61DnXDdwEdgVB"
			$s &= "8EXbbsB7/y7wqZl9H4Zhj5lpCS27zewH4DEz2xNF0W+bfgNm9nwhvAtLkwMkSXIbuA6Q5/m+tlCQ"
			$s &= "53leLINVQkoFwHpbAJjZVLF8a2hoyC2jZy/wCkAQBFNt0cDo6OjOIAh+BbqKsvu4Xq//GQTBQUmf"
			$s &= "m9ke4Js4jo8VunjKzD4zsx5JNeBUFEXpcvpaKsNqtXpM0jmg3MD9S5Zlr1cqlZmJiYlgfn7+mqRX"
			$s &= "l8XEcRxXN0QBQBRFX5vZATM7I2kamJM0ZWafSDpQqVRmAGq12ssNkgO8w1oCahLEDeDkOoJ93LmG"
			$s &= "//TEhkXYkqDMrgN/NXB9uyERjo+Pb8uy7LCZHQVelPQcsB3oBGpFsi/jOH5/SWW8AZwBdhRbVyT1"
			$s &= "Jkky3zQA7/0hM4sl9QIda2D8McuyI4saWLSRkZHOcrn8gqS7YRj+tFoFrABQrVafBk5LOlps/QNc"
			$s &= "lfSdmd3Msuznrq6uv/v6+u4PDw+XAQYHB//dtHHsvb8KHAbuAKecc9UwDO82+0bw3r9kZkck7XPO"
			$s &= "dQIPgNuSbkm6lCTJnVUBeO/3A1PAPUl7GwWv0SfelPQhsH+NsDrwValUeq+/v//WiiqQ9GyxnGwl"
			$s &= "eZqmvZLOrpN8cZYcX1hYmEzTtKNRH3ik+D6ZpmnvukPEuckoimbN7ESLtO8CuoHLqzWig2Y20QTn"
			$s &= "PcBsMSNate0rbsA5Nw2cb/aEPM9nCyCTzrm5FhvW9NbTfsv+N/YfRPAmYSbO3YkAAAAASUVORK5C"
			$s &= "YII="
		Case "Clone_Profile_Dark"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAB9UlEQVR42u2WTUhUURTH/1cTww+E"
			$s &= "CD8Qo1wIGkghQZQQfi3aVBuxFi4FF+3bt2jlxk0bESJooYEQFJWkCxeuBEFFMShiRhhGwqDUWuj8"
			$s &= "3JyBx2OeznXmScL8N4d37rnn4/7PPe9KJZRwHgG4Yvkq8wjaDXwC9iRlgBTwEmg4i4qHgQNyYwu4"
			$s &= "GmfwFuCvBZu07wrgLrBi+rk4E3hmQb6EuQeuALu2fi2uHmg3OeOcI7jgnEtIWrLPjrgSyJgsj1i/"
			$s &= "YPIwrgTWTD4GykIUtEnqCtkVvQfqgd/G8wxww3QPgG+mfxewvwy8tmu6AYwWPDeAh8C/iGu4CTSa"
			$s &= "XTmwmMNmpBgn0Qm8ARLADrAKPAfqAja3IpJcPqsR3ReRwI+CR3GeWJL0M4f+42krugjcB8ZsECWt"
			$s &= "ITNGw1fgRWhPP7AdqH42SFO+ge8Ar4A9jsd6tgFD+2tsVLd73QCgwSrNYh94DzwF7gGNQLXZVgKV"
			$s &= "hXIWnu3zknokpSSNS5pwzu14vBFuSuq1sVwjaV9SQtJ3SZ+dc6njHFy3qv8ATZ6UDQFrJ9B1AEwB"
			$s &= "rVFOHpnhB8/gg/hhC6gK/0gkqcLkJWAwj9gLzrm0pCeetDdL6pY0G04gi9uSpvNwNCApLan2FL1X"
			$s &= "l+sEkpLeejhJZ09C0i/PBJKlp30J/w2OANwthw6HSaECAAAAAElFTkSuQmCC"
		Case "Clone_Profile_Dark_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAADB0lEQVR42u2WTWgVVxTHf2dmfK+8"
			$s &= "PiuKtSVSF4Haqgu1BbElXfiRdXHxtKUIWZQ0JLyZfCxKpUJaNy6Cb2ZeSNOU6koRP9GNtqUushYK"
			$s &= "NfQLUTFYTRE/0LZjkrmnmxuIJi95UV9RyH9zh3vOnPPn/M+958I85vGcQv73QEEQNBhjPheR94Ac"
			$s &= "cENETgJfRFE0UlMCvu/vBA4A7jTma47jNIRheOVxCDizOXR2dr4GDNjk+z3PW5EkScYY0yAiF4Dl"
			$s &= "qvptzSpQLBY/FZG9wI9xHDcCOkmWFar6C/CiMaa+t7f38lOvgIissuuJyckBoii6Cpy39tU1kQAw"
			$s &= "AKrqViDo2TWtFYEhu37Q3d39kH9bW9tKVX3bEhyqSQ+0tLQsy2QyF4GFwEnHcb5MkuTPbDa7UVVL"
			$s &= "QL2qni6Xy+8DdHV1LR0bG9sHNAJ3gCiO468fla/qCvT39/8F7AQeANuMMT9lMpkRVT0F1AN/pGn6"
			$s &= "CUChUHBHR0dPW/9XgTeBr4Ig+PhJJCCO41MisgE4pKrDwG0rzZ4kSTb09fXdAKirq3tLRN559H9V"
			$s &= "ba0U26tWqyiKfgY+mslHVV+qYFr8RBWoFkmSnAduTmM681hN2NTU9EI+n98kIltEZB3wBrAIyNsG"
			$s &= "uwkci+N416SLa6uIHAJetls/JElSGBgYuFs1Ad/33wWagYIdPJXw6/j4+OaJHphAa2tr3nGctZ7n"
			$s &= "3QrD8LdKJ2AKgSAIXlHVg8AWu/WviJwDzhpjLqRp+nsul7vX09Pzd7FYzAKUy+UHT20c+75/DtgE"
			$s &= "XFfVyPO8b0ql0q1qY7W3t683xmwGVluZ/gGuquol13W/C8PwekUCHR0da9I0HQLuO46zcjrnGd4K"
			$s &= "O4wxu0VkzQxuKXDcdd3PSqXSpSmnQFVft5+Dc0xeUNXDsyTHjvPtaZoONjc356bcA6q6wH4uCYKg"
			$s &= "UEXuwSiKRlT1wznKvjybzTYA31e6iDaq6pHZoqhqIzBiZ8TcJqDjLJpSAWPMsIgcrTaIqk68Awft"
			$s &= "1Vw1jDHD8+/6eTwz+A/cRSuVzNmpzwAAAABJRU5ErkJggg=="
		Case "Rename_Profile"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABuklEQVR42u3Wu2tVQRAG8N/1RawE"
			$s &= "iUk6sbSwUHsFwQeoSAKmCGpjExR7kVSSf0BBq1QWFqlFiSktkiIKmsTKRhFJwErRKD6uzRxYDufc"
			$s &= "e27knOp8MCz7mP12dnZmlhYtWmwPV7CCX/iNl7jaFPkDdEvkYd3kU0H0DdPYFzIdY91YUxuWguRW"
			$s &= "wdzNmFuq8wCZlSMFc8PJ7VTGjgEP8DfanQVzu6L9U+cBXkV7rWAuG1up0wWX4pp/YgaHQmZirIsL"
			$s &= "dUfCbI8wnG0qF5zHc2xgE4tNWP4/GMZTfMUj7G2S/ABe51y1iKFBNxrDdczFS9/Ej4j795GA7mMi"
			$s &= "R/6m5L3cqUI6FIXnReSAbh/ZwrnQHcFqj7Vz/chP4kOi8CmUpnAU+7EHu8PHx3AkIV8LvY0C8u+x"
			$s &= "vhQH8SXJ7RMl2a8Iown5evRv58hP99vkbix+kqTYquTrobsW/U6U6cxFZ6ps9HgbpXUUb0NvNdzQ"
			$s &= "Sf4PWzhbVkDKxo/Hr6cXPoabTuAw3uEUPkdU3IhoGcdCVWvmK7z4TOZDZzLpd3AvqRsX9bE0j+UB"
			$s &= "rj6/9nKIIB/HsyYy3mTuZnpa3qJFhn96yp4uwA28CAAAAABJRU5ErkJggg=="
		Case "Rename_Profile_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAC8klEQVR42u2WT2gUdxTHP282G3pp"
			$s &= "4qE1XowgXuqfVuipiBZCb1KqYHJoRRjcmZ1Ii2VPhVYIYuuhILaYrjO/JQFFQQoRQePfaG8KLRVr"
			$s &= "Wy9eBEmpBHIJGndnfs/Lb2FZzborXS/Ng2Hm9/t9f+/75s1739/Asi3b/93kVTYZY3ar6pfAe87H"
			$s &= "HeBoGIYnux5AkiTjwL4XOhMpB0GwrxN/XifgOI4/deSPgVFVXaGqK4BR4LGqjjpM29bTUbpEvnCP"
			$s &= "X4VheLxh6bgxJqeqxxzmdFcyALwLkGXZmeYFa+2ZRky3ArAAnuflmhfSNK1nM+taACLyu7vvee5b"
			$s &= "9vTU537rWg0AR4BtwMEkSfIicgpAVT8DDjRguteGxphDqvr1Ehn6NgiCb7ouRHEcbxeR/a7gBPgD"
			$s &= "+CEMw/OvRQlfIeC3ROQEsBU4u7CwUCyVSk9eSwATExNvp2l6rak9r+Xz+Y99319suwjHx8dX9fb2"
			$s &= "blfVD4DNwGqg37XdHDAL/CoivwRBMNVAPgNsanL3UZqmJeC7lgFMTk6+kabpLlUtAltUdamMDbpr"
			$s &= "c5Zl0wDlcnllrVabEZGNL9qgqmtbtmGSJB9Wq9WTIrLaTf0DTKvq9Vwudw940NfXtzA/P68uE4NA"
			$s &= "LYqiu+VyeWUul7sObAD+BQaa3D9R1Z+WrIFKpbLGWnsXeBO4JSLf9/f3nxsZGcnaaNMBVZ1x5H+L"
			$s &= "yJC11heRw3VyEfkkCIKrSyqhqu515BdmZ2e3BkEw1QF5/c3/EpGhQqHwyPO8QQdZVNUddfJWAaxz"
			$s &= "99NjY2NpmwI1oKo3gPWq+meWZUOFQuGRMeaYqo4Ci8COYrF45aVSLCI9qoqIvB/Hca0Vsao+jKLo"
			$s &= "prV2m4i8A9zP5/NDvu/PGWN+dP8Pi9banVEUXe70LCiJtJYKz/N+Bm6KA4rIbd/35yqVylHgc6Bq"
			$s &= "rR2JouhS24eRqt56GXEjtmk8bIwZdsOnwM4oii52dBqGYXjkPxDBqrV2uBX5si0bwDMc3EEwT7tX"
			$s &= "5AAAAABJRU5ErkJggg=="
		Case "Rename_Profile_Dark"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAB0UlEQVR42u2WsWtTURTGv9fGEqdC"
			$s &= "SZNu4ujg0HS3INQWaikN2CGoS5eguItkkv4DLdipU4cOmaVFMzqkQyq0USeXFpEWnCyahGh+LufB"
			$s &= "4/GS917lZXofXC73nHvud849757zpBQpUlwDwGOgCfSAP8Ax8GRU5G8YjJ2kyctG9AuoAJM2KiYD"
			$s &= "KCfpQMNIXgTonpuukaQDbpT5AF3OvZ04Z47F9KFv83iALmPz3yQd+Gjz0wCdK2smmYJVu+YuUAVu"
			$s &= "26iaDOBh0i9hc8gz3BxVLVgG3gMXwCVQTzzy/3Q4BxwAV8AecHOU5NPAiS9VdSAb96AZYAPYtT5w"
			$s &= "CXSsNpxZkdoGSj7y0wHfy6sopFlrPB+APuFoA0tmmwdaQ/buhpHPA+ceg+8WfRmYBaaACeCG5bgI"
			$s &= "3PWQfzK7iwDy30BxGPkt4Kdb24ESMB4xVQUP+Wdbv/SRL4Qd8to2vwUyMb6TgpFiThQAB9jxpOhB"
			$s &= "lIP247ZWI/tidi1Lg+P5f2gDi4MayCD5HNAL4f7mOE5D0j1JdyR9lXRf0g9J25KeSepIWnMc513U"
			$s &= "aGpER81s1t21Rb7l6RsrConUj6MYJcK/95ENSepa5IejqHjrvpsZGnmKFC7+AUlSC/RVegBKAAAA"
			$s &= "AElFTkSuQmCC"
		Case "Rename_Profile_Dark_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAADBElEQVR42u2WT2gcdRTHP29nB3Jw"
			$s &= "mRJs46UVxEuJfwpCQEorRG8itmA8qEjEQzcbZ0aai1CFIP45CMnO7Kp7DBYLJVDxYP3XRG9psChS"
			$s &= "/1y8CJJGzSlIMu6f+XqZhbB204y4XsyDYX783vu9953fe+/7BvZlX/7vYv/kUBiGz0h6EbgfMEnf"
			$s &= "mlk1juPzAwcQBMHbQOWmzszejaKoksdfIeeXP5UF3wKmkiQ5kCTJAWAK2JI0ldnsWYp5jCX52fKl"
			$s &= "OI4bO1SNIAgcoJ7ZXBjIDQD3ATSbzYu9Ctd1L+60GRSAFGBoaMjpVWxvb3dvszNIAF8DdDqdZ/+W"
			$s &= "y2Kxu3dtYDUAzAEnzexV3/ddSe9n1f808Eq2nht0G74GnOujfj2O45fz+HPyAlhdXV0eGxu7ZmYH"
			$s &= "gdvMbAtYMbOwpzMGx4R5ZWZm5vZ2u/2epBPAB47jnJmfn9/+TwD4vn/QzK70tOeVzc3NxxYWFpI9"
			$s &= "F2GlUrnDdd1HJT0IHDOzw5K8rO02gDXgK0lf1mq1S93ghUJhSdK9Pe4e8TzvLPDGrgAmJyeHPM97"
			$s &= "QtIZ4Lgk28GKO02PZM8xM7sMUC6XD5nZkqR7+rDqXbu2oe/7DwHnJR3Otm4Al81sOU3TH4vF4s+e"
			$s &= "5/2xtramUqnkdTqdI+12u1Wv16+Xy+VDrusuA6PAr8BIL28VCoV3+tbA9PT0nY7jXAdKwFVJb62v"
			$s &= "r3+4uLh4S5YLw3AkTdMlMxsFfjCzceA5SW92g5vZ41EUfd6XCR3HeR4omdlHw8PDJ2q12qW9Bpe0"
			$s &= "bGajkr43s/Eoin7L0gOQSDrVDd43BWZ2d5bjC7Ozs+09juoRSV8AR4HvWq3Ww41G4/cgCOqSpoDE"
			$s &= "zE7FcfzZLalYUjF7PxCGYWtXIjH7pVqtrgAngaOSfgLGG43Ghu/7cfb/kACnoyj6NO8sONtT7TcD"
			$s &= "uwisdDvEzL6J43gjDMOqpBeApqQna7XaJ3mG0dUcXNNrOxEEwUQG/M80TU/X6/WPc03DOI7n/gUS"
			$s &= "bEqa2C34vuwLwF+SoU6kxrHIiAAAAABJRU5ErkJggg=="
		Case "Remove_Profile"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABg0lEQVR42u3VT0tUYRQG8N9MDkZQ"
			$s &= "QmALQWxTqyihRat2rtpnqa1EwgQ3+gGqjR+hNrVo2ULSVcsKSQbCVe4FgwgJREUhsblujnAX1zt3"
			$s &= "ppmB4D7wcl7uc885z/vvHEqUKNEcFzCP7zjB35jPo9qL5MtIzhnL3RYxF4kOMI0rGMBMfEsw200B"
			$s &= "G5HkWQY3G9y3bgo4iiTXMrjB4A7/JUFfE74Rtprj28jg+nEpJ+4hjosIrMcqFzK4xeDWM7inORc3"
			$s &= "wcOiO/Aa97CEGt6jgkd4Ef+8yvD7g92cuMdFj6iCtzkredOrYjSJz9iJ8QkTZY3uBCo53BAe4D5u"
			$s &= "YQSX4+z3sY1NrOEjfnZC0EVM4Uu876TgaMQdmYga0BbG8CMV9Ffc8se4g6vxFGsxHw2x7/A75bcV"
			$s &= "u9YSrqeay1eMR6Ki6MeT6AsJ9jDcioCX4bjS5F40QxWrEet5UQe4EfZDOLeLRlRLuNlKMzqzt9N1"
			$s &= "uk3cDVtrRcAZFnpdB/pSXa/TqCtR4n/AKfj9bKzwISPxAAAAAElFTkSuQmCC"
		Case "Remove_Profile_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACbElEQVR42u1VPWgUQRh973aOeGJQ"
			$s &= "MNUiaqMQDTYKVunEQkExkggpFO/cXbCIYGG9NvYe6LmbnNeIkoUkCIKNlQFJn6itGLhg4x4xkp/N"
			$s &= "zmczSjA5s/E8QbwHC7vzfTPf2zcz7wM66OB/B7dLiKLIajQaN0XEJdkLgCLyjmRYr9cf+L6v20Yg"
			$s &= "iiIrjuOI5MBWcRGZXFhYGGyFRO5XwUaj4ZniSwBKKysre0Vkn4g4AJZIDti27baigNomXjJ/esfz"
			$s &= "vMcbxsfCMFQAKiRLAB61RQEAvQCgtZ7YxFypCUPuWDsV0IbAJqJJkiiSP3I2olwudymldjdbtKen"
			$s &= "5+vQ0NBaFgXmACCfzw9vERsGAJKzPwcKhcI1pdTnZk8cxxczKSAiFZKnAdwLwzCfpum4Uopa6ysk"
			$s &= "fZP2cJNsWq+SjJvuey63lukaighHR0fHABSbpFRd173RViMCgCAIhkm6AL4fuLckQ8dxnnW8vG29"
			$s &= "oFqt2uvr6+dI9gPoI3lIRLoBCIBFAB9JzgGYzuVyL0ulUr1lArVabVeSJJdJuiLSn/WMGFKvSQbL"
			$s &= "y8uTIyMjqzsmEIbhGQA1AAfM0CcALwC80lq/V0rNp2n6BQAsy+rWWh8EcBzAWZLnRWS/mfeB5FXH"
			$s &= "caYzE6hUKocty5oFsAfAGwD3RWTK87wkyyLlcrmrUCgMArglIqcALCql+orF4nwmK7Ys67op/txx"
			$s &= "nEskZSf7aCR/4vv+U9u2pwBcSNO0COBu1mZ0xBjP1E6Lb4Tv+1pExs3n0czNiKQSEZA8EQTBYEvX"
			$s &= "ijxpXvO/0w1vmw7316CM9DN/urCIzHRstoN/At8AYmryRZky3y4AAAAASUVORK5CYII="
		Case "Remove_Profile_Dark"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABl0lEQVR42u2VzytEURTHv3eYSKGm"
			$s &= "WCixYSWUhdXsrGys/BpKyQJl4x/Axp/AZiwsLSasLJGUkhV7RUkSoVHE+9icV7N4njfGTKn3rdN5"
			$s &= "3fPO93y799xzpRgxYvwAoApYAM6BD+DTvheARCWK5/geubKKAOat0AswDTQAjcCMrQHMllPAmRWZ"
			$s &= "C4jNWuy0nAJerUhzQKzJYvlSalT/EPfMJ0JyvQBxNZLqQnjzzrn374gLcWE+ExDz184DYlOSHkJs"
			$s &= "KOoOrEvql7QKJCVtSXKSRiUt2z9rAXlvkh5DeN+j9oADNkKuYbZSwygDHAB3ZvvAeDym/wIuZNtb"
			$s &= "JA1KSkvqktQmqV4Skp4lXdktOZK055y7+YuzrgUmgEPAIzo865FxmwG/Kj4AXBeQ3gJZYAzoAVJA"
			$s &= "0iwF9JrYTeC+IO8SSBdbvL3gcTkGRuzeR82vASaBU+N4AlqLEbBiiTuAK+EIE8CucS1FyfFHcYf5"
			$s &= "beccv+5o5zyblpLUWcxj5PtuYLjEXu4znyxGgI/FSs8BX8BJGbhPFCPGf8AXz0LH0AduVLsAAAAA"
			$s &= "SUVORK5CYII="
		Case "Remove_Profile_Dark_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACcUlEQVR42u2VT0gUcRTHP29mFqNt"
			$s &= "KS0Ql6guBZZ0KciLt+hQUGQMgYcyLYNwdqVDh07TxaPQjmUtVpcIDFSKoEunhFA6KnXoEglBB3fB"
			$s &= "2lh1dl6XMaR2dWzZINovDG/m9/59+fKb96COOv53yEYBtm2bLS0t14A+oDXMeQdkm5qa7riuG9SM"
			$s &= "gG3bZjKZfKqqnWWTRSYaGxvtakgY6zmTyeTVsPk3Ve1V1e3FYnEHcCU868zlcn3VKGCt5wyCoFdE"
			$s &= "UNUbnuc9XOMaTaVSFjAiIr3AvZooICKtACsrK+O/+lR1PLQHa6YAEAAYhvEbUdM0rSAIfsasheM4"
			$s &= "Db7vb61UtLm5ueC67vKGCgBzAJZldZVRoCu0s2WUuxiLxXKVnnw+fyaqAiPAMWDQcZyYaZpjvu+L"
			$s &= "aZrnVdUN1blbJm8JyFcqqqrLUeeApFKpUaCngv9BJpO5XM0dMDcKmJmZed7e3v4B2AXEge+q+ha4"
			$s &= "6XneYH2W12wX9Pf3Jw3DOKmqHUCbiOwFEoACi8AnYE5Epkql0svh4eHPVRPo7u7ekkgkzolIH9AR"
			$s &= "ZVmtXmzgtareByY8z1vaNAHHcY6LyCNgd3j0BXgBvFLV95ZlzRcKha8A8Xg8oap7SqXSIeCEiJwC"
			$s &= "doZ5H1X1gud5U5EJDAwM7AuCYBbYBrwBbheLxclsNrsSpYjjOA2GYdhAWlWPAouWZbUNDQ3NRxrF"
			$s &= "qnopbP4sk8mcDSWNjFDyx67rPllYWJgUkdO+7/cAt6Iuo/2hndxs87VwXTcwDGMs/DwQeRmp6upI"
			$s &= "PpxOp+1qfitVPRK+xv5kG15X1b86B1YJTNeg9jR11PEv4AccSvGnmyVjbQAAAABJRU5ErkJggg=="
		Case "Settings"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACa0lEQVR42uWXTUtUURjHfxMpjSBh"
			$s &= "tXFTiS7shTHKNKgPkKHRC1jzDdq0TcFNOG3cRBst6yOkC+kLtIhcBAYVzCiWWouihQWz6ZY2bf7C"
			$s &= "w/Gec++dsaA6cDjnPud5457/83Lgfx+5OmT2AEOesyfAt9/t9Cmg5pknsyrbXYcD3VrLwBvtjwNH"
			$s &= "NBeyKNvVgAMPgGHNaeesYQe6gU7P2VGtq4a2orXgkenM4lwOeA5sAo+BPtH7gafmvnuMTMHQ54Gz"
			$s &= "ovdJx6Z0pgJ9MQZcC8CG9p+Ae0CLkckDE8A78WxIxtVTTDKeB9bEPArcBJaM0tviCYH6FvBDMkvS"
			$s &= "MaLvtQR5xsS4CDQZnAwGYj9uDGpuYawJqEj3mE+oHaiKaTKFkQPABWBA+6QxKd1V2do2WoBH5r5m"
			$s &= "gDZP5NwBIsMbASVPVLVJ1xbvfQc/28Y14KuYVx20I+O+TFhyeHukowZ8Bi6mvcMOA8Yrzm+PAg5E"
			$s &= "znVcEv2t77f7EtEK8EX794Z+GmgOON4M9JrvD1qrwMesqbjWQMV09eeypuIOYJ/2hwz9BfA9YDAS"
			$s &= "D47sXuBgWq+HHRCeyADC8QAI14GrIcNuGM4GwrAUE4bjgTCcNbzTvjCsJxENAOeB/Sn4p5ISkU3F"
			$s &= "lZhUXMwAvssxqXgxKRW7xWjEKUY14CHQGpBvBe4CP51iNGowla+nHL805XhdV5R3HJ/SWagcX0/b"
			$s &= "kMyriZhRIwJwBnhmlBVSNCT99TQkqLns8pzNyZDN60OizXlkunwtmS8RlYFlz9lrrYedxAXwyiOz"
			$s &= "LGDvSFte1noDOKf9Ma2VP/Ga2tGHyV/5NPu3xi9hrdn3CxzSbwAAAABJRU5ErkJggg=="
		Case "Settings_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAEmElEQVR42u2XXWwUVRTHf2e6NkK7"
			$s &= "IRgSU0haCUJaEUhVkEQS302AIKGKb8jOzFoxMVWMih+jlqgY+tLYdO4s8GKkCJKAic++GDBN5MMP"
			$s &= "sBCxmK4xYghhi7rMzvGBWRzW3W1X4UnPy+7cM/d//vd83oH/ukijG/bs2XN7sVhcXU3X3Nz8yaZN"
			$s &= "m35vBC/VKIEwDBeLyEfVdMVi8X7gy1tKQFU747+nROTreO1eoEtEuholYP2DsHXGRodt2+6xbbsH"
			$s &= "8JO6f03A9/1O3/cX1PDAPQAi8kNi+Vz8u7QG3gLf9zunRUBVxbKs3SIyZozZn8vlVsQgDxpjPhOR"
			$s &= "RwGiKBq/nsl/kVljjDmSy+UeAsjlciuMMftFZMyyrN2qKlNWQRAEG1X1wwpSx0RkKdAE/AyMqOrL"
			$s &= "ruteARgYGJjR2trqARuA+UBJVU+KSPcNxkSesG17b00CMdBpoF1VXxKRSeAZYGEM2j85OfluX1/f"
			$s &= "b9Xc6Xleqq2trU9EtscJfgYYBGYC7wDnC4VCZ3L/DSFoaWnpA9qBMWCn4ziD+Xy+E1gdRdE613W9"
			$s &= "WsZjAqHrujuAdcDqfD7f6TjOoKoOqOp3QHts4+8e8H2/TUTGgFZgyHGcp+tlr+/7cyzLWqHXZNR1"
			$s &= "3Qv13jfGvA/0AgVVXeS67k+VfeCSiIyoagboNcbcGYah3dvbe7HilNa8efPeVNWtqtocx7ZojNmR"
			$s &= "z+df9zwvSr4/NDQ0O5VKBcD6eOkD4FK9JHxMVX1gFjAeRdHabDZ7IqHvV9VtNQ7a7zjOq+WH4eHh"
			$s &= "ZZZlHQI6gF+AjOM4h+uWoW3b++LsPQ90NDU1LUi6XVW31vH0C77vz0lk/XygQ1W/V9VllcZrNiLb"
			$s &= "ts8BFwFKpdL5BOByoLkOgWZVfeA6uGX9GO+7XI55I61YYxDhH4qqWlNN3aoEgiCYD9wRs+9IAI4C"
			$s &= "xTo2/wjDcDThsfLeWb7vt0+LgDGmR1WPxf1gXFXPlnWu614QkfdqXi5EdmzZsuXX8nOpVDoDjAMd"
			$s &= "InLcGLO+JgHf92cGQRAA+4BZqnowDMNux3GOJzdMTEy8BvRXeKIoIm9NTEx4yXez2eyJMAy7VfUg"
			$s &= "MBs44F+TmTelEYnI8iiKNAzD0eTJa4R1SFWfqmxEUgG6TUT647a5xHXdq57nWXPnzn1ERNKVg6RO"
			$s &= "11sHXM3n8596nhf5vn9bfHlZpKqvuK67fcphBLwIXEkMI4Cgqanpuc2bN1+uZnjXrl3pUqn0BvBs"
			$s &= "jH0GGFTVFhF5GxgvFApdyXkyrXEMHAeWxOP4IrC3UCg8XwYaGBiYkU6nd6rq43Gsq45jYKPjOCN1"
			$s &= "qyCTyYwAR4EI+FhVVzqO0y0iq4DPYwO96XS67BXS6fTCOL6zgaOWZT3suu59qroSOABEInLEtu19"
			$s &= "U15KRUSDIHhSRK5mMpmzie54FFhljDkErFHVu4CTcbl1WJYFcNhxnLWJsv0C2JDL5e4ulUopEdFp"
			$s &= "3Ypt2z5Vp9a/UtUygWTPp0yoilfP3sxr+anYaDYIglXx2uJYfbpRvIYJiMhpVQXoUtWuauRuKYFU"
			$s &= "KvVNsVjsqfFp9i3/S4PyJ/b+OMoWcMANAAAAAElFTkSuQmCC"
		Case "Settings_Dark"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAClUlEQVR42u2Xz0tUURTHzx1GaQQJ"
			$s &= "y42batDFWDFGpRPUH5DhDP2AqfkP2rRNwU04btxEGzXrT0gX0j/QInIRGPTLUSq1FkULC2bTlPZp"
			$s &= "cwYul3dv740JQV143HvP+Z7vPe/dc8+5T+RfbyapAbBPRIoe9UNjzLc99Rg4hb+dTMqXbsGHnPYr"
			$s &= "IvJSx8dFpF+f5SRkqV04cNcYUzbGlEVkztHtzgEgB/R6bI5qv2HJ1rXPe/h6gVzcPTbAE2AHeAAM"
			$s &= "qbwAPLL2e8CyyVvyJeCsyoeUY0c5TRwHKhHBtQxs6/gTcAfosGwywBTwTjHbauO2yu8WzwCbCh4D"
			$s &= "bgBrFuktIBOwTwM3gR9qs6YcozrfDNkLMK7AVaBNZSlgBCgmOKoj+qR03gbUlHvcZ9QD1BU0HWOR"
			$s &= "buACMAx0x8BPK3cd6IkCdAD3rf2aB7oicClgEmhY2AZQbb6xg+9SrmabteMnypGrwFcFb9jRrvrJ"
			$s &= "QCasOtgB5QD4DJTi7mHWCsbLzmdvBBxo2NsBXFT528jP7ktExph1Efmi0/eWalBE2gO+t4vIaWv+"
			$s &= "Qfu6MeZj0lRMqxUzgt8kTcVZETmg08OW6qmIfA8s2FCMOLb7gUNx97/sBOGJBEE4EQjCLeBKaGH3"
			$s &= "GC4EjmE14hhOBI7hgoWdizyGLSaiYeA8cDAGfiaYiJxUXItIxZUEqfhSRCpeDabiiGI06hQjgHtA"
			$s &= "Z8C+E7gN/HSK0ZgVU5lWyvEzqxxvaV7POI7PqC5Ujq/FvZAs6SViHiio/Azw2CLLx7iQFBJfSNSw"
			$s &= "H+jz6BZ1oZIlK6ps0WPT57uSpT2peCXg3wsRKYnIEUuW1f65h+/Nn7yWN527DpzT8THta3v+K/U3"
			$s &= "/Ji8EpGyR/da/reE7ReoyGVYInyHsgAAAABJRU5ErkJggg=="
		Case "Settings_Dark_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAE70lEQVR42u1WTWxUVRT+zntTOkVh"
			$s &= "mIkbXbQ0WDIVadMqbU2JrFygAYOEBlgRo43FvjcdCo2KiU8FkZLSzn1TwJIY3AgYIRESl9INgZmm"
			$s &= "QhAtf5EfF4aoLT9K3/B897jwDnkMM0NHZKU3mWTeufec851zz/nOBf7ri0pVWLNmTTAUCi3Jt3f9"
			$s &= "+vXDe/bscUqxFygVwMyZM+cx8xf59mbNmvUMgG8fKgBmjhIRAIwBOK3ETwOo9TyvtlQAWqkANE2L"
			$s &= "KiC7hBBtQog2AJ/49x4YQGdnZ9QwjDkFdJ5Szi7dKSSiiwAgpazLp2AYxpzOzs7oVK+AiOhTImo2"
			$s &= "TfMgM2+zbTsdi8WamXkrMy9Szi77dC4pxaWmaR6TUq5PJpNHDcNoIqINAF4BkALQCoCLdoFhGKuI"
			$s &= "6PMc8QkAdQB0AFcB7HMc552hoaFbABCPxys8z7MArABQDcADcApAQ079rLZte29BAMrQGQCVRPQ2"
			$s &= "M/8BwABQo4xu0nV9a39//2S+dFqWFRgfH18HYLPK7nkANjNPJ6KPAVzRdT3q17+rBjzPWwegEsC5"
			$s &= "ycnJPiGEHYlEokS0hJmXCSGsQs4VgD+FEL1EtIyIlkQikagQws5kMtsBnAVQqXzcm4Gurq7HpZTn"
			$s &= "ADwKYIcQ4s1i1dvd3f2Y67pNUkouLy8f6evr+7XYedM0BwGsBfC7pmlzBwYGfr4LQHt7+/RgMJgA"
			$s &= "8JoSHXBd9/WdO3dO5ESpjY+PfwBgA4BpSnybiHrD4fB7lmVJ//mOjo5wWVnZbgDLlWiX4zjd2frR"
			$s &= "swdHR0fdVCp1uKWl5QwRvQCgQdf1lU1NTUfS6fTV7Lm6uroPAWz066r/zzuOo6dSqSO+gq7XdX0Y"
			$s &= "wHMAfiGi1UKI7aOjo25BHkgkEvs9z2sAcAVAFYA5/rSryAuxZI868zcqXa9WNn7UNK0+kUgcmhIR"
			$s &= "JZPJiwAmlNErWXkmk1ngS3u+Nc113WezH1LKn9Tfm9k7L4WKWUVR8sT0MZp2v6lbiIqrAURUFFVZ"
			$s &= "eXl5+QiA20V8ZjzPG/FlIKsbisVilVMCYJpmm67rJxQfXNZ1/UJ2T7XatiIAegcHB3/zfZ8HcBlA"
			$s &= "FTOfjMViy3MVdH8btra27gCwBUCQiA66rvtSMpm85FdYvHjxsOM4OoAWn/5tAB9FIhFreHj4Dten"
			$s &= "0+mrjY2NnwUCgRoAjQDampubn6ivr/8m2wkPRESZTGaBpmnsed5ITuT3rFgstoOZOwoSkUr/RgCb"
			$s &= "AJx1HGf+0NCQa1mWNjEx8aKUckbuICnCesuIyA2Hw19bliXb29vLgsHgaQBzAbwrhNh832HEzG8R"
			$s &= "0S3fMAIz766oqOju7e29mc9xT0/PDMdx3gfQpWyfB2AT0SPMvEXVVK1/nkx1HJ8EMF/d+QSAvbqu"
			$s &= "r88aisfjFVLKPmZeCSBcaBwDWCWE2Fe0C2zb3gfgOAAJ4AARtQghGph5IREdVQ7WSilrfO1Wo+43"
			$s &= "DOC4lHKREKKRiFoAfAlAMvMxIcT+qbyIWNO0V4nI7e/vv+ADdhzAQsMwviKipQBmqyghpawiIjDz"
			$s &= "Idu2X/bRegrAing8/qTruoHc11DBV/HAwMBYEXb7DsBSKeVsn7havRNP5dPxB/JvPMvHiAhE9IZp"
			$s &= "mguVeJ7KxJlS7QX+Ab9nndSqH3zTb+yhA7hx48b3oVCoLd/etWvXfsD/q8T1F3tELHpTKPx0AAAA"
			$s &= "AElFTkSuQmCC"
	EndSwitch
	Return $s
EndFunc
#EndRegion Profile action icons

#Region Embedded Readme
; The text of Readme.txt, built into the program (shown by the ? button of the Associations window).
; Nothing is written to a file.  Keep it in sync with Readme.txt when the Readme changes.
Func _ReadmeText()
	Local $s = ""
	$s &= "==========" & @CRLF
	$s &= "README.TXT" & @CRLF
	$s &= "==========" & @CRLF
	$s &= "" & @CRLF
	$s &= "FileAssociatorPortable  (version 3.0.0.5)   (formerly PortableFileAssociator)" & @CRLF
	$s &= "Take your file associations with you.  Open local files with your portable applications." & @CRLF
	$s &= "" & @CRLF
	$s &= "Owner / Trademark:  ShihabUddinX" & @CRLF
	$s &= "Original work by Erik Pilsits." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "Main Window:" & @CRLF
	$s &= "============" & @CRLF
	$s &= "Add File Associations    = Writes all enabled associations of the active profile to the registry (HKCU only)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Remove File Associations = Removes them again and restores what was backed up." & @CRLF
	$s &= "" & @CRLF
	$s &= "Configuration:" & @CRLF
	$s &= "   Associations = Opens the association editor (context-menu entries)." & @CRLF
	$s &= "   File Types   = Opens the file type editor (icons, defaults, ""New"" menu)." & @CRLF
	$s &= "   SendTo       = Opens the SendTo editor." & @CRLF
	$s &= "" & @CRLF
	$s &= "System Restore:" & @CRLF
	$s &= "   Create System Restore Point = Creates a Windows restore point (see ""System Restore"" below)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Profile  = Profile selection and the profile buttons (see ""Profile"" below)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Settings = The gear icon at the bottom right opens the Settings window: theme, start and exit options," & @CRLF
	$s &= "           update check, splash screen (see ""Settings"" below)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Version  = The version number (ie v3.0.0.5) is shown at the bottom left of the main window.  It is also the" & @CRLF
	$s &= "           file version of FileAssociatorPortable.exe." & @CRLF
	$s &= "" & @CRLF
	$s &= "Owner    = ShihabUddinX (owner and trademark).  Also written in the file properties of" & @CRLF
	$s &= "           FileAssociatorPortable.exe (Company, Legal copyright, Legal trademarks).  Original work by" & @CRLF
	$s &= "           Erik Pilsits." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "Associations:" & @CRLF
	$s &= "=============" & @CRLF
	$s &= "Association Name = The name of the association as recorded in the GUI list and INI file." & @CRLF
	$s &= "                   It cannot include the characters ',' or '*'." & @CRLF
	$s &= "" & @CRLF
	$s &= "Associated Types = File extensions only, separated by the | (pipe) character, ie txt|log|ini" & @CRLF
	$s &= "                   (do not include the period [.]).  The extension entry is added to that specific file" & @CRLF
	$s &= "                   extension.  'exe' and 'com' add an entry to program files without changing their" & @CRLF
	$s &= "                   normal open action." & @CRLF
	$s &= "" & @CRLF
	$s &= "                   This box is disabled while ""Files"" is ticked (see below)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Also add to      = Tick boxes for the special targets:" & @CRLF
	$s &= "" & @CRLF
	$s &= "                   Files       -> all files, any extension ('*' wildcard)  (HKCU\Software\Classes\*\shell)" & @CRLF
	$s &= "                                  The Associated Types box is disabled, because Files already covers" & @CRLF
	$s &= "                                  every file." & @CRLF
	$s &= "                   Folders     -> all folders (HKCU\Software\Classes\Directory\shell)" & @CRLF
	$s &= "                                  Folders can have their own optional ""Folder Command""." & @CRLF
	$s &= "                   Drives      -> all drives (HKCU\Software\Classes\Drive\shell)" & @CRLF
	$s &= "                                  Drives can have their own optional ""Drive Command""." & @CRLF
	$s &= "                   Recycle Bin -> the Recycle Bin" & @CRLF
	$s &= "                   Background  -> the empty space of a folder window and of the Desktop, like" & @CRLF
	$s &= "                                  ""Open Terminal here""" & @CRLF
	$s &= "                                  (HKCU\Software\Classes\Directory\Background\shell)" & @CRLF
	$s &= "" & @CRLF
	$s &= "                   Any combination can be ticked, together with file extensions." & @CRLF
	$s &= "" & @CRLF
	$s &= "                   NOTE:  Older INI files that listed drives, files, folders, recycle or background in the" & @CRLF
	$s &= "                          Associated Types box are converted automatically when the profile is loaded:" & @CRLF
	$s &= "                          the word is removed from the box and the matching tick box is set.  If 'files'" & @CRLF
	$s &= "                          was used, the extension list is dropped (Files covers every file).  An" & @CRLF
	$s &= "                          association that was only for drives keeps its old command as the Drive Command." & @CRLF
	$s &= "                          These words can no longer be typed into the Associated Types box." & @CRLF
	$s &= "" & @CRLF
	$s &= "Single file type = Show the association only when ONE item is selected.  When several items are selected" & @CRLF
	$s &= "                   the entry is hidden in the context menu.  Works for Files, Folders, Drives and file extensions" & @CRLF
	$s &= "                   (ie iso).  Unchecked = the entry is shown for single and multiple selection." & @CRLF
	$s &= "                   (Not used by Recycle Bin and Background.  The setting applies to every" & @CRLF
	$s &= "                   target of the association; use two associations if you need different behaviour.)" & @CRLF
	$s &= "" & @CRLF
	$s &= "Run as Admin = Starts the command with administrator rights (Windows asks for confirmation, UAC), for" & @CRLF
	$s &= "               programs that need admin access.  Unchecked = the command runs normally." & @CRLF
	$s &= "               Works for Files, Folders, Drives, Background and file extensions.  Not used by Recycle Bin." & @CRLF
	$s &= "               The setting applies to every target of the association; use two associations if you need" & @CRLF
	$s &= "               different behaviour." & @CRLF
	$s &= "               Admin entries do not start your program directly.  They start FileAssociatorPortable.exe" & @CRLF
	$s &= "               (internal parameters multi_open_admin / bg_open_admin), which then starts the program" & @CRLF
	$s &= "               elevated.  So PFA must stay at the same place while associations are active." & @CRLF
	$s &= "" & @CRLF
	$s &= "Title = File Association Name as it will appear in the file's context menu (make sure it is UNIQUE so" & @CRLF
	$s &= "        it does not conflict with local entries)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Context-menu icon = Optional icon shown next to the entry (.ico, .exe or .dll).  Relative paths are portable." & @CRLF
	$s &= "Icon index        = Icon number inside a multi-icon file.  Usually 0 for .ico files." & @CRLF
	$s &= "" & @CRLF
	$s &= "Disabled = Check this box to disable the current association." & @CRLF
	$s &= "" & @CRLF
	$s &= "Command = Command line to execute.  The application path must be surrounded by "" (double quotes) if it" & @CRLF
	$s &= "          contains spaces and cannot use environment variables.  Use these tokens (placeholders) for the" & @CRLF
	$s &= "          clicked-on item(s):" & @CRLF
	$s &= "" & @CRLF
	$s &= "          %1   = path of the clicked-on file, folder or drive.  Explorer starts one run per selected item." & @CRLF
	$s &= "                 Example -  ""X:\PortableApps\App Path\app.exe"" ""%1""" & @CRLF
	$s &= "" & @CRLF
	$s &= "          %%1  = ALL selected items in ONE run, each one in quotes." & @CRLF
	$s &= "                 Example -  ""X:\FastCopy\FastCopy.exe"" %%1" & @CRLF
	$s &= "                 With three files selected this runs:  FastCopy.exe ""file1"" ""file2"" ""file3""" & @CRLF
	$s &= "                 Notes:  Explorer starts one process per selected item, so PFA registers a small" & @CRLF
	$s &= "                 wrapper (FileAssociatorPortable.exe multi_open ...).  The wrapper processes collect their" & @CRLF
	$s &= "                 files and the first one starts your command (it waits about 1.5 seconds for the other" & @CRLF
	$s &= "                 files).  Files are passed in name order, like Explorer's default sort.  Very long" & @CRLF
	$s &= "                 selections are split into several runs (about 30000 characters per command line)." & @CRLF
	$s &= "                 %%1 works for Files, Folders, Drives and file extensions.  With Folders or Drives it" & @CRLF
	$s &= "                 passes all selected folders / drives in one run.  A drive root such as E:\ is passed" & @CRLF
	$s &= "                 safely (as ""E:\\""), so the closing quote is not swallowed." & @CRLF
	$s &= "                 The command is started with ShellExecute, so programs that need administrator rights" & @CRLF
	$s &= "                 (for example FastCopy) show the normal Windows confirmation (UAC) instead of failing" & @CRLF
	$s &= "                 silently.  Tick ""Run as Admin"" to always start the command elevated." & @CRLF
	$s &= "" & @CRLF
	$s &= "          %V   = the current folder.  Meant for Background (and also works for folders)." & @CRLF
	$s &= "                 Example -  ""wt.exe"" -d ""%V""      or      cmd.exe /k cd /d ""%V""" & @CRLF
	$s &= "                 Notes:  The command is started inside that folder.  A drive root such as C:\ is passed" & @CRLF
	$s &= "                 safely (as ""C:\\""), so terminals do not fail on the trailing backslash.  For Background" & @CRLF
	$s &= "                 %V, %1 and %%1 all mean ""this folder""." & @CRLF
	$s &= "                 When ""Run as Admin"" is ticked, %1 commands of Files, Folders and Drives are started the" & @CRLF
	$s &= "                 same way (through PFA) and %V / %1 mean ""the clicked-on item""." & @CRLF
	$s &= "" & @CRLF
	$s &= "          NOTE:  PFA must stay at the same place while associations are active, because %%1 and" & @CRLF
	$s &= "                 Background entries start FileAssociatorPortable.exe." & @CRLF
	$s &= "" & @CRLF
	$s &= "          The Command box is disabled when only Folders and / or Drives are ticked (no Files, Recycle Bin," & @CRLF
	$s &= "          Background or extensions).  Then each ticked Folders / Drives box must have its own Folder" & @CRLF
	$s &= "          Command / Drive Command.  Otherwise the Command is needed." & @CRLF
	$s &= "" & @CRLF
	$s &= "Folder Command = Command used for folders.  Enabled only when Folders is ticked." & @CRLF
	$s &= "                 Use %1 for the folder (one run per folder) or %%1 for all selected folders in one run." & @CRLF
	$s &= "Drive Command  = Command used for drives.  Enabled only when Drives is ticked." & @CRLF
	$s &= "" & @CRLF
	$s &= "          If a Folder Command / Drive Command is empty and the association also has other targets" & @CRLF
	$s &= "          (Files, Recycle Bin, Background or extensions), folders / drives simply use the Command." & @CRLF
	$s &= "          Fill them in when folders or drives need a different command line." & @CRLF
	$s &= "" & @CRLF
	$s &= "          Examples -" & @CRLF
	$s &= "          * Only Folders ticked, Folder Command filled in:  the Command box is disabled and only the" & @CRLF
	$s &= "            Folder Command is used." & @CRLF
	$s &= "          * Only Drives ticked, Drive Command filled in:  the Command box is disabled and only the" & @CRLF
	$s &= "            Drive Command is used." & @CRLF
	$s &= "          * Only Folders ticked, Folder Command empty:  Save shows an error, a Folder Command is needed." & @CRLF
	$s &= "          * Folders + Drives + Background ticked:  Command is used for Background; folders and drives" & @CRLF
	$s &= "            use their own command if one is entered, otherwise the Command." & @CRLF
	$s &= "" & @CRLF
	$s &= "          A drive path such as E:\ ends with a backslash, so write %1 or %V WITHOUT quotes in the" & @CRLF
	$s &= "          Drive Command:  ""..."" would turn  ""E:\""  into an escaped quote and many programs fail." & @CRLF
	$s &= "" & @CRLF
	$s &= "          Example (the same portable terminal for folders, background and drives) -" & @CRLF
	$s &= "          Command       = ""E:\PortableApps\TerminalPortable\TerminalPortable.exe"" -d ""%1""" & @CRLF
	$s &= "          Drive Command = ""E:\PortableApps\TerminalPortable\TerminalPortable.exe"" -d %1" & @CRLF
	$s &= "                          (or  ... -d %V )" & @CRLF
	$s &= "          Folder Command = ""E:\PortableApps\TerminalPortable\TerminalPortable.exe"" -d ""%1""" & @CRLF
	$s &= "" & @CRLF
	$s &= """..."" (next to each command box) = Browse for the program.  Inserts ""%V"" in the Command when Background" & @CRLF
	$s &= "                          is the only target, ""%1"" otherwise.  In the Folder Command it inserts ""%1""." & @CRLF
	$s &= "                          In the Drive Command it inserts %1." & @CRLF
	$s &= "" & @CRLF
	$s &= "Clear = Clear all fields." & @CRLF
	$s &= "" & @CRLF
	$s &= "Save = Save any association changes.  Must be done after each change.  Asks before overwriting an" & @CRLF
	$s &= "       existing association." & @CRLF
	$s &= "" & @CRLF
	$s &= "Delete = Delete selected association.  The last association cannot be deleted." & @CRLF
	$s &= "" & @CRLF
	$s &= "Done = Closes the association dialog." & @CRLF
	$s &= "" & @CRLF
	$s &= "? = Opens this Readme in a window.  The Readme is built into the program, no Readme file is needed." & @CRLF
	$s &= "" & @CRLF
	$s &= "Associations are stored in Data\settings\<profile>_assoc.ini, one section per association:" & @CRLF
	$s &= "" & @CRLF
	$s &= "    [My Association]" & @CRLF
	$s &= "    mode=iso|img" & @CRLF
	$s &= "    files=1" & @CRLF
	$s &= "    folders=1" & @CRLF
	$s &= "    drives=1" & @CRLF
	$s &= "    recycle=1" & @CRLF
	$s &= "    background=1" & @CRLF
	$s &= "    title=Open with MyApp" & @CRLF
	$s &= "    command='""..\MyApp\MyApp.exe"" ""%1""'" & @CRLF
	$s &= "    foldercommand='""..\MyApp\MyApp.exe"" ""%1""'" & @CRLF
	$s &= "    drivecommand='""..\MyApp\MyApp.exe"" %1'" & @CRLF
	$s &= "    icon=..." & @CRLF
	$s &= "    disabled=4" & @CRLF
	$s &= "    single=1" & @CRLF
	$s &= "    admin=1" & @CRLF
	$s &= "" & @CRLF
	$s &= "'mode' holds the file extensions only.  The keys files, folders, drives, recycle, background, single and" & @CRLF
	$s &= "admin are only present when the tick box is checked (=1).  'foldercommand' and 'drivecommand' are only" & @CRLF
	$s &= "present when a Folder Command / Drive Command is set." & @CRLF
	$s &= "" & @CRLF
	$s &= "NOTE:  Older INI files where a folders-only association kept its command in 'command' are converted" & @CRLF
	$s &= "       automatically when the profile is loaded: the command becomes the 'foldercommand'.  If Drives was" & @CRLF
	$s &= "       ticked as well and there is no Drive Command, the same command is used as 'drivecommand'." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "File Types:" & @CRLF
	$s &= "===========" & @CRLF
	$s &= "Association = Filter the list of file types by association name.  Choose All to show every extension." & @CRLF
	$s &= "" & @CRLF
	$s &= "File Type = Selected file type." & @CRLF
	$s &= "" & @CRLF
	$s &= "Default PFA Association = Default PFA association for the selected extension (dbl-click action)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Hide Extension = Prevent the selected extension from being displayed in Explorer." & @CRLF
	$s &= "" & @CRLF
	$s &= "Copy Host Associations = Copy the file type associations already present on the host computer for the" & @CRLF
	$s &= "                         selected extension." & @CRLF
	$s &= "" & @CRLF
	$s &= "Host Precedence = If host default association exists, it will take precedence over the PFA default." & @CRLF
	$s &= "" & @CRLF
	$s &= "Iconfile = The file to extract the icon from.  This can be an .exe, .dll, or .ico file.  Used when a" & @CRLF
	$s &= "           Host computer association is not the default action." & @CRLF
	$s &= "" & @CRLF
	$s &= "Index = The index of the embedded icon in a multi-icon resource.  Locate the desired icon with the arrow" & @CRLF
	$s &= "        buttons or type the index in the input box.  .ico files do not use an index, leave it set to 0." & @CRLF
	$s &= "" & @CRLF
	$s &= "        NOTE:  The index in the dialog will not exactly match the index used by Windows, however the" & @CRLF
	$s &= "               correct Windows index will be saved and written to the registry." & @CRLF
	$s &= "" & @CRLF
	$s &= "Show in New menu in context menu = Adds the file type to Explorer's right-click > New submenu." & @CRLF
	$s &= "" & @CRLF
	$s &= "New menu name = Name shown under right-click > New.  Default: PFA_<extension> File." & @CRLF
	$s &= "" & @CRLF
	$s &= "Use template file = New items are created from a template instead of an empty file.  PFA looks for the" & @CRLF
	$s &= "                    exact filename  Data\newitems\<EXTENSION IN CAPITALS>.<extension>  (ie Data\newitems\TXT.txt)." & @CRLF
	$s &= "                    A message appears if the file is missing.  The host's own ""New"" entry for the extension" & @CRLF
	$s &= "                    is backed up and restored when the associations are removed." & @CRLF
	$s &= "" & @CRLF
	$s &= "Save File Type = Save any file type changes.  Must be done after each change." & @CRLF
	$s &= "" & @CRLF
	$s &= "Done = Closes the file type edit dialog, and prompts to apply changes if any have been made while the" & @CRLF
	$s &= "       associations are active." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "For new file extensions, the icon will initially be set to the first association defined in the INI file" & @CRLF
	$s &= "which is associated with the extension." & @CRLF
	$s &= "" & @CRLF
	$s &= "When selecting a host default, PFA first looks to see if one is explicitly defined.  If so this association" & @CRLF
	$s &= "is used.  If not, PFA searches for a registry verb named 'open' and uses this association." & @CRLF
	$s &= "" & @CRLF
	$s &= "PFA's behavior when applying the default association and icon depends on several factors:" & @CRLF
	$s &= "" & @CRLF
	$s &= "1)  A PFA default association is selected:" & @CRLF
	$s &= "a)  Host Precedence is selected:  If a host default association exists it will be set as the default and the" & @CRLF
	$s &= "host DefaultIcon will be used.  If a DefaultIcon does not exist, the PFA icon will be used.  If a host default" & @CRLF
	$s &= "is not found, the PFA default association and DefaultIcon will be used.  If no default is found and no PFA" & @CRLF
	$s &= "default is set, then the OS will decide what association to use and the PFA icon will be used." & @CRLF
	$s &= "b)  Host Precedence is not selected:  The default action for this extension will be set to the selected" & @CRLF
	$s &= "PFA association.  The DefaultIcon will be set to the user-defined icon from this dialog." & @CRLF
	$s &= "" & @CRLF
	$s &= "2)  No PFA default association is selected:" & @CRLF
	$s &= "a)  Copy Host Associations is selected:  If a host default association exists it will be set as the default" & @CRLF
	$s &= "and the host DefaultIcon will be used.  If a DefaultIcon does not exist, the PFA icon will be used." & @CRLF
	$s &= "If no host default action is found, then the OS will decide what action to use as the default.  The PFA" & @CRLF
	$s &= "defined icon will be used." & @CRLF
	$s &= "b)  Copy Host Associations is not selected:  No default action is defined and the OS will decide.  The PFA" & @CRLF
	$s &= "defined icon will be used." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "SendTo:" & @CRLF
	$s &= "=======" & @CRLF
	$s &= "Shortcuts defined here will show up in the system's 'Send to ->' context menu." & @CRLF
	$s &= "" & @CRLF
	$s &= "ListView = Lists the currently defined shortcut names and targets.  Drag-and-drop files / folders onto this" & @CRLF
	$s &= "           control to add new shortcuts (you are asked for a shortcut name and optional parameters)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Add... = Add a shortcut by browsing to it." & @CRLF
	$s &= "" & @CRLF
	$s &= "Remove = Remove a shortcut from the listview." & @CRLF
	$s &= "" & @CRLF
	$s &= "Clear = Clear all shortcuts from the listview." & @CRLF
	$s &= "" & @CRLF
	$s &= "Save = Save the current settings." & @CRLF
	$s &= "" & @CRLF
	$s &= "Done = Close the dialog (asks to save unsaved changes)." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "Profile:" & @CRLF
	$s &= "========" & @CRLF
	$s &= "Profile settings are stored per profile (Data\settings\<profile>_assoc.ini, _state.ini, _types.ini," & @CRLF
	$s &= "_sendto.ini)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Dropdown = Displays the active profile.  Switch profiles by choosing a new one." & @CRLF
	$s &= "" & @CRLF
	$s &= "New    = Create a new profile." & @CRLF
	$s &= "" & @CRLF
	$s &= "Clone  = Create a copy of an existing profile." & @CRLF
	$s &= "" & @CRLF
	$s &= "Rename = Rename the active profile." & @CRLF
	$s &= "" & @CRLF
	$s &= "Remove = Remove the active profile.  This action cannot be undone." & @CRLF
	$s &= "" & @CRLF
	$s &= "The last used profile is stored as 'active' in 'Data\settings\profile.ini'." & @CRLF
	$s &= "" & @CRLF
	$s &= "The profile buttons are icons (New, Clone, Rename, Remove).  They are shown greyed out and cannot be used" & @CRLF
	$s &= "while the associations are active." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "Settings:" & @CRLF
	$s &= "=========" & @CRLF
	$s &= "Click the gear icon at the bottom right of the main window.  Every option is saved as soon as it is changed" & @CRLF
	$s &= "(no Save button).  They are stored in 'Data\settings\settings.ini' ([settings] section), the splash screen" & @CRLF
	$s &= "option in 'FileAssociatorPortable.ini' next to the exe.  The profile files only keep profile data" & @CRLF
	$s &= "('Data\settings\profile.ini' has [profile] active=<last used profile>)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Theme = System / Light / Dark." & @CRLF
	$s &= "        System = Follow the Windows app theme (light or dark)." & @CRLF
	$s &= "        Light  = Always light." & @CRLF
	$s &= "        Dark   = Always dark.  Window and title bar, text, inputs, lists, buttons, the tray menu and the" & @CRLF
	$s &= "                 icons (white instead of black) use dark colors." & @CRLF
	$s &= "        settings.ini:  theme=system | light | dark" & @CRLF
	$s &= "" & @CRLF
	$s &= "Add associations on start = The associations of the last active profile are added automatically when PFA" & @CRLF
	$s &= "        is started without command line arguments." & @CRLF
	$s &= "        settings.ini:  addassociationonstart=true | false" & @CRLF
	$s &= "" & @CRLF
	$s &= "Remove associations on exit = The file associations are removed again when PFA is closed (Exit, close" & @CRLF
	$s &= "        button, Windows shutdown).  On by default." & @CRLF
	$s &= "        settings.ini:  removeonexit=true | false" & @CRLF
	$s &= "" & @CRLF
	$s &= "Check for updates on startup = Looks for a newer version in the background each time PFA starts (a message" & @CRLF
	$s &= "        is only shown when a newer version exists).  The tray menu item ""Check for updates"" checks at any time." & @CRLF
	$s &= "        settings.ini:  checkupdateonstartup=true | false" & @CRLF
	$s &= "" & @CRLF
	$s &= "Start minimized = On: PFA starts minimized to the tray.  Off: the main window is shown." & @CRLF
	$s &= "        settings.ini:  startminimized=true | false" & @CRLF
	$s &= "" & @CRLF
	$s &= "Disable splash screen = No splash screen when PFA starts." & @CRLF
	$s &= "        FileAssociatorPortable.ini (next to the exe):  DisableSplash=true" & @CRLF
	$s &= "" & @CRLF
	$s &= "Close button (X) minimizes to the tray = The close button hides the window in the tray instead of exiting" & @CRLF
	$s &= "        (use the tray menu item Exit to quit).  Off by default." & @CRLF
	$s &= "        settings.ini:  closetotray=true | false" & @CRLF
	$s &= "" & @CRLF
	$s &= "Values:  true, 1, yes, on = on;  false, 0 or blank = off.  Example settings.ini:" & @CRLF
	$s &= "" & @CRLF
	$s &= "    [settings]" & @CRLF
	$s &= "    theme=dark" & @CRLF
	$s &= "    addassociationonstart=true" & @CRLF
	$s &= "    removeonexit=true" & @CRLF
	$s &= "    checkupdateonstartup=true" & @CRLF
	$s &= "    startminimized=false" & @CRLF
	$s &= "    closetotray=false" & @CRLF
	$s &= "" & @CRLF
	$s &= "Settings of older versions are taken over automatically the first time this version starts (no settings.ini" & @CRLF
	$s &= "yet):  theme and 'commandline=add_gui' (-> add associations on start + start minimized, and its profile" & @CRLF
	$s &= "name) from profile.ini, the per-profile 'remove on close' state, and DisableUpdateCheck=true from" & @CRLF
	$s &= "FileAssociatorPortable.ini.  The old 'commandline' and 'theme' lines are then removed from profile.ini." & @CRLF
	$s &= "" & @CRLF
	$s &= "NOTE:  Windows' own message and file dialogs are not themed.  Dark buttons, combo boxes and scroll bars" & @CRLF
	$s &= "       need Windows 10 (1903) or newer; on older systems they stay light." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "Tray Menu:" & @CRLF
	$s &= "==========" & @CRLF
	$s &= "Left-click the tray icon to show the main window.  Right-click it to access these options." & @CRLF
	$s &= "" & @CRLF
	$s &= "Refresh icons now = Sends the SHChangeNotify() system message so Explorer refreshes the icons." & @CRLF
	$s &= "" & @CRLF
	$s &= "Check for updates = Checks online if a newer version of PFA is available (needs an internet connection)." & @CRLF
	$s &= "" & @CRLF
	$s &= "Exit = Close PFA." & @CRLF
	$s &= "" & @CRLF
	$s &= "The options ""Add associations on start"" and ""Remove associations on exit"" are in the Settings window." & @CRLF
	$s &= "" & @CRLF
	$s &= "System Restore:" & @CRLF
	$s &= "===============" & @CRLF
	$s &= "While nothing destructive should happen as a result of using this app, it's always a good idea to have a backup." & @CRLF
	$s &= "Press the Create System Restore Point button to create a System Restore Point." & @CRLF
	$s &= "" & @CRLF
	$s &= "Remember, this is a safety measure.  Under normal circumstances, Adding and Removing the file associations is" & @CRLF
	$s &= "all that is necessary." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "Modes of Operation:" & @CRLF
	$s &= "===================" & @CRLF
	$s &= "If run directly, the program starts the GUI where you can add or remove the associations, edit the" & @CRLF
	$s &= "associations, file types and SendTo entries, or create a restore point.  Depending on the setting" & @CRLF
	$s &= "'Remove associations on exit', the file associations are removed when PFA is closed." & @CRLF
	$s &= "" & @CRLF
	$s &= "You can also run the program via command line: FileAssociatorPortable.exe <param1> <param2>" & @CRLF
	$s &= "" & @CRLF
	$s &= "<param1> can be one of the following:" & @CRLF
	$s &= "" & @CRLF
	$s &= "add = Adds the file associations, then exits." & @CRLF
	$s &= "add_gui = Adds the file associations, starts the GUI minimized to the tray." & @CRLF
	$s &= "remove = Removes the file associations, then exits." & @CRLF
	$s &= "" & @CRLF
	$s &= "<param2> is an optional parameter and must specify the profile to activate and use.  This parameter is" & @CRLF
	$s &= "ignored if <param1> is 'remove'.  If it is left out, the last active profile is used (the profile" & @CRLF
	$s &= "that was selected the last time PFA was used, stored as 'active' in 'Data\Settings\profile.ini')." & @CRLF
	$s &= "" & @CRLF
	$s &= "Examples -" & @CRLF
	$s &= "    FileAssociatorPortable.exe add_gui                  (last active profile)" & @CRLF
	$s &= "    FileAssociatorPortable.exe add_gui DefaultProfile   (this profile)" & @CRLF
	$s &= "" & @CRLF
	$s &= "Without command line arguments the Settings decide:  'Add associations on start' adds the associations of" & @CRLF
	$s &= "the last active profile, 'Start minimized' starts the GUI in the tray.  Older versions used" & @CRLF
	$s &= "'commandline=add_gui' in 'Data\Settings\profile.ini' for this; that line is no longer read (it is taken over" & @CRLF
	$s &= "into the Settings automatically).  A launcher that can pass arguments can still use the command line above." & @CRLF
	$s &= "" & @CRLF
	$s &= "If PFA is already running, there is one command line parameter available:" & @CRLF
	$s &= "" & @CRLF
	$s &= "exit = Close the running instance of PFA.  File associations are removed based on the setting" & @CRLF
	$s &= "       'Remove associations on exit'." & @CRLF
	$s &= "" & @CRLF
	$s &= "Internal parameters:  multi_open and bg_open are used by the context-menu entries created for %%1 and" & @CRLF
	$s &= "Background commands.  multi_open_admin and bg_open_admin are the same with ""Run as Admin"" (elevated start)." & @CRLF
	$s &= "They are not meant to be started by hand." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "Known Issues / Notes:" & @CRLF
	$s &= "=====================" & @CRLF
	$s &= "- The program was renamed from PortableFileAssociator to FileAssociatorPortable.  The old" & @CRLF
	$s &= "  PortableFileAssociator.ini (DisableSplash / DisableUpdateCheck) is copied to FileAssociatorPortable.ini" & @CRLF
	$s &= "  automatically.  Data\settings and the registry entries (PortableFileAssoc_<ext>) keep their names, so profiles" & @CRLF
	$s &= "  and Remove File Associations keep working.  Entries added by the old exe start the old exe: remove the" & @CRLF
	$s &= "  associations with the old version first (or Remove, then Add once with the new exe)." & @CRLF
	$s &= "- Windows' own default app for an extension (Settings > Default apps, ie WinRAR for zip) is left alone unless a PFA" & @CRLF
	$s &= "  default association takes over that extension.  In that case the key is renamed, not copied, while the" & @CRLF
	$s &= "  associations are active, so the default app is back after Remove.  If Windows refuses the rename, the" & @CRLF
	$s &= "  default app is left untouched (the PFA default may then not take effect)." & @CRLF
	$s &= "- Windows 11 shows these (classic) context-menu entries under ""Show more options""." & @CRLF
	$s &= "- 'Single file type' relies on the Windows verb setting MultiSelectModel=Single.  If an entry still appears" & @CRLF
	$s &= "  with several items selected on your Windows version, leave the option unchecked." & @CRLF
	$s &= "- Message boxes, input boxes and file dialogs are drawn by Windows and do not follow the Dark theme." & @CRLF
	$s &= "- Background entries do not appear in virtual folders such as This PC or Control Panel." & @CRLF
	$s &= "- File extension entries are also written to SystemFileAssociations\.<ext>\shell, so they show up even when" & @CRLF
	$s &= "  Windows has a default app chosen for the extension (typical for media files such as mp3 and mp4).  Use" & @CRLF
	$s &= "  Remove File Associations and then Add File Associations once after updating." & @CRLF
	$s &= "- ""Run as Admin"" shows the Windows confirmation (UAC) every time the entry is used.  It is not available for" & @CRLF
	$s &= "  the Recycle Bin." & @CRLF
	$s &= "- After updating PFA, use Remove File Associations and then Add File Associations once, so the new" & @CRLF
	$s &= "  commands (%%1, Run as Admin, Folder Command) are written to the registry." & @CRLF
	$s &= "" & @CRLF
	$s &= "" & @CRLF
	$s &= "Owner / Trademark:" & @CRLF
	$s &= "==================" & @CRLF
	$s &= "FileAssociatorPortable is owned by ShihabUddinX.  ShihabUddinX is a trademark of ShihabUddinX." & @CRLF
	$s &= "Original work by Erik Pilsits." & @CRLF
	Return $s
EndFunc
#EndRegion Embedded Readme
