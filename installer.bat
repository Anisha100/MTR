curl https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe -o C:/test/installer.exe 
cd C:/test
REM installer.exe 
START installer.exe /passive PrependPath=1 Include_pip=1 InstallAllUsers=1
