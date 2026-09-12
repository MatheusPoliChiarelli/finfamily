Set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = "C:\users\matheus\desktop\Projetos\finfamily\finfamily\build\web"
shell.Run "python -m http.server 8085", 0, False
WScript.Sleep 1200
shell.Run "chrome.exe --app=http://localhost:8085 --window-size=1600,1000"