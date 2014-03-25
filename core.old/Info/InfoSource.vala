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

public interface BeatBox.InfoSource : GLib.Object {
	
	// TODO: Is 64 too big??
	/*public enum InfoTypes {
		TRACK_META = 1,
		ALBUM_META = 2,
		ARTIST_META = 4,
		//LYRICS = 8, // lyrics only
		WRITTEN_INFO = 16, // written descriptions, summaries, biographies
		ALBUM_ART = 32, // album art images
		IMAGES = 64; // all other images
	}*/
	
	public abstract TrackInfo fetch_track_info(string artist, string title);
	public abstract AlbumInfo fetch_album_info(string artist, string album);
	public abstract ArtistInfo fetch_artist_info(string artist);
	
	//public abstract InfoTypes supported_info_types();
}
