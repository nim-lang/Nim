REM Some debug info
echo "Running on %CI_RUNNER_ID% (%CI_RUNNER_DESCRIPTION%) with tags %CI_RUNNER_TAGS%."
gcc -v

git clone --depth 1 https://github.com/nim-lang/csources_v1.git csources
cd csources
call build64.bat
cd ..
set PATH=%CD%\bin;%PATH%
nim -v
nim c koch
koch.exe boot
copy bin/nim bin/nimd
koch.exe boot -d:release
