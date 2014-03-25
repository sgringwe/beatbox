/*
 * LibraryInterface.vala
 * =====================
 * Interface to LibraryManager.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

using GLib;

namespace Beatbox {

	public interface LibraryInterface : GLib.Object {
		public delegate bool MediaFilter(MediaInterface m);

		public signal void media_added(List<unowned MediaInterface> media);
		public signal void media_removed(List<unowned MediaInterface> media);

		public abstract void add_media(MediaInterface m);
		public abstract void add_media_list(List<MediaInterface> media_list);
		public abstract void remove_media(MediaInterface m);
		public abstract void remove_media_list(List<MediaInterface> media_list);

		public abstract void refresh_async();
		public abstract void filter(string keyword, 
			out List<unowned MediaInterface> result,
			List<unowned MediaInterface>? range = null,
			MediaFilter? filter_func = null);

		public abstract List<unowned MediaInterface> get_media_list();
		public abstract uint get_media_count();
	}
}