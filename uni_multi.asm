SEUnicodeFileUU PROC STDCALL sEncoding:DWORD, sFilename:DWORD, bBOM:DWORD
	
	PrintText "SEWriteUnicodeFileUU"
	PrintHex sEncoding
	PrintHex sFilename
	PrintHex bBOM
	DbgDump sEncoding, 32
	DbgDump sFilename, 32
	DbgDump bBOM, 32
	; sEncoding and sFilename are both in Unicode, so nothing else to do but pass the parameters
	MOV ECX, rv(SysStringLen,sEncoding)
	PrintDec ECX
	MOV ECX, rv(SysStringLen,sFilename)
	PrintDec ECX
	
	invoke SEWriteUnicodeFile,sEncoding,sFilename,bBOM		
	ret

SEUnicodeFileUU endp

SEUnicodeFileUA PROC STDCALL sEncoding:DWORD, sFilename:DWORD, bBOM:DWORD
	
	LOCAL wpszFilename:DWORD
	LOCAL lpWideCharStr[128]:BYTE
	
	PrintText "SEWriteUnicodeFileUA"
	PrintHex sEncoding
	PrintHex sFilename
	PrintHex bBOM
	
	DbgDump sEncoding, 32
	DbgDump sFilename, 32
	DbgDump bBOM, 32
	
	;convert sFilename to unicode before passing on
	invoke MultiByteToWideChar,CP_ACP,MB_PRECOMPOSED,sFilename,-1,lpWideCharStr,sizeof lpWideCharStr
	;DbgDump offset lpWideCharStr, 10
	MOV wpszFilename, rv(SysAllocString,lpWideCharStr)
	invoke SEWriteUnicodeFile,sEncoding, wpszFilename,bBOM
	invoke SysFreeString, wpszFilename
	PrintLine
	ret

SEUnicodeFileUA endp
SEWriteUnicodeFileAU PROC STDCALL sEncoding:DWORD, sFilename:DWORD, bBOM:DWORD
	
	;convert sEncoding to unicode before passing on
	ret

SEWriteUnicodeFileAU endp
SEWriteUnicodeFileAA PROC STDCALL sEncoding:DWORD, sFilename:DWORD, bBOM:DWORD

	;convert sEncoding and sFilename to unicode before passing on
	ret
	
SEWriteUnicodeFileAA endp
SEWriteMultibyteFileUU PROC STDCALL sEncoding:DWORD, sFilename:DWORD
	
	
	ret

SEWriteMultibyteFileUU endp
SEWriteMultibyteFileUA PROC STDCALL sEncoding:DWORD, sFilename:DWORD
	
	
	ret

SEWriteMultibyteFileUA endp
SEWriteMultibyteFileAU PROC STDCALL sEncoding:DWORD, sFilename:DWORD
	
	
	ret

SEWriteMultibyteFileAU endp
SEWriteMultibyteFileAA PROC STDCALL sEncoding:DWORD, sFilename:DWORD


	ret
	
SEWriteMultibyteFileAA endp
SEWriteMultibyteFile PROC STDCALL uses EDI ESI EBX sEncoding:DWORD, sFilename:DWORD
	
	
	ret

SEWriteMultibyteFile endp
SEWriteUnicodeFile PROC STDCALL uses EDI ESI EBX sEncoding:DWORD, sFilename:DWORD, bIncludeBOM:DWORD
	
	;make sure current slot is active and occupied
	;encode current slot into slot zero using sEncoding
	;write slot zero to sFilename, including BOM if bIncludeBOM is true
		
	LOCAL sEnc:DWORD
	LOCAL sFile:DWORD
	LOCAL bBOM:DWORD
	
	PrintText "SEWriteUnicodeFile"
	PrintHex sEncoding
	PrintHex sFilename
	PrintHex bIncludeBOM
	
	DbgDump sEncoding, 32
	DbgDump sFilename, 32
	DbgDump bBOM, 32

	PUSH ECX
	PUSH EDX
	
	MOV EDX, sEncoding
	MOV EAX, [EDX]
	MOV sEnc, EAX
		
	MOV EDX, sFilename
	MOV EAX, [EDX]
	MOV sFile, EAX

	MOV ECX, rv(SysStringByteLen, sEncoding)
	PrintDec ECX
	;DbgDump sEncoding,ECX
	
	MOV ECX, rv(SysStringByteLen,sFilename)
	PrintDec ECX
	;DbgDump sFilename, ECX
	
	;PrintHex sFile
	;PrintStringByAddr sFile
	PrintLine
	
	;MOV EDX, bIncludeBOM
	;MOV EAX, [EDX]
	;MOV bBOM, EAX
	
	;PrintHex bBOM
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;make sure slot is instantiated
	MOV EAX, Slots[ESI].instantiated
	.if EAX == 0 
		fn Log_Error, "SEWriteUnicodeFile", EDI, E_COMPARE_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F ;jump over occupation test
	.endif
	
	;make sure slot is occupied
	MOV EAX, Slots[ESI].occupied
	.if EAX == 0
		fn Log_Error, "SEWriteUnicodeFile", EDI, E_COMPARE_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		jmp @F
	.endif
	
	;make sure there's something in slot zero to hold stuff
	fn Instantiate, 0d

		
	;MOV EAX, rv(IsEncoding,sEncoding)
	PrintLine
	jmp @F
	
	
	
	fn szLen, sFile
	.if EAX == 0d
		fn Log_Error, "SEWriteUnicodeFile", EDI, E_WRITEFILE_NO_FILENAME, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

;	.if rv(ErrorCode) != 0
;		fn Log_Error, "SEWriteUnicodeFile", EDI, E_WRITEUNICODEFILE_CONVERSION_ERROR, -1
;		fn Set_Error, E_ERROR_LOGGED
;		jmp @F
;	.endif

	;fn ConvertToUnicode,sEncoding,ESI
	
@@:
	POP EDX
	POP ECX
	ret

SEWriteUnicodeFile endp

