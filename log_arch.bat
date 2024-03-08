@echo off
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
md C:/test/Archive_folder
move C:/test/log.txt C:/test/Archive_folder/log.txt
ren C:test/Archive_folder/log.txt log-%mydate%.txt













