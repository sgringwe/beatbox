find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.17.5" MINIMUM)

add_definitions(${NORMAL_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${NORMAL_LINK_DIRS})

vala_precompile(VALA_C
		LastFMInfoPlugin.vala
		LastFMInfoSource.vala
    PACKAGES
        beatbox
        beatbox-core
        gtk+-3.0
        libnotify
        gstreamer-0.10
#        gstreamer-interfaces-0.10
		gstreamer-pbutils-0.10
        glib-2.0
        libxml-2.0
        gee-1.0
        gio-unix-2.0
        PeasGtk-1.0
        libpeas-1.0
        libsoup-2.4
        granite
		libgpod-1.0
		${ADD_PKG}
    OPTIONS
        --target-glib=2.32
        --vapidir=${CMAKE_SOURCE_DIR}/vapi
        --vapidir=${CMAKE_BINARY_DIR}/core/
        --vapidir=${CMAKE_BINARY_DIR}/src/
    )
   
add_library(lastfminfo MODULE ${VALA_C})
add_definitions(${NORMAL_CFLAGS})
link_directories(${NORMAL_LINK_DIRS})
target_link_libraries (lastfminfo ${NORMAL_LIBRARIES})
install(TARGETS lastfminfo DESTINATION ${PLUGIN_DIR}/LastFMInfo/)
install(FILES lastfminfo.plugin DESTINATION ${PLUGIN_DIR}/LastFMInfo/)
add_dependencies(lastfminfo beatbox)
