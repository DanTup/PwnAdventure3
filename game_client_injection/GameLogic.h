#define DllImport __declspec(dllimport)

class GameAPI
{
  public:
	DllImport int GetTeamPlayerCount(void);
};
