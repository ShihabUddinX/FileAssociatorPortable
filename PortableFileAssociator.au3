#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=..\..\App\AppInfo\appicon.ico
#AutoIt3Wrapper_outfile=..\..\PortableFileAssociator.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Res_Comment=Create custom portable file associations and context menus.
#AutoIt3Wrapper_Res_Description=PortableFileAssociator
#AutoIt3Wrapper_Res_ProductName=PortableFileAssociator
#AutoIt3Wrapper_Res_CompanyName=ShihabUddinX
#AutoIt3Wrapper_Res_Fileversion=3.0.0.1
#AutoIt3Wrapper_Res_ProductVersion=3.0.0.1
#AutoIt3Wrapper_Res_LegalCopyright=Copyright (c) ShihabUddinX. Original work by Erik Pilsits
#AutoIt3Wrapper_Res_LegalTrademarks=ShihabUddinX
#AutoIt3Wrapper_Res_Field=Owner|ShihabUddinX
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
#AutoIt3Wrapper_Run_Obfuscator=y
#Obfuscator_Parameters=/sf=1 /sv=1 /om /cs=0 /cn=0
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <_RegFunc.au3>
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

Global Const $version = "3.0.0.1"

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
		If $wndMSG_msg <> -1 Then _SendMessage(WinGetHandle("PortableFileAssociator"), $wndMSG, $wndMSG_msg, 0)
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
Global $aProfIcons[4][2], $fGDIP = False ; profile action icon bitmaps: [n][0] = normal, [n][1] = disabled
Global $iThemeMode = 0, $fDark = False ; theme: 0 = system, 1 = light, 2 = dark
Global $iBgCol = 0xF0F0F0, $iCtrlCol = 0xFFFFFF, $iTextCol = 0x000000, $iLightBg = 0xF0F0F0
Global $nTheme
Global $aMutedLbl[4][3] ; muted labels: [n][0] = ctrl id, [n][1] = light colour, [n][2] = dark colour
Global Const $aProfIconNames[4] = ["New_Profile", "Clone_Profile", "Rename_Profile", "Remove_Profile"]
Global $refreshnow, $rebuildonchange, $trayexit, $trayonclose, $trayaddonstart
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
Global $curProfile = IniRead($profileini, "profile", "active", "__error__")
If $curProfile = "__error__" Or Not FileExists($settingsdir & "\" & $curProfile & "_assoc.ini") Then $curProfile = _GetNextProfile()
Global $associni, $stateini, $typesini, $sendtoini
_SetProfile($curProfile)

FileChangeDir(@ScriptDir) ; set working directory

; operating mode
_OperatingMode()
; if the GUI is running...
_SetTrayStatus()
#EndRegion Init
; GUI loop
While 1
	Sleep(1000)
WEnd

#Region Misc Functions
;=======================================================================================
; Misc Functions
;=======================================================================================

Func _OperatingMode()
	Local $arg1 = "", $arg2 = ""

	If $CmdLine[0] > 2 Then ; max commandline args
		MsgBox(16, "Error", "Too many commandline arguments.")
		Exit
	EndIf
	If $CmdLine[0] = 0 Then
		; check for INI arguments
		Local $inicommands = IniRead($profileini, "profile", "commandline", "")
		If $inicommands <> "" Then
			Local $aCmd = StringSplit(StringStripWS($inicommands, 3), " ")
			$arg1 = $aCmd[1] ; there's at least one argument if $inicommands is not ""
			If $aCmd[0] > 1 Then $arg2 = $aCmd[2] ; possible profile
		EndIf
	Else ; commandline args
		$arg1 = $CmdLine[1]
		If $CmdLine[0] > 1 Then $arg2 = $CmdLine[2]
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
	; get OnClose setting, 1 = remove associations on close (default)
	$onclose = Number(IniRead($stateini, "state", "onclose", "-1"))
	If $onclose = -1 Then
		IniWrite($stateini, "state", "onclose", "1")
		$onclose = 1
	EndIf
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
	_ThemeLoad() ; read theme setting (system / light / dark)
	TraySetClick(8) ; show menu only on right-click
	TraySetState(1) ; show tray icon

	If $state = 1 Then
		TraySetToolTip("PortableFileAssociator (enabled)" & @CRLF & "Profile:  " & $curProfile)
	Else
		TraySetToolTip("PortableFileAssociator (disabled)")
	EndIf

	; ===== message GUI for context menu, active but off screen
	$contextGUI = GUICreate("", 1, 1, -1000, 0, -1, $WS_EX_TOOLWINDOW)
	GUISetState()
#Region	===== main GUI & tray
	; Main window: wider layout with clearer grouping and more comfortable spacing.
	$nGUI = GUICreate("PortableFileAssociator", 310, 545, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_MINIMIZEBOX))
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

	; theme selector
	GUICtrlCreateLabel("Theme:", 150, 510, 42, 18)
	$nTheme = GUICtrlCreateCombo("", 196, 506, 98, 24, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	GUICtrlSetTip(-1, "System follows the Windows app theme.")
	GUICtrlSetData($nTheme, "System|Light|Dark", StringUpper(StringLeft(_ThemeModeName(), 1)) & StringTrimLeft(_ThemeModeName(), 1))

	; GUI events
	GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
	GUISetOnEvent($GUI_EVENT_MINIMIZE, "_HideMainGUI")
	GUISetOnEvent($GUI_EVENT_RESTORE, "_RestoreMainGUI")

	; tray menu
	$rebuildonchange = TrayCreateItem("Rebuild icon cache on change")
	$refreshnow = TrayCreateItem("Refresh icons now")
	TrayCreateItem("")
	$trayaddonstart = TrayCreateItem("Add associations on start")
	$trayonclose = TrayCreateItem("Remove associations on close")
	TrayCreateItem("")
	TrayCreateItem("")
	$trayexit = TrayCreateItem("Exit")

	; tray events
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "_RestoreMainGUI")
	TrayItemSetOnEvent($trayaddonstart, "_ToggleAddOnStart")
	TrayItemSetOnEvent($trayonclose, "_ToggleOnClose")
	TrayItemSetOnEvent($rebuildonchange, "_ToggleRebuildOnChange")
	TrayItemSetOnEvent($refreshnow, "_RefreshNow")
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
	GUICtrlSetOnEvent($nTheme, "_ThemeEvent")

	; set button states
	_ActionButtonsState() ; action buttons
#EndRegion ===== main GUI & tray
#Region	===== association GUI
	$aGUI = GUICreate("Edit Associations", 550, 490, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOOLWINDOW, $nGUI)
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
	$tGUI = GUICreate("Configure File Types", 465, 340, -1, -1, $WS_CAPTION, $WS_EX_TOOLWINDOW, $nGUI)

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
	$sGUI = GUICreate("SendTo Configuration", 600, 315, -1, -1, $WS_CAPTION, $WS_EX_TOOLWINDOW, $nGUI)
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

	_ThemeApply() ; apply light / dark theme to all GUIs

	; populate profile list
	_PopulateProfiles()

	GUISwitch($nGUI) ; switch to main GUI
	If $guimode = "add_gui" Then
		_AddAssociations()
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
	; if the GUI is running
	If WinExists($nGUI) Then
		_SetTrayStatus()
	EndIf
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
		$newname = StringStripWS(InputBox("Profiles...", "Enter new profile name:", $newname, "", 220, 130, Default, Default, 0, $nGUI), 8)
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

Func _SetTrayStatus()
		; tray status
		If _AddOnStartEnabled() Then
			TrayItemSetState($trayaddonstart, $TRAY_CHECKED)
		Else
			TrayItemSetState($trayaddonstart, $TRAY_UNCHECKED)
		EndIf
		If $onclose = 1 Then
			TrayItemSetState($trayonclose, $TRAY_CHECKED)
		Else
			TrayItemSetState($trayonclose, $TRAY_UNCHECKED)
		EndIf
		If $fVistaOrBetter Then
			TrayItemSetState($rebuildonchange, $TRAY_DISABLE)
		Else
			If $rebuild = 1 Then
				TrayItemSetState($rebuildonchange, $TRAY_CHECKED)
			Else
				TrayItemSetState($rebuildonchange, $TRAY_UNCHECKED)
			EndIf
		EndIf
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

Func _AddOnStartEnabled()
	; "Add associations on start" is on when profile.ini [profile] commandline starts with add_gui
	Local $aCmd = StringSplit(StringStripWS(IniRead($profileini, "profile", "commandline", ""), 3), " ")
	Return ($aCmd[1] = "add_gui")
EndFunc

Func _ToggleAddOnStart()
	; saved in Data\settings\profile.ini:  commandline=add_gui  (on)  /  commandline=  (off)
	; add_gui uses the last active profile ([profile] active), no profile name needed
	If _AddOnStartEnabled() Then
		IniWrite($profileini, "profile", "commandline", "")
		TrayItemSetState($trayaddonstart, $TRAY_UNCHECKED)
	Else
		IniWrite($profileini, "profile", "commandline", "add_gui")
		TrayItemSetState($trayaddonstart, $TRAY_CHECKED)
	EndIf
EndFunc

Func _ToggleOnClose()
	If $onclose = 1 Then
		TrayItemSetState($trayonclose, $TRAY_UNCHECKED)
		$onclose = 0
		IniWrite($stateini, "state", "onclose", "0")
	Else
		TrayItemSetState($trayonclose, $TRAY_CHECKED)
		$onclose = 1
		IniWrite($stateini, "state", "onclose", "1")
	EndIf
EndFunc

Func _ToggleRebuildOnChange()
	If $rebuild = 1 Then
		TrayItemSetState($rebuildonchange, $TRAY_UNCHECKED)
		$rebuild = 0
		IniWrite($stateini, "state", "refresh", "0")
	Else
		If $fVistaOrBetter Then ; we should never see this message
			MsgBox(0 + 64, "Error", "This function will not work on Vista+.")
			Return
		Else
			TrayItemSetState($rebuildonchange, $TRAY_CHECKED)
			$rebuild = 1
			IniWrite($stateini, "state", "refresh", "1")
		EndIf
	EndIf
EndFunc


Func _AddAssociations()
	_FileAssociations("add")
	_ActionButtonsState() ; set button states
	TraySetToolTip("PortableFileAssociator (enabled)" & @CRLF & "Profile:  " & $curProfile) ; set tooltip
EndFunc

Func _RemoveAssociations()
	_FileAssociations("remove")
	_ActionButtonsState() ; set button states
	TraySetToolTip("PortableFileAssociator (disabled)") ; set tooltip
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

Func _AssocHelp() ; help
	ShellExecute('"' & @ScriptDir & '\App\portablefileassociator\Readme.txt"', "", "", "open")
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
			If $bKeepUC Then
				; keep Windows' default app (UserChoice) as it is: nothing to back up, nothing to restore on remove
			ElseIf _RegKeyExists("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i]) Then ; key exists
				; backup
				_RegMoveKey("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i], _
							"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_PFA")
				; don't copy any defaut "Open With..." settings
				_RegCopyKey("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_PFA\OpenWithList", _
							"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "\OpenWithList")
				_RegCopyKey("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "_PFA\OpenWithProgids", _
							"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i] & "\OpenWithProgids")
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
				RegDelete("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." & $aExts[$i])
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
	Local $s = IniRead($profileini, "profile", "theme", "system"), $aRet, $v, $i
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
	For $i = 0 To 3
		$aMutedLbl[$i][2] = 0xA0A0A0 ; muted label colour in dark mode
	Next
EndFunc

Func _ThemeEvent()
	Local $m = "system"
	Switch GUICtrlRead($nTheme)
		Case "Light"
			$m = "light"
		Case "Dark"
			$m = "dark"
	EndSwitch
	IniWrite($profileini, "profile", "theme", $m)
	_ThemeLoad()
	_ThemeApply()
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
	Local $aTargets[4] = [$nGUI, $aGUI, $tGUI, $sGUI], $iCount = 4
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
		; dark popup / tray menus (uxtheme ordinals: 135 = SetPreferredAppMode, 136 = FlushMenuThemes)
		If $fDark Then
			DllCall("uxtheme.dll", "int", 135, "int", 2)
		Else
			DllCall("uxtheme.dll", "int", 135, "int", 0)
		EndIf
		DllCall("uxtheme.dll", "none", 136)
	EndIf

	; window background + title bar
	For $j = 0 To $iCount - 1
		GUISetBkColor($iBgCol, $aTargets[$j])
		DllCall("dwmapi.dll", "long", "DwmSetWindowAttribute", "hwnd", $aTargets[$j], "dword", 20, "int*", $iVal, "dword", 4)
		DllCall("dwmapi.dll", "long", "DwmSetWindowAttribute", "hwnd", $aTargets[$j], "dword", 19, "int*", $iVal, "dword", 4)
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
					For $j = 0 To 3
						If $aMutedLbl[$j][0] = $id Then $bMuted = True
					Next
					If Not $bMuted Then GUICtrlSetColor($id, $iTextCol)
				EndIf
		EndSwitch
	Next

	If Not $hOnly Then
		; muted labels
		For $j = 0 To 3
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

#Region Profile action icons
; Icons converted from the SVG files: New_Profile.svg, Clone_Profile.svg, Rename_Profile.svg, Remove_Profile.svg
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
	For $i = 0 To 3
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
	; free the previous bitmaps after the controls switched to the new ones
	For $i = 0 To 3
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
	For $i = 0 To 3
		For $j = 0 To 1
			If $aProfIcons[$i][$j] Then DllCall("gdi32.dll", "bool", "DeleteObject", "handle", $aProfIcons[$i][$j])
			$aProfIcons[$i][$j] = 0
		Next
	Next
	If $fGDIP Then _GDIPlus_Shutdown()
	$fGDIP = False
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
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACJklEQVR42u3WTYiOURQH8N+M+ajJ"
			$s &= "jNgIMxYkY8rCZ0RZmjILm5kNKSk72ymJWNhYWUhZiYUYO4WIhRSzGIUphMH42E2GkYkZeW3OW0+3"
			$s &= "9/G+Y2Ykvadu57nnf++5/3vuOfc+VKUq/4nUzJbjdlzEKAr4GP32wBvxNLCXOIa5M7X4FoyF87R9"
			$s &= "wdYYtzPBHmLBdBdvxHA4vIkO1IW+EfbhGFeDNwmJMyV8rgv7/koIdIWj12hKsCa8CrwrbOcTAmOo"
			$s &= "T+b1BHYpa6zNIbAq9DWMJ9g4rsd3R+gPyZhmLK5kp3U59kIZgnMqGFfAZrRGf1PoNnSXI9YZDt6i"
			$s &= "JcFa8D7w7WG7kBzBaGyuLyeJi+1nXgRu4QVWRBL24lmU3wkswXPcjmhsS+afww/0Y37YFmJ1kL+f"
			$s &= "RLCkrMFIDvMRrI1xuxLsbuRAKt2B902lHNtwGkMR1qHot2bK9UFcUP04gIYcX39EYCblrxCo/w3W"
			$s &= "UOJOKfmI1GI9doTuiESah88R7icYwNXQxWRaiYNxRAO4hzsxr6y04ijelSmdtA3jMBZlNnUyg3/D"
			$s &= "lXhbcuUQvmcmDeJ43AdLM1ndHP3OwAeThXozF9WjEmRPlbq09gY4gbPYMMVz3xhvwWT42RP2fTkR"
			$s &= "O5I6KO6iZ5oJuDv8PI7+8hwCn9InYCKA+mkSaMpEslgReXnTln2M6jM/FjNZipOVlmthFlo538uy"
			$s &= "Ebg8ixdTnu+v1f/4qvwz8gsq2dTkDSE67QAAAABJRU5ErkJggg=="
		Case "Clone_Profile_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAADtUlEQVR42u2WTWhcVRTHf+e9hAxo"
			$s &= "0wkuxDCdLkQaE0RLi1rcWarEKsRFhaIoSWbuC0aijVIQF310UVEX4kNs7ryJC7GCLVi60EK6UYlK"
			$s &= "NbQqIRShrVadrGxTrEKJc4+bmzIZJ1+mikj+q/vO1z333HP+98Ea1vB/gKrK3/Vd1NFa2wHEIvIg"
			$s &= "kAUuqeoYEEdRdCZJkpZMJvM10AGcBQ7Nzs6+Njg4eGXVCZTL5fucc8eBdQ3UV1S1O4qicWttj4gc"
			$s &= "rdF9EwTB/YVC4eJyEggaCZMkaXHOvec3P+Gc66pUKs3OuS5gDLhRRA4lSdJijDkG/FDjfme1Wn25"
			$s &= "PmaaplustTZNU7NkAplMZgeQB75X1Z6BgYGpOI7/GBgYmFLVR4HzQD6TyewQEQU+nVdWkd3W2ua6"
			$s &= "PrlVRIyqbl8yARG53S8/iqLo91qd/z7ug3Z6+5/rQqwLw7B9OVfQtEBX62IJAiFAEATq7f9iV61W"
			$s &= "dWRkZJuI5LzoXp/sBmvtrkUr4Jyb9IF3JknSWtcfrcDDXv+tF2+oCzEzPT1dCcNwj4gcFpHDwB7v"
			$s &= "s21OJiLvN5yCOI6b2tvbp4DbgJPOub2qekZEOoIgeBW4B/iuUql0dXZ26szMzAWgtuRvGGOeK5VK"
			$s &= "w0C3l90M3AH8JCJfzFV6sTHcrKonVPWmBj3yi3PugSiKTpVKpceBd2vU42EYPtTf3/9rHafs8qc+"
			$s &= "UiwWH2OJO6ZQKJwOw3CziBxU1XPAjKqeE5GDwF1RFJ1KkqQFGAYuASeBoWw2u71+8xU34Rz6+vp+"
			$s &= "BJ5eSD80NHQV2LIaGg+u55tQP/u1aGtrO6aqN9SWvyEVx3Ec5HK5rc65ncBWoBNoA9YDl4GLwJSq"
			$s &= "TojIh8ViccKTEaOjo5uccy8COVWdAD5X1U+iKLq85FuQpmnOOVcQkX4gt4KDX1DVMlCOomhaVSVN"
			$s &= "09eBZ73+qqqOhWH4SqFQ+KzhFVhrX1LVsyKyz2c/qaoHnHPdqroxDMNWY4yEYdiqqhu9/ICqTgJ5"
			$s &= "EdkvIuettXtFRLPZ7PPAHEe0iMgjzrlxa+2bcRzPu3ZJ07RXVd8GZoFDwFvGmK+We/xyuXy3c+4Z"
			$s &= "YDfQJCJPFYvFd9I07feVqcc+Y8z+axVwzg379RPGmN6VbO7H9UtjzJMi0uvJ5QXPph8v4DIcx/G1"
			$s &= "6QtEZJN3PLqaCXDOfeCXHXO9sYDp+nw+f0stD8yNTo+19npMY7N/NWdLpdKiNvOIyD8Y/zqaROTI"
			$s &= "PxV8odjVavW3tV/5Nfxn8CeIVKLpsoAUsAAAAABJRU5ErkJggg=="
		Case "Clone_Profile_Dark"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACXElEQVR42u2WPWhTURTH/7dJWgim"
			$s &= "oouoiUsRY8DBT5QKjhbs0KVdFEEEN9eCiKKDi5ODCJ1EB9G6CSoWHUTQDhHUgoraarRupbUVRVvp"
			$s &= "z8Hz5Hl5L3kxKYjkLJdz/+frnnc+ntSiFv0PBLi/1W2rYbgIXAVm+EXTxhcN7wBeSFoE3gCngWXN"
			$s &= "elU3MEc0fQZ2m1yfhz0BVjbqvAOomMERoASk7bxj9xWTc8A7L4ihCJtbgSHgSJIAes3QWyDrYVlg"
			$s &= "wvBeu7vsBTAHZDy9AcOuJamBjXbecs59DQPG3za2ZOdHTz8naU2SbKfjklAjwFQCOYBdkvLG77Sz"
			$s &= "APTX+gQ9lq73QKeHdQKThu+1uyveJ5ixmhmmOi3GZeCupNeS1ksaAQYlvZRUlHRW0lpJryTdA1KS"
			$s &= "9nj6l5xzP4BRSSvsbpWkTZImJT3yMhiZhc3AVEzkU8AWk9vvYQ+AXIS9fsOH62nHAnABGLe0jhuf"
			$s &= "D7XrYxtQo8BRoD3GVv0BNHlcL30Afu97WLs/UyTJRQi2SdomaZ+dJSuk5ZJmJU1Lei6pLOmmpLJz"
			$s &= "DtPdIOmYtV5Z0kNJ951zs0mizwOngA/URxXgBLA62IzAuRD+DbgBdFdzfhz4HlIaA87YPFgXVDWQ"
			$s &= "M77H8DHP0aDJpYCnEcGetwz/4fyQgfPARWB7nd99h+2CBbNz0O4Px2TspG8geMVAgwV4wOw8M74r"
			$s &= "JoBPQDqsOG9ApsEAskEmg46oUjeF8DIKHPcBzejGjG3NhSr2fj/W0SSv3sp2wTqMEelyzk0EGbi+"
			$s &= "hAMwzvaX1q98i/4Z+glO4HhmYYC7kAAAAABJRU5ErkJggg=="
		Case "Clone_Profile_Dark_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAADv0lEQVR42u2WTWhcVRTHf+dlhpmg"
			$s &= "TZ1xIWraLkQaW0RLixhcCBaVWIW4GKEoSqhkIfPuG6IUxEUfXShGSebNG1IcgqAYFwYsXWghVVCJ"
			$s &= "38GPEkJR2mr9yCrTNlbzhjTvuLnVcZx8ESsiOZv37jnnnvO/93xdWKd1+p+QXJaN+Xy+Q0R8EbkX"
			$s &= "uAo4q6pjquqXy+UTruumROQroAM4KSIj8/PzLwwNDV1YM4B8Pn+H4zhHgQ1NxBdEpCsIgvFCodAd"
			$s &= "x/HhOtnXLS0tdw0ODlZXAsBpxnRdN+U4zuvW+TFV3Z7NZpOquh0YA65U1RHXdVPFYvEI8H3d9lsW"
			$s &= "Fhaea7RpjNlpjHnJGNO7LADHce4GNgPfRVHUHYbhlO/7F8MwnIqi6EHgNLDZ6inwQYOJvb29vckG"
			$s &= "3g1AL7B7WQBxHN9kf9+uVCq/1cvs+iiAqm6z7J8aTGxIJpPXrSQEiaaJIaJLARSRFlVFVRfVSyQS"
			$s &= "WigUOlW13YK93X43eZ6XWxIAMGmV97iu2xaG4WxdfrSp6v02VMctoE1/YgHgXCaT+blarb4I5BrA"
			$s &= "d6pqp11qUwDZbPadarX6rYjcCIx5nre/VqudSKVSHaraD1wPfJPJZN7N5XItqnpng4lXfN+/aIz5"
			$s &= "BMhYx9eo6s3Aj8DHlwAsWoau6+4QkWPA1U3EM47j3FMsFr9wXfdhEXmtTjaeTqfv6+/v/6V+g+d5"
			$s &= "OVV9AxgtlUoPLZmEAGEYfplIJHaIyCHgFHAOOCUih1T1Vus8BfQBZ4FPAZPNZnc3Ol91El6igYGB"
			$s &= "H4AnlgBZA3aupYc7/+RAaFL7f1AmkzkSRdEV9dfftBX7vu/MzMzschxnj6ruAraJSEZVN4rIeVWt"
			$s &= "isiUqk6IyFtBEEzYZoTneVtV9WmgXUQmgI/m5uber1Qq55edBa7rtovI48A+oH0VBz8DDDuOM1ws"
			$s &= "FqcBMcYMAp6V14CxOI6fL5fLHzYNgTHmGRE5CRywzidV9VmgS0S2pNPptlKpJOl0uk1EtgBdVj5p"
			$s &= "W/bBOI5PG2P2Azo9Pf0kcNz6SAEPOI4zbowp+77/l7CLMaYHeBmYF5ERYCgIgs9XenzXdW8TkTyw"
			$s &= "F0iIyGNBELzqed4+VR1u1FfVA2EYHqy/gT77/0gQBD2rcW4r4bNSqfSoiPRY1lN2nry3yKDr830/"
			$s &= "UQ9gK0AURYfXUgFzc3Nv2hN2ANRqtTPN9FR14+zs7LX1fSAJ0Nra2u153prK0M6DpJ2a88aYxfSS"
			$s &= "f2tEtk3+65QARi+j/dFF3hu/rr/j1+k/Q78DHfiPE52Z8QEAAAAASUVORK5CYII="
		Case "Rename_Profile"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABRElEQVR42u2Xv04CQRDGfxgtiAUV"
			$s &= "CqGxkJ6GmsSo8AL4UhbGhghvQEhIeAUfAfxXmQg0NCQmRu2wmUsmy63sZW+12S+ZYm/n5vtmd24y"
			$s &= "BxER27gAFsAmZ5tL7J0IQZ7Ym4uAxDlvpMbd++/7zlPAMdACDoMclUPhvst7r8CpT9ysAi6BT6PY"
			$s &= "lkDtLwSkkSd2HboI28AEKFr2P0LWQBv4Er+xkOnsp0Ap1BV0FHkPKABdg7wcqgh15gMhPwIe5Nkz"
			$s &= "UPGtLZujJu8r8pkDubcAfex3Ql7OQO4lwEY+VeTVPD9v0/Fb1rcpmT9KCyakgGRtZp6F3CpgP0OA"
			$s &= "IdAA6sATcAasgZuUtqtx5duIzBb7Ind+IE1o1xDy6wkULAL0XtfYvwdWwAnQdEhoZIkbJyKrgIXl"
			$s &= "7n0NmYydppt5oIn4PP71RJj4AWV76H431ah2AAAAAElFTkSuQmCC"
		Case "Rename_Profile_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACEUlEQVR42u2XT2sTYRDGn5kEjBdP"
			$s &= "LR7aioKCoIIfQatNexWxx4DJvllDLv0GfgTFy777B/dYSg+tZ6kUz94KRT0Vc9AiFASFwIZ9vGwk"
			$s &= "LCmmcbcKdi4Ls7P7e2bemX3fBc7sfzfJO8IwXCL5EsB8kSCSPVVtGWNej/p1TGDhcAAQkQWSUd5f"
			$s &= "HRM7DwDtdluKFBAEAQFcyvv1b/dAtagXhWF4keT1Wq32rtFo/Jj0OS0IvkTyI4Ddfr+/F0XR1VMT"
			$s &= "4Pt+neQrABcy15U0TXc9z5srXYDv+3UR2QZwPndrrlKprJXaA0EQLAPYBlA7Zuy+l1aBHHwLQL7p"
			$s &= "9tI0fV6KAGvtyhAuIp4x5iHJx6PwarV6z3Xdb4ULCIJgWVW3ssxDx3G61tpZEXmahbxPkqTebDa/"
			$s &= "Fj4Fo2UnGRhjXGvtrKruALiRwe92u90vJ0lKT1p2AH673X4Sx/GMqu6IyM1p4RMJsNaujJTdN8Z0"
			$s &= "4jieGQwGv+AkF6eBTyRAVYcN92IIT5LkDYBbAPZF5I7rup+nHedJluAcADiOs5bLfF9EFo0xh6ey"
			$s &= "GUVRtEHyNoBrQ3iapke+7z9T1WM/u8aY1UIEkHyUXT8AuE/ySEQ2ADwgWV4FSK7meuKtMebQ87zL"
			$s &= "qroOYL3UJXBdd3Ocv9PpHAA4+NPd9N87EZHsichCdoYr2j79tgKq2iLZKwneOvsTOrO8/QRpTOEl"
			$s &= "BA7vwgAAAABJRU5ErkJggg=="
		Case "Rename_Profile_Dark"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABXUlEQVR42u2Xu0oDQRSG/xO0EAur"
			$s &= "GEMULbS3sRaEGF8gvkAeJ4XYiPoGIgi+go8Qr5VFYmMjCEHtPpsJLMPsJe4ONvt3O5yZ/zJnD7tS"
			$s &= "jRoegC4woXqMga7PZwEBE0nrkfyNzWwzLwEAIiQbPLfx31feqNBhC9gHlqNEVaBxP93WV2D7z+fO"
			$s &= "KwA4BL68jn8DOtEFpJDPMIzahEBP0q2kpZSSabQeAHrAtyu9Aaae+xGwEuUKgKME+RlgQN8jb0Zp"
			$s &= "Qs/5pSNfBR7c2jOwVqq30go98osE+X0eeWkBXuznjrxZlLyUgAzyUYK8XdnrHRDw45ZOA84fgVal"
			$s &= "EzYgYAbfeWHyLAELc4yIK0m7knYkPUk6kPQBnEjqpG0ys+NSgygwYl+ANrDohlAm8hIIfRHhlJt7"
			$s &= "7nsld2b2DmxJ2sszZGbXoXPrL6KsJpxI2oiRgqRxkQQGTkQM8kH941PDxy/5Lw4zYQlEOwAAAABJ"
			$s &= "RU5ErkJggg=="
		Case "Rename_Profile_Dark_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACFUlEQVR42u1XwWoTURQ991GSuHFl"
			$s &= "cdFWFBQEFfwErTbtVkT3ks2IzLzMF/gDAee9wIhR3JbiIu1aKsW1u0KpropZaBEKgk1CkpnjZiJx"
			$s &= "iBjiTBXM2QyceTPn3Mu9970HzPC/Q9KE1nqF5EsAi1kKkWwppSrGmNejvBqzMHNxABCRJZIv0vzc"
			$s &= "mLWLAGCtlSwNeJ5HAOfSvPrbNTCX1Y+01mfjOL5cLBbf1Wq140m/UxmJr5D8ICI7vV5v1/f9iydm"
			$s &= "wHXdMsktAKcT6kIURTu+7y/kbsB13bKIbAI4lXq1EEVRNVcDWutVEdkaIz7Et9wMaK1XSW4CKAFo"
			$s &= "AjhO9fxut9sNcjHged7aUFxEnlpr74rIg1HxOI5vNRqNr5m3YRJ5E0CJ5HNr7SPHcebjOH4sIgCw"
			$s &= "3+/3y2EYfsl8DqTS3qjX647jOPOFQmEbwBUA+4PB4GYYhp8zH0RJ2ptJ2p8ZYx66rntGRLYBXJ1W"
			$s &= "fKIa8DxvLSm0n8SVUj/ElVLL04hPWoTDgrMjkb8heQ3AnojcCILg07TtPImBIgAYY6qpyPdEZNkY"
			$s &= "c3gim5HneRsArpO8NBTvdDpHWusnJH85dq2197Nqw3vJ871S6na73T4qlUobJO/kmgERSUfwNgiC"
			$s &= "w2q1ep7kOoD1XA0YY16N44MgOABw8Ke76b93IiLZEpGl5AyXNT7+NgNKqQrJVh7iJCuzm9AMaXwH"
			$s &= "mEzq7L5bfzMAAAAASUVORK5CYII="
		Case "Remove_Profile"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAq0lEQVR42u2XsQ2DMBBFn6IUFGxB"
			$s &= "QRmizEHNBsyRiimYgJI5mCElAyQNHTQuXBAIxjJE+l+65su+/3TX2CBJ21QC40qVPoKaH4K2VjMX"
			$s &= "dDnzuHND3u7o0Zoe+bcDh0/ABSAFHkBsebHx0hAANdABmeVlxqtDABy+AgEIQAACEIBXXR3uFEAE"
			$s &= "9JbXAQkwhADoZ7wBeP3lCpZ09/ggvblCVMBnR/AbeOo3Iy1pAtjyTzqf/xYRAAAAAElFTkSuQmCC"
		Case "Remove_Profile_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABF0lEQVR42u2XPU7DQBCFZ9arFUVu"
			$s &= "QZE2F3E6oLZs45V8CipOYMn2xheALrmGJUSZhgKhXAAXkaXdRwVFBEhLiMLPvnI08+abmWK1REH/"
			$s &= "XeyTbIy5BNB8ashc5Hne7gVgjLkBcPatkzLf5nl+vhsXP/YEdV3HQoglgFVRFPOvmDdNs2Tm2Dk3"
			$s &= "11qv3ss5+gakb0HXdVPn3GQcx3VZlgMRUVVVE6XUVAgxpGm69vHz3oC1dgGgl1LO3qaQcgagt9Yu"
			$s &= "fP2OfoIAEAACQAAIAL/vNYyi6IKZT5h58xpTSvUATgFsDw6QpulmN5YkyZaIHv7WCaSUT845Yua4"
			$s &= "bVvs2efRewNZlt0R0TURDXs0fgZwpbW+Dz+goI/0Atg5X47aq8GRAAAAAElFTkSuQmCC"
		Case "Remove_Profile_Dark"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAvElEQVR42u2XPQ6CQBCFvzEWFtzC"
			$s &= "gpaLUHsDzmHlKTgBJefgAjQWxnAApaB7NltQoIYfg5p5zSYvmzffzhS7Cy7XCEnK9F7ZEoUKLa9i"
			$s &= "qNbmm9udBvJyRkYZMtJne1bvwHbCqWIgAmoza4MXATHQmlk9Jm9KB3KgApKelwQvHxu2+ggcwAEc"
			$s &= "wAEc4PduQ+AA7ICm51XAHug+DmBmzYDXAee/G8E1rKkkzaxzmfqmO0m6z3gJ3yQd/UPjeqUHDI7z"
			$s &= "k6/Cr2oAAAAASUVORK5CYII="
		Case "Remove_Profile_Dark_Disabled"
			$s = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABF0lEQVR42u2XO07DQBCG/wUvUKTx"
			$s &= "GSjSQuVTOF3CDUCy5PE1aL1rWQJRuCXpkltYvkAaCoQiOssiRSRbHhqniWIh5yFe+ze7mpmd+Xam"
			$s &= "WC1g9N8lugQT0S2Ahy/C7pRSj3sBENEYwPDAl50opUabxpMfOwLf910hxBTATCk12CU5EU0BuMw8"
			$s &= "0FrPtsV8ewesrgeCIOgzc6+qqnkcx0sA8DyvZ1lWXwixDMNw3iVf5w4w8xOATEp5tbY1+6zx4agA"
			$s &= "h5YBMAAGwAAYgN/3GtZ1fSOlvMjzfLG2FUWR2bZ9WZbl6ugAURQtNm1JkqwAvPy5Ebw1q0tEvGed"
			$s &= "1zbHaZsjTdN3x3HOAVwDONux8AeAe631s/kBGbXpE0w8UjLO8EsYAAAAAElFTkSuQmCC"
	EndSwitch
	Return $s
EndFunc
#EndRegion Profile action icons
