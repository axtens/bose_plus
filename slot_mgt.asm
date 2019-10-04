SEGetSlot PROC STDCALL 
	
	MOV EAX, currentSlot
	RET

SEGetSlot endp

SESetSlot PROC STDCALL uses EDI ESI nSlot:DWORD
	
	PUSH EDX
	MOV EDX, nSlot
	MOV EDI, [EDX]
	
	.if EDI < 0d || EDI > SLOT_COUNT
		fn Log_Error, "SESetSlot", EDI, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	MOV EDX, Slots[ESI].instantiated
	.if EDX == 0
		PUSH EDX
		fn Instantiate, EDI
		POP EDX
	.endif
	MOV currentSlot, EDI
    fn Set_Error, E_NO_ERROR
    
@@:
	POP EDX
	RET

SESetSlot endp

SESetGlobalSlotSize PROC STDCALL nSize:DWORD
	
	PUSH EDX
	PUSH ECX

	MOV EDX, nSize
	MOV ECX, [EDX]
	
	.if ECX < 0d || ECX > 65535
		fn Log_Error, "SESetGlobalSlotSize", ECX, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	MOV slotSize, ECX
	
;	.if Slots[0].slotbase != 0d
;		fn SysFreeString, Slots[0].slotbase
;	.endif
	fn Instantiate, 0 ;reinstantiate slot 0 with the new size
	fn Set_Error, E_NO_ERROR
	
@@:
	POP ECX
	POP EDX
	RET

SESetGlobalSlotSize endp

SEGetGlobalSlotSize PROC STDCALL
	
	MOV EAX, slotSize
	RET

SEGetGlobalSlotSize endp

SESwapSlot PROC STDCALL uses EBX EDI ESI nSlotFrom:DWORD, nSlotTo:DWORD

	LOCAL nFrom:DWORD
	LOCAL nTo:DWORD
	LOCAL dSlot:Slot
	
	PUSH ECX
	PUSH EDX
	
	MOV EDX, nSlotFrom
	MOV EAX, [EDX]
		
	.if EAX < 0d || EAX > SLOT_COUNT
		fn Log_Error, "SESwapSlot", EAX, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV nFrom,EAX
	
	MOV EDX, nSlotTo
	MOV EAX, [EDX]
	
	.if EAX < 0d || EAX > SLOT_COUNT
		fn Log_Error, "SESWapSlot", EAX, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV nTo, EAX
	
	.if EAX == nFrom
		; Swapping from the same slot. Treat as a NOP.
		fn Set_Error, E_NO_ERROR
		JMP @F
	.endif
	
	MOV EDI, rv(IntMul, EAX, SIZEOF Slot)
	MOV EAX, nFrom
	MOV ESI, rv(IntMul, EAX, SIZEOF Slot)
	
	fn MemCopy, ADDR Slots[ESI], ADDR dSlot, SIZEOF Slot
	fn MemCopy, ADDR Slots[EDI], ADDR Slots[ESI], SIZEOF Slot
	fn MemCopy, ADDR dSlot, ADDR Slots[EDI], SIZEOF Slot
	
	fn Set_Error, E_NO_ERROR
	
@@:
	POP EDX
	POP ECX
	Ret
SESwapSlot EndP

SEForget PROC STDCALL uses EDI ESI nSlot:DWORD
	
	PUSH ECX
	PUSH EDX
	
	MOV EDX, nSlot
	MOV EDI, [EDX]
;	PrintDec EDI, "Trying to forget"
	.if EDI > 0 
		.if EDI < (SLOT_COUNT + 1)
			MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
			MOV Slots[ESI].instantiated, 0
			MOV Slots[ESI].occupied, 0
			fn SysFreeString, Slots[ESI].slotbase
			MOV Slots[ESI].slotbase, 0
			MOV Slots[ESI].slotlength, 0
			MOV Slots[ESI].textbase, 0
			MOV Slots[ESI].textlength, 0
			fn Set_Error, E_NO_ERROR
			JMP @F
		.endif
	.endif
	fn Log_Error, "SEForget", EDI, E_INVALID_SLOT, -1
	fn Set_Error, E_ERROR_LOGGED
	
@@:
	POP EDX
	POP ECX
	
	RET

SEForget endp

CopyAndOrForget PROC STDCALL uses EDI ESI nFrom:DWORD, nTo:DWORD, bForget:DWORD

	PUSH ECX
	PUSH EDX

	MOV ESI, nFrom
	MOV EDI, nTo
	
;	PrintLine
;	PrintText "CopyAndOrForget"
;	PrintLine
	
	.if Slots[EDI].occupied == 1
;		PrintText "CopyAndOrForget occupied"
		; if there's enough room in the slot, copy, else reallocate and then copy
		; this will clobber whatever values are already in textbase and textlength
		MOV ECX, Slots[EDi].slotlength
		.if Slots[ESI].slotlength > ECX ;if greater then need to reallocate
;			PrintText "CopyAndOrForget need to reallocate"
			; free destination slot's slotbase
			fn SysFreeString, Slots[EDI].slotbase
			
			fn CalculateAndAllocate, ESI, EDI
						 
		.else ;else just use what's there
;			PrintText "CopyAndOrForget Just using what's there"
			; get destination slot's length, divide by two
			MOV ECX, Slots[EDI].slotlength
			SHR ECX, 1
			
			; add to destination slot's base to find destination slot's middle
			ADD ECX, Slots[EDI].slotbase
			
			; get source text's length, divide by two
			MOV EAX, Slots[ESI].textlength
			SHR EAX, 1
			
			; subtract from destination slot's middle address to find copy_to address
			SUB ECX, EAX
			
			; copy
			MOV EAX, Slots[ESI].textbase
;			PrintHex EAX, "CopyAndOrForget Slots at ESI textbase"
;			PrintHex ECX, "CopyAndOrForget Where to put it"
			fn MemCopy, Slots[ESI].textbase, ECX, Slots[ESI].textlength
			m2m Slots[EDI].textlength, Slots[ESI].textlength
			
			; update slot details
			; ?
		.endif
	.else ; destination slot not occupied
;		PrintText "CopyAndOrForget not occupied"
		; calculate new allocation length as source's text length plus BUFFER_INCREMENT
		; allocate and store in destination slot's slotbase
		; store new length in destination slot's slotlength
		; halve that figure, add to slotbase, giving address of halfway
		; halve length of source slot's text, subtract from address of halfway
		; copy to that address the text in source slot
		; update other slot details
		
		fn CalculateAndAllocate, ESI, EDI
		
	.endif
	
	.if bForget == 1
;		PrintDec ESI, "Forgetting"
		;forget the source slot
		MOV Slots[ESI].instantiated, 0d
		MOV Slots[ESI].occupied, 0d
		fn SysFreeString, Slots[ESI].slotbase
		MOV Slots[ESI].slotbase, 0d
		MOV Slots[ESI].slotlength, 0d
		MOV Slots[ESI].textbase, 0d
		MOV Slots[ESI].textlength, 0d
	.endif 
	
	POP EDX
	POP ECX
	
	Ret
CopyAndOrForget EndP
SEMoveSlot PROC STDCALL uses EBX EDI ESI nSlotFrom:DWORD, nSlotTo:DWORD
	; first, make sure that nSlotFrom and nSlotTo are allowable, ie. between 0 and SLOT_COUNT
	; if source slot not instantiated, error
	; if source slot not occupied, error
	; if destination slot not instantiated, instantiate with size of source's text plus BUFFER_INCREMENT and copy
	; else if destination slot is instantiated
	;	if text already big enough for source's text, copy
	;	otherwise free destination's text and reallocate with size of source's text plus BUFFER_INCREMENT
	;		then copy
	; once copied, release all storage in source slot, and reset all slot flags
	
	LOCAL dFrom:DWORD
	LOCAL dTo:DWORD
	LOCAL dHalfway:DWORD
	LOCAL dSlot:Slot
	
	PUSH ECX
	PUSH EDX

;	PrintLine
;	PrintText "SEMoveSlot"
;	PrintLine
	
	MOV EDX, nSlotFrom
	MOV EAX, [EDX]
	MOV dFrom, EAX
	
	MOV EDX, nSlotTo
	MOV EAX, [EDX]
	MOV dTo, EAX
	
;	PrintText "SEMoveSlot"
	
	.if dFrom < 0d || dFrom > SLOT_COUNT
		fn Log_Error, "SEMoveSlot", dFrom, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	.if dTo < 0d || dTo > SLOT_COUNT
		fn Log_Error, "SEMoveSlot", dTo, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EAX, dFrom
	.if EAX == dTo
		; moving to self is self-destructive. throw an error
		fn Log_Error, "SEMoveSlot", dTo, E_MOVE_SELF_TO_SELF, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EDI, dFrom
;	PrintDec EDI, "SEMoveSlot dFrom"
	
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	fn MemCopy, ADDR Slots[ESI], ADDR dSlot, SIZEOF Slot
;	DumpMem ADDR dSlot, SIZEOF Slot, "dSlot"
	
;	PrintDec dSlot.instantiated
	
;	MOV EDX, OFFSET Slots
;	PrintHex EDX, "Slots is supposed to be here"
;	ADD EDX, ESI
;	PrintHex EDX, "Add this is where the data's supposed to be"
;	DumpMem EDX, SIZEOF Slot, "really?"
	
	.if Slots[ESI].instantiated == 0d
		fn Log_Error, "SEMoveSlot", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	.if Slots[ESI].occupied == 0d
		fn Log_Error, "SEMoveSlot", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EBX, dTo
;	PrintDec EBX, "dTo in SEMoveSlot"
	
	MOV EDX, rv(IntMul, EBX, SIZEOF Slot)
	
;	DumpMem ADDR Slots[EDX], SIZEOF Slot, "Slots @ EDX in SEMoveSlot"
	
	.if Slots[EDX].instantiated == 0d
;		PrintDec EBX, "SEMoveSlot Instantiating"
		fn Instantiate, EBX
	.endif
	
	fn CopyAndOrForget, ESI, EDX, 1 
	fn Set_Error, E_NO_ERROR
		
@@:
	POP EDX
	POP ECX
	
	Ret
SEMoveSlot EndP

SECopySlot PROC STDCALL uses EBX EDI ESI nSlotFrom:DWORD, nSlotTo:DWORD
	; first, make sure that nSlotFrom and nSlotTo are allowable, ie. between 0 and SLOT_COUNT
	; if source slot not instantiated, error
	; if source slot not occupied, error
	; if destination slot not instantiated, instantiate with size of source's text plus BUFFER_INCREMENT and copy
	; else if destination slot is instantiated
	;	if text already big enough for source's text, copy
	;	otherwise free destination's text and reallocate with size of source's text plus BUFFER_INCREMENT
	;		then copy
	
	LOCAL dFrom:DWORD
	LOCAL dTo:DWORD
	LOCAL dHalfway:DWORD
	
	PUSH ECX
	PUSH EDX

;	PrintLine
;	PrintText "SECopySlot"
;	PrintLine
	
	MOV EDX, nSlotFrom
	MOV EAX, [EDX]
	MOV dFrom, EAX
	
	MOV EDX, nSlotTo
	MOV EAX, [EDX]
	MOV dTo, EAX
	
;	PrintText "SECopySlot"
	
	.if dFrom < 0d || dFrom > SLOT_COUNT
		fn Log_Error, "SECopySlot", dFrom, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	.if dTo < 0d || dTo > SLOT_COUNT
		fn Log_Error, "SECopySlot", dTo, E_INVALID_SLOT, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EAX, dFrom
	.if EAX == dTo
		; copying to self in a NOP
		fn Set_Error, E_NO_ERROR
		JMP @F
	.endif
	
	MOV EDI, dFrom
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	.if Slots[ESI].instantiated == 0d
		fn Log_Error, "SECopySlot", EDI, E_SLOT_NOT_INSTANTIATED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif

	.if Slots[ESI].occupied == 0d
		fn Log_Error, "SECopySlot", EDI, E_SLOT_NOT_OCCUPIED, -1
		fn Set_Error, E_ERROR_LOGGED
		JMP @F
	.endif
	
	MOV EBX, dTo
	MOV EDX, rv(IntMul, EBX, SIZEOF Slot)
	
	.if Slots[EDX].instantiated == 0d
;		PrintDec EBX, "SECopySlot Instantiating"
		fn Instantiate, EBX
	.endif
	
;	PrintDec EDI, "Copying from"
;	PrintDec EBX, "Copying to"
	
	fn CopyAndOrForget, ESI, EDX, 0d ;no forgetting 
	fn Set_Error, E_NO_ERROR
		
@@:
	POP EDX
	POP ECX
	
	Ret
SECopySlot EndP

Instantiate PROC STDCALL uses EDI ESI nSlot:DWORD
	;LOCAL dSlot:Slot
	
	;allocate space and store pointer in Slots[ESI].slotbase
	; store slotSize in Slots[ESI].slotlength
	; ADD slotSize / 2 to slotbase and store in Slots[EDI*32].textbase
	; store 0 in Slots[ESI].textlength
	; store 0 in Slots[ESI].occupied
	; store 1 in Slots[ESI].instantiated
	PUSH ECX
	PUSH EDX
	
	MOV EDI, nSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
	
	.if Slots[ESI].slotbase != 0d
		fn SysFreeString, Slots[ESI].slotbase
	.endif
	
	MOV Slots[ESI].slotbase, rv( SysAllocStringByteLen, 0, slotSize )
	
;	MOV EDX, OFFSET Slots
;	PrintHex EDX, "Instantiate: Slots's offset"
;	ADD EDX, ESI
;	PrintHex EDX, "Instantiate: Slots's offset + the slot's offset"
	PUSH EAX
	MOV EAX, slotSize
	MOV Slots[ESI].slotlength, EAX
	MOV ECX, slotSize
	SHR ECX, 1 ; divide by two
	POP EAX
	ADD ECX, EAX ; ECX new points halfway along slot
	MOV Slots[ESI].textbase, ECX
	MOV Slots[ESI].textlength, 0
	MOV Slots[ESI].occupied, 0
	MOV Slots[ESI].instantiated, 1
	fn Set_Error, E_NO_ERROR
	
	POP EDX
	POP ECX
	RET

Instantiate endp

SpaceAtBase PROC STDCALL uses EDI ESI ;in currentSlot
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
 
 	; return number of bytes between slotbase and textbase
 	MOV EAX, Slots[ESI].textbase
 	SUB EAX, Slots[ESI].slotbase
	RET

SpaceAtBase endp

SpaceToTop PROC STDCALL uses EDI ESI ;in currentSlot
	
	PUSH ECX
 	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
 	
 	; return number of bytes between (slotbase+slotlength) and (textbase+textlength)
 	MOV EAX, Slots[ESI].slotbase
 	ADD EAX, Slots[ESI].slotlength
	MOV ECX, Slots[ESI].textbase
 	ADD ECX, Slots[ESI].textlength
 	SUB EAX, ECX
 	POP ECX
	RET

SpaceToTop endp

WillFitAtBase PROC STDCALL uses EDI ESI nSize:DWORD ;in currentSlot
	
	PUSH ECX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
 
 	; if slotbase + nSize > textbase, return 0, else return 1
 	MOV EAX, Slots[ESI].slotbase
 	ADD EAX, nSize
 	MOV ECX, Slots[ESI].textbase
 	.if EAX > ECX
 		MOV EAX, 0
 	.else
 		MOV EAX, 1
 	.endif 
 	POP ECX
	RET

WillFitAtBase endp

WillFitAtTop PROC STDCALL uses EDI ESI nSize:DWORD ;in currentSlot
	
	PUSH ECX
 	
 	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)
 	
 	; if textbase + textlength + nSize > slotbase + slotlength, return 0, else return 1
 	MOV EAX, Slots[ESI].textbase
 	ADD EAX, Slots[ESI].textlength
 	ADD EAX, nSize
	MOV ECX, Slots[ESI].slotbase
	ADD ECX, Slots[ESI].slotlength
	.if EAX > ECX
		MOV EAX, 0
	.else
		MOV EAX, 1
	.endif
	POP ECX
	RET

WillFitAtTop endp

Verify PROC STDCALL uses EDI ESI ;on currentSlot
	
	;make sure that:
	; slotbase is less than textbase
	; slotbase + slotlength is greater than textbase + textlength
	; occupied == 1 if instantiated == 1

	PUSH ECX
	PUSH EDX
	
	MOV EDI, currentSlot
	MOV ESI, rv(IntMul, EDI, SIZEOF Slot)

	MOV EDX, Slots[ESI].slotbase
	MOV ECX, Slots[ESI].textbase
	.if ECX < EDX ;if textbase < slotbase
		fn MessageBox, 0, "Textbase less than Slotbase", "BOSE", MB_OK
	.endif
	
	MOV EDX, Slots[ESI].slotbase
	ADD EDX, Slots[ESI].slotlength
	MOV ECX, Slots[ESI].textbase
	ADD EDX, Slots[ESI].textlength
	.if ECX > EDX ; if top pointer of text over the top of the slot
		fn MessageBox, 0, "Text extends beyond slot", "BOSE", MB_OK
	.endif
	
	MOV EDX, Slots[ESI].instantiated
	MOV ECX, Slots[ESI].occupied
	.if ECX == 1
		.if EDX != 1
			fn MessageBox, 0, "Occupied by not instantiated?", "BOSE", MB_OK
		.endif
	.endif
	POP EDX
	POP ECX
	RET

Verify endp

CalculateAndAllocate PROC STDCALL uses EDI ESI nFrom:DWORD, nTo:DWORD

	PUSH ECX
	PUSH EDX

;	PrintLine
;	PrintText "CalculateAndAllocate"
;	PrintLine
	
	MOV ESI, nFrom
	MOV EDI, nTo
	
;	PrintDec ESI, "From Offset"
;	PrintDec EDI, "To Offset"
	
	; calculate new allocation length as source's text length plus BUFFER_INCREMENT
	MOV ECX, Slots[ESI].textlength
	ADD ECX, BUFFER_INCREMENT
	
;	PrintDec ECX, "CalculateAndAllocate new allocation size"
	
	; allocate and store in destination slot's slotbase
	PUSH ECX
	MOV Slots[EDI].slotbase, rv(SysAllocStringByteLen, 0d, ECX)
;	PrintHex EAX, "CalculateAndAllocate Allocated here"
	POP EAX
	
	; store new length in destination slot's slotlength
	MOV Slots[EDI].slotlength, EAX
	
	; halve that figure, add to slotbase, giving address of halfway
	SHR EAX, 1
	ADD EAX, Slots[EDI].slotbase
;	PrintHex EAX, "half way"
	
	; halve length of source slot's text, subtract from address of halfway
	MOV ECX, Slots[ESI].textlength
;	PrintDec ECX, "source slot's text length"
	SHR ECX, 1
;	PrintDec ECX, "half source slot's text length"
	
	SUB EAX, ECX
;	PrintHex EAX, "new textbase"
	
	MOV Slots[EDI].textbase, EAX
	
	; copy to that address the text in source slot
;	PrintText "CalculateAndAllocate copying"
	
;	MOV EDX, Slots[ESI].textbase
;	PrintHex EDX, "CalculateAndAllocate Slots ESI textbase"
;	MOV EDX, EAX
;	PrintHex EAX, "CalculateAndAllocate new destination"
;	MOV EDX, Slots[ESI].textlength
;	PrintDec EDX, "CalculateAndAllocate Slots ESI textlength"
	
	fn MemCopy, Slots[ESI].textbase, EAX, Slots[ESI].textlength
	
	; update other slot details
	m2m Slots[EDI].textlength, Slots[ESI].textlength
	MOV Slots[EDI].occupied, 1
	;???
	MOV Slots[EDI].instantiated, 1
	
;	DumpMem ADDR Slots[ESI], SIZEOF Slot, "source was"
;	DumpMem ADDR Slots[EDI], SIZEOF Slot, "destination is"
	
	POP EDX
	POP ECX
	
	Ret
CalculateAndAllocate EndP
