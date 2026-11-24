cmake_minimum_required(VERSION 3.20)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
	message(FATAL_ERROR "Use a separate build directory.")
endif()

project(love_uwp C CXX)

if(NOT WINDOWS_STORE)
	message(FATAL_ERROR "Configure with -DCMAKE_SYSTEM_NAME=WindowsStore -DCMAKE_SYSTEM_VERSION=10.0")
endif()

set(DEPS_DIR "${CMAKE_SOURCE_DIR}/deps" CACHE PATH "Directory filled by scripts/fetch-sources.ps1")
set(LOVE_SOURCE_DIR "${DEPS_DIR}/love-11.5" CACHE PATH "Patched LOVE source")
set(MEGASOURCE_DIR "${DEPS_DIR}/megasource-11.5" CACHE PATH "megasource 11.5")
set(SDL2_SOURCE "${DEPS_DIR}/SDL2-2.30.9" CACHE PATH "SDL2 source")
set(OPENAL_SOURCE "${DEPS_DIR}/openal-soft-1.24.3" CACHE PATH "OpenAL Soft source")
set(LUAJIT_UWP_DIR "${DEPS_DIR}/luajit-uwp" CACHE PATH "LuaJIT built by scripts/build-luajit.ps1")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MP")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MP")
set(CMAKE_SUPPRESS_REGENERATION TRUE)
add_compile_options(/sdl-)
add_compile_definitions(_CRT_SECURE_NO_WARNINGS _WINSOCK_DEPRECATED_NO_WARNINGS)

set(MEGA TRUE)
set(MEGA_X64 TRUE)
set(MEGA_ARCH x64)

function(disable_warnings ARG_TARGET)
	get_target_property(OLD_FLAGS ${ARG_TARGET} COMPILE_FLAGS)
	set(NEW_FLAGS -W0)
	if(OLD_FLAGS)
		set(NEW_FLAGS "${OLD_FLAGS} ${NEW_FLAGS}")
	endif()
	set_target_properties(${ARG_TARGET} PROPERTIES COMPILE_FLAGS ${NEW_FLAGS})
endfunction()

set(SKIP_INSTALL_ALL TRUE)
set(ZLIB_FOUND TRUE)
set(ZLIB_LIBRARY zlibstatic)
set(ZLIB_INCLUDE_DIR .)
set(OGG_LIBRARY ogg-static)

add_subdirectory("${MEGASOURCE_DIR}/libs/zlib-1.2.12" "${CMAKE_BINARY_DIR}/zlib")
set(MEGA_ZLIB zlibstatic)

add_subdirectory("${MEGASOURCE_DIR}/libs/libogg-1.3.2" "${CMAKE_BINARY_DIR}/libogg")
set(MEGA_LIBOGG ogg-static)

add_subdirectory("${MEGASOURCE_DIR}/libs/libvorbis-1.3.5" "${CMAKE_BINARY_DIR}/libvorbis")
set(MEGA_LIBVORBIS vorbis-static)
set(MEGA_LIBVORBISFILE vorbisfile-static)

add_subdirectory("${MEGASOURCE_DIR}/libs/libtheora-1.1.1" "${CMAKE_BINARY_DIR}/libtheora")
set(MEGA_LIBTHEORA theora-static)

add_subdirectory("${MEGASOURCE_DIR}/libs/freetype-2.8.1" "${CMAKE_BINARY_DIR}/freetype")
set(MEGA_FREETYPE freetype)

set(SDL_SHARED ON CACHE BOOL "" FORCE)
set(SDL_STATIC OFF CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)
set(SDL2_DISABLE_INSTALL ON CACHE BOOL "" FORCE)
set(SDL2_DISABLE_UNINSTALL ON CACHE BOOL "" FORCE)
add_subdirectory("${SDL2_SOURCE}" "${CMAKE_BINARY_DIR}/SDL2")
set(MEGA_SDL2 SDL2)
set(MEGA_SDL2MAIN)

set(LIBTYPE SHARED)
set(ALSOFT_UTILS OFF CACHE BOOL "" FORCE)
set(ALSOFT_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ALSOFT_TESTS OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_CONFIG OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_HRTF_DATA OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_AMBDEC_PRESETS OFF CACHE BOOL "" FORCE)
set(ALSOFT_NO_CONFIG_UTIL ON CACHE BOOL "" FORCE)
set(ALSOFT_BACKEND_DSOUND OFF CACHE BOOL "" FORCE)
set(ALSOFT_EAX OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_UTILS OFF CACHE BOOL "" FORCE)
set(ALSOFT_BACKEND_WINMM OFF CACHE BOOL "" FORCE)
set(ALSOFT_BACKEND_WASAPI ON CACHE BOOL "" FORCE)
set(ALSOFT_REQUIRE_WASAPI ON CACHE BOOL "" FORCE)
add_subdirectory("${OPENAL_SOURCE}" "${CMAKE_BINARY_DIR}/openal-soft")
set(MEGA_OPENAL OpenAL)

set(MEGA_MODPLUG)
set(LOVE_MPG123 OFF CACHE BOOL "" FORCE)
set(LOVE_JIT ON CACHE BOOL "" FORCE)

add_custom_target(luajit)
set(MEGA_LUAJIT_LIB "${LUAJIT_UWP_DIR}/lua51.lib")
set(MEGA_LUAJIT_INCLUDE "${LUAJIT_UWP_DIR}/include")
set(MEGA_LUAJIT_DLL)

set(MEGA_3P
	${MEGA_ZLIB}
	${MEGA_LIBOGG}
	${MEGA_LIBVORBIS}
	${MEGA_LIBVORBISFILE}
	${MEGA_LIBTHEORA}
	${MEGA_FREETYPE}
)

set(LOVE_LIB_TYPE STATIC)
add_subdirectory("${LOVE_SOURCE_DIR}" "${CMAKE_BINARY_DIR}/love")
set_target_properties(liblove PROPERTIES OUTPUT_NAME liblove RELEASE_OUTPUT_NAME liblove DEBUG_OUTPUT_NAME liblove)

foreach(MEGA_LIB ${MEGA_3P})
	disable_warnings(${MEGA_LIB})
endforeach()

set_target_properties(lovec PROPERTIES EXCLUDE_FROM_ALL TRUE EXCLUDE_FROM_DEFAULT_BUILD TRUE)

set_source_files_properties(
	"${LOVE_SOURCE_DIR}/src/libraries/physfs/physfs_platform_winrt.cpp"
	DIRECTORY "${LOVE_SOURCE_DIR}"
	PROPERTIES COMPILE_FLAGS "/ZW /EHsc"
)

target_sources(love PRIVATE "${CMAKE_SOURCE_DIR}/src/winrt_main.cpp")
set_source_files_properties(
	"${CMAKE_SOURCE_DIR}/src/winrt_main.cpp"
	DIRECTORY "${LOVE_SOURCE_DIR}"
	PROPERTIES COMPILE_FLAGS "/ZW /EHsc"
)

target_link_libraries(liblove bcrypt)
target_compile_definitions(love_3p_luasocket PRIVATE LUASOCKET_HAVE_SETFUNCS)

target_link_libraries(love vccorlib msvcrt)
set_property(TARGET love APPEND_STRING PROPERTY LINK_FLAGS " /NODEFAULTLIB:vccorlib /NODEFAULTLIB:msvcrt")
