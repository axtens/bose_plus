; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

      .686p                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive 

;     include files
;     ~~~~~~~~~~~~~
      include \masm32\include\windows.INC
      include \masm32\include\masm32.INC
      include \masm32\include\gdi32.INC
      include \masm32\include\user32.INC
      include \masm32\include\kernel32.INC
      include \masm32\include\Comctl32.INC
      include \masm32\include\comdlg32.INC
      include \masm32\include\shell32.INC
      include \masm32\include\ole32.inc
      include \masm32\include\oleaut32.INC
      include \masm32\include\dialogs.INC
      include \masm32\com\include\oaidl.inc
	  include \masm32\com\include\shlobj.inc

      include \masm32\macros\macros.asm     ; the macro file
IFDEF DEBUG
	  include \masm32\include\debug.INC
ENDIF	  

;     libraries
;     ~~~~~~~~~
      includelib \masm32\lib\masm32.lib
      includelib \masm32\lib\gdi32.lib
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \masm32\lib\Comctl32.lib
      includelib \masm32\lib\comdlg32.lib
      includelib \masm32\lib\shell32.lib
      includelib \masm32\lib\oleaut32.lib
      includelib \masm32\lib\ole32.lib
IFDEF DEBUG      
      includelib \masm32\lib\debug.lib
ENDIF

	include prototypes.inc

	include bose_plus.INC								

    .code
	align 8
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

LibMain proc uses EDI ESI instance:DWORD,reason:DWORD,unused:DWORD 
	LOCAL dSlot:Slot
	
    .if reason == DLL_PROCESS_ATTACH
      	PUSH instance
      	POP hInstance
;      	PrintLine
      	MOV EDI, SLOT_COUNT
      	MOV ECX, 0
      	.while EDI > 0
      		PUSH ECX
      		MOV ESI, rv(IntMul, ECX, SIZEOF Slot)
      		MOV Slots[ESI].instantiated, 0
      		MOV Slots[ESI].slotbase, 0
      		MOV Slots[ESI].textbase, 0
      		MOV Slots[ESI].slotlength, 0
      		MOV Slots[ESI].textlength, 0
      		MOV Slots[ESI].occupied, 0
			DEC EDI
			POP ECX
			INC ECX
      	.endw
      	MOV ECX, 64*4
;      	PrintDec ECX, "LibMain SysAllocStringByteLen"
      	MOV EStack, rv(SysAllocStringByteLen, 0, ECX)
      	
      	
;      	fn Log_Error, "LibMain",0, 0, 1
;      	fn Log_Error, "LibMain",0, 1, 1
;      	fn Log_Error, "LibMain",1, 0, 1
		
		invoke CoInitializeEx,0,0
		MOV hResult, rv(CoCreateInstance,ADDR CLSID_Converters,NULL,CLSCTX_INPROC_SERVER,ADDR IID_IConverters,ADDR pIConverters)
		;PrintHex pIConverters
		;PrintHex hResult
		.if hResult != 0
			MOV EAX,FALSE
		.else
			MOV EAX, TRUE
		.endif
      	
    .elseif reason == DLL_PROCESS_DETACH
		MOV ECX, SLOT_COUNT
		.repeat
			PUSH ECX
			MOV ESI, rv(IntMul, ECX, SIZEOF Slot)
;			PrintText "LibMain freeing string"
			fn SysFreeString,Slots[ESI].slotbase
    		POP ECX
    		DEC ECX
		.until ECX == 0
;		PrintText "Libmain freeing slot zero string"
		fn SysFreeString, Slots[0].slotbase
		fn SEEmptyStack
;		PrintText "Libmain freeing EStack"
		;PrintLine
		fn SysFreeString, EStack
		PrintText "after SysFreeString"
		;invoke IDispRelease,ADDR pIConverters
		;PrintDec eax
		;PrintText "After IDispRelease"
		invoke CoUninitialize      	
		PrintText "After CoUninitialize"
		
    .elseif reason == DLL_THREAD_ATTACH

    .elseif reason == DLL_THREAD_DETACH

    .endif

    RET

LibMain endp

include com_procs.asm
include slot_mgt.asm
include error_mgt.asm
include uni_multi.asm

SEMessage PROC STDCALL pBuffer:DWORD
	
	LOCAL Source:DWORD
	PUSH ECX
	PUSH EDX
	MOV ECX, errNum
	MOV EDX, ErrorMessages[ECX*4]
	MOV Source, EDX
	MOV ECX, len(EDX)
	fn MemCopy, Source, pBuffer, ECX 
	MOV EAX, 0
	POP EDX
	POP ECX  
	RET

SEMessage endp
SEMessage2 PROC STDCALL uses ESI EBX
 
 	PUSH ECX
 	PUSH EDX
 	
 	MOV ESI, errNum
 	;PrintDec ESI, "errNum"
 	MOV EBX, ErrorMessages[ESI*4]
 	;PrintHex EBX, "ErrorMessages @ errNum"
 	
 	PUSH EBX
 	MOV ECX, rv(szLen,EBX)
 	;PrintDec ECX, "length of ErrorMessage"
 	POP EBX
 	
 	PUSH ECX
; 	PrintDec ECX, "SEMessage2 SysAllocStringByteLen"
	MOV EDX, rv(SysAllocStringByteLen, 0h, ECX)
	;PrintHex EDX, "Allocation"
	POP ECX
	
	PUSH EDX
	PUSH ECX
	PUSH EBX
	fn MemCopy, EBX, EDX, ECX
	POP EBX
	POP ECX
	POP EDX
	
	;DumpMem EBX, ECX, "memory dump"
	
	MOV EAX, EDX
	;PrintHex EAX, "allocation"
	
	POP EDX
	POP ECX
	
	RET 

SEMessage2 endp
SEStore PROC STDCALL uses EDI ESI sText:DWORD
	LOCAL nStringLength:DWORD
		
	;1. 	make sure that the currentSlot is instantiated
	;2. 	make sure that there is room in the slot for the string
	;2.1 	if there not enough room, release the storage it has
	;			then keep doubling the size of a standard allocation until it
	;			is greater than the size of the incoming string.
	;			with that figure, allocate and update the slot
	;2.2	find the middle of the slot, and subtract from that address
	;			the length of the incoming string divided by 2: that's the address
	;			to copy the incoming string to
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
 
	MOV EAX, Slots[ESI].instantiated
	.if (EAX == 0)
		fn Instantiate, currentSlot
	.endif
	
	;calculate length of sText. Length returned in EAX.
	MOV nStringLength, rv(SysStringByteLen, sText)
	MOV ECX, EAX
	.if ECX == 0
		fn Log_Error, "SEStore", EDI, E_STORE_NULL, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	;compare against slotlength
	MOV EAX, Slots[ESI].slotlength
	
	.if ECX > EAX ;if length of text greater than space available
;******
;		MOV EDX, slotSize
;		.while EDX < ECX ;keep doubling slotSize
;			SHL EDX, 1
;		.endw
		; how about ECX*2
		MOV EDX, ECX
;		SHL EDX, 1
		ADD EDX, BUFFER_INCREMENT
		
		MOV Slots[ESI].slotlength, EDX
		PUSH EDX ;save new count ahead of free
		MOV EDX, Slots[ESI].slotbase
;		PrintText "SEStore Freeing string" 
		fn SysFreeString, EDX
		POP EDX ;recover count
;		PrintDec EDX, "SEStore SysAllocStringByteLen"
		fn SysAllocStringByteLen,0,EDX
		MOV Slots[ESI].slotbase, EAX
	.endif
	
	;find middle of slot. take slotlength, divide by 2, ADD to address of slotbase
	MOV ECX, Slots[ESI].slotlength
	
	SHR ECX, 1
	MOV EDX, Slots[ESI].slotbase
	
	ADD EDX, ECX
	
	;EDX now points to middle of slot.
	;from that point subtract the length of the incoming string divided by two
	MOV ECX, nStringLength
	SHR ECX, 1
	SUB EDX, ECX
	
	PUSH EDX
	;now copy the text to EDX 
	fn MemCopy, sText, EDX, nStringLength
	POP EDX
	
	;update dSlot and then copy it back into the Slots list
	MOV Slots[ESI].textbase, EDX
	m2m Slots[ESI].textlength, nStringLength
	MOV Slots[ESI].occupied, 1
	
	fn Set_Error, E_NO_ERROR
@@:
	POP	EDX
	POP ECX
	
	RET

SEStore endp
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

SELength PROC STDCALL uses EDI ESI 
	
	; 	if currentSlot is not instantiated, return -1
	;	copy Slots at current slot to temp slot
	;	if temp slot is not occupied, return -1
	;	return temp slot's textlength

	PUSH ECX
	
	MOV EDI, currentSlot
	
	.if (EDI > 0)
		.if (EDI < SLOT_COUNT + 1)
			MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
			MOV ECX, Slots[ESI].instantiated
			.if ECX == 1
				MOV ECX, Slots[ESI].occupied
				.if ECX == 1
					MOV EAX, Slots[ESI].textlength
				.else
					fn Log_Error, "SELength", EDI, E_SLOT_NOT_OCCUPIED, -1
					fn Set_Error, E_ERROR_LOGGED
				.endif
			.else
				fn Log_Error, "SELength", EDI, E_SLOT_NOT_INSTANTIATED, -1 
				fn Set_Error, E_ERROR_LOGGED
			.endif
		.endif
	.endif
	POP ECX
	RET ;return length rather than 0 or -1
SELength endp

SELengthOf PROC STDCALL uses EDI ESI nSlot:DWORD
	LOCAL dSlot:Slot
	
	; 	if currentSlot is not instantiated, return -1
	;	copy Slots at current slot to temp slot
	;	if temp slot is not occupied, return -1
	;	return temp slot's textlength

	PUSH ECX
	PUSH EDX
	
	MOV EDX, nSlot
	MOV EDI, [EDX]
	.if (EDI > 0)
		.if (EDI < SLOT_COUNT + 1)
			MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
			MOV ECX, Slots[ESI].instantiated
			.if ECX == 1
				MOV ECX, Slots[ESI].occupied
				.if ECX == 1
					MOV EAX, Slots[ESI].textlength
				.else
					fn Log_Error, "SELengthOf", EDI, E_SLOT_NOT_OCCUPIED, -1
					fn Set_Error, E_ERROR_LOGGED
				.endif
			.else
				fn Log_Error, "SELengthOf", EDI, E_SLOT_NOT_INSTANTIATED, -1
				fn Set_Error, E_ERROR_LOGGED
			.endif
		.endif
	.endif
	
	POP EDX
	POP ECX
	RET
SELengthOf endp

SEPrependFrom PROC STDCALL uses EDI ESI nSlot:DWORD
	LOCAL dFrom:DWORD
	LOCAL dResult:DWORD
	
	PUSH ECX
	PUSH EDX
	
	MOV EDX, nSlot
	MOV EAX, [EDX]
	
	.if EAX < 0d && EAX > SLOT_COUNT
		fn Log_Error, "SEPrependFrom", EAX, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ESI, rv(IntMul, EAX, SIZEOF Slot)
	MOV dFrom, rv(SysAllocStringByteLen, 0d, Slots[ESI].textlength)
	fn MemCopy, Slots[ESI].textbase, dFrom, Slots[ESI].textlength
	MOV dResult, rv(SEPrepend, dFrom)
	fn SysFreeString, dFrom
	MOV EAX, dResult
	
@@:	
	POP EDX
	POP ECX
	
	Ret
SEPrependFrom EndP
SEPrepend PROC STDCALL uses EDI ESI sText:DWORD
	LOCAL dSlot:Slot
	LOCAL dMiddleNew:DWORD
	LOCAL dLen:DWORD
	
	;	make sure that the currentSlot is instantiated
	;	copy Slots at currentSlot to tempSlot
	;	if tempSlot is not occupied already
	;		call SEStore with sText
	;	else 
	;		if there's room between slotbase and textbase (in tempSlot)
	;			insert prepending text before textbase
	;			update textbase and textlength
	;		else 
	;			allocate space that is nearest multiple of slotSize > length of occupying string and prepending string
	;			find middle of space
	;			subtract from it half of occupying text length and half of prepending text length
	;			copy prepending text there followed by occupying text
	;			release tempSlot's memory allocation
	;			copy address of space into tempSlot's pointer
	;			update pointers
	;		endif
	;	endif
	;	copy tempSlot to Slots at currentSlot
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;MOV EAX, E_ERROR_LOGGED
	;fn Set_Error, E_ERROR_LOGGED
	;fn Log_Error, EDI, E_INVALID_SLOT, -1
	
	MOV ECX, Slots[ESI].instantiated
	.if ECX != 1
		fn Instantiate, currentSlot
		fn SEStore, sText
		JMP @F ;keep SEStore's error code alive
	.endif
	
	;get length of incoming string
	MOV ECX, rv(SysStringByteLen, sText)
	.if ECX == 0
		fn Log_Error, "SEPrepend", EDI, E_STORE_NULL, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	MOV dLen, ECX
	.if rv(WillFitAtBase, dLen) == 0
		;registers:
		;	EAX = current slot's slotbase
		;	EBX = undefined
		;	ECX = length of incoming string
		;	EDX = space below textbase
		;	EDI = number of current slot
		;	ESI = offset into slots list
		
		; initialise dSlot 
		MOV dSlot.instantiated, 1
		MOV dSlot.occupied, 1
			
		; ADD length of incoming string to length of existing string
		MOV ECX, dLen
		ADD ECX, Slots[ESI].textlength
		
		; save this new length in dSlot
		MOV dSlot.textlength, ECX
		
		; find out what multiple of slotSize will contain this amount of string
;*****
;		MOV EAX, slotSize
;		.while EAX < ECX
;			SHL EAX, 1
;		.endw
;		
		MOV EAX, ECX
;		SHL EAX, 1
		ADD EAX, BUFFER_INCREMENT
		
		; save new total length
		PUSH ECX
		
		; save new slot size
		PUSH EAX
		
		; save new slot size in dSlot's slotlength
		MOV dSlot.slotlength, EAX
		
		; allocate this much space and save pointer in dSlot
;		PrintDec EAX, "SEPrepend SysAllocStringByteLen"
		MOV EDX, rv(SysAllocStringByteLen, 0h, EAX)
		MOV dSlot.slotbase, EDX
		
		; find middle of allocation, by halving its length and 
		; 	adding that to the base address
		
		; recover new slot size
		POP EAX
		; divide by two
		SHR EAX, 1
		; ADD to slotbase, which is in EDX
		ADD EDX, EAX
		; save address of middle
		MOV dMiddleNew, EDX
		
		; find place of first insertion:
		;	divide new total length by two, subtract this figure from slot middle
		
		; recover new total length and divide by 2
		POP ECX
		SHR ECX, 1
		
		; subtract from address of middle
		SUB EDX, ECX 
		
		; store this offset into dSlot's textbase
		MOV dSlot.textbase, EDX
		
		; copy memory from sText for dLen bytes to EDX
		
		; save EDX as MemCopy will likely change it
		PUSH EDX
		fn MemCopy, sText, dSlot.textbase, dLen
		
		; recover EDX
		POP EDX
		
		; ADD dLen to EDX to get next insertion point
		ADD EDX, dLen
		
		; insert from Slots
		fn MemCopy, Slots[ESI].textbase, EDX, Slots[ESI].textlength
		
		; release old slot
;		PrintText "SEPrepend releasing string (old slot)"
		fn SysFreeString, Slots[ESI].slotbase
		
		; copy memory from dSlot to current slot
		fn MemCopy, ADDR dSlot, ADDR Slots[ESI], SIZEOF Slot
		
		; set error flag and move on
		fn Set_Error, E_NO_ERROR
	.else
		; modify Slot
		MOV EDX, Slots[ESI].textbase
		SUB EDX, dLen
		MOV Slots[ESI].textbase, EDX
		MOV EAX, Slots[ESI].textlength
		ADD EAX, dLen
		MOV Slots[ESI].textlength, EAX
		MOV Slots[ESI].occupied, 1
		
		;copy sText to new textbase for ECX bytes
		fn MemCopy, sText, Slots[ESI].textbase, dLen
		
		;update textbase and textlength
		fn Set_Error, E_NO_ERROR 
	.endif
@@:
	PUSH EAX
	fn Verify
	POP EAX
	
	POP EDX
	POP ECX
	RET

SEPrepend endp

SEAppendFrom PROC STDCALL uses EDI ESI nSlot:DWORD
	LOCAL dFrom:DWORD
	LOCAL dResult:DWORD
	
	PUSH ECX
	PUSH EDX
	
	MOV EDX, nSlot
	MOV EAX, [EDX]
	
	.if EAX < 0d && EAX > SLOT_COUNT
		fn Log_Error, "SEAppendFrom", EAX, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ESI, rv(IntMul, EAX, SIZEOF Slot)
	MOV dFrom, rv(SysAllocStringByteLen, 0d, Slots[ESI].textlength)
	fn MemCopy, Slots[ESI].textbase, dFrom, Slots[ESI].textlength
	MOV dResult, rv(SEAppend, dFrom)
	fn SysFreeString, dFrom
	MOV EAX, dResult
	
@@:	
	POP EDX
	POP ECX
	
	Ret
SEAppendFrom EndP

SEAppend PROC STDCALL uses EDI ESI sText:DWORD
	LOCAL dNewSpace:DWORD
	LOCAL dSlot:Slot
	LOCAL dMiddleNew:DWORD
	LOCAL dLen:DWORD
	
	;	make sure that the currentSlot is instantiated
	;	copy Slots at currentSlot to tempSlot
	;	if tempSlot is not occupied already
	;		call SEStore with sText
	;	else 
	;		if there's room between textbase+textlength and slotbase+slotlength (in tempSlot)
	;			insert appending text after textbase+textlength
	;			update textlength
	;		else (ie. no room)
	;			allocate new space that is nearest multiple of slotSize > length of occupying string and prepending string
	;			find middle of space
	;			subtract from it half of occupying text length and half of prepending text length
	;			copy occupying text there followed by appending text
	;			release tempSlot's memory allocation
	;			copy address of space into tempSlot's pointer
	;		endif
	;	endif
	;	copy tempSlot to Slots at currentSlot
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	MOV ECX, Slots[ESI].instantiated
	.if ECX != 1
		fn Instantiate, currentSlot
		fn SEStore, sText
		JMP @F ;keep SEStore's return code alive
	.endif
	
	;get length of incoming string
	MOV ECX, rv(SysStringByteLen, sText)
	.if ECX == 0
		fn Log_Error, "SEAppend", EDI, E_STORE_NULL, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	MOV dLen, ECX
	
	.if rv(WillFitAtTop, dLen) == 0
		;registers:
		;	EAX = address of slotbase + slotlength
		;	EBX = undefined
		;	ECX = length of incoming string
		;	EDX = address after textbase + textlength + new string length
		;	EDI = number of current slot
		;	ESI = offset into slots list
		
		; initialise dSlot 
		MOV dSlot.instantiated, 1
		MOV dSlot.occupied, 1
			
		; ADD length of incoming string to length of existing string
		ADD ECX, Slots[ESI].textlength
		
		; save this new length in dSlot
		MOV dSlot.textlength, ECX
		
		; find out what multiple of slotSize will contain this amount of string
;*****
;		MOV EAX, slotSize
;		.while EAX < ECX
;			SHL EAX, 1
;		.endw
		MOV EAX, ECX
;		SHL EAX, 1
		ADD EAX, BUFFER_INCREMENT
		
		; save new total length
		PUSH ECX
		
		; save new slot size
		PUSH EAX
		
		; save new slot size in dSlot's slotlength
		MOV dSlot.slotlength, EAX
		
		; allocate this much space and save pointer in dSlot
;		PrintDec EAX, "SEAppend SysAllocStringByteLen"
		MOV EDX, rv(SysAllocStringByteLen, 0h, EAX)
		MOV dSlot.slotbase, EDX
		
		; find middle of allocation, by halving its length and 
		; 	adding that to the base address
		
		; recover new slot size
		POP EAX
		; divide by two
		SHR EAX, 1
		; ADD to slotbase, which is in EDX
		ADD EDX, EAX
		; save address of middle
		MOV dMiddleNew, EDX
		
		; find place of first insertion:
		;	divide new total length by two, subtract this figure from slot middle
		
		; recover new total length and divide by 2
		POP ECX
		SHR ECX, 1
		
		; subtract from address of middle
		SUB EDX, ECX 
		
		; store this offset into dSlot's textbase
		MOV dSlot.textbase, EDX
		
		; copy memory from sText for dLen bytes to EDX
		
		; save EDX as MemCopy will likely change it
		PUSH EDX
		
		; copy from Slots for textlength to EDX
		fn MemCopy, Slots[ESI].textbase, EDX, Slots[ESI].textlength
		
		; recover EDX
		POP EDX
		
		; ADD Slots textlength to EDX to get next insertion point
		ADD EDX, Slots[ESI].textlength
		
		; insert from Slots
		fn MemCopy, sText, EDX, dLen
		
		; release old slot
;		PrintText "SEAppend freeing string (old slot)"
		fn SysFreeString, Slots[ESI].slotbase
		
		; copy memory from dSlot to current slot
		fn MemCopy, ADDR dSlot, ADDR Slots[ESI], SIZEOF Slot
		
		; set error flag and move on
		fn Set_Error, E_NO_ERROR
	.else
		;copy sText to new textbase for ECX bytes
		PUSH ECX
		MOV EDX, Slots[ESI].textbase
		ADD EDX, Slots[ESI].textlength
		fn MemCopy, sText, EDX, ECX
		POP ECX
		
		;update textbase and textlength
		MOV EAX, Slots[ESI].textlength
		ADD EAX, ECX
		MOV Slots[ESI].textlength, EAX
		MOV Slots[ESI].occupied, 1
		fn Set_Error, E_NO_ERROR 
	.endif

@@:
	PUSH EAX
	fn Verify
	POP EAX
	
	POP EDX
	POP ECX
	
	RET

SEAppend endp

SEFrame PROC STDCALL uses EDI ESI sText1:DWORD, sText2:DWORD
	LOCAL dSlot:Slot
	
	;	make sure that the currentSlot is instantiated
	;	copy Slots at currentSlot to tempSlot
	;	if tempSlot is not occupied already
	;		call SEStore with sText1
	;		call SEAppend with sText2
	;	else 
	;		call SEPrepend with sText1
	;		call SEAppend with sText2
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	MOV ECX, Slots[ESI].instantiated
	.if ECX != 1
		fn Instantiate, currentSlot
		MOV ECX, rv(SEStore, sText1)
		PUSH ECX
		MOV EDX, rv(SEAppend, sText2)
		POP ECX
		.if (ECX == E_NO_ERROR) && (EDX == E_NO_ERROR)
			fn Set_Error, E_NO_ERROR
		.else
			fn Log_Error, "SEFrame", EDI, E_FRAMING_ERROR, -1
			fn Set_Error, E_ERROR_LOGGED
		.endif
	.else
		MOV ECX, Slots[ESI].occupied
		.if ECX == 0
			MOV ECX, rv(SEStore, sText1)
			PUSH ECX
			MOV EDX, rv(SEAppend, sText2)
			POP ECX
			.if (ECX == E_NO_ERROR) && (EDX == E_NO_ERROR)
				fn Set_Error, E_NO_ERROR
			.else
				fn Log_Error, "SEFrame", EDI, E_FRAMING_ERROR, -1
				fn Set_Error, E_ERROR_LOGGED
			.endif
		.else
			MOV ECX, rv(SEPrepend, sText1)
			PUSH ECX
			MOV EDX, rv(SEAppend, sText2)
			POP ECX
			.if (ECX == E_NO_ERROR) && (EDX == E_NO_ERROR)
				fn Set_Error, E_NO_ERROR
			.else
				fn Log_Error, "SEFrame", EDI, E_FRAMING_ERROR, -1
				fn Set_Error, E_ERROR_LOGGED
			.endif
		.endif
	.endif
	
	POP EDX
	POP ECX
	
	RET

SEFrame endp

SEDelete PROC STDCALL uses EBX EDI ESI nPos:DWORD, nLength:DWORD
	
	;	if the currentSlot is not instantiated, return error
	;	if it is not occupied, return error
	; if nPos > 0 and nPos < textlength
	;	if nLength >= 0 and nLength <= (textlength - nPos )
	;		move memory from textbase+nPos+nLength to textbase+textlength down to textbase+nPos
	;		set textlength to textlength - nLength
	
	LOCAL dLength:DWORD
	LOCAL dPos:DWORD
	
	PUSH ECX
	PUSH EDX
		
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;PrintText "foo"
	
	MOV ECX, Slots[ESI].instantiated
	.if ECX == 0
		fn Log_Error, "SEDelete", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ECX, Slots[ESI].occupied
	.if ECX == 0
		fn Log_Error, "SEDelete", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EDX, nLength
	MOV EAX, [EDX]
	MOV dLength, EAX
	
	MOV EDX, nPos
	MOV EAX, [EDX] ;nPos's value in EAX
	MOV dPos, EAX
	
	; if dPos < 0 then
	;	dPos := 0
	.if EAX < 0
		fn Log_Error, "SEDelete", EDI, E_DELETE_BAD_POSITION, EAX
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
		
	; if dPos == 0
	;	if dLength >= textlength
	;		textlength := 0
	;		mark okay
	;		exit
	;	else
	;		textbase := textbase + dLength
	;		mark okay
	;		exit
	.if EAX == 0
		;PrintText "dPos == 0"
		MOV ECX, dLength
		MOV EDX, Slots[ESI].textlength
		.if ECX >= EDX
			MOV Slots[ESI].textlength, 0
			fn Set_Error, E_NO_ERROR
			JMP @F
		.else
			MOV EDX, Slots[ESI].textbase
			ADD EDX, dLength
			MOV Slots[ESI].textbase, EDX
			fn Set_Error, E_NO_ERROR
			JMP @F
		.endif
	.endif
	
	
	;if textbase + dPos > textbase + textlength
	;	mark bad
	;	exit
	MOV EDX, Slots[ESI].textbase
	MOV ECX, EDX ;both sides will need textbase
	ADD EDX, EAX ;still 'live'
	ADD ECX, Slots[ESI].textlength
	.if EDX > ECX
		;PrintText "textbase + dPos > textbase + textlength"
		fn Log_Error, "SEDelete", EDI, E_DELETE_BAD_POSITION, EDX
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	
	;next special case:
	; if textlength - dPos - dLength <= 0 (or less than 1)
	;	set textlength to dPos
	;	mark okay
	;	exit
	MOV ECX, Slots[ESI].textlength
	SUB ECX, EAX ;still live
	SUB ECX, dLength
	
	TEST ECX, 80000000h
	.if !ZERO? || ECX == 0 
		;PrintText "textlength - dPos - dLength < 1"
		MOV Slots[ESI].textlength, EAX ; EAX still 'live'
		fn Set_Error, E_NO_ERROR
		JMP @F
	.endif
	
	;PrintText "textlength - dPos - dLength >= 1"
	
	;from is textbase + dPos + dLength ; calculate into EAX
	;to is textbase + dPos ; still in EDX
	;for is textlength - dPos - dLength ; still in ECX
	;(EAX still has dPos value)
	ADD EAX, Slots[ESI].textbase
	ADD EAX, dLength
	
	;PrintHex EAX, "from"
	;PrintHex EDX, "to"
	;PrintDec ECX, "for"
	
	PUSH ECX
	PUSH EDX
	fn MemCopy, EAX, EDX, ECX
	POP EDX
	POP ECX
	
	; update details in Slots[ESI]
	MOV EAX, Slots[ESI].textlength
	SUB EAX, dLength
	MOV Slots[ESI].textlength, EAX
	fn Set_Error, E_NO_ERROR 
	
@@:
	POP EDX
	POP ECX
	
	RET

SEDelete endp

SEInsertFrom PROC STDCALL uses EDI nPos:DWORD, nSlot:DWORD
	LOCAL dFrom:DWORD
	LOCAL dResult:DWORD
	
	PUSH ECX
	PUSH EDX
	
	MOV EDX, nSlot
	MOV EAX, [EDX]
	
	.if EAX < 0d && EAX > SLOT_COUNT
		fn Log_Error, "SEAppendFrom", EAX, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	MOV ESI, rv(IntMul, EAX, SIZEOF Slot)
	MOV dFrom, rv(SysAllocStringByteLen, 0d, Slots[ESI].textlength)
	fn MemCopy, Slots[ESI].textbase, dFrom, Slots[ESI].textlength

	MOV dResult, rv(SEInsert, nPos, dFrom) ;pass nPos 'raw'
	fn SysFreeString, dFrom
	MOV EAX, dResult
	
@@:	
	POP EDX
	POP ECX
	

	Ret
SEInsertFrom EndP
SEInsert PROC STDCALL uses EDI ESI nPos:DWORD, sText:DWORD
	
	;	if the currentSlot is not instantiated, instantiate
	;	if it is not occupied, store
	;else
	; if nPos = 0, prepend text
	; if nPos > textlength, append text
	; otherwise
	; allocate new space that is that multiple of slotSize > than combined length of 
	;	text below and text above and inserting text
	; move texts in
	; release original allocation
	; copy new pointer over to existing (use dSlot)
		
	LOCAL dPos:DWORD
	LOCAL dSlot:Slot
	LOCAL dLength:DWORD
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	MOV EAX, Slots[ESI].instantiated
	.if EAX == 0
		fn Log_Error, "SEInsert", EDI, E_SLOT_NOT_INSTANTIATED, -1	
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif	
	
	MOV EAX, Slots[ESI].occupied
	.if EAX == 0
		fn Log_Error, "SEInsert", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EDX, nPos
	MOV EAX, [EDX]
	MOV dPos, EAX
	
	.if EAX == 0
		fn SEPrepend,sText
		JMP @F
	.endif
	
	TEST EAX, 80000000h
	.if ! ZERO? 
		fn Log_Error, "SEInsert", EDI, E_INSERT_BAD_POSITION, EAX
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EDX, Slots[ESI].textlength
	MOV EAX, dPos
	.if EAX >= EDX
		fn SEAppend, sText
		JMP @F
	.endif
	
	;first calculate the size of the final text blob
	MOV ECX, rv(SysStringByteLen, sText)
	MOV dLength, ECX
	ADD ECX, Slots[ESI].textlength
	MOV EAX, slotSize
	
;*****	
;	.while EAX < ECX
;		SHL EAX, 1
;	.endw

	MOV EAX, ECX
;	SHL EAX, 1
	ADD EAX, BUFFER_INCREMENT
		
	MOV dSlot.instantiated, 1
	MOV dSlot.occupied, 1
	MOV dSlot.textlength, ECX
	MOV dSlot.slotlength, EAX
	PUSH EAX
	PUSH ECX
;	PrintDec ECX, "SEInsert SysAllocStringByteLen"
	MOV EDX, rv(SysAllocStringByteLen, 0h, ECX)
	MOV dSlot.slotbase, EDX ;need to keep this handy
	
	POP ECX ;and textlength
	POP EAX ;and slotlength
	
	; find middle of slot
	; subtract textlength / 2
	; giving the place to start putting stuff
	SHR EAX, 1 ; half of slotlength
	ADD EDX, EAX ; EDX now at halfway
		
	SHR ECX, 1 ; half of textlength
	SUB EDX, ECX ; EDX now at insertion point
	MOV dSlot.textbase, EDX
	
	PUSH EDX ;save insertion address
	MOV ECX, dPos
	
	fn MemCopy, Slots[ESI].textbase, EDX, ECX
	
	POP EDX ;still points at insertion point
	ADD EDX, dPos ;assuming pointing at next place to insert

	PUSH EDX
	fn MemCopy, sText, EDX, dLength
	
	POP EDX ;pointing at last place to insert
	ADD EDX, dLength ;now pointing at final insertion place
	
	;now have to copy text from textbase + nPos for textlength - nPos
	MOV ECX, Slots[ESI].textlength
	SUB ECX, dPos
	
	MOV EAX, Slots[ESI].textbase
	ADD EAX, dPos
	
	fn MemCopy, EAX, EDX, ECX
	
	
	MOV EDX, Slots[ESI].slotbase
;	PrintText "SEInsert freeing string (old slot)"
	fn SysFreeString, EDX
	fn MemCopy, ADDR dSlot, ADDR Slots[ESI], SIZEOF Slot
	fn Set_Error, E_NO_ERROR
@@:
	POP EDX
	POP ECX
	RET

SEInsert endp


SECharacterDistribution PROC STDCALL uses EBX EDI ESI

	LOCAL dLen:DWORD
	LOCAL Distrib[257]:DWORD
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	MOV EAX, Slots[ESI].instantiated
	.if EAX == 0
		fn Log_Error, "SECharacterDistribution", EDI, E_SLOT_NOT_INSTANTIATED, -1	
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif	
	
	MOV EAX, Slots[ESI].occupied
	.if EAX == 0
		fn Log_Error, "SECharacterDistribution", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	
	fn memfill, ptr$(Distrib), SIZEOF Distrib, 0d
	
	MOV EDX, Slots[ESI].textbase
	MOV ECX, 0d
	.repeat
		
		;ADD EDX, ECX ;point to next char from textbase
		MOVZX EBX, BYTE PTR [EDX+ECX]
		INC EBX ;fiddle
		
		MOV EDX, ptr$(Distrib)
		SHL EBX, 2
		ADD EDX, EBX
		
		PUSH EDX
		
;		PrintHex EDX
		MOV EAX, ptr$(Distrib)
		ADD EAX, SIZEOF Distrib
;		PrintHex EAX
		
		.if EDX > EAX
			PrintText "overbudget"
			PrintHex EDX
			PrintHex EAX
		.endif
		
		POP EDX
		
		MOV EAX, [EDX]
		INC EAX
		MOV [EDX], EAX
		PrintDec EAX
		INC ECX

	.until ECX == Slots[ESI].textlength
	
	PUSH slotSize
	MOV slotSize, 4096
	fn Instantiate, 0d
	POP slotSize
	
	MOV EAX, Slots[0].slotbase
	MOV Slots[0].textbase, EAX
	MOV Slots[0].occupied, 1
	
	MOV ECX, 1d
	MOV EDX, Slots[0].textbase

;	PrintLine
	.repeat

		PUSH ECX
		PUSH EDX
		MOV EDX, ptr$(Distrib)
		SHL ECX, 2
		ADD EDX, ECX
		
		MOV EAX, DWORD PTR [EDX]

		MOV EBX, sstr$(EAX)
		MOV EAX, len(EBX)
		MOV dLen, EAX
		
		
		POP EDX
		
		PUSH EDX
		fn MemCopy, EBX, EDX, dLen	 
		POP EDX
		
		ADD EDX, dLen
		
		MOV BYTE PTR [EDX], "^"
		INC EDX
		
		POP ECX
		INC ECX
	.until ECX == 257
	MOV EAX, Slots[0].textbase
	SUB EDX, EAX
	MOV Slots[0].textlength, EDX
	MOV EAX, EDX
@@:	
	POP EDX
	POP ECX
	Ret
SECharacterDistribution EndP
SELeft PROC STDCALL uses EDI ESI nLength:DWORD
	
	;	if the currentSlot is not instantiated, return error
	;	if it is not occupied, return error
	;	else copy nLength bytes to slotbase at slot 0
	;		(NOTE: if nLength greater than textlength, make equal to textlength
	;	and thus available for SERecallLMR
	
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	
	;fn Set_Error, E_INVALID_SLOT
	
	MOV ECX, Slots[ESI].instantiated
	.if ECX == 0
		fn Log_Error, "SELeft", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ECX, Slots[ESI].occupied
	.if ECX == 0
		fn Log_Error, "SELeft", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @f
	.endif

	MOV EDX, nLength
	MOV ECX, [EDX]
	.if ECX == 0
		fn Log_Error, "SELeft", EDI, E_STORE_NULL, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EDX, Slots[ESI].textlength
	.if ECX > EDX
		MOV ECX, EDX
	.endif
	
	PUSH ECX
	fn MemCopy, Slots[ESI].textbase, Slots[0].slotbase, ECX
	POP ECX
	MOV Slots[0].occupied, 1
	MOV Slots[0].textlength, ECX 
	MOV EAX, ECX
	
@@:
	POP EDX
	POP ECX
	
	RET

SELeft endp

SERight PROC STDCALL uses EDI ESI nLength:DWORD
	
	;	if the currentSlot is not instantiated, return error
	;	if it is not occupied, return empty array
	;	else copy nLength bytes to slotbase at slot 0
	;		(take textlength, subtract nLength, ADD to textbase: gives start address
	;		(NOTE: if textlength - nLength is less than zero, just take it all from textbase 
	;	and thus available for SERecallLMR
	
	PUSH EDX
	PUSH ECX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;fn Set_Error, E_INVALID_SLOT
	MOV ECX, Slots[ESI].instantiated
	.if ECX == 0
		fn Log_Error, "SERight", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ECX, Slots[ESI].occupied
	.if ECX == 0
		fn Log_Error, "SERight", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @f
	.endif

	; get length
	MOV EDX, nLength  
	MOV ECX, [EDX]
	.if ECX == 0
		fn Log_Error, "SERight", EDI, E_STORE_NULL, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif		
	
	;get length of text in slot
	MOV EAX, Slots[ESI].textlength
	;subtract length required
	SUB EAX, ECX
	;if the result is less than 0, set result to 0
	.if EAX < 0
		MOV EAX, 0
	.endif
	
	;get textbase and ADD the offset
	MOV EDX, Slots[ESI].textbase
	ADD EDX, EAX
	
	;save nLength
	PUSH ECX
	;copy ECX bytes from EDX to slotbase 
	fn MemCopy, EDX, Slots[0].slotbase, ECX

	;recover nLength
	POP ECX			
	;update structure
	MOV Slots[0].occupied, 1
	MOV Slots[0].textlength, ECX
	
	MOV EAX, ECX
@@:
	POP ECX
	POP EDX
	
	RET

SERight endp

SEMid PROC STDCALL uses EDI ESI nPos:DWORD, nLength:DWORD
	
	;	if the currentSlot is not instantiated, return error
	;	if it is not occupied, return error
	;	else copy nLength bytes to slotbase at slot 0 starting from nPos
	;		(take nPos, ADD to textbase: gives start address
	;		(use nLength as number of bytes to copy
	;		(NOTE: nPos must be in range 0 to textlength
	;		(	and nLength in the range of 0 to textlength-nPos
	;		( 	if nPos > textlength, return error
	
	LOCAL dOffset:DWORD
	LOCAL dLength:DWORD
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;fn Set_Error, E_INVALID_SLOT

	MOV ECX, Slots[ESI].instantiated
	.if ECX == 0
		fn Log_Error, "SEMid", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ECX, Slots[ESI].occupied
	.if ECX == 0
		fn Log_Error, "SEMid", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @f
	.endif

	MOV EDX, nPos
	MOV ECX, [EDX]
	MOV EAX, Slots[ESI].textlength
	INC EAX
	.if ECX < EAX ; if nPos < textlength+1. rather than having no INC, and doing a <=
		DEC ECX ; because arrays are zero-based
		MOV dOffset, ECX
		MOV EDX, nLength
		MOV ECX, [EDX]
		.if ECX == 0
			fn Log_Error, "SEMid", EDI, E_STORE_NULL, -1
			fn Set_Error, E_ERROR_LOGGED
			JMP @F
		.endif
		MOV EAX, Slots[ESI].textlength
		SUB EAX, dOffset
		.if ECX > EAX ;nLength > textlength-nPos
			MOV ECX, EAX
		.endif
		MOV dLength, ECX
		MOV EDX, Slots[ESI].textbase
		ADD EDX, dOffset
		fn MemCopy, EDX, Slots[0].slotbase, dLength
		MOV Slots[0].occupied, 1
		m2m Slots[0].textlength, dLength
		MOV EAX, dLength
	.else
		fn Log_Error, "SEMid", EDI, E_MID_BAD_BOUNDS, nPos
		fn Set_Error, E_ERROR_LOGGED
	.endif
@@:
	POP EDX
	POP ECX
	
	RET

SEMid endp
SERecallLMR PROC STDCALL pBuffer:DWORD
	
	; 	if slot 0 not instantiated, return error
	;	if slot 0 not occupied, return error
	;	copy from slotbase for textlength to supplied buffer

	PUSH ECX
	
	MOV ECX, Slots[0].instantiated
	.if ECX == 0
		fn Log_Error, "SERecallLMR", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ECX, Slots[0].occupied
	.if ECX == 0
		fn Log_Error, "SERecallLMR", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	fn MemCopy, Slots[0].slotbase, pBuffer, Slots[0].textlength
	fn Set_Error, E_NO_ERROR
	
@@:
	POP ECX
	RET
	
SERecallLMR endp

SEResetLMR PROC STDCALL 
	
	PUSH EDX
	MOV Slots[0].occupied, 0
	MOV Slots[0].textlength, 0
	MOV EDX, Slots[0].slotbase
	fn Set_Error, E_NO_ERROR
	POP EDX
	RET

SEResetLMR endp

SERecallString PROC STDCALL uses EDI ESI
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	MOV ECX, Slots[ESI].instantiated
	.if ECX == 0
		fn Log_Error, "SERecallString", EDI, E_SLOT_NOT_INSTANTIATED, -1
		;fn Set_Error, E_ERROR_LOGGED
		MOV EAX, 0d
		JMP @F
	.endif
	
	MOV ECX, Slots[ESI].occupied
	.if ECX == 0
		fn Log_Error, "SERecallString", EDI, E_SLOT_NOT_OCCUPIED, -1
		;fn Set_Error, E_ERROR_LOGGED
		MOV EAX, 0d
		JMP @F
	.endif
	
	MOV ECX, Slots[ESI].textlength
;	PrintDec ECX, "number of bytes to copy"
	PUSH ECX
	MOV EDX, rv(SysAllocStringByteLen, 0d, ECX)
	POP ECX
	PUSH EDX
	fn MemCopy, Slots[ESI].textbase, EDX, ECX 
	POP EDX

@@:	
	POP EDX
	POP ECX

	Ret
SERecallString EndP
SERecall PROC STDCALL uses EDI ESI pBuffer:DWORD
	
	; 	if currentSlot is not instantiated, return error
	;	if temp slot is not occupied, return error
	;	copy from textbase for textlength to supplied buffer
	;	return success

	PUSH ECX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	MOV ECX, Slots[ESI].instantiated
	.if ECX == 0
		fn Log_Error, "SERecall", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ECX, Slots[ESI].occupied
	.if ECX == 0
		fn Log_Error, "SERecall", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	fn MemCopy, Slots[ESI].textbase, pBuffer, Slots[ESI].textlength 
	fn Set_Error, E_NO_ERROR

@@:	
	POP ECX
	RET
	
SERecall endp

SEHexDump PROC STDCALL uses EDI ESI 
	
	PUSH ECX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)

	MOV ECX, Slots[ESI].instantiated
	.if ECX == 0
		fn Log_Error, "SEHexDump", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ECX, Slots[ESI].occupied
	.if ECX == 0
		fn Log_Error, "SEHexDump", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	MOV ECX, Slots[ESI].textlength
	fn bin2hex, Slots[ESI].textbase, ECX, Slots[0].slotbase
	m2m Slots[0].textbase, Slots[ESI].slotbase
	fn szLen, Slots[0].slotbase
	MOV Slots[0].textlength, EAX
	MOV Slots[0].occupied, 1
;	fn Set_Error, E_NO_ERROR

@@:	
	POP ECX
	RET

SEHexDump endp

SERawHex PROC STDCALL uses EDI ESI EBX
	
	PUSH EDX
	PUSH ECX
	
	MOV EDI, currentSlot
	MOV EBX, rv(IntMul, EDI, SIZEOF Slot)

	MOV ECX, Slots[EBX].instantiated
	.if ECX == 0
		fn Log_Error, "SERawHex", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV ECX, Slots[EBX].occupied
	.if ECX == 0
		fn Log_Error, "SERawHex", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	; we're going to do this the hard way:
	; ESI is source index
	; EDI is destination index
	; therefore EBX points to the slot
	MOV ECX, Slots[EBX].textlength
	MOV ESI, Slots[EBX].textbase
	MOV EDI, Slots[0].slotbase
	PUSH ECX
	SHL ECX, 1
	MOV Slots[0].textlength, ECX
	POP ECX
	INC ECX
	.while ECX > 0
		MOV dl, byte ptr [ESI]
		MOV al, dl
		SHR al, 4
		and al, 0fh
		.if al > 9
			ADD al, 'A' - 10
		.else
			ADD al, '0'
		.endif
		MOV byte ptr [EDI], al
		INC EDI
		MOV al, dl
		and al, 0fh
		.if al > 9
			ADD al, 'A' - 10
		.else
			ADD al, '0'
		.endif
		MOV byte ptr [EDI], al
		INC EDI
		INC ESI
		DEC ECX
	.endw
	MOV Slots[0].occupied, 1
	m2m Slots[0].textbase, Slots[0].slotbase
	MOV EAX, Slots[0].textlength
;	fn Set_Error, E_NO_ERROR
@@:	
	POP ECX
	POP EDX
	RET

SERawHex endp

SEUTF16Scan PROC STDCALL uses EDI ESI EBX nStart:DWORD
	
	HIGH_SURROGATE_MIN EQU 0D800H
	HIGH_SURROGATE_MAX EQU 0DBFFH
	LOW_SURROGATE_MIN  EQU 0DC00H
	LOW_SURROGATE_MAX  EQU 0DFFFH
	
	LOCAL dOffset:DWORD
	LOCAL dCount:DWORD
	LOCAL dStart:DWORD
		
	;start at nStart in current slot's text
	;read thru as if word values into AX
	;if AL <> 0 then assume bad UTF8
	; and return BYTE offset
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	MOV EAX, Slots[ESI].instantiated
;	PrintDec EAX, "instantiated"
	.if EAX == 0
		fn Log_Error, "SEUTF16Scan", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EAX, Slots[ESI].occupied
;	PrintDec EAX, "occupied"
	.if EAX == 0
		fn Log_Error, "SEUTF16Scan", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	;get offset
	MOV EDX, nStart
	MOV EAX, [EDX]
	MOV dStart, EAX
;	PrintDec EAX, "dStart"
	
	MOV EDX, Slots[ESI].textlength
;	PrintDec EDX, "textlength"
	.if EAX > EDX ; start > length of string
		fn Log_Error, "SEUTF16Scan", EDI, E_SCAN_START_BEYOND_END, ECX
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	SUB EDX, EAX ;subtract offset from textlength
	MOV dCount, EDX ; save count of bytes to check
;	PrintDec EDX, "bytes to check"
	 	
	MOV EDX, Slots[ESI].textbase
;	PrintHex EDX, "textbase"
	ADD EDX, EAX ;add offset to textbase
	MOV dStart, EDX ;and store
;	PrintHex EDX, "offset into textbase"
	
	; step through the data, word by word
	; decrementing dCount by 2
	; and checking for dCount == 1
	; which means there's not enough word data left.
	
	; for each word
	;	if word is low surrogate
	;		if next word is not high surrogate or dCount == 3
	;			error, return dCount
	;		end
	;	elseif word is high surrogate
	;		error, return dCount
	;	else
	;		continue
	
	;MOV EDX, dStart
	.repeat
		PUSH EDX
;		PrintHex EDX, "Pointing at"
		MOV ECX, dCount
		.if ECX == 1
;			PrintText "dCount == 1"
			POP EDX
			MOV ECX, Slots[ESI].textbase
			SUB EDX, ECX 
			DEC EDX ;offset to faulty char. make one based.
			fn Log_Error, "SEUTF16Scan", EDI, E_TRAILING_BYTE, EDX
			fn Set_Error, E_ERROR_LOGGED
			JMP @F
		.endif
		
		.if ECX == 0d
			POP EDX
			fn Set_Error, E_NO_ERROR
			JMP @F
		.endif
		
		MOV AX, WORD PTR [EDX]
		MOVZX ECX, AX
;		PrintHex ECX, "Word value" 	
	
		.if ECX <= HIGH_SURROGATE_MAX && ECX >= HIGH_SURROGATE_MIN
			; if dCount > 1 then
			;	if next word is not in LOW_SURROGATE range then we have an error
;			PrintText "High Surrogate"
			.if dCount > 1
				MOV AX, WORD PTR [EDX+2]
				MOVZX ECX, AX
				.if ECX <= LOW_SURROGATE_MAX && ECX >= LOW_SURROGATE_MIN
;					PrintText "Has normal low surrogate trailing"
					POP EDX
					INC EDX
					INC EDX
					JMP Continue
				.else
;					PrintText "Has no trailing low surrogate"
					POP EDX
					MOV ECX, Slots[ESI].textbase
					SUB EDX, ECX 
					DEC EDX ;offset to faulty char. make one based.
					fn Log_Error, "SEUTF16Scan", EDI, E_BROKEN_SURROGATE_PAIR, EDX
					fn Set_Error, E_ERROR_LOGGED
					.break
				.endif
			.else
;				PrintText "Trailing high surrogate"
				POP EDX
				MOV ECX, Slots[ESI].textbase
				SUB EDX, ECX 
				DEC EDX ;offset to faulty char. make one based.
				fn Log_Error, "SEUTF16Scan", EDI, E_TRAILING_HIGH_SURROGATE, EDX
				fn Set_Error, E_ERROR_LOGGED
				.break
			.endif
		.else
			.if ECX <= LOW_SURROGATE_MAX && ECX >= LOW_SURROGATE_MIN
;				PrintText "Solitary low surrogate"
				POP EDX
				MOV ECX, Slots[ESI].textbase
				SUB EDX, ECX 
				DEC EDX ;offset to faulty char. make one based.
				fn Log_Error, "SEUTF16Scan", EDI, E_LEADING_LOW_SURROGATE, EDX
				fn Set_Error, E_ERROR_LOGGED
				.break
			.endif
		.endif	
		
		POP EDX
Continue:			
		INC EDX
		INC EDX
;		PrintHex EDX, "now pointing at"
		
		MOV ECX, dCount
		DEC ECX
		DEC ECX
		MOV dCount, ECX
;		.if ECX < 2
;			jmp @F
;		.endif
;		PrintDec ECX, "count now set at"
	.until 0
@@:

	POP EDX
	POP ECX
	
	RET

SEUTF16Scan endp

Compare_CheckReferenceSlot PROC STDCALL uses EBX EDI ESI RefSlot:DWORD

	PUSH ECX
	PUSH EDX
	
	MOV EDI, RefSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;make sure slot is instantiated
	MOV EAX, Slots[ESI].instantiated
	.if EAX == 0 
		fn Log_Error, "SECompare", EDI, E_COMPARE_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F ;jump over occupation test
	.endif
	
	;make sure slot is occupied
	MOV EAX, Slots[ESI].occupied
	.if EAX == 0
		fn Log_Error, "SECompare", EDI, E_COMPARE_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		jmp @F
	.endif
	
	fn Set_Error, E_NO_ERROR
	
@@:
	POP EDX
	POP ECX
	
	Ret
Compare_CheckReferenceSlot EndP

Compare_CheckTargetSlots PROC STDCALL uses EBX EDI ESI SlotSet:DWORD, TextLength:DWORD
	;make sure that all the other slots in dSlotSet 
	;are also instantiated and occupied

	LOCAL dErrorCount:DWORD
		
	PUSH ECX
	PUSH EDX
	
	MOV dErrorCount, 0d
	
	MOV EDI, 1
	MOV EBX, 0 ; start with slot 0 

	.repeat
;		PrintDec EBX, "Compare_ checking this slot"
;		PrintHex EDI
		
		MOV ECX, SlotSet
		TEST ECX, EDI
		JZ @F ;bit not set
		
;		PrintDec ECX, "Checking this slot"
		
		;bit is set so check this slot out
		MOV ESI, rv(IntMul, EBX, SIZEOF Slot)
	
		;make sure slot is instantiated
		MOV ECX, Slots[ESI].instantiated
;		PrintDec ECX, "instantiated?"
	
		.if ECX == 0
;			PrintText "Not instantiated"
			fn Log_Error, "SECompare", EBX, E_COMPARE_SLOT_NOT_INSTANTIATED, -1
			fn Set_Error, E_ERROR_LOGGED
			INC dErrorCount
			JMP @F ;jump over occupation TEST and length TEST
		.endif
		
		MOV ECX, Slots[ESI].occupied
;		PrintDec ECX, "occupied?"
		
		.if ECX == 0
;			PrintText "Not occupied"
			fn Log_Error, "SECompare", EBX, E_COMPARE_SLOT_NOT_OCCUPIED, -1
			fn Set_Error, E_ERROR_LOGGED
			INC dErrorCount
			JMP @F ;jump over length TEST
		.endif
		
		MOV ECX, Slots[ESI].textlength
;		PrintDec ECX, "length"
		.if ECX != TextLength
;			PrintText "bad length"
			fn Log_Error, "SECompare", EBX, E_COMPARE_LENGTH_DIFFERENT, TextLength
			fn Set_Error, E_ERROR_LOGGED
			INC dErrorCount
			JMP @F
		.endif
		
;		PrintText "No Error"
		fn Set_Error, E_NO_ERROR
			
@@:
		INC EBX
		ADD EDI, EDI
	.until EDI == SLOT_LIMIT

	POP EDX
	POP ECX
	
	.if dErrorCount > 0d
		fn Set_Error, E_ERROR_LOGGED
	.endif
;	PrintDec EAX, "Final return code"
	Ret
Compare_CheckTargetSlots EndP
SECompare PROC STDCALL uses EBX EDI ESI nReferenceSlot:DWORD, nSlotSet:DWORD
	
	; nReference slot is compared against all the slots specified in nSlotSet
	; nSlotSet's bits reference each of the 16 slots, 1 for selected, 0 for unselected
	; use the MASM forum answer re stepping through the slot set
	
	LOCAL dSlot:Slot
	LOCAL dRefSlot:DWORD
	LOCAL dSlotSet:DWORD
	LOCAL bChar:BYTE
	LOCAL dCheckLength:DWORD
	LOCAL dCounter:DWORD	
	
	PUSH ECX
	PUSH EDX
	
	; make parameters more readily available
	MOV EDX, nReferenceSlot
	MOV EAX, [EDX]
	MOV dRefSlot, EAX
	
	MOV ECX, rv(Compare_CheckReferenceSlot, dRefSlot)
	.if ECX != 0
;		PrintText "Compare_CheckReferenceSlot error"
		jmp @F
	.endif
	
	
	MOV EDX, nSlotSet
	MOV EAX, [EDX]
	MOV dSlotSet, EAX
	
	MOV EDI, dRefSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	fn MemCopy, ADDR Slots[ESI], ADDR dSlot, SIZEOF Slot
	
	MOV ECX, rv(Compare_CheckTargetSlots, dSlotSet, dSlot.textlength ) 
	.if ECX != 0
;		PrintText "Compare_CheckTargetSlots error"
		jmp @F
	.endif
	
		
	
	;at this point, all the required slots are instantiated and occupied
	;and the length of the string of each is the same as that of the reference
	
	; for i = 0 to length of text in reference slot
	;	bChar = byte pointer [reference slot textbase + i]
	;	for j = 0 to slotcount
	;		if j in slot set
	;			if byte pointer [Slot[j].textbase + i] != bChar
	;				error
	;			end
	;		end
	;	end
	; end
	; success
	;:error
	;				
	MOV ECX, 0
	MOV dCounter, ECX
	.while dSlot.textlength > ECX
;		PUSH ECX
;		PrintDec ECX, "character offset"
		MOV EDX, dSlot.textbase
		ADD EDX, ECX
;		PrintHex EDX, "reference character here"
		
		XOR EAX, EAX
		MOV al, BYTE PTR [EDX]
;		PrintDec al, "bChar there"
		MOV bChar, al
		
		MOV EDI, 1
		MOV EBX, 0 ;check slot 0 while we're at it
		.repeat
			MOV EAX, dSlotSet
			TEST EAX, EDI
			JZ ByteCheckEnd ;bit not set
;			PrintDec EBX, "checking in this slot"
			;bit is set so check this slot out
			MOV ESI, rv(IntMul, EBX, SIZEOF Slot)
		
			;make sure slot is instantiated
			MOV EDX, Slots[ESI].textbase
;			POP ECX
;			PUSH ECX
			MOV ECX, dCounter
			ADD EDX, ECX
;			PrintHex EDX, "looking for character here"
			
			XOR EAX, EAX
			MOV al, BYTE PTR [EDX]
;			PrintDec al, "character in slot"
			MOVZX EDX, bChar
			.if EAX != EDX
;				PrintText "Logging Error"
				fn Log_Error, "SECompare", EBX, E_COMPARE_DATA_DIFFERENT, dCounter
				fn Set_Error, E_ERROR_LOGGED
;				PrintText "Finishing"
;				jmp @F ;this jmp would mean exiting after the first fail, which might
;						not be what is wanted.
			.endif
	
	ByteCheckEnd:
			INC EBX
;			PrintDec EBX, "About to check this slot"
			ADD EDI, EDI
		.until EDI == SLOT_LIMIT
;		PrintHex EDI, "At ByteCheckEnd"
;		cmp EDI, SLOT_LIMIT
;		JNZ ByteCheckLoop 
;		
		MOV ECX, dCounter
		INC ECX
		MOV dCounter, ECX
;		PrintDec ECX, "about to check this character"
	.endw
	fn Set_Error, E_NO_ERROR
@@:
	POP EDX
	POP ECX
;	PrintText "Finished"
;	PrintDec EAX, "EAX at the end"
	RET

SECompare endp

SEWriteFile PROC STDCALL uses EDI ESI sFilename:DWORD
	
	LOCAL sFile:DWORD
	
	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;make sure slot is instantiated
	MOV EAX, Slots[ESI].instantiated
	.if EAX == 0 
		fn Log_Error, "SEWriteFile", EDI, E_COMPARE_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F ;jump over occupation test
	.endif
	
	;make sure slot is occupied
	MOV EAX, Slots[ESI].occupied
	.if EAX == 0
		fn Log_Error, "SEWriteFile", EDI, E_COMPARE_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		jmp @F
	.endif
	
	MOV EDX, sFilename
	MOV EAX, [EDX]
	MOV sFile, EAX
	
	fn szLen, sFile
	.if EAX == 0d
		fn Log_Error, "SEWriteFile", EDI, E_WRITEFILE_NO_FILENAME, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	
	;PrintStringByAddr sFile
	fn write_disk_file, sFile, Slots[ESI].textbase, Slots[ESI].textlength
	;PrintDec EAX, "result of write"
	.if EAX == 0d
		fn Log_Error, "SEWriteFile", EDI, E_WRITEFILE_NOTHING_WRITTEN, -1
		fn Set_Error, E_ERROR_LOGGED
		jmp @F
	.endif
	
	fn Set_Error, E_NO_ERROR
	
@@:
	POP EDX
	POP ECX
	
	Ret
SEWriteFile EndP


SEReadFile PROC STDCALL uses EDI ESI EBX sFilename:DWORD, nInsertionType:DWORD
	
	LOCAL hFile:DWORD
	LOCAL sFile:DWORD
	LOCAL dBuff:DWORD
	LOCAL dLeng:DWORD
	LOCAL dRead:DWORD
	LOCAL dType:DWORD
	
	PUSH ECX
	PUSH EDX
	
;	MOV EDI, currentSlot
;	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)

	MOV EDX, sFilename
	MOV EAX, [EDX]
	MOV sFile, EAX
	
	MOV EDX, nInsertionType
	MOV EAX, [EDX]
	MOV dType, EAX
	
;	PrintStringByAddr sFile
	
	MOV ECX, rv(exist,sFile)
;	PrintDec ECX, "exist result"	 
	.if ECX == 1
		MOV hFile, fopen( sFile )
		MOV dLeng, fsize( hFile )
;		PrintDec dLeng, "Length of input file"
;		PrintDec dLeng, "SEReadFile SysAllocStringByteLen"
		MOV dBuff, rv(SysAllocStringByteLen, 0d, dLeng)
;		PrintHex dBuff, "global allocation"
		MOV dRead, fread( hFile, dBuff, dLeng)
;		PrintDec dRead,"bytes read"
		fclose hFile 
		MOV ECX, dRead
		.if ECX == 0
			fn Log_Error, "SEReadFile", currentSlot, E_FILE_NOT_READ, -1
			fn Set_Error, E_ERROR_LOGGED
			jmp @F
		.else	
			fn Set_Error, E_NO_ERROR
		.endif
	.else
		fn Log_Error, "SEReadFile", currentSlot, E_FILE_NOT_FOUND, -1
		fn Set_Error, E_ERROR_LOGGED
		jmp @F
	.endif
	
	.if dType == 1 ;STORE
		fn SEStore, dBuff
	
	.elseif dType == 2 ;PREPEND
		fn SEPrepend, dBuff
		
	.elseif dType == 3 ;APPEND
		fn SEAppend, dBuff
		
	.endif
;	PrintText "SEReadFile freeing buffer"
	fn SysFreeString, dBuff
	MOV EAX, dRead
@@:
	POP EDX
	POP ECX
	Ret
SEReadFile EndP

SEReverseBytes PROC STDCALL uses EDI ESI

	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;make sure slot is instantiated
	MOV EAX, Slots[ESI].instantiated
	.if EAX == 0 
		fn Log_Error, "SEReverseBytes", EDI, E_COMPARE_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F ;jump over occupation test
	.endif
	
	;make sure slot is occupied
	MOV EAX, Slots[ESI].occupied
	.if EAX == 0
		fn Log_Error, "SEReverseBytes", EDI, E_COMPARE_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		jmp @F
	.endif
	
	;load textbase into ESI and end of text into EDI and length into ECX
	MOV EDX, ESI
	MOV ESI, Slots[EDX].textbase
	MOV EDI, ESI
	MOV ECX, Slots[EDX].textlength
	ADD EDI, ECX
	DEC EDI ;?
	;DEC ECX ;?
	SHR ECX, 1
	
	.while ECX > 0d
		MOV AL, BYTE PTR [ESI]
;		PrintDec AL
		MOV AH, BYTE PTR [EDI]
;		PrintDec AH
		MOV BYTE PTR [EDI], AL
		MOV BYTE PTR [ESI], AH
		INC ESI
;		PrintHex ESI, "bottom"
		DEC EDI
;		PrintHex EDI, "top"
		DEC ECX
	.endw
@@:
	POP EDX
	POP ECX
	
	Ret
SEReverseBytes EndP

SEReverseWords PROC STDCALL uses EDI ESI EBX

	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;make sure slot is instantiated
	MOV EAX, Slots[ESI].instantiated
	.if EAX == 0 
		fn Log_Error, "SEReverseWords", EDI, E_COMPARE_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F ;jump over occupation test
	.endif
	
	;make sure slot is occupied
	MOV EAX, Slots[ESI].occupied
	.if EAX == 0
		fn Log_Error, "SEReverseWords", EDI, E_COMPARE_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		jmp @F
	.endif
	
	;load textbase into ESI and end of text into EDI and length into ECX
	MOV EDX, ESI
	MOV ESI, Slots[EDX].textbase
	MOV EDI, ESI
	MOV ECX, Slots[EDX].textlength
	ADD EDI, ECX
	;DEC EDI ;?
	;DEC EDI ;?
	SUB EDI, 2
	SHR ECX, 2 ;divide by 4
	
	.while ECX > 0d
		MOV AX, WORD PTR [ESI]
;		PrintDec AX
		MOV BX, WORD PTR [EDI]
;		PrintDec BX
		MOV WORD PTR [EDI], AX
		MOV WORD PTR [ESI], BX
		;INC ESI
		;INC ESI
		ADD ESI, 2
;		PrintHex ESI, "bottom"
		;DEC EDI
		;DEC ESI
		SUB EDI, 2
;		PrintHex EDI, "top"
		DEC ECX
	.endw
@@:
	POP EDX
	POP ECX
	
	Ret
SEReverseWords EndP

SEReverseDWords PROC STDCALL uses ESI EDI EBX

	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	;make sure slot is instantiated
	MOV EAX, Slots[ESI].instantiated
	.if EAX == 0 
		fn Log_Error, "SEReverseDWords", EDI, E_COMPARE_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F ;jump over occupation test
	.endif
	
	;make sure slot is occupied
	MOV EAX, Slots[ESI].occupied
	.if EAX == 0
		fn Log_Error, "SEReverseDWords", EDI, E_COMPARE_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		jmp @F
	.endif
	
	;load textbase into ESI and end of text into EDI and length into ECX
	MOV EDX, ESI
	MOV ESI, Slots[EDX].textbase
	MOV EDI, ESI
	MOV ECX, Slots[EDX].textlength
	ADD EDI, ECX
	;DEC EDI ;?
	;DEC EDI ;?
	;DEC EDI
	;DEC EDI
	SUB EDI, 4
	SHR ECX, 3 ;divide by 8
;	PrintDec ECX, "this many iterations"
	.while ECX > 0d
		MOV EAX, [ESI]
;		PrintDec EAX
		MOV EBX, [EDI]
;		PrintDec EBX
		MOV [EDI], EAX
		MOV [ESI], EBX
		;INC ESI
		;INC ESI
		;INC ESI
		;INC ESI
		ADD ESI, 4
;		PrintHex ESI, "bottom"
		;DEC EDI
		;DEC EDI
		;DEC EDI
		;DEC EDI
		SUB EDI, 4
;		PrintHex EDI, "top"
		DEC ECX
	.endw
@@:
	POP EDX
	POP ECX
	
	Ret
SEReverseDWords EndP
SEDump PROC STDCALL uses EDI ESI EBX
	;LOCAL dSlot:Slot
	LOCAL hFile:DWORD
	LOCAL stm:SYSTEMTIME
	LOCAL dCount:DWORD
	LOCAL dAddr:DWORD
	
	;LOCAL pNow:DWORD
		
	PUSH EDX
	PUSH ECX
	
	MOV ECX, rv(exist,"bose.$$$")
	.if ECX == 1
		MOV hFile, fopen( "bose.$$$" )
		MOV ECX, fseek( hFile, 0, FILE_END )
	.else
		MOV hFile, fcreate( "bose.$$$" )
	.endif

	fprintc hFile, "**************************************************\n"
;	MOV pNow, ptr$(Now)
	fn GetSystemTime, ADDR stm
	
	fprintc hFile, "["
	MOVZX EAX, WORD PTR stm.wYear
	fprintc hFile, sstr$( EAX )
	fprintc hFile, "-"
	MOVZX EAX, WORD PTR stm.wMonth
	fprintc hFile, sstr$( EAX )
	fprintc hFile, "-"
	MOVZX EAX, WORD PTR stm.wDay
	fprintc hFile, sstr$( EAX )
	fprintc hFile, " "
	MOVZX EAX, WORD PTR stm.wHour
	fprintc hFile, sstr$( EAX )
	fprintc hFile, ":"
	MOVZX EAX, WORD PTR stm.wMinute
	fprintc hFile, sstr$( EAX )
	fprintc hFile, ":"
	MOVZX EAX, WORD PTR stm.wSecond
	fprintc hFile, sstr$( EAX )
	fprintc hFile, "."
	MOVZX EAX, WORD PTR stm.wMilliseconds
	fprintc hFile, sstr$( EAX )
	fprintc hFile, "]\n"
;	
	;MOV hFile, fcreate( "bose.$$$" )
    
	MOV EDI, SLOT_COUNT
	MOV EDX, EDI
	INC EDX
	.repeat
		PUSH EDX
		MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
      	; log each instantiated slot with a dump of text, if any
		MOV EAX, Slots[ESI].instantiated
;		PrintText "before uhex1 and uhex2"
		.if EAX == 1
			fprintc hFile, "Slot: "
			fprint hFile, sstr$( EDI )
			fprintc hFile, "\tinstantiated="
			fprint hFile, sstr$( Slots[ESI].instantiated )
			fprintc hFile, "\tslotbase="
;			mov ECX, Slots[ESI].slotbase
;			PrintHex ECX, "before uhex1"
			fprint hFile, uhex$( Slots[ESI].slotbase )
;			PrintText "after uhex1"
			fprintc hFile, "\tslotlength="
			fprint hFile, sstr$( Slots[ESI].slotlength )
			fprintc hFile, "\ttextbase="
;			mov ECX, Slots[ESI].slotbase
;			PrintHex ECX, "before uhex2"
			fprint hFile, uhex$( Slots[ESI].textbase )
;			PrintText "after uhex2"
			fprintc hFile, "\ttextlength="
			fprint hFile, sstr$( Slots[ESI].textlength )
			fprintc hFile, "\toccupied="
			fprint hFile, sstr$( Slots[ESI].occupied )
			MOV EBX, Slots[ESI].textbase
			MOV ECX, Slots[ESI].textlength
;			PrintText "before uhex3"
			.while ECX > 0
				PUSH ECX
				fprintc hFile, "\t\t"
;				PrintHex EBX, "before uhex3"
				fprintc hFile, uhex$(EBX)
;				PrintText "after uhex3"
				fprintc hFile, ": "
				XOR EAX, EAX
				MOV al, byte ptr [EBX]
				PUSH EBX
				fprint hFile, sstr$( EAX )
				POP EBX
				INC EBX
				POP ECX
				DEC ECX
			.endw
;			PrintText "after uhex3"
			fprintc hFile, "\n\n"
		.endif
		DEC EDI
		POP EDX
		DEC EDX
	.until EDX == 0

	fprintc hFile, "\nERROR STACK"
	
	MOV ECX, EStackCount
	
	DEC ECX
	
;	PrintText "about to print out stack"
	.if ECX == 0
;		PrintText "stack is empty"
		PUSH ECX
		fprint hFile, " EMPTY"
		POP ECX
	.else
;		PrintText "stuff in stack"
		PUSH ECX
		fprintc hFile, "\n"
		POP ECX
;		PrintText "before uhex4"
		.while ECX > 0
			MOV dCount, ECX
			MOV EDI, EStack
			SHL ECX, 2
			ADD EDI, ECX
			MOV EDX, dword ptr [EDI]
			MOV dAddr, EDX
			fprintc hFile, "\t#"
			fprintc hFile, sstr$( dCount )
			fprintc hFile, " "
;			PrintHex dAddr, "before uhex4"
			fprintc hFile, uhex$( dAddr )
;			PrintText "after uhex4"
			fprintc hFile, ": "
			MOV ECX, fwrite( hFile, dAddr, len(dAddr))
			fprintc hFile, "\n"
			MOV ECX, dCount
			DEC ECX
		.endw 
	.endif
		
;	PrintText "end of stack printout"
	fclose hFile
;	PrintText "Dump file closed" 
	fn Set_Error, E_NO_ERROR
;	PrintText "set error to zero"
	POP ECX
	POP EDX
;	PrintText "ecx and edx popped"
	RET

SEDump endp


end LibMain
