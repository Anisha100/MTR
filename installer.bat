@echo Off
powercfg /h off
REM SCHTASKS /CREATE /SC DAILY /TN "MTRboot1" /TR "shutdown -l -f" /RU Skype /ST 02:45 /IT /F >> C:\installerlog.txt 
REM SCHTASKS /CREATE /SC DAILY /TN "MTRboot3" /TR "shutdown -r -f" /ST 03:00 /F >> C:\installerlog.txt 
echo "Completed MTRboot" >> C:\installerlog.txt 
REM SCHTASKS /CREATE /SC DAILY /TN "MTRboot4" /TR "logoff" /RU Skype /ST 07:45 /IT /F >> C:\installerlog.txt 
REM SCHTASKS /CREATE /SC DAILY /TN "MTRboot2" /TR "shutdown -r -f" /ST 08:00 /F >> C:\installerlog.txt 
echo "Completed MTRboot2" >> C:\installerlog.txt 
SCHTASKS /CREATE /TN "MTRlock1" /TR "pythonw C:/test/script.py" /RU Skype /SC ONLOGON /IT /F >> C:\installerlog.txt 
SCHTASKS /CREATE /TN "MTRlock" /TR "pythonw C:/test/script.py" /RU Skype /SC ONSTARTUP /IT /F >> C:\installerlog.txt
SCHTASKS /CREATE /TN "MTRarchive" /TR "C:/test/log_arch.bat" /SC weekly /d WED /F >> C:\installerlog.txt 
echo "Python running" >> C:\installerlog.txt 
rmdir "C:/test" /s /q >> C:\installerlog.txt 
md "C:/test" >> C:\installerlog.txt 
echo "Test folder made" >> C:\installerlog.txt 
curl https://anisha100.github.io/MTR/script.py -o C:/test/script.py >>  C:\installerlog.txt 
curl https://anisha100.github.io/MTR/checkall.bat -o C:/test/checkall.bat >>  C:\installerlog.txt 
curl https://anisha100.github.io/MTR/userlist.csv -o C:/test/userlist.csv >>  C:\installerlog.txt 
curl https://anisha100.github.io/MTR/img.png -o C:/test/img.png >>  C:\installerlog.txt 
curl https://anisha100.github.io/MTR/configfile.py -o C:/test/configfile.py >>  C:\installerlog.txt 
curl https://anisha100.github.io/MTR/log_arch.bat -o C:/test/log_arch.bat >>  C:\installerlog.txt 
curl https://anisha100.github.io/MTR/ScriptLaunch.ps1 -o C:/Rigel/x64/Provisioning/Scripts/ScriptLaunch.ps1 >>  C:\installerlog.txt 
curl https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe -o C:/test/installer.exe >>  C:\installerlog.txt 
echo "Test config comlete" >> C:\installerlog.txt 
cd "C:/test" >>  C:\installerlog.txt 
attrib +H script.py
START /wait installer.exe /passive PrependPath=1 Include_pip=1 InstallAllUsers=1 >>  C:\installerlog.txt 
echo "config file is present in C:/test/configfile.py" >>  C:\installerlog.txt 
shutdown -r -t 10 -c "This pc will restart for the update to work Installer log stored in C drive " -f >>  C:\installerlog.txt 
EXIT /B 0 
