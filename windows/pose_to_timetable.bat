@echo off
set FILENAME=%1
set UNIXNAME=%FILENAME:\=/%
bash -i -c "pose.sh -w %UNIXNAME%"
pause
