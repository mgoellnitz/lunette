@echo off
set FILENAME=%*
set UNIXNAME=%FILENAME:\=/%
set UNIXNAME=%UNIXNAME: =___%
bash -i -c "issue.sh %UNIXNAME%"
pause
