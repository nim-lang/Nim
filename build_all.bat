@echo off
rem build development version of the compiler; can be rerun safely but won't pickup
rem modifications in config/build_config.txt after 1st run, see build_all.sh for a way

rem read in some common shared variables (shared with other tools)
rem see https://stackoverflow.com/questions/3068929/how-to-read-file-contents-into-a-variable-in-a-batch-file
for /f "delims== tokens=1,2" %%G in (config/build_config.txt) do set %%G=%%H

if not exist csources (
  git clone -q --depth 1 --branch %nim_csources2_tag% %nim_csources2url% csources
)
if not exist bin\nim.exe (
  cd csources
  if PROCESSOR_ARCHITECTURE == AMD64 (
    SET ARCH=64
  )
  CALL build.bat
  cd ..
)
bin\nim.exe c --skipUserCfg --skipParentCfg --hints:off koch
koch.exe boot -d:release --skipUserCfg --skipParentCfg --hints:off
koch.exe tools --skipUserCfg --skipParentCfg --hints:off 

