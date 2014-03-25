/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
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

public interface BeatBox.LastFMInterface : GLib.Object {
	public abstract string session_key { get; set; }
	public abstract bool is_subscriber { get; set; }
	public abstract string username { get; set; }
	
	public signal void login_returned(bool successful);
	public signal void logged_out();
	public signal void similar_retrieved(Gee.LinkedList<BeatBox.Media> internals, Gee.LinkedList<BeatBox.Media> externals);
	public signal void top_artist_songs_retrieved(HashTable<int, BeatBox.Media> songs);
	public signal void top_artist_albums_retrieved(HashTable<int, BeatBox.ExternalAlbum> albums);
	
	public abstract void query(string type, Gee.HashMap<string, string> params, bool requires_sk, Soup.SessionCallback call_back);
	
	public abstract void authenticate_user(string username, string password);
	public abstract void logout_user();
	
	public abstract void ban_track(string title, string artist);
	public abstract void love_track(string title, string artist);
	public abstract void post_now_playing();
	public abstract void scrobble();
	
	public abstract void fetch_current_similar_songs();
	public abstract void fetch_top_artist_songs();
	public abstract void fetch_top_artist_albums();
}
