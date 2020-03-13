@echo off
rem build development version of the compiler; can be rerun safely
if not exist csources (
  git clone --depth 1 https://github.com/nim-lang/csources.git
)
if not exist bin\nim.exe (
  cd csources
  if PROCESSOR_ARCHITECTURE == AMD64 (
    SET ARCH=64
  )
  CALL build.bat
  cd ..
)
bin\nim.exe c --skipUserCfg --skipParentCfg koch
koch.exe boot -d:release --skipUserCfg --skipParentCfg
koch.exe tools --skipUserCfg --skipParentCfg

