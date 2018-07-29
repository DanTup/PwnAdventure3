// Compile with
//    cl /EHsc hack_echo.cpp /LD echo_lib.obj C:\Users\danny\Desktop\Detours-4.0.1\Detours-4.0.1\lib.X86\detours.lib

#define _X86_
#include <iostream>
#include <string>
#include <windows.h>
#include <fstream>
#include "..\\detours\\include\\detours.h"
#include "GameLogic.h"
#define DllExport __declspec(dllexport)

std::ofstream myfile;

class CDetour /* add ": public CGameApi" to enable access to member variables... */
{
  public:
    int Mine_GetTeamPlayerCount(void);
    static int (CDetour::*Real_GetTeamPlayerCount)(void);

    // Class shouldn't have any member variables or virtual functions.
};

int CDetour::Mine_GetTeamPlayerCount(void)
{
    return 123;
    //return (this->*Real_GetTeamPlayerCount)();
}

int (CDetour::*CDetour::Real_GetTeamPlayerCount)(void) = (int (CDetour::*)(void)) & GameAPI::GetTeamPlayerCount;

DllExport BOOL DllMain(HINSTANCE hinst, DWORD dwReason, LPVOID reserved)
{
    int (GameAPI::*pfTarget)(void) = &GameAPI::GetTeamPlayerCount;
    int (CDetour::*pfMine)(void) = &CDetour::Mine_GetTeamPlayerCount;

    DetourTransactionBegin();
    DetourUpdateThread(GetCurrentThread());
    DetourAttach(&(PVOID &)CDetour::Real_GetTeamPlayerCount, *(PBYTE *)&pfMine);
    DetourTransactionCommit();

    return TRUE;
}
