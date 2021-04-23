@echo off
rem build development version of the compiler; can be rerun safely
rem TODO: call nimBuildCsourcesIfNeeded or auto-generate this file (from a nim script)
rem to avoid duplication.
if not exist csources_v1 (
  git clone --depth 1 https://github.com/nim-lang/csources_v1.git
)
if not exist bin\nim.exe (
  cd csources_v1
  git checkout a8a5241f9475099c823cfe1a5e0ca4022ac201ff
  if PROCESSOR_ARCHITECTURE == AMD64 (
    SET ARCH=64
  )
  CALL build.bat
  cd ..
)
bin\nim.exe c --skipUserCfg --skipParentCfg koch
koch.exe boot -d:release --skipUserCfg --skipParentCfg
koch.exe tools --skipUserCfg --skipParentCfg

