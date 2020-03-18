@echo off
for %%i in (nim.exe) do (set NIM_BIN=%%~dp$PATH:i)

for %%i in ("%NIM_BIN%\..\") do (set NIM_ROOT=%%~fi)

set @GDB_PYTHON_MODULE_PATH=%NIM_ROOT%\tools\nim-gdb.py
set @NIM_GDB=gdb.exe

%@NIM_GDB% -eval-command="source  %@GDB_PYTHON_MODULE_PATH%" %*

EXIT /B %ERRORLEVEL%
@echo on
