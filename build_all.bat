@echo off
rem Build development version of the compiler; can be rerun safely
rem bare bones version of ci/funs.sh adapted for windows.

rem Read in some common shared variables (shared with other tools),
rem see https://stackoverflow.com/questions/3068929/how-to-read-file-contents-into-a-variable-in-a-batch-file
for /f "delims== tokens=1,2" %%G in (config/build_config.txt) do set %%G=%%H
SET nim_csources=bin\nim_csources_%nim_csourcesHash%.exe
echo "building from csources" 
echo %nim_csources%

if not exist %nim_csourcesDir% (
  git clone -q --depth 1 %nim_csourcesUrl% %nim_csourcesDir%
)

if not exist %nim_csources% (
  cd %nim_csourcesDir%
  git checkout %nim_csourcesHash%
  if PROCESSOR_ARCHITECTURE == AMD64 (
    SET ARCH=64
  )
  CALL build.bat
  cd ..
  cp bin\nim.exe  %nim_csources%
)

if "%nim_build_all_only_csources%"=="" (
  echo "skipping building koch and tools"
) else (
  echo "building koch and tools"
  bin\nim.exe c --skipUserCfg --skipParentCfg --hints:off koch
  koch.exe boot -d:release --skipUserCfg --skipParentCfg --hints:off
  koch.exe tools --skipUserCfg --skipParentCfg --hints:off
)
