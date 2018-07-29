SET VS_TOOLS="C:\Program Files (x86)\Microsoft Visual Studio\Preview\Community\Common7\Tools\VsDevCmd.bat"
SET GAME_PATH="M:\Games\PwnAdventure3\PwnAdventure3_Data\PwnAdventure3\PwnAdventure3\Binaries\Win32\PwnAdventure3-Win32-Shipping.exe"

call %VS_TOOLS%
cd "%~dp0"

lib /def:GameLogic.def /out:GameLogic.lib
cl /EHsc game_enhancements.cpp /LD /link GameLogic.lib ..\detours\lib.X86\detours.lib
rem This is handled in the launch config now.
rem ..\detours\bin.X86\withdll.exe /d:game_enhancements.dll %GAME_PATH%
