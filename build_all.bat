echo "build from source on windows"

rem requires `gcc` in your PATH
rem one way is via calling finish.exe in command prompt after installing via
rem https://nim-lang.org/install_windows.html
rem note: this won't work if it's in a networked drive
rem eg if using parallels on OSX, don't use a parallels shared folder, use C:\

rem better to be verbose, for debugging purposes
@echo on

echo "checks that gcc in PATH:"
gcc -v

IF EXIST csources\nul (
  echo "csources already exists"
) ELSE (
  git clone --depth 1 https://github.com/nim-lang/csources.git
)

rem nesting this inside an IF branch triggered a weird parsing error
rem https://stackoverflow.com/questions/601089/detect-whether-current-windows-version-is-32-bit-or-64-bit
if defined ProgramFiles(x86) (
  echo detected 64 bit
  set buildfilename=.\build64.bat
) ELSE (
  echo detected 32 bit
  set buildfilename=.\build.bat
)

IF EXIST .\bin\nim.exe (
  echo skipping csources\build
) ELSE (
  cd csources
  rem %buildfilename%
  %buildfilename%
  cd ..
)

bin\nim c koch
koch boot -d:release

rem Compile Nimble and other tools
koch tools
