REM - Run the full testsuite;  tests\testament\tester all

REM - Uncomment the list of changes in news.txt
REM - write a news ticker entry
REM - Update the version

REM - Generate the full docs;  koch web0
REM - Generate the installers;
REM - Update the version in system.nim
REM - Test the installers
REM - Tag the release
REM - Merge devel into master
REM - Update csources

set NIMVER=0.14.3

Rem Build -docs file:
koch web0
cd web\upload
7z a -tzip docs-%NIMVER%.zip *.html
move /y docs-%NIMVER%.zip download
cd ..\..

Rem Build .zip file:
rem koch csources -d:release
rem koch xz -d:release
rem move /y build\nim-%NIMVER%.zip web\upload\download

ReM Build Win32 version:

set PATH=C:\Users\araq\projects\mingw32\bin;%PATH%
cd build
call build.bat
cd ..
nim c koch || exit /b
koch boot -d:release || exit /b
cd ..\nimsuggest
nim c -d:release --noNimblePath --path:..\nim  nimsuggest || exit /b
copy /y nimsuggest.exe ..\nim\bin || exit /b
cd ..\nim
koch nsis -d:release || exit /b
move /y build\nim_%NIMVER%.exe web\upload\download\nim-%NIMVER%_x32.exe || exit /b


ReM Build Win64 version:
set PATH=C:\Users\araq\projects\mingw64\bin;%PATH%
cd build
call build64.bat
cd ..
nim c koch || exit /b
koch boot -d:release || exit /b
cd ..\nimsuggest
nim c -d:release --noNimblePath --path:..\nim  nimsuggest || exit /b
copy /y nimsuggest.exe ..\nim\bin || exit /b
cd ..\nim
koch nsis -d:release || exit /b
move /y build\nim_%NIMVER%.exe web\upload\download\nim-%NIMVER%_x64.exe || exit /b
