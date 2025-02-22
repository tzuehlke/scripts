# Idea
* the Excel file contains a list of persons
  * for each person some basic information like firstname, lastname, ...
  * additional for each person an individual password
  * additional for each person an individual mail address
* the word documents using the excel list for mail merge
* the word document contains the macro `MailMergeSaveAsSinglePDFwithPWAndSendViaMail`, that does
  1. create for each person a individual pdf file
  2. encrypt each pdf file as new file with the command line tool [PDFtk Server](https://www.pdflabs.com/tools/pdftk-server/) (in subfolder `\pdftk`) by using the users individual password
  3. sending the encrypted pdf as mail attachment via function `SendEmailWithAttachment` with some text from the local outlook instance


# Macros
```vba
Sub MailMergeSaveAsSinglePDFwithPWAndSendViaMail()
    Dim i As Long
    Dim strFilenameDOCX As String
    Dim strFilenamePDF As String
    Dim strPassword As String
    Dim OUTPUTPATH As String
    Dim PDFENCRYPTPATH As String
    OUTPUTPATH = ActiveDocument.Path & "\output"
    PDFENCRYPTPATH = ActiveDocument.Path & "\pdftk\bin\pdftk.exe"
    Application.ScreenUpdating = False
    With ThisDocument.MailMerge
        .Destination = wdSendToNewDocument
        .SuppressBlankLines = True
        For i = 1 To .dataSource.RecordCount
            With .dataSource
                .FirstRecord = i
                .LastRecord = i
                .ActiveRecord = i
                strFilenamePDF = .DataFields("firstname").Value & "_" & .DataFields("lastname").Value
                strPassword = Trim(.DataFields("password").Value)
            End With
            .Execute Pause:=False
            With ActiveDocument
                .ExportAsFixedFormat OUTPUTPATH & "\" & strFilenamePDF & ".pdf", ExportFormat:=wdExportFormatPDF, UseISO19005_1:=False
                .Close False
            End With
            Shell (PDFENCRYPTPATH & " " & OUTPUTPATH & "\" & strFilenamePDF & ".pdf output " & OUTPUTPATH & "\" & strFilenamePDF & "_secured.pdf user_pw " & strPasswort & " allow AllFeatures")
            SendEmailWithAttachment .dataSource.DataFields("firstname").Value, .dataSource.DataFields("lastname").Value, .dataSource.DataFields("mail").Value, OUTPUTPATH & "\" & strFilenamePDF & "_secured.pdf"
        Next
        .dataSource.Close
    End With
    Application.ScreenUpdating = True
End Sub

Private Sub SendEmailWithAttachment(fn, ln, mail, filepath)
    Dim OutlookApp As Object
    Dim OutlookMail As Object
    Dim WordDoc As Object
    Dim AttachmentPath As String

    Set OutlookApp = CreateObject("Outlook.Application")
    Set OutlookMail = OutlookApp.CreateItem(olMailItem)
    AttachmentPath = filepath
    With OutlookMail
        .To = mail
        .Subject = "Personal File " & ln
        .Body = "Dear " & fn & " " & ln & ", " & vbCrLf & _
        "see the attached file. The password will be provided later." & vbCrLf & _
        "Kind regards "
        .Attachments.Add AttachmentPath
        .Send
    End With
    Set OutlookMail = Nothing
    Set OutlookApp = Nothing
End Sub
```