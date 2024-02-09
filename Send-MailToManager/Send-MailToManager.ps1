function Send-MailToManager {

	param (
		[string]$To,
		[string]$From,
		[string]$CC,
		[string]$Subject,
		[string]$Body,
		[string]$SmtpServer,
		[int]$Port,
		[bool]$UseSSL
	)

Send-MailMessage -To $To -From $From -CC $CC -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SmtpServer -Port $Port -UseSsl $UseSSL

}
