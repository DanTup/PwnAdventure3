rem Set up PATH for the C++ tools.
call "C:\Program Files (x86)\Microsoft Visual Studio\Preview\Community\Common7\Tools\VsDevCmd.bat"

rem Set cwd back (the .bat above changes the dir).
cd "%~dp0"

rem Build a /lib file from our .def that we can link against.
lib /def:GameLogic.def /out:GameLogic.lib

rem Compile our "enhancements" DLL using the lib created and above and MS Detours.
cl /EHsc game_enhancements.cpp /LD /link GameLogic.lib ..\detours\lib.X86\detours.lib

rem This is handled in the launch config now.
rem SET GAME_PATH="M:\Games\PwnAdventure3\PwnAdventure3_Data\PwnAdventure3\PwnAdventure3\Binaries\Win32\PwnAdventure3-Win32-Shipping.exe"
rem ..\detours\bin.X86\withdll.exe /d:game_enhancements.dll %GAME_PATH%
