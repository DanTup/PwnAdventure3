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

class GameApiDetour /* add ": public GameApi" to enable access to member variables... */
{
  public:
    int Mine_GetTeamPlayerCount(void);
    static int (GameApiDetour::*Real_GetTeamPlayerCount)(void);

    void Mine_Login(char const *u, char const *p);
    static void (GameApiDetour::*Real_Login)(char const *, char const *);

    // Class shouldn't have any member variables or virtual functions.
};

int GameApiDetour::Mine_GetTeamPlayerCount(void)
{
    return 123;
    //return (this->*Real_GetTeamPlayerCount)();
}

void GameApiDetour::Mine_Login(char const *u, char const *p)
{
    // This ways user/pass during login.
    //(this->*Real_Login)(p, u);
    (this->*Real_Login)(u, p);
}

class PlayerDetour
{
  public:
    // float Mine_GetWalkingSpeed(void);
    // static float (PlayerDetour::*Real_GetWalkingSpeed)(void);

    BOOL Mine_CanJump(void);
    static BOOL (PlayerDetour::*Real_CanJump)(void);
};

// float PlayerDetour::Mine_GetWalkingSpeed(void)
// {
//     return 0.0f; // * (this->*Mine_GetWalkingSpeed)();
// }

BOOL PlayerDetour::Mine_CanJump(void)
{
    return true;
}

int (GameApiDetour::*GameApiDetour::Real_GetTeamPlayerCount)(void) = (int (GameApiDetour::*)(void)) & GameAPI::GetTeamPlayerCount;
void (GameApiDetour::*GameApiDetour::Real_Login)(char const *, char const *) = (void (GameApiDetour::*)(char const *, char const *)) & GameAPI::Login;
//float (PlayerDetour::*PlayerDetour::Real_GetWalkingSpeed)(void) = (float (PlayerDetour::*)(void)) & Player::GetWalkingSpeed;
BOOL (PlayerDetour::*PlayerDetour::Real_CanJump)
(void) = (BOOL(PlayerDetour::*)(void)) & Player::CanJump;

DllExport BOOL DllMain(HINSTANCE hinst, DWORD dwReason, LPVOID reserved)
{
    int (GameApiDetour::*pfMine_GetTeamPlayerCount)(void) = &GameApiDetour::Mine_GetTeamPlayerCount;
    void (GameApiDetour::*pfMine_Login)(char const *, char const *) = &GameApiDetour::Mine_Login;
    //float (PlayerDetour::*pfMine_GetWalkingSpeed)(void) = &PlayerDetour::Mine_GetWalkingSpeed;
    BOOL(PlayerDetour::*pfMine_CanJump)
    (void) = &PlayerDetour::Mine_CanJump;

    DetourTransactionBegin();
    DetourUpdateThread(GetCurrentThread());
    DetourAttach(&(PVOID &)GameApiDetour::Real_GetTeamPlayerCount, *(PBYTE *)&pfMine_GetTeamPlayerCount);
    DetourAttach(&(PVOID &)GameApiDetour::Real_Login, *(PBYTE *)&pfMine_Login);
    //DetourAttach(&(PVOID &)PlayerDetour::Real_GetWalkingSpeed, *(PBYTE *)&pfMine_GetWalkingSpeed);
    DetourAttach(&(PVOID &)PlayerDetour::Real_CanJump, *(PBYTE *)&pfMine_CanJump);
    DetourTransactionCommit();

    return TRUE;
}
