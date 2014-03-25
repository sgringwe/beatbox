/*-
 * Copyright (c) 2011-2012		Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 * 
 * The BeatBox project hereby grant permission for non-gpl compatible GStreamer
 * plugins to be used and distributed together with GStreamer and BeatBox. This
 * permission is above and beyond the permissions granted by the GPL license
 * BeatBox is covered by.
 */

using Gtk;

public class BeatBox.Icon : GLib.Object {
	public string name { get; private set; }

	public bool has_backup {
		get {
			return (this.backup != null);
		}
	}

	public string backup_filename {
		get {
			if (backup == null)
				return "";

			return backup;
		}
	}

	private string? backup;
	private int? size;
	private IconsInterface.Type? type;
	private IconsInterface.FileType? file_type;
	
	protected const string MIMETYPES_FOLDER = "mimetypes";
    protected const string ACTIONS_FOLDER = "actions";
    protected const string STATUS_FOLDER = "status";
    protected const string APPS_FOLDER = "apps";
    protected const string OTHER_FOLDER = "other";

    protected const string PNG_EXT = ".png";
    protected const string SVG_EXT = ".svg";

	/**
	 * @param name icon name
	 *
	 * The following parameters are only necessary if has_backup is true.
	 * @param size pixel-size of the backup icon
	 * @param type Icon category
	 * @param file_type Icon type (SVG or PNG)
	 * FIXME deprecate has_backup
	 * @param has_backup whether a backup exists or not. It will be deprecated in the future since it's redundant
	 */
	public Icon (string name, int? size = 16, IconsInterface.Type? type = IconsInterface.Type.ACTION, IconsInterface.FileType? file_type = IconsInterface.FileType.SVG, bool has_backup = false) {

		this.name = name;
		this.size = size;
		this.type = type;
		this.file_type = file_type;

		/**
		 * The following code creates a backup path for the icon.
		 * This ensures consistency in the way we store icons in the
		 * 'images' folder.
		 **/
		if (has_backup && type != null && size != null) {
			string size_folder, type_folder, actual_icon_name;

			if (size != null)
				size_folder = size.to_string() + "x" + size.to_string();
			else
				size_folder = "";

			switch (type)
			{
				case IconsInterface.Type.MIMETYPE:
					type_folder = MIMETYPES_FOLDER;
					break;
				case IconsInterface.Type.ACTION:
					type_folder = ACTIONS_FOLDER;
					break;
				case IconsInterface.Type.STATUS:
					type_folder = STATUS_FOLDER;
					break;
				case IconsInterface.Type.APP:
					type_folder = APPS_FOLDER;
					break;
				default:
					type_folder = OTHER_FOLDER;
					break;
			}

			if (file_type != null) {
				switch (file_type)
				{
					case IconsInterface.FileType.SVG:
						actual_icon_name = this.name + SVG_EXT;
						break;
					case IconsInterface.FileType.PNG:
						actual_icon_name = this.name + PNG_EXT;
						break;
					default:
						actual_icon_name = this.name + SVG_EXT;
						break;
				}
			}
			else {
				actual_icon_name = name + SVG_EXT;
			}

			var icon_path = GLib.Path.build_path("/", Build.ICON_DIR, size_folder, type_folder);
			IconTheme.get_default().append_search_path (icon_path);
			this.backup = GLib.Path.build_filename("/", Build.ICON_DIR, size_folder, type_folder, actual_icon_name);
		}
		else {
			this.backup = null;
		}
	}

	public GLib.Icon get_gicon () {
		return new GLib.ThemedIcon.with_default_fallbacks (this.name);
	}

	public Gtk.IconInfo? get_icon_info (int size) {
		var icon_theme = IconTheme.get_default();
		var lookup_flags = Gtk.IconLookupFlags.GENERIC_FALLBACK;
		return icon_theme.lookup_by_gicon (get_gicon(), size, lookup_flags);
	}

	public Gdk.Pixbuf? render (Gtk.IconSize? size, StyleContext? context = null, int px_size = 0) {
		Gdk.Pixbuf? rv = null;
		int width = 16, height = 16;

		// Don't load image as a regular icon if it's a PNG and belongs
		// to the project's folder.
		if (file_type == IconsInterface.FileType.PNG && has_backup && size == null) {
			try {
				rv = new Gdk.Pixbuf.from_file(backup);
			}
			catch (Error err) {
				warning ("Could not load PNG image: %s\n", err.message);
			}

			return rv;
		}

		// If a null size was passed, use original size
		if (size != null) {
			icon_size_lookup (size, out width, out height);
		}
		else if (px_size > 0) {
			width = px_size;
			height = px_size;
		}
		else if (this.size != null) {
			width = this.size;
			height = width;
		}

		// Try to load icon from theme
		if (IconTheme.get_default().has_icon(this.name)) {
			try {
				var icon_info = get_icon_info (height);
				if (icon_info != null) {
					if (context != null)
						rv = icon_info.load_symbolic_for_context (context);
					else
						rv = icon_info.load_icon ();
				}
			}
			catch (Error err) {
				message ("%s, falling back to default.", err.message);
			}
		}

		// If the above failed, use available backup
		if (rv == null && has_backup) {
			try {
				message ("Loading backup icon for %s", this.name);
				rv = new Gdk.Pixbuf.from_file_at_size (this.backup, width, height);
			}
			catch (Error err) {
				warning ("Couldn't load backup icon: %s", err.message);
			}
		}

		return rv;
	}

	/**
	 * Use this method for loading symbolic icons. They will follow every state.
	 **/
	public Gtk.Image? render_image (Gtk.IconSize? size, Gtk.StyleContext? ctx = null, int px_size = 0) {
		Gtk.Image? rv = null;
		int width = 16, height = 16;

		// If a null size was passed, use original size
		if (size != null) {
			icon_size_lookup (size, out width, out height);
		}
		else if (px_size > 0) {
			width = px_size;
			height = px_size;
		}
		else if (this.size != null) {
			width = this.size;
			height = width;
		}

		if (IconTheme.get_default().has_icon (this.name) && size != null) {
			// Try to load icon from theme
			rv = new Image.from_icon_name (this.name, size);
		} else if (has_backup) {
			// If the icon theme doesn't contain the icon, load backup
			message ("Loading %s from backup", this.name);
			rv = new Image.from_file (this.backup);
		} else {
			// And if there was no backup, use the default method
			message ("Loading %s using default method", this.name);
			rv = new Image.from_pixbuf (this.render (size, ctx));
		}

		return rv;
	}

}

