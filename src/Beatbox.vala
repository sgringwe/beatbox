/*
 * Beatbox.vala
 * ============
 * Main application class.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

namespace Beatbox {

	public class CommandLineOptions : GLib.Object {
		public static bool verbose_enabled;
		public static bool plugins_disabled;

		construct {
			verbose_enabled = false;
			plugins_disabled = false;
		}
	}

	public class Beatbox : Granite.Application {

		// TODO: Define modules here.
		public static IconInterface icon_manager { get; private set; }

		public static const OptionEntry[] available_options = {
				{"debug", 'd', 0, OptionArg.NONE,
					ref (CommandLineOptions.verbose_enabled), "Enable debugging mode", null},
				{"no-plugins", 0, 0, OptionArg.NONE,
					ref (CommandLineOptions.plugins_disabled), "Disable all plugins", null},
				{null}
			};

		construct {
			// Allows opening files.
			flags |= ApplicationFlags.HANDLES_OPEN;

			// Application info
			build_data_dir 		= Build.DATADIR;
			build_pkg_data_dir 	= Build.PKG_DATADIR;
			build_release_name 	= Build.RELEASE_NAME;
			build_version 		= Build.VERSION;
			build_version_info 	= Build.VERSION_INFO;

			program_name 	= "Beatbox";
			exec_name 		= "beatbox";
			application_id	= "net.launchpad.beatbox";

			app_copyright 	= "2014";
			app_icon 		= "beatbox";
			app_launcher 	= "beatbox.desktop";
			app_years 		= "2010-2014";

			main_url 		= "http://github.com/5Ki3s0x1C9/beatbox";
			bug_url 		= "http://github.com/5Ki3s0x1C9/beatbox/issues";
			help_url 		= "https://answers.launchpad.net/beat-box";
			translate_url 	= "https://translations.launchpad.net/beat-box";

			about_authors 	= {	"Scott Ringwelski <sgringwe@mtu.edu>",
							 	"Victor Eduardo M. <victoreduardm@gmail.com>",
							 	"Charles Weng <mystery.wd@gmail.com>",
							 	null};

			about_artists 	= {	"Scott Ringwelski <sgringwe@mtu.edu>",
							 	"Daniel Foré <daniel@elementaryos.org>", 
							 	null};
		}

		public Beatbox() {
			// TODO: Create and load settings here.
		}

		public override void open(File[] files, string hint) {
			// TODO: open files
		}

		protected override void activate() {
			// TODO: Restore the window if exists

			// Setup debugger
			if (CommandLineOptions.verbose_enabled) {
				Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
				debug("Debug mode enabled.");
			} else {
				Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
			}
			
			// TODO: Initialize everything
			icon_manager = new IconManager();
		}
		
		/**
		 * We use this identifier to init everything inside the application.
		 * For instance: libnotify, etc.
		 */
		public string get_id () {
			return application_id;
		}

		public string get_name () {
			return program_name;
		}

		public string get_desktop_file_name () {
			return app_launcher;
		}
	}
}
