;-===========================================================================-
;
; Generated .INC file (by Tlb2Inc v1.2.3 - Copyright (c) 2001 Maurice MONTGENIE)
;
; TypeLib filename: COMlibiconv.tlb
;
;-===========================================================================-

IFNDEF _COMlibiconv_INC_
_COMlibiconv_INC_ EQU 1

;Library : COMlibiconv
;~~~~~~~~~~~~~~~~~~~~~
;{55B7D56A-C63A-4B39-9833-A2925972CA96}
sLIBID_COMlibiconv TEXTEQU <{055B7D56AH, 0C63AH, 04B39H, {098H, 033H, 0A2H, 092H, 059H, 072H, 0CAH, 096H}}>

;CoClass : Converters
;~~~~~~~~~~~~~~~~~~
;{0CF7C6A0-981D-4C2C-A74C-26DD713C22BE}
sCLSID_Converters TEXTEQU <{00CF7C6A0H, 0981DH, 04C2CH, {0A7H, 04CH, 026H, 0DDH, 071H, 03CH, 022H, 0BEH}}>

;DispInterface : IConverters
;~~~~~~~~~~~~~~~~~~~~~~~
;{8DD3E3E3-5DF7-4BA8-8C00-2D22DEFF8190}
sIID_IConverters TEXTEQU <{08DD3E3E3H, 05DF7H, 04BA8H, {08CH, 000H, 02DH, 022H, 0DEH, 0FFH, 081H, 090H}}>

IConverters_ConvertToUnicodeProto typedef proto IConverters_ConvertToUnicodeProto :DWORD,:DWORD,:DWORD,:SDWORD,:SDWORD,:DWORD
IConverters_get_ErrorCodeProto typedef proto IConverters_get_ErrorCodeProto :DWORD,:DWORD
IConverters_get_SuccessProto typedef proto IConverters_get_SuccessProto :DWORD,:DWORD
IConverters_get_CountProto typedef proto IConverters_get_CountProto :DWORD,:DWORD
IConverters_AliasesProto typedef proto IConverters_AliasesProto :DWORD,:SDWORD,:DWORD
IConverters_CNamesProto typedef proto IConverters_CNamesProto :DWORD,:SDWORD,:DWORD
IConverters_AliasKeysProto typedef proto IConverters_AliasKeysProto :DWORD,:DWORD
IConverters_AliasDictionaryProto typedef proto IConverters_AliasDictionaryProto :DWORD,:DWORD
IConverters_get_ErrorStringProto typedef proto IConverters_get_ErrorStringProto :DWORD,:DWORD
IConverters_ConvertToMultibyteProto typedef proto IConverters_ConvertToMultibyteProto :DWORD,:DWORD,:DWORD,:SDWORD,:SDWORD,:DWORD
IConverters_CheckConversionProto typedef proto IConverters_CheckConversionProto :DWORD,:DWORD,:DWORD,:SDWORD,:WORD,:DWORD
IConverters_get_CharactersConsumedProto typedef proto IConverters_get_CharactersConsumedProto :DWORD,:DWORD
IConverters_get_CharactersGeneratedProto typedef proto IConverters_get_CharactersGeneratedProto :DWORD,:DWORD
IConverters_GuessEncodingProto typedef proto IConverters_GuessEncodingProto :DWORD,:DWORD,:WORD,:DWORD,:DWORD
IConverters_VariantConvertToUnicodeProto typedef proto IConverters_VariantConvertToUnicodeProto :DWORD,:DWORD,:VARIANT,:SDWORD,:SDWORD,:DWORD
IConverters_VariantConvertToMultibyteProto typedef proto IConverters_VariantConvertToMultibyteProto :DWORD,:DWORD,:DWORD,:SDWORD,:SDWORD,:DWORD
IConverters_VariantCheckConversionProto typedef proto IConverters_VariantCheckConversionProto :DWORD,:DWORD,:VARIANT,:SDWORD,:WORD,:DWORD
IConverters_VariantGuessEncodingProto typedef proto IConverters_VariantGuessEncodingProto :DWORD,:VARIANT,:WORD,:DWORD,:DWORD
IConverters_VariantConvertToMultibyteBufferedProto typedef proto IConverters_VariantConvertToMultibyteBufferedProto :DWORD,:DWORD,:DWORD,:SDWORD,:SDWORD,:DWORD
IConverters_VariantConvertToMultibyteBufferProto typedef proto IConverters_VariantConvertToMultibyteBufferProto :DWORD,:SDWORD,:DWORD
IConverters_IetfToUTF8Proto typedef proto IConverters_IetfToUTF8Proto :DWORD,:DWORD,:DWORD
IConverters_get_LoggingProto typedef proto IConverters_get_LoggingProto :DWORD,:DWORD
IConverters_put_LoggingProto typedef proto IConverters_put_LoggingProto :DWORD,:WORD
IConverters_IsEncProto typedef proto IConverters_IsEncProto :DWORD,:VARIANT,:DWORD
IConverters_get_LogDirectoryProto typedef proto IConverters_get_LogDirectoryProto :DWORD,:DWORD
IConverters_put_LogDirectoryProto typedef proto IConverters_put_LogDirectoryProto :DWORD,:VARIANT

IConverters_ConvertToUnicodeVal typedef ptr IConverters_ConvertToUnicodeProto
IConverters_get_ErrorCodeVal typedef ptr IConverters_get_ErrorCodeProto
IConverters_get_SuccessVal typedef ptr IConverters_get_SuccessProto
IConverters_get_CountVal typedef ptr IConverters_get_CountProto
IConverters_AliasesVal typedef ptr IConverters_AliasesProto
IConverters_CNamesVal typedef ptr IConverters_CNamesProto
IConverters_AliasKeysVal typedef ptr IConverters_AliasKeysProto
IConverters_AliasDictionaryVal typedef ptr IConverters_AliasDictionaryProto
IConverters_get_ErrorStringVal typedef ptr IConverters_get_ErrorStringProto
IConverters_ConvertToMultibyteVal typedef ptr IConverters_ConvertToMultibyteProto
IConverters_CheckConversionVal typedef ptr IConverters_CheckConversionProto
IConverters_get_CharactersConsumedVal typedef ptr IConverters_get_CharactersConsumedProto
IConverters_get_CharactersGeneratedVal typedef ptr IConverters_get_CharactersGeneratedProto
IConverters_GuessEncodingVal typedef ptr IConverters_GuessEncodingProto
IConverters_VariantConvertToUnicodeVal typedef ptr IConverters_VariantConvertToUnicodeProto
IConverters_VariantConvertToMultibyteVal typedef ptr IConverters_VariantConvertToMultibyteProto
IConverters_VariantCheckConversionVal typedef ptr IConverters_VariantCheckConversionProto
IConverters_VariantGuessEncodingVal typedef ptr IConverters_VariantGuessEncodingProto
IConverters_VariantConvertToMultibyteBufferedVal typedef ptr IConverters_VariantConvertToMultibyteBufferedProto
IConverters_VariantConvertToMultibyteBufferVal typedef ptr IConverters_VariantConvertToMultibyteBufferProto
IConverters_IetfToUTF8Val typedef ptr IConverters_IetfToUTF8Proto
IConverters_get_LoggingVal typedef ptr IConverters_get_LoggingProto
IConverters_put_LoggingVal typedef ptr IConverters_put_LoggingProto
IConverters_IsEncVal typedef ptr IConverters_IsEncProto
IConverters_get_LogDirectoryVal typedef ptr IConverters_get_LogDirectoryProto
IConverters_put_LogDirectoryVal typedef ptr IConverters_put_LogDirectoryProto

  _vtIConverters MACRO CastName:REQ
  ; IDispatch methods
  _vtIDispatch CastName
  ; IConverters methods
  &CastName&_ConvertToUnicode IConverters_ConvertToUnicodeVal ?
  &CastName&_get_ErrorCode IConverters_get_ErrorCodeVal ?
  &CastName&_get_Success IConverters_get_SuccessVal ?
  &CastName&_get_Count IConverters_get_CountVal ?
  &CastName&_Aliases IConverters_AliasesVal ?
  &CastName&_CNames IConverters_CNamesVal ?
  &CastName&_AliasKeys IConverters_AliasKeysVal ?
  &CastName&_AliasDictionary IConverters_AliasDictionaryVal ?
  &CastName&_get_ErrorString IConverters_get_ErrorStringVal ?
  &CastName&_ConvertToMultibyte IConverters_ConvertToMultibyteVal ?
  &CastName&_CheckConversion IConverters_CheckConversionVal ?
  &CastName&_get_CharactersConsumed IConverters_get_CharactersConsumedVal ?
  &CastName&_get_CharactersGenerated IConverters_get_CharactersGeneratedVal ?
  &CastName&_GuessEncoding IConverters_GuessEncodingVal ?
  &CastName&_VariantConvertToUnicode IConverters_VariantConvertToUnicodeVal ?
  &CastName&_VariantConvertToMultibyte IConverters_VariantConvertToMultibyteVal ?
  &CastName&_VariantCheckConversion IConverters_VariantCheckConversionVal ?
  &CastName&_VariantGuessEncoding IConverters_VariantGuessEncodingVal ?
  &CastName&_VariantConvertToMultibyteBuffered IConverters_VariantConvertToMultibyteBufferedVal ?
  &CastName&_VariantConvertToMultibyteBuffer IConverters_VariantConvertToMultibyteBufferVal ?
  &CastName&_IetfToUTF8 IConverters_IetfToUTF8Val ?
  &CastName&_get_Logging IConverters_get_LoggingVal ?
  &CastName&_put_Logging IConverters_put_LoggingVal ?
  &CastName&_IsEnc IConverters_IsEncVal ?
  &CastName&_get_LogDirectory IConverters_get_LogDirectoryVal ?
  &CastName&_put_LogDirectory IConverters_put_LogDirectoryVal ?

ENDM

IConverters STRUCT
  _vtIConverters IConverters
IConverters ENDS

ENDIF