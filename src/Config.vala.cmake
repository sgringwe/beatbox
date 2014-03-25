/*
 * Config.vala.cmake
 * =================
 * Basic compile-time settings produced by CMake.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

namespace Build {
	public const string DATADIR = "@DATADIR@";
	public const string PKG_DATADIR = "@PKG_DATADIR@";
	public const string ICON_DIR = "@ICON_DIR@";
	public const string SCHEMA_DIR = "@SCHEMA_DIR@";
	public const string PLUGIN_DIR = "@PLUGIN_DIR@";
	public const string GETTEXT_PACKAGE = "@GETTEXT_PACKAGE@";
	public const string RELEASE_NAME = "@RELEASE_NAME@";
	public const string VERSION = "@VERSION@";
	public const string VERSION_INFO = "@VERSION_INFO@";
	public const string CMAKE_INSTALL_PREFIX = "@CMAKE_INSTALL_PREFIX@";

	/**
	 * Translatable launcher (.desktop) strings to be added to
	 * template (.pot) file. These strings should reflect any
     * changes in these launcher keys in .desktop file.
     */
	public const string COMMENT 	= N_("Listen to music, podcasts and stations");
	public const string GENERIC 	= N_("Audio Player");
	public const string FULL_NAME 	= N_("BeatBox Audio Player");
}
