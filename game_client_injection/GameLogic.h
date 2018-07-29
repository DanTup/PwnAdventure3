#define DllImport __declspec(dllimport)

class GameAPI
{
  public:
	DllImport void ConnectToGameServer(char const *, unsigned short, int, char const *);
	DllImport void ConnectToMasterServer(char const *, unsigned short, char const *);
	DllImport void CreateCharacter(char const *, unsigned char, unsigned int *);
	DllImport class Actor *CreateRemoteActorByName(class std::basic_string<char, struct std::char_traits<char>, class std::allocator<char>> const &, BOOL);
	DllImport class Actor *CreateRemoteActorByNameWithOwner(class std::basic_string<char, struct std::char_traits<char>, class std::allocator<char>> const &, BOOL, class IActor *);
	DllImport void DeleteCharacter(int);
	DllImport void DisconnectFromMasterServer(void);
	DllImport class IAchievement *GetAchievement(char const *);
	DllImport class IAchievementList *GetAchievements(void);
	DllImport int GetCharacterId(void);
	DllImport class FastTravelDestination *GetFastTravelDestination(class std::basic_string<char, struct std::char_traits<char>, class std::allocator<char>> const &);
	DllImport class GameServerConnection *GetGameServer(void);
	DllImport unsigned int GetGoldenEggCount(void);
	DllImport class IItem *GetItemByName(char const *);
	DllImport class LootTier *GetLootTier(unsigned int);
	DllImport class MasterServerConnection *GetMasterServer(void);
	DllImport BOOL GetNamedLocationPoint(class std::basic_string<char, struct std::char_traits<char>, class std::allocator<char>> const &, struct LocationAndRotation &);
	DllImport class IQuest *GetQuestByName(char const *);
	DllImport char const *GetTeamHash(void);
	DllImport void GetTeammates(void);
	DllImport char const *GetTeamName(void);
	DllImport int GetTeamPlayerCount(void);
	DllImport int GetTotalPlayerCount(void);
	DllImport int GetUserId(void);
	DllImport char const *GetUserNameW(void);
	DllImport void GiveAll(class IPlayer *);
	DllImport BOOL HasActorFactory(class std::basic_string<char, struct std::char_traits<char>, class std::allocator<char>> const &);
	DllImport void InitClient(class ILocalPlayer *);
	DllImport void InitLocal(class ILocalPlayer *);
	DllImport void InitObjects(void);
	DllImport void InitServer(char const *, unsigned short, int, char const *, unsigned short, char const *, char const *, char const *);
	DllImport BOOL IsAuthority(void);
	DllImport BOOL IsConnectedToGameServer(void);
	DllImport BOOL IsConnectedToMasterServer(void);
	DllImport BOOL IsDedicatedServer(void);
	DllImport BOOL IsTransitioningToNewServer(void);
	DllImport void JoinGameServer(int, BOOL);
	DllImport void __cdecl GameAPI::Log(char const *, ...);
	DllImport void Login(char const *, char const *);
	DllImport void Register(char const *, char const *, char const *);
	DllImport void Shutdown(void);
	DllImport void StartServerListener(struct ServerInfo const &);
	DllImport void SubmitAnswer(char const *, char const *);
	DllImport void Tick(float);
	DllImport void TransitionToNewGameServer(void);
	DllImport void UpdatePlayerCounts(void);
};
