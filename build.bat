
if not exist "csources"(
	git clone --depth 1 https://github.com/nim-lang/csources.git
)

cd "csources"

for /f "skip=1 delims=" %%x in ('wmic cpu get addresswidth') do if not defined AddressWidth set AddressWidth=%%x
if %AddressWidth%==64 (
	call build64.bat
) else (
	call build.bat
)

cd ".."

./bin/nim c koch
./koch boot -d:release

xcopy /Y install.bat.template install.bat

pause