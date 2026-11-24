#include <SDL_main.h>
#include <wrl.h>

#pragma comment(lib, "runtimeobject.lib")

int CALLBACK WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
	return SDL_WinRTRunApp(SDL_main, nullptr);
}
