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

public class BeatBox.StaticPlaylist : BasePlaylist {
	/*public int id { get; set; }
	public string name { get; set; }
	
	public TreeViewSetup tvs { get; set; }*/
	
	private Gee.HashMap<Media, int> _medias; // media, 1
	
	public StaticPlaylist() {
		name = _("New Playlist");
		_medias = new Gee.HashMap<Media, int>();
	}
	
	public StaticPlaylist.with_info(int rowid, string name) {
		_medias = new Gee.HashMap<Media, int>();
		this.id = rowid;
		this.name = name;
	}
	
	public Gee.Collection<Media> medias() {
		return _medias.keys;
	}
	
	public void add_medias(Collection<Media> ids) {
		foreach(var m in ids)
			_medias.set(m, 1);
	}
	
	public void remove_medias(Collection<Media> ids) {
		foreach(var m in ids) {
			_medias.unset(m);
		}
	}
	
	public void clear_all() {
		_medias = new HashMap<Media, int>();
	}
	
	public void medias_from_string(string medias, LibraryInterface lm) {
		string[] media_strings = medias.split(",", 0);
		
		int index;
		for(index = 0; index < media_strings.length - 1; ++index) {
			int id = int.parse(media_strings[index]);
			Media m = lm.media_from_id(id);
			if(m != null) {
				_medias.set(m, 1);
			}
			else {
				message("error loading media from int %d", id);
			}
		}
	}
	
	public string medias_to_string() {
		string rv = "";
		if(_medias == null) {
			return rv;
		}
		
		lock(_medias) {
			foreach(var m in _medias.keys) {
				rv += m.rowid.to_string() + ",";
			}
		}
		
		return rv;
	}
	
	public override Gee.Collection<Media> analyze(Collection<Media> not_used) {
		return _medias.keys;
	}
	
	public bool contains_media(Media i) {
		return _medias.get(i) != 1;
	}
	
	public override GPod.Playlist get_gpod_playlist() {
		GPod.Playlist rv = new GPod.Playlist(name, false);
		
		warning("TODO: Fixme");
		//rv.sortorder = tvs.get_gpod_sortorder();
		
		return rv;
	}
}
