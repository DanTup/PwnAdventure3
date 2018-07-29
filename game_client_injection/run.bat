SET VS_TOOLS="C:\Program Files (x86)\Microsoft Visual Studio\Preview\Community\Common7\Tools\VsDevCmd.bat"
SET GAME_PATH="M:\Games\PwnAdventure3\PwnAdventure3_Data\PwnAdventure3\PwnAdventure3\Binaries\Win32\PwnAdventure3-Win32-Shipping.exe"

pushd "%~dp0"
call %VS_TOOLS%
popd

lib /def:GameLogic.def /out:GameLogic.lib
cl /EHsc game_enhancements.cpp /LD /link GameLogic.lib ..\detours\lib.X86\detours.lib
..\detours\bin.X86\withdll.exe /d:game_enhancements.dll %GAME_PATH%
