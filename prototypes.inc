    ; ----------------------------------------
    ; prototypes for local procedures go here
    ; ----------------------------------------
	SEAppend                        	PROTO	:DWORD
	SEAppendFrom						PROTO	:DWORD
	SECharacterDistribution				PROTO
	SECompare                       	PROTO	:DWORD, :DWORD
	SECopySlot							PROTO	:DWORD, :DWORD
	SECountStack						PROTO
	SEDelete                        	PROTO	:DWORD, :DWORD
	SEDump                          	PROTO
	SEEmptyStack						PROTO
	SEForget                        	PROTO	:DWORD
	SEFrame                         	PROTO	:DWORD, :DWORD
	SEGetGlobalSlotSize             	PROTO
	SEGetSlot                       	PROTO
	SEHexDump							PROTO
	SEInsert                        	PROTO	:DWORD, :DWORD
	SEInsertFrom						PROTO	:DWORD, :DWORD
	SELeft                          	PROTO	:DWORD
	SELength	                    	PROTO
	SELengthOf                        	PROTO 	:DWORD
	SEMessage							PROTO	:DWORD
	SEMessage2							PROTO	
	SEMid                           	PROTO	:DWORD, :DWORD
	SEMoveSlot							PROTO	:DWORD, :DWORD
	SEPop								PROTO
	SEPrepend                       	PROTO	:DWORD
	SEPrependFrom						PROTO	:DWORD
	SERawHex							PROTO
	SEReadFile							PROTO	:DWORD, :DWORD
	SERecall                        	PROTO	:DWORD
	SERecallLMR                  		PROTO	:DWORD
	SERecallString						PROTO	
	SEResetLMR							PROTO
	SEReverseBytes						PROTO
	SEReverseWords						PROTO
	SERight                         	PROTO	:DWORD
	SESetGlobalSlotSize             	PROTO	:DWORD
	SESetSlot                       	PROTO	:DWORD
	SEStatus                        	PROTO	:DWORD
	SEStore                         	PROTO	:DWORD
	SESwapSlot							PROTO	:DWORD, :DWORD
	SEUTF16Scan                        	PROTO	:DWORD
	SEWriteFile                        	PROTO	:DWORD
SEWriteMultibyteFile            	PROTO	:DWORD,:DWORD
SEWriteMultibyteFileAA          	PROTO	:DWORD,:DWORD
SEWriteMultibyteFileAU          	PROTO	:DWORD,:DWORD
SEWriteMultibyteFileUA          	PROTO	:DWORD,:DWORD
SEWriteMultibyteFileUU          	PROTO	:DWORD,:DWORD
SEWriteUnicodeFile              	PROTO	:DWORD,:DWORD,:DWORD
SEWriteUnicodeFileAA            	PROTO	:DWORD,:DWORD,:DWORD
SEWriteUnicodeFileAU            	PROTO	:DWORD,:DWORD,:DWORD
SEUnicodeFileUA            	PROTO	:DWORD,:DWORD,:DWORD
SEUnicodeFileUU            	PROTO	:DWORD,:DWORD,:DWORD

	
	;Internal functions
	CalculateAndAllocate				PROTO	:DWORD, :DWORD
	Compare_CheckReferenceSlot			PROTO	:DWORD
	Compare_CheckTargetSlots			PROTO	:DWORD, :DWORD
	CopyAndOrForget						PROTO	:DWORD, :DWORD, :DWORD
	Instantiate							PROTO	:DWORD
	Log_Error							PROTO	:DWORD, :DWORD, :DWORD, :DWORD
	Set_Error							PROTO	:DWORD
	SpaceAtBase                     	PROTO
	SpaceToTop                      	PROTO
	Verify								PROTO
	WillFitAtBase                   	PROTO	:DWORD
	WillFitAtTop                    	PROTO	:DWORD

