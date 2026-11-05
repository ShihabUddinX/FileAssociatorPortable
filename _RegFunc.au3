#include-once
#include <Constants.au3>
; ===============================================================================================================================
; Reg Value type Constants
; ===============================================================================================================================

;~ Global Const $REG_SZ = 1
;~ Global Const $REG_EXPAND_SZ = 2
;~ Global Const $REG_BINARY = 3
;~ Global Const $REG_DWORD = 4
;~ Global Const $REG_MULTI_SZ = 7

Global Const $PFA_HKEY_CLASSES_ROOT = 0x80000000
Global Const $PFA_HKEY_CURRENT_USER = 0x80000001
Global Const $PFA_HKEY_LOCAL_MACHINE = 0x80000002
Global Const $PFA_HKEY_USERS = 0x80000003
Global Const $PFA_HKEY_PERFORMANCE_DATA = 0x80000004
Global Const $PFA_HKEY_PERFORMANCE_TEXT = 0x80000050
Global Const $PFA_HKEY_PERFORMANCE_NLSTEXT = 0x80000060
Global Const $PFA_HKEY_CURRENT_CONFIG = 0x80000005
Global Const $PFA_HKEY_DYN_DATA = 0x80000006
Global Const $PFA_KEY_QUERY_VALUE = 0x0001
Global Const $PFA_KEY_SET_VALUE = 0x0002
Global Const $PFA_KEY_WRITE = 0x20006
Global Const $PFA_REG_OPTION_NON_VOLATILE = 0x0000
Global Const $PFA_REG_OPTION_VOLATILE = 0x0001
Global Const $PFA_REG_QWORD = 11

Func _RegCopyKey($s_key, $d_key, $delete = False)
	Local $i, $val, $data, $type, $key

	RegWrite($d_key) ; write dest key, in case key empty
	If @error Then Return @error ; some error
	; value loop
	$i = 0
	While 1
		$i += 1
		$val = RegEnumVal($s_key, $i)
		If @error Then ExitLoop ; no more values
		$data = RegRead($s_key, $val)
		If @error Then ContinueLoop ; some error reading value, skip it
		Switch @extended ; set val type
			Case $REG_SZ
				$type = "REG_SZ"
			Case $REG_EXPAND_SZ
				$type = "REG_EXPAND_SZ"
			Case $REG_BINARY
				$type = "REG_BINARY"
			Case $REG_DWORD
				$type = "REG_DWORD"
			Case $REG_MULTI_SZ
				$type = "REG_MULTI_SZ"
		EndSwitch
		RegWrite($d_key, $val, $type, $data) ; write new value
	WEnd
	; key loop
	$i = 0
	While 1
		$i += 1
		$key = RegEnumKey($s_key, $i)
		If @error Then ExitLoop ; no more keys
		_RegCopyKey($s_key & "\" & $key, $d_key & "\" & $key) ; recurse
	WEnd
	; move key
	If $delete Then RegDelete($s_key)
EndFunc   ;==>_RegCopyKey

Func _RegMoveKey($s_key, $d_key)
	_RegCopyKey($s_key, $d_key, True)
EndFunc   ;==>_RegMoveKey

Func _RegCopyValue($s_key, $s_val, $d_key, $d_val, $delete = False)
	Local $data, $type

	$data = RegRead($s_key, $s_val)
	If @error Then Return SetError(1, 0, 0) ; some error reading value, skip it

	Switch @extended ; set val type
		Case $REG_SZ
			$type = "REG_SZ"
		Case $REG_EXPAND_SZ
			$type = "REG_EXPAND_SZ"
		Case $REG_BINARY
			$type = "REG_BINARY"
		Case $REG_DWORD
			$type = "REG_DWORD"
		Case $REG_MULTI_SZ
			$type = "REG_MULTI_SZ"
	EndSwitch
	RegWrite($d_key, $d_val, $type, $data)
	If $delete Then RegDelete($s_key, $s_val)
EndFunc   ;==>_RegCopyValue

Func _RegMoveValue($s_key, $s_val, $d_key, $d_val)
	_RegCopyValue($s_key, $s_val, $d_key, $d_val, True)
EndFunc   ;==>_RegMoveValue

Func _RegKeyExists($s_key)
	RegRead($s_key, "")
	If @error <= 0 Then ; key exists
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_RegKeyExists

Func _RegSubkeySearch($s_key, $s_search, $s_mode = 0, $s_case = 0)
	; success returns subkey index
	; failure returns 0
	Local $i = 1, $key, $len, $string

	$len = StringLen($s_search)

	While 1
		$key = RegEnumKey($s_key, $i)
		If @error Then Return 0 ; no more keys
		Switch $s_mode
			Case 0 ; substring
				If StringInStr($key, $s_search, $s_case) Then Return $i
			Case 1 ; beginning of string
				$string = StringLeft($key, $len)
				Switch $s_case
					Case 0 ; case insensitive
						If $string = $s_search Then Return $i
					Case 1 ; case sensitive
						If $string == $s_search Then Return $i
				EndSwitch
		EndSwitch
		$i += 1
	WEnd
EndFunc   ;==>_RegSubkeySearch

Func _RegValueExists($s_key, $s_val)
	RegRead($s_key, $s_val)
	; @error = -2 is 'type not supported', implying value exists
	If @error = -1 Or @error >= 1 Then ; value does not exist
		Return 0
	Else
		Return 1
	EndIf
EndFunc   ;==>_RegValueExists

Func _RegKeyEmpty($s_key)
	Local $err1 = 0, $err2 = 0

	; check for keys
	RegEnumKey($s_key, 1)
	If @error Then $err1 = 1
	; check for values
	RegEnumVal($s_key, 1)
	If @error Then $err2 = 1
	; set return
	If $err1 And $err2 Then ; empty
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_RegKeyEmpty

Func _RegWrite($szKey, $szValue = "", $iType = -1, $bData = Default, $dwOptions = $PFA_REG_OPTION_NON_VOLATILE)
	Local $hRoot = StringLeft($szKey, StringInStr($szKey, "\") - 1)
	If $hRoot = "" Then $hRoot = $szKey ; passed a root key
	Switch $hRoot
		Case "HKEY_LOCAL_MACHINE", "HKLM"
			$hRoot = $PFA_HKEY_LOCAL_MACHINE
		Case "HKEY_USERS", "HKU"
			$hRoot = $PFA_HKEY_USERS
		Case "HKEY_CURRENT_USER", "HKCU"
			$hRoot = $PFA_HKEY_CURRENT_USER
		Case "HKEY_CLASSES_ROOT", "HKCR"
			$hRoot = $PFA_HKEY_CLASSES_ROOT
		Case "HKEY_CURRENT_CONFIG", "HKCC"
			$hRoot = $PFA_HKEY_CURRENT_CONFIG
		Case Else
	Return SetError(1, 0, 0)
	EndSwitch

	Local $szSubkey = StringTrimLeft($szKey, StringInStr($szKey, "\"))

	Local $ret = DllCall("advapi32.dll", "long", "RegCreateKeyExW", "ulong_ptr", $hRoot, "wstr", $szSubkey, "dword", 0, "ptr", 0, "dword", $dwOptions, _
											"dword", $PFA_KEY_WRITE, "ptr", 0, "ulong_ptr*", 0, "ptr*", 0)
	If $ret[0] <> 0 Then Return SetError(2, $ret[0], 0)
	Local $hKey = $ret[8], $lpData
	If $iType >= 0 And $bData <> Default Then
		Switch $iType
			Case $REG_SZ, $REG_EXPAND_SZ
				$bData &= Chr(0) ; add terminating null
				$lpData = DllStructCreate("wchar[" & StringLen($bData) & "]")
			Case $REG_MULTI_SZ
				$bData &= Chr(0) & Chr(0) ; add 2 terminating nulls
				$lpData = DllStructCreate("wchar[" & StringLen($bData) & "]")
			Case Else
				$lpData = DllStructCreate("byte[" & BinaryLen($bData) & "]")
		EndSwitch
		DllStructSetData($lpData, 1, $bData)
		$ret = DllCall("advapi32.dll", "long", "RegSetValueExW", "ulong_ptr", $hKey, "wstr", $szValue, "dword", 0, _
										"dword", $iType, "ptr", DllStructGetPtr($lpData), "dword", DllStructGetSize($lpData))
	EndIf
	DllCall("advapi32.dll", "long", "RegCloseKey", "ulong_ptr", $hKey)

	If $ret[0] <> 0 Then Return SetError(3, $ret[0], 0)
	Return 1
EndFunc

Func _RegRead($szKey, $szValue)
    Local $hRoot = StringLeft($szKey, StringInStr($szKey, "\") - 1)
    If $hRoot = "" Then $hRoot = $szKey ; passed a root key
    Switch $hRoot
        Case "HKEY_LOCAL_MACHINE", "HKLM"
            $hRoot = $PFA_HKEY_LOCAL_MACHINE
        Case "HKEY_USERS", "HKU"
            $hRoot = $PFA_HKEY_USERS
        Case "HKEY_CURRENT_USER", "HKCU"
            $hRoot = $PFA_HKEY_CURRENT_USER
        Case "HKEY_CLASSES_ROOT", "HKCR"
            $hRoot = $PFA_HKEY_CLASSES_ROOT
        Case "HKEY_CURRENT_CONFIG", "HKCC"
            $hRoot = $PFA_HKEY_CURRENT_CONFIG
        Case Else
            Return SetError(1, 0, 0)
    EndSwitch

    Local $szSubkey = StringTrimLeft($szKey, StringInStr($szKey, "\"))

    Local $ret = DllCall("advapi32.dll", "long", "RegOpenKeyExW", "ulong_ptr", $hRoot, "wstr", $szSubkey, "dword", 0, "dword", $PFA_KEY_QUERY_VALUE, "ulong_ptr*", 0)
    If $ret[0] <> 0 Then Return SetError(2, $ret[0], 0)
    Local $hKey = $ret[5]
    $ret = DllCall("advapi32.dll", "long", "RegQueryValueExW", "ulong_ptr", $hKey, "wstr", $szValue, "ptr", 0, _
									"dword*", 0, "ptr", 0, "dword*", 0)
	If $ret[0] <> 0 Then
		DllCall("advapi32.dll", "long", "RegCloseKey", "ulong_ptr", $hKey)
		Return SetError(3, $ret[0], 0)
	EndIf

	Local $iType = $ret[4], $iLen = $ret[6], $sType
	Switch $iType ; set type of value
		Case $REG_SZ, $REG_EXPAND_SZ, $REG_MULTI_SZ
			$sType = "wchar"
			; iLen is byte length, if unicode string divide by 2
			; add 2 terminating nulls for possibly incorrectly stored strings
			$iLen = ($iLen / 2) + 2
		Case $REG_BINARY, $REG_NONE
			$sType = "byte"
		Case $PFA_REG_QWORD
			$sType = "int64"
			$iLen = $iLen / 8 ; int64 = 8 bytes
		Case Else
			$sType = "int"
			$iLen = $iLen / 4 ; int = 4 bytes
	EndSwitch
    Local $lpData = DllStructCreate($sType & "[" & $iLen & "]")
    $ret = DllCall("advapi32.dll", "long", "RegQueryValueExW", "ulong_ptr", $hKey, "wstr", $szValue, "ptr", 0, _
                                    "dword*", 0, "ptr", DllStructGetPtr($lpData), "dword*", DllStructGetSize($lpData))
    DllCall("advapi32.dll", "long", "RegCloseKey", "ulong_ptr", $hKey)

    If $ret[0] <> 0 Then Return SetError(3, $ret[0], 0)
    Return SetError(0, $iType, DllStructGetData($lpData, 1))
EndFunc

Func _TypeToString($iType)
	Local $sType
	Switch $iType
		Case $REG_NONE
			$sType = "REG_NONE"
		Case $REG_SZ
			$sType = "REG_SZ"
		Case $REG_EXPAND_SZ
			$sType = "REG_EXPAND_SZ"
		Case $REG_BINARY
			$sType = "REG_BINARY"
		Case $REG_DWORD
			$sType = "REG_DWORD"
		Case $REG_DWORD_BIG_ENDIAN
			$sType = "REG_DWORD_BIG_ENDIAN"
		Case $REG_LINK
			$sType = "REG_LINK"
		Case $REG_MULTI_SZ
			$sType = "REG_MULTI_SZ"
		Case $REG_RESOURCE_LIST
			$sType = "REG_RESOURCE_LIST"
		Case $REG_FULL_RESOURCE_DESCRIPTOR
			$sType = "REG_FULL_RESOURCE_DESCRIPTOR"
		Case $REG_RESOURCE_REQUIREMENTS_LIST
			$sType = "REG_RESOURCE_REQUIREMENTS_LIST"
		Case $PFA_REG_QWORD
			$sType = "REG_QWORD"
		Case Else
			$sType = ""
	EndSwitch
	Return $sType
EndFunc

;~ ;; EXAMPLE
;~ ; just create a key
;~ _RegWrite("HKCU\Software\AAB Test")
;~ ; sets the default value
;~ _RegWrite("HKCU\Software\AAA Test", "", $REG_SZ, "default value")
;~ $read = _RegRead("HKCU\Software\AAA Test", "")
;~ ConsoleWrite("Type:  " & _TypeToString(@extended) & @CRLF)
;~ ConsoleWrite("Data:  " & $read & @CRLF)
;~ ; writes an empty reg_none value
;~ _RegWrite("HKCU\Software\AAA Test", "value1", $REG_NONE, "")
;~ $read = _RegRead("HKCU\Software\AAA Test", "value1")
;~ ConsoleWrite("Type:  " & _TypeToString(@extended) & @CRLF)
;~ ConsoleWrite("Data:  " & $read & @CRLF)
;~ ; writes some string data as binary
;~ _RegWrite("HKCU\Software\AAA Test", "value2", $REG_BINARY, "test data")
;~ $read = _RegRead("HKCU\Software\AAA Test", "value2")
;~ ConsoleWrite("Type:  " & _TypeToString(@extended) & @CRLF)
;~ ConsoleWrite("Data:  " & $read & @CRLF)
;~ ; writes some binary data
;~ _RegWrite("HKCU\Software\AAA Test", "value3", $REG_BINARY, Binary("0x02000000"))
;~ $read = _RegRead("HKCU\Software\AAA Test", "value3")
;~ ConsoleWrite("Type:  " & _TypeToString(@extended) & @CRLF)
;~ ConsoleWrite("Data:  " & $read & @CRLF)
;~ ; write a string
;~ _RegWrite("HKCU\Software\AAA Test", "value4", $REG_SZ, "here is a string")
;~ $read = _RegRead("HKCU\Software\AAA Test", "value4")
;~ ConsoleWrite("Type:  " & _TypeToString(@extended) & @CRLF)
;~ ConsoleWrite("Data:  " & $read & @CRLF)
;~ ; write an integer
;~ _RegWrite("HKCU\Software\AAA Test", "value5", $REG_DWORD, 123456)
;~ $read = _RegRead("HKCU\Software\AAA Test", "value5")
;~ ConsoleWrite("Type:  " & _TypeToString(@extended) & @CRLF)
;~ ConsoleWrite("Data:  " & $read & @CRLF)
