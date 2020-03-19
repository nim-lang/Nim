@echo off
REM COLOR 0A
chcp 65001
SET NIMPATH=%~dp0\..
SET PATH=%NIMPATH%\bin;%NIMPATH%\dist\mingw\bin;%PATH%
cd %NIMPATH%
cmd 


