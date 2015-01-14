
if not exist "csources"(
	git clone --depth 1 https://github.com/nim-lang/csources.git
)

cd "csources"
if exist "C:\Program Files (x86)" (
	call build64.bat
) else (
	call build.bat
)

cd ".."

./bin/nim c koch
./koch boot -d:release

xcopy /Y install.bat.template install.bat

pause