SEStatus PROC STDCALL nType:DWORD

	; nType -1 resets error
	; nType 0 returns number of last error
	; nType 1 returns text of last error
	PUSH EDX
	PUSH ECX
	
	MOV EDX, nType
	MOV ECX, [EDX]
	.if ECX == -1
		MOV errNum, 0
		MOV EAX, 0
		
	.elseif ECX == 0
		MOV EAX, errNum
		
	.elseif ECX == 1
		MOV ECX, errNum
		MOV EDX, ErrorMessages[ECX*4] 
		MOV EAX, rv(szLen, EDX) 
		
	.endif
	POP ECX
	POP EDX
	
	RET

SEStatus endp

Set_Error PROC STDCALL nLevel:DWORD
	
	MOV EAX, nLevel
;	MOV errNum, EAX
;	NEG EAX ;because errors have to be negative
	RET

Set_Error endp

Log_Error PROC STDCALL uses EDI ESI sFacility:DWORD, nSlot:DWORD, nError:DWORD, nOffset:DWORD
	; Build record as text representations of the parameters separated by caret
	; StackCount points to available slot
	; Store pointer to allocated text in slot
	; increment StackPtr (allocate space for about 32 (?)
	LOCAL dNew:DWORD
	
	PUSH ECX
	PUSH EDX
	
;	PrintText "Log_Error alloc 64"
	MOV dNew, alloc(64) ;rv(SysAllocStringByteLen, 0, 64)
	MOV byte ptr [EAX], 0
	
	MOV EDX, nError
	MOV EDI, ErrorMessages[EDX*4]

	MOV dNew, cat$( dNew, sFacility, "^", sstr$(nSlot), "^-", sstr$(nError), "^", sstr$(nOffset), "^", EDI )
;	PrintStringByAddr dNew
	
	MOV ECX, EStackCount
	MOV EDX, EStack
	SHL ECX, 2
	ADD EDX, ECX
	MOV dword ptr [EDX], EAX

	MOV ECX, EStackCount
	INC ECX
	MOV EStackCount, ECX
	POP EDX
	POP ECX

	MOV EAX, nError
	MOV errNum, EAX
	;NEG EAX
;	PrintText "Log_Error but not freed!!"
	Ret
Log_Error EndP


SEPop PROC STDCALL uses EDI ESI
	;allocates new string
	;copies top element of stack to new string
	;releases top element's storage
	;decrements EStackPtr, but not below zero
	LOCAL dNew:DWORD
	LOCAL dPtr:DWORD

	MOV ECX, EStackCount
	DEC ECX
	.if ECX > 0 && ECX < STACK_SIZE + 1
		MOV ESI, EStack
		SHL ECX, 2
		ADD ESI, ECX
		
		MOV EDX, dword ptr [ESI]
		
		MOV dPtr, EDX
		MOV ECX, len(EDX)
		PUSH ECX
;		PrintDec ECX, "SEPop SysAllocStringByteLen"
		MOV dNew, rv(SysAllocStringByteLen, 0, ECX)
		POP ECX
		fn MemCopy, dPtr, dNew, ECX
		MOV EDX, dPtr
;		PrintText "SEPop freeing alloc done in Log_Error"
		free( EDX )
		MOV EAX, EStackCount
		.if EAX > 1
			DEC EStackCount
		.endif
	.else
		MOV ECX, len(ADDR EEmptyStack)
		PUSH ECX
;		PrintDec ECX, "SEPop SysAllocStringByteLen"
		MOV dNew, rv(SysAllocStringByteLen, 0, ECX)

		POP ECX
		fn MemCopy, ADDR EEmptyStack, dNew, ECX

	.endif
	MOV EAX, dNew ;returns to caller as a string which the DLL mechanism munges into UTF16
	Ret
SEPop EndP 

SEEmptyStack PROC STDCALL uses EDI ESI
	;works back through stack until stackptr = zero releasing storage
	PUSH ECX
	PUSH EDX
	
	MOV ECX, EStackCount
	DEC ECX ;point to last occupied one
	; if StackCount = 7 then there are 6 slots used
	.while ECX > 0
		PUSH ECX
		MOV ESI, EStack
		MOV EAX, ECX
		SHL EAX, 2
		ADD ESI, EAX ;ESI now points at StackCount's offset in Stack
		MOV EDX, dword ptr [ESI] ;EDX now contains address of alloc'd space
;		PrintText "SEEmptyStack releasing a Log_Error alloc"
		free( EDX )
		POP ECX
		DEC ECX
	.endw
	
	MOV EStackCount, 1 ;we ignore position zero
	
	POP EDX
	POP ECX
	
	MOV EAX, 0
	Ret
SEEmptyStack EndP

SECountStack PROC STDCALL uses EDI ESI
	MOV EAX, EStackCount
	DEC EAX
	Ret
SECountStack EndP

