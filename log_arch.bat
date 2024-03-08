@echo off
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
mkdir C:/test/Archive_folder
mv C:/test/log.txt C:/test/Archive_folder/log.txt
ren C:test/Archive_folder/log.txt log-%mydate%.txt













