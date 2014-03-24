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

public interface BeatBox.PlaybackInterface : GLib.Object {
	public enum ShuffleMode {
		OFF,
		ALL;
	}
	
	public enum RepeatMode {
		OFF,
		MEDIA,
		ALBUM,
		ARTIST,
		ALL;
	}
	
	public signal void media_played(Media id, Media? old_id);
	public signal void start_playback_requested(); // for when nothing is playing but play() is called
	public signal void playback_played();
	public signal void playback_paused();
	public signal void playback_stopped(Media? was_playing);
	
	public signal void media_found(Media m);
	public signal void media_not_found(Media m);
	
	public signal void current_cleared();
	
	public signal void media_queued(Media m);
	public signal void queue_changed();
	public signal void history_changed();
	
	public signal void end_of_stream();
	public signal void buffer_percent_update(int percent);
	public signal void current_position_update(int64 position);
	public signal void video_enabled();
	
	// Shuffle and Repeat
	public abstract void set_shuffle_mode(ShuffleMode mode);
	public abstract ShuffleMode get_shuffle_mode();
	public abstract void set_repeat_mode(RepeatMode mode);
	public abstract RepeatMode get_repeat_mode();
	public abstract bool is_shuffled { get; }
	
	// Playback
	public abstract Media current_media { get; protected set; }
	public abstract bool media_active { get; }
	public abstract bool playing { get; }
	public abstract void play();
	public abstract void pause();
	public abstract void stop_playback();
	public abstract Media? getPrevious(bool play);
	public abstract Media? getNext(bool play);
	public abstract void request_previous();
	public abstract void request_next();
	public abstract void play_media(Media m, bool use_resume_position);
	public abstract int64 get_position();
	public abstract void set_position(int64 pos);
	public abstract int64 get_duration();
	public abstract double get_volume();
	public abstract void set_volume(double vol);
	
	// Current playback list management
	public abstract int current_index { get; protected set; }
	public abstract void clear_playback_list();
	public abstract void set_playback_list(LinkedList<Media> list, Media? play_first);
	public abstract Media media_from_playback_list_index(int index);
	
	// Queue management
	public abstract bool queue_empty();
	public abstract void clear_queue();
	public abstract void queue_medias(Collection<Media> medias);
	public abstract void unqueue_media(Media m);
	public abstract Media peek_queue();
	public abstract Media poll_queue();
	public abstract LinkedList<Media> queue();
	
	// History management
	public abstract bool history_empty();
	public abstract void reset_history();
	public abstract void add_to_history(Media m);
//	public abstract void remove_from_history(Media m);
	public abstract LinkedList<Media> history();
	
	// Equalizer
	public abstract void* change_gains_thread();
	public abstract void setEqualizerGain(int index, int val);
}
