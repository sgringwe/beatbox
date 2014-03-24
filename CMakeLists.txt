# ch3eck http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)
project(beatbox)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )
enable_testing()

find_package(PkgConfig)
pkg_check_modules(DEPS
    REQUIRED
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
    libpeas-gtk-1.0
    libpeas-1.0)
 
# Check if we have sqlheavy-0.2
pkg_check_modules(SQLHEAVY2 sqlheavy-0.2)
if(${SQLHEAVY2_FOUND})
    set(ADD_PKG ${ADD_PKG} sqlheavy-0.2)
    message("-- Will use sqlheavy-0.2")
    set (SQLHEAVY_CFLAGS ${SQLHEAVY2_CFLAGS})
    set (SQLHEAVY_LIBRARY_DIRS ${SQLHEAVY2_LIBRARY_DIRS})
    set (SQLHEAVY_LIBRARIES ${SQLHEAVY2_LIBRARIES})
else()
    pkg_check_modules (SQLHEAVY REQUIRED sqlheavy-0.1)
    set(ADD_PKG ${ADD_PKG} sqlheavy-0.1)
    message("-- Will use sqlheavy-0.1")
endif() 

pkg_check_modules(ZEITGEIST zeitgeist-1.0)
if(${ZEITGEIST_FOUND})
set(ADD_PKG ${ADD_PKG}
                zeitgeist-1.0)
set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_ZEITGEIST)
message("-- Zeitgeist enabled")
else()
message("-- Zeitgeist disabled")
endif()

pkg_check_modules(INDICATE indicate-0.7)
if(${INDICATE_FOUND})
set(ADD_PKG ${ADD_PKG}
        Indicate-0.7)
set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_INDICATE)
message("-- Indicate enabled")
else()
message("-- Indicate disabled")
endif()

pkg_check_modules(UNITY unity)
if(${UNITY_FOUND})
set(ADD_PKG ${ADD_PKG}
                unity)
set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_UNITY)
message("-- Unity enabled")
else()
message("-- Unity disabled")
endif()

pkg_check_modules(GUPNP
				gupnp-1.0
				gupnp-av-1.0)
if(${GUPNP_FOUND})
set(ADD_PKG ${ADD_PKG}
        gupnp-1.0
        gupnp-av-1.0)
set(ADD_OPTIONS ${ADD_OPTIONS})
message("-- UPnP Plugin enabled")
else()
message("-- UPnP Plugin disabled")
set(GUPNP_FOUND 0)
endif()

set (CMAKE_C_FLAGS -w)
set (NORMAL_CFLAGS ${DEPS_CFLAGS} ${ZEITGEIST_CFLAGS} ${INDICATE_CFLAGS} ${DBUS_MENU_CFLAGS} ${SQLHEAVY_CFLAGS} ${UNITY_CFLAGS} ${GUPNP_CFLAGS})
set (NORMAL_LIBRARIES ${DEPS_LIBRARIES} ${ZEITGEIST_LIBRARIES} ${DBUS_MENU_LIBRARIES} ${SQLHEAVY_LIBRARIES} ${INDICATE_LIBRARIES} ${UNITY_LIBRARIES} ${GUPNP_LIBRARIES})
set (NORMAL_LINK_DIRS ${DEPS_LIBRARY_DIRS} ${ZEITGEIST_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS} ${INDICATE_LIBRARY_DIRS} ${DBUS_MENU_LIBRARY_DIRS} ${UNITY_LIBRARY_DIRS} ${GUPNP_LIBRARY_DIRS})

set(DATADIR         "${CMAKE_INSTALL_PREFIX}/share")
set(PKG_DATADIR     "${DATADIR}/beatbox")
set(ICON_DIR        "${PKG_DATADIR}/icons/hicolor")
set(SCHEMA_DIR      "${PKG_DATADIR}/database")
set(PLUGIN_DIR      "${PKG_DATADIR}/plugins")
set(GETTEXT_PACKAGE "beatbox")
set(RELEASE_NAME    "Everlong")
set(VERSION         "0.7")
set(VERSION_INFO    "Alpha")

add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

add_subdirectory(vapi)
add_subdirectory(src)
add_subdirectory(data)
add_subdirectory(schemas)
add_subdirectory(po)
add_subdirectory(images)

# Supress C compiler warnings
option (BUILD_PLUGINS "Whether to build plugins or not" OFF)
if (BUILD_PLUGINS)
    message("-- Plugins will be built")
    add_subdirectory(plugins)
endif()
