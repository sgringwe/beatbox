/*
 * Icon.vala
 * =========
 * Base type of icons.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

using Gtk;

namespace Beatbox {

	public class Icon : GLib.Object {

		public enum Type {
	        MIMETYPE,
	        ACTION,
	        STATUS,
	        APPS,
	        OTHER
	    }

	    public enum FileType {
	        SVG,
	        PNG
	    }

	    public string 	name { get; private set; }
	    public int 		size { get; private set; }
	    public Type 	icon_type { get; private set; }
	    public FileType	file_type { get; private set; }

	    private bool	has_default;
	    private string	default_filename;

	    public Icon (string name, 
	    			 int size = 16, 
	    			 Type type = Type.ACTION, 
	    			 FileType file_type = FileType.SVG,
	    			 bool has_default = false) {
	    	this.name = name;
	    	this.size = size;
	    	this.icon_type = type;
	    	this.file_type = file_type;
	    	this.has_default = has_default;

	    	if(has_default) {
	    		string type_folder, icon_file_name;

	    		switch(type)
	    		{
	    			case Type.MIMETYPE:
	    				type_folder = ICON_FOLDER_MIMETYPES;
	    				break;
	    			case Type.ACTION:
	    				type_folder = ICON_FOLDER_ACTIONS;
	    				break;
	    			case Type.STATUS:
	    				type_folder = ICON_FOLDER_STATUS;
	    				break;
	    			case Type.APPS:
	    				type_folder = ICON_FOLDER_APPS;
	    				break;
	    			default:
	    				type_folder = ICON_FOLDER_OTHER;
	    				break;
	    		}

	    		switch(file_type) {
	    			case FileType.SVG:
	    				icon_file_name = this.name + ICON_EXT_SVG;
	    				break;
	    			case FileType.PNG:
	    				icon_file_name = this.name + ICON_EXT_PNG;
	    				break;
	    			default:
	    				icon_file_name = this.name;
	    				break;
	    		}

	    		IconTheme.get_default().append_search_path(
	    			GLib.Path.build_path("/",
	    				Build.ICON_DIR,
	    				size.to_string() + "x" + size.to_string(),
	    				type_folder));
	    		default_filename = GLib.Path.build_filename("/",
	    			Build.ICON_DIR,
	    			size.to_string() + "x" + size.to_string(),
	    			type_folder,
	    			icon_file_name);
	    	}
	    }

	    public GLib.Icon get_gicon() {
			return new GLib.ThemedIcon.with_default_fallbacks(name);
		}

		public Gtk.IconInfo? get_icon_info(int size) {
			return IconTheme.get_default().lookup_by_gicon(
				get_gicon(), size, Gtk.IconLookupFlags.GENERIC_FALLBACK);
		}

		public Gdk.Pixbuf? render(Gtk.IconSize? size, StyleContext? context = null, int px_size = 0) {
			Gdk.Pixbuf? rv = null;
			int width = 16, height = 16;

			// Don't load image as a regular icon if it's a PNG and belongs
			// to the project's folder.
			if(file_type == FileType.PNG && has_default && size == null) {
				try {
					rv = new Gdk.Pixbuf.from_file(default_filename);
				} catch (Error e) {
					warning("Could not load PNG image: %s\n", e.message);
				}

				return rv;
			}

			// If a null size was passed, use original size
			if(size != null) {
				icon_size_lookup(size, out width, out height);
			} else if(px_size > 0) {
				width = px_size;
				height = px_size;
			} else {
				width = this.size;
				height = this.size;
			}

			// Try to load icon from theme
			if(IconTheme.get_default().has_icon(this.name)) {
				try {
					var icon_info = get_icon_info(height);
					if(icon_info != null) {
						if(context != null)
							rv = icon_info.load_symbolic_for_context(context);
						else
							rv = icon_info.load_icon();
					}
				} catch (Error e) {
					warning("%s, falling back to default.", e.message);
				}
			}

			// If the above failed, use available backup
			if(rv == null && has_default) {
				try {
					message("Loading backup icon for %s", this.name);
					rv = new Gdk.Pixbuf.from_file_at_size(this.default_filename, width, height);
				} catch (Error e) {
					warning("Couldn't load default icon: %s", e.message);
				}
			}

			return rv;
		}

		/**
		 * Original note:
		 *   Use this method for loading symbolic icons. They will follow every state.
		 **/
		public Gtk.Image? render_image (Gtk.IconSize? size, Gtk.StyleContext? ctx = null, int px_size = 0) {
			Gtk.Image? rv = null;
			int width = 16, height = 16;

			// If a null size was passed, use original size
			if(size != null) {
				icon_size_lookup (size, out width, out height);
			} else if(px_size > 0) {
				width = px_size;
				height = px_size;
			} else {
				width = this.size;
				height = width;
			}

			if(IconTheme.get_default().has_icon (this.name) && size != null) {
				// Try to load icon from theme
				rv = new Image.from_icon_name(this.name, size);
			} else if(has_default) {
				// If the icon theme doesn't contain the icon, load backup
				message("Loading %s from backup", this.name);
				rv = new Image.from_file(this.default_filename);
			} else {
				// And if there was no backup, use the default method
				message("Loading %s using default method", this.name);
				rv = new Image.from_pixbuf(this.render(size, ctx));
			}

			return rv;
		}
	}
}