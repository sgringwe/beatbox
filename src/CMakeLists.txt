find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.17.5" MINIMUM)
include(ValaPrecompile)

configure_file(Config.vala.cmake Config.vala)

vala_precompile(VALA_C
	main.vala
	Beatbox.vala

    Interfaces/IconInterface.vala
    Interfaces/MediaInterface.vala
    Interfaces/LibraryInterface.vala

    Managers/IconManager.vala

    Types/Icon.vala
    Types/Music.vala

	${CMAKE_BINARY_DIR}/src/Config.vala

PACKAGES
    glib-2.0
    gtk+-3.0
    gdk-x11-3.0
    gee-1.0
    gstreamer-0.10
    gstreamer-interfaces-0.10
    gstreamer-pbutils-0.10
    gstreamer-cdda-0.10
    taglib_c
    gio-2.0
    libxml-2.0
    libnotify
    libsoup-2.4
    json-glib-1.0
    gio-unix-2.0
    granite
    libgpod-1.0
    ${ADD_PKG}

OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_BINARY_DIR}/core/
    --target-glib=2.32
    --define=USE_GRANITE_DECORATED_WINDOW
    ${ADD_OPTIONS}
GENERATE_VAPI
    ${CMAKE_PROJECT_NAME}
GENERATE_HEADER
    ${CMAKE_PROJECT_NAME}
)
add_executable(${CMAKE_PROJECT_NAME} ${VALA_C})
link_directories(${DEPS_LIBRARY_DIRS} ${ZEITGEIST_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS} ${INDICATE_LIBRARY_DIRS} ${DBUS_MENU_LIBRARY_DIRS} ${UNITY_LIBRARY_DIRS})
add_definitions(${DEPS_CFLAGS} ${ZEITGEIST_CFLAGS} ${INDICATE_CFLAGS} ${DBUS_MENU_CFLAGS} ${SQLHEAVY_CFLAGS} ${UNITY_CFLAGS})
target_link_libraries(${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES} ${ZEITGEIST_LIBRARIES} ${DBUS_MENU_LIBRARIES} ${SQLHEAVY_LIBRARIES} ${INDICATE_LIBRARIES} ${UNITY_LIBRARIES})
install(TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION bin)
