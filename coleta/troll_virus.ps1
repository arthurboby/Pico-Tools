# Abre o CMD em tela cheia com efeito Matrix
Start-Process cmd -ArgumentList "/c color 0a & title SYSTEM_OVERRIDE & mode con: cols=120 lines=40 & :a & echo %random%%random%%random%%random% & goto a"
# Para dar o susto final, a placa envia um ALT+ENTER (que deixa o CMD em tela cheia)
$wshell = New-Object -ComObject WScript.Shell
$wshell.SendKeys('%{ENTER}')
