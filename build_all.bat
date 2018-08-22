rem "build from source on windows"

@echo off
echo requires `gcc` in your PATH
echo one way is via calling finish.exe in command prompt after installing via
echo https://nim-lang.org/install_windows.html
echo you can also use something like this
echo set path="%%path%%;C:\Users\User\pathto\nim-0.18.0_x64\nim-0.18.0\dist\mingw64\bin\"
echo
echo note: this won't work if it's in a networked drive
echo eg if using parallels on OSX, don't use a parallels shared folder, use C:\
echo
echo use "echo on" for debugging

rem  lifetime of the environment will end with the termination of the batch
setlocal

echo "checks that gcc in PATH:"
gcc -v
IF %ERRORLEVEL% neq 0 (GOTO:END)

IF EXIST csources\ (
  echo "csources already exists"
) ELSE (
  git clone --depth 1 https://github.com/nim-lang/csources.git
  IF %ERRORLEVEL% neq 0 (GOTO:END)
)

rem this didn't work in command prompt:
rem https://stackoverflow.com/questions/12322308/batch-file-to-check-64bit-or-32bit-os
rem reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT

rem https://stackoverflow.com/questions/601089/detect-whether-current-windows-version-is-32-bit-or-64-bit
if defined ProgramFiles(x86) (
  set OS=64BIT
) ELSE (
  set OS=32BIT
)

echo %OS%
if %OS% == 64BIT (
  set buildfilename=.\build64.bat
) ELSE (
  set buildfilename=.\build.bat
  echo "OS not recognized"
)

IF EXIST .\bin\nim.exe (
  echo skipping csources\build
) ELSE (
  cd csources
  IF %ERRORLEVEL% neq 0 (GOTO:END)
  rem %buildfilename%
  %buildfilename%
  IF %ERRORLEVEL% neq 0 (GOTO:END)
  cd ..
)

bin\nim c koch
IF %ERRORLEVEL% neq 0 (GOTO:END)
koch boot -d:release
IF %ERRORLEVEL% neq 0 (GOTO:END)

rem Compile Nimble and other tools
koch tools
IF %ERRORLEVEL% neq 0 (GOTO:END)

:END
IF %ERRORLEVEL% neq 0 (
    ECHO FAILURE
) ELSE (
    ECHO SUCCESS
)

rem: "TODO: error code seems ignored in command prompt"
exit /b %ERRORLEVEL%
