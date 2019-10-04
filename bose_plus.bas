Attribute VB_Name = "Module1"
Sub Main()
    Const sData As String = "+AKM-1 +ZeVnLIqe- Hi Mom -+Jjo--! A+ImIDkQ."
    Dim i As New COMlibiconv.Converters
    Dim b As Boolean

    'Debug.Print i.Aliases(0)
    'Debug.Print i.IsEnc("1")
    'Debug.Print i.ErrorString
    'Debug.Print i.ErrorCode
    
    ChDir "p:\BOSE_PLUS"
    SESetSlot 1
    SEStore StrPtr(StrConv("my dog has fleas", vbFromUnicode))
    'Debug.Print SEIsEncoding(StrPtr("US-ASCII"))
    
    b = SEUnicodeFileUU(StrPtr("US-ASCII"), StrPtr("utf7.out"), False)
    b = SEUnicodeFileUA(StrPtr("US-ASCII"), "utf7.out", False)
    Dim s As String
    s = i.ConvertToUnicode("UTF-7", sData)
    
    Debug.Print i.ConvertToUnicodeFile("UTF-7", sData, "utf7.out")
    Debug.Print i.ConvertToMultibyteFile("UTF-7", s, "utf7a.out")
    'Debug.Print b
    'SEDump
End Sub
