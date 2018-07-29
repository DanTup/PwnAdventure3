# PwnAdventure3 Proxy and Injection

[PwnAdventure3: Pwnie Island](http://www.pwnadventure.com/) is a game intentionally vulnerable to all kinds of silly hacks! Flying, endless cash, and more are all one client change or network proxy away.

I saw some of [LiveOverflow's videos on this](https://www.youtube.com/watch?v=RDZnlcnmPUA&list=PLhixgUqwRTjzzBeFSHXrw9DnQtssdAwgG&index=1) and it seemed like a fun way to learn something new (I've no C++/RE experience).

The network proxy is written in Dart and runs handler code inside isolates so that they can be hot-reloaded as you make changes (restarting the proxy would otherwise drop connecitons, meaning restarting the game constantly).

The DLL injection is written specifically for Windows. LiveOverflow's videos cover using `LD_PRELOAD` to inject the client but since that doesn't work on Windows this code uses the [Microsoft Detours](https://github.com/Microsoft/Detours/) library to inject the DLL.

![Inection Sample](https://user-images.githubusercontent.com/1078012/43366011-e4d65e86-932d-11e8-82fb-55222d9cd399.png)

## Running locally

// TODO: Verify these:

- Clone repo + submodule
- Fix up `gameServer` hostname in `proxy/bin/proxy.dart` to point at the server you're using
- Run name(?) in the detours/sample folder
- Update paths to game client and `VsDevCmd.bat` in `Workspace.code-workspace` file
- `File` -> `Open Workspace` in VS Code and select `Workspace.code-workspace`
- Select the proxy and/or the injected client in debug side bar
- Press `F5`
