echo "build from source on windows"

rem requires `gcc` in your PATH
rem one way is via calling finish.exe in command prompt after installing via
rem https://nim-lang.org/install_windows.html
rem note: this won't work if it's in a networked drive
rem eg if using parallels on OSX, don't use a parallels shared folder, use C:\

rem better to be verbose, for debugging purposes

@echo on

rem  lifetime of the environment will end with the termination of the batch
setlocal

echo "checks that gcc in PATH:"
gcc -v
IF ERRORLEVEL 1 (GOTO:END)

IF EXIST csources\ (
  echo "csources already exists"
) ELSE (
  git clone --depth 1 https://github.com/nim-lang/csources.git
  IF ERRORLEVEL 1 (GOTO:END)
)

rem https://stackoverflow.com/questions/12322308/batch-file-to-check-64bit-or-32bit-os

reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT
IF ERRORLEVEL 1 (GOTO:END)

echo %OS%
if %OS%==64BIT (
  set buildfilename=.\build64.bat
) ELSE (
  set buildfilename=.\build.bat
  echo "OS not recognized"
)

IF EXIST .\bin\nim.exe (
  echo skipping csources\build
) ELSE (
  cd csources
  IF ERRORLEVEL 1 (GOTO:END)
  rem %buildfilename%
  %buildfilename%
  IF ERRORLEVEL 1 (GOTO:END)
  cd ..
)

bin\nim c koch
IF ERRORLEVEL 1 (GOTO:END)
koch boot -d:release
IF ERRORLEVEL 1 (GOTO:END)

rem Compile Nimble and other tools
koch tools
IF ERRORLEVEL 1 (GOTO:END)

:END
IF ERRORLEVEL 1 (
    ECHO FAILURE
) ELSE (
    ECHO SUCCESS
)
exit /b %ERRORLEVEL%
