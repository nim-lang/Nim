@echo off
rem build development version of the compiler; can be rerun safely
rmdir csources /S /Q
git clone --depth 1 https://github.com/nim-lang/csources.git
cd csources
if PROCESSOR_ARCHITECTURE == AMD64 (
  SET ARCH=64
)
CALL build.bat
cd ..
bin\nim c koch
koch boot -d:release
koch tools