@echo off
set FILENAME=%1
set UNIXNAME=%FILENAME:\=/%
bash -i -c "issue.sh %UNIXNAME%"
pause
