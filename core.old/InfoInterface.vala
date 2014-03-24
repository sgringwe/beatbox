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

using Gee;

public interface BeatBox.InfoInterface : GLib.Object {
	public signal void track_info_updated(TrackInfo info);
	public signal void album_info_updated(AlbumInfo info);
	public signal void artist_info_updated(ArtistInfo info);
	
	public abstract TrackInfo current_track { get; set; }
	public abstract AlbumInfo current_album { get; set; }
	public abstract ArtistInfo current_artist { get; set; }

	public abstract void add_source(InfoSource source);
	public abstract void remove_source(InfoSource source);
	
	// These functions return null if nothing is yet fetched. It does not
	// fetch if nothing found
	public abstract TrackInfo? get_track_info(string artist, string title);
	public abstract AlbumInfo? get_album_info(string artist, string album);
	public abstract ArtistInfo? get_artist_info(string artist);
	public abstract TrackInfo? get_track_info_from_key(string key);
	public abstract AlbumInfo? get_album_info_from_key(string key);
	public abstract ArtistInfo? get_artist_info_from_key(string key);
	public abstract TrackInfo? get_track_info_from_media(Media m);
	public abstract AlbumInfo? get_album_info_from_media(Media m);
	public abstract ArtistInfo? get_artist_info_from_media(Media m);
	
	public abstract Collection<TrackInfo> get_tracks();
	public abstract Collection<AlbumInfo> get_albums();
	public abstract Collection<ArtistInfo> get_artists();
	
	public abstract string get_track_key(string? artist, string? title);
	public abstract string get_album_key(string? album_artist, string? album);
	public abstract string get_artist_key(string? artist);
	
	public abstract void fetch_track_info(string artist, string title);
	public abstract void fetch_album_info(string album_artist, string album);
	public abstract void fetch_artist_info(string artist);
	
	// Last fm stuff. Probably not a good spot, but has to have an
	// interface somewhere
	public abstract LastFMInterface lastfm { get; protected set; }
	public abstract LyricsInterface lyrics { get; protected set; }
}
