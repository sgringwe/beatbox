/*
 * IconInterface.vala
 * ==================
 * Interface to IconManager
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

namespace Beatbox {

	public interface IconInterface : GLib.Object {
		public abstract int size_of_album_view_image();

		public abstract bool register_icon(string resource_name, Icon icon);
		public abstract bool unregister_icon(string resource_name);

		public abstract bool register_prerendered_icon(string resource_name, Gdk.Pixbuf buf);
		public abstract bool unregister_prerendered_icon(string resource_name);

		public abstract unowned Gdk.Pixbuf?	get_prerendered_icon(string resource_name);
		public abstract unowned Icon? 	get_icon(string resource_name);
	}
}
