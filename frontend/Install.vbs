Set objShell = CreateObject("Wscript.Shell")
strPath = CreateObject("Scripting.FileSystemObject").GetAbsolutePathName(".")
objShell.Run "cmd /c """ & strPath & "\Easy Install.bat""", 0, True