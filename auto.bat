"c:\Program Files\Oracle\VirtualBox\VBoxManage.exe"  controlvm  EOSOS poweroff

mingw32-make clean
mingw32-make all
if %errorlevel% neq 0 goto exception
"c:\Program Files\Oracle\VirtualBox\VBoxManage.exe"  startvm "EOSOS"
exit
:exception	
	pause
	exit /b %errorlevel%