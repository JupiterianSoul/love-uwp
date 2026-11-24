#include <SDL_main.h>
#include <wrl.h>

#pragma comment(lib, "runtimeobject.lib")

extern "C" void love_uwp_setup_view(void)
{
	using namespace Windows::UI::ViewManagement;

	try
	{
		ApplicationViewScaling::TrySetDisableLayoutScaling(true);
	}
	catch (Platform::Exception ^)
	{
	}

	try
	{
		ApplicationView::GetForCurrentView()->SetDesiredBoundsMode(ApplicationViewBoundsMode::UseCoreWindow);
	}
	catch (Platform::Exception ^)
	{
	}
}

int CALLBACK WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
	return SDL_WinRTRunApp(SDL_main, nullptr);
}
