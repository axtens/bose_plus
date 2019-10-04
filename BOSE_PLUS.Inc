	BOSE_GOOD 			EQU 0
	SLOT_COUNT			EQU 16
	STACK_SIZE  		EQU 32
	SLOT_LIMIT			EQU 00020000h ;was 00010000h
	BUFFER_INCREMENT	EQU 512

include COMlibiconv.inc
include COMlibiconvc.inc

 
	Slot STRUCT 
		instantiated dd 0
		slotbase	 dd 0
		slotlength	 dd 0
		textbase	 dd 0
		textlength	 dd 0
		occupied	 dd 0
	Slot ends

	.const
		LIBID_COMlibiconv GUID sLIBID_COMlibiconv
		CLSID_Converters GUID sCLSID_Converters 
		IID_IConverters GUID sIID_IConverters
	
    .data?
    	align 8
        hInstance 	dd ?
		;hFile		dd ?
		errNum		dd ?
		pIConverters	dd ?
		hResult		DD ?
		bIsEncoding VARIANT_BOOL ?		
	.data
		align 8
		currentSlot dd 1
		slotSize	dd 1024*4 ;bytes
		workSlot	dd 0 ; initial setting. varies.
		Slots		Slot (SLOT_COUNT + 1) dup (<0,0,0,0,0,0>) ;slot 0 is the initial workSlot
		overflow	dd 0f0f0f0fh
		
		EStack		dd 0
		EStackCount	dd 1
		EEmptyStack	db "out of stack space", 0
;		Distrib	DD 256 DUP (0)
		
		;Error Numbers
		E_ERROR_LOGGED  				EQU -1
		E_NO_ERROR 			    		EQU 0
		E_INVALID_SLOT 		    		EQU 1
		E_INVALID_SLOT_SIZE     		EQU 2
        E_STORE_NULL            		EQU 3
        E_SLOT_NOT_OCCUPIED     		EQU 4
        E_SLOT_NOT_INSTANTIATED 		EQU 5
        E_INSUFFICIENT_MEMORY   		EQU 6
        E_FRAMING_ERROR         		EQU 7
        E_MID_BAD_BOUNDS        		EQU 8
        E_DELETE_BAD_LENGTH				EQU 9
        E_DELETE_BAD_POSITION			EQU 10
        E_DELETE_BEYOND_END				EQU 11
        E_INSERT_BAD_POSITION			EQU 12
        E_COMPARE_SLOT_NOT_INSTANTIATED EQU 13
        E_COMPARE_SLOT_NOT_OCCUPIED 	EQU 14
        E_COMPARE_LENGTH_DIFFERENT 		EQU 15
        E_COMPARE_DATA_DIFFERENT 		EQU 16
        E_SCAN_START_BEYOND_END	 		EQU 17
        E_FILE_NOT_FOUND	     		EQU 18
        E_FILE_NOT_READ			 		EQU 19
        E_BROKEN_SURROGATE_PAIR	 		EQU 20
        E_TRAILING_HIGH_SURROGATE 		EQU 21
        E_LEADING_LOW_SURROGATE  		EQU 22
        E_TRAILING_BYTE					EQU 23
        E_MOVE_SELF_TO_SELF				EQU 24
        E_WRITEFILE_NO_FILENAME			EQU 25
        E_WRITEFILE_NOTHING_WRITTEN		EQU 26
        E_WRITEUNICODEFILE_CONVERSION_ERROR \
        								EQU 27
        								
		MSG_NO_ERROR		        		DB "No error",0
		MSG_INVALID_SLOT	        		DB "Bad slot number",0
		MSG_INVALID_SLOT_SIZE	    		DB "Bad slot size", 0
		MSG_STORE_NULL              		DB "Nothing to store",0
		MSG_SLOT_NOT_OCCUPIED       		DB "Slot not occupied",0
        MSG_SLOT_NOT_INSTANTIATED   		DB "Slot not instantiated",0
        MSG_INSUFFICIENT_MEMORY     		DB "Insufficient memory",0
        MSG_FRAMING_ERROR           		DB "Framing error",0
        MSG_MID_BAD_BOUNDS          		DB "Mid position beyond length", 0
		MSG_DELETE_BAD_LENGTH				DB "Delete length too large or small",0	
        MSG_DELETE_BAD_POSITION				DB "Delete position too low or high",0
        MSG_DELETE_BEYOND_END				DB "Delete start beyond end",0
        MSG_INSERT_BAD_POSITION				DB "Insert position too low",0
        MSG_COMPARE_SLOT_NOT_INSTANTIATED 	DB "Slot not instantiated", 0
        MSG_COMPARE_SLOT_NOT_OCCUPIED 		DB "Slot not occupied", 0
        MSG_COMPARE_LENGTH_DIFFERENT  		DB "Slot has a different text length to the reference slot",0
        MSG_COMPARE_DATA_DIFFERENT  		DB "Slot different from reference slot",0
        MSG_SCAN_START_BEYOND_END			DB "Scan started beyond end of text",0
        MSG_FILE_NOT_FOUND					DB "File not found", 0
        MSG_FILE_NOT_READ					DB "File not read",0
        MSG_BROKEN_SURROGATE_PAIR			DB "High surrogate missing following low surrogate", 0d
        MSG_TRAILING_HIGH_SURROGATE 		DB "High surrogate is last character", 0d
        MSG_LEADING_LOW_SURROGATE 			DB "Low surrogate lacks leading high surrogate",0d
        MSG_TRAILING_BYTE					DB "Uneven number of bytes in slot", 0d
        MSG_MOVE_SELF_TO_SELF				DB "Moving a slot to itself destroys the slot", 0d
        MSG_WRITEFILE_NO_FILENAME			DB "No filename to write to", 0d
        MSG_WRITEFILE_NOTHING_WRITTEN		DB "No bytes written", 0d
        MSG_WRITEUNICODEFILE_CONVERSION_ERROR \
        									DB "Conversion error", 0d
        									
        ErrorMessages	DD 	MSG_NO_ERROR
						DD 	MSG_INVALID_SLOT
						DD 	MSG_INVALID_SLOT_SIZE
                        DD 	MSG_STORE_NULL
                        DD 	MSG_SLOT_NOT_OCCUPIED
                        DD 	MSG_SLOT_NOT_INSTANTIATED
                        DD 	MSG_INSUFFICIENT_MEMORY
                        DD 	MSG_FRAMING_ERROR
                        DD 	MSG_MID_BAD_BOUNDS
                        DD 	MSG_DELETE_BAD_LENGTH 
        				DD 	MSG_DELETE_BAD_POSITION
        				DD 	MSG_DELETE_BEYOND_END
        				DD  MSG_INSERT_BAD_POSITION
        				DD	MSG_COMPARE_SLOT_NOT_INSTANTIATED
        				DD	MSG_COMPARE_SLOT_NOT_OCCUPIED
						DD  MSG_COMPARE_LENGTH_DIFFERENT
						DD  MSG_COMPARE_DATA_DIFFERENT
						DD	MSG_SCAN_START_BEYOND_END
        				DD	MSG_FILE_NOT_FOUND
        				DD  MSG_FILE_NOT_READ
        				DD	MSG_BROKEN_SURROGATE_PAIR
        				DD	MSG_TRAILING_HIGH_SURROGATE
        				DD	MSG_LEADING_LOW_SURROGATE
        				DD  MSG_TRAILING_BYTE
        				DD  MSG_MOVE_SELF_TO_SELF
        				DD 	MSG_WRITEFILE_NO_FILENAME
        				DD  MSG_WRITEFILE_NOTHING_WRITTEN
        				DD  MSG_WRITEUNICODEFILE_CONVERSION_ERROR
        																
