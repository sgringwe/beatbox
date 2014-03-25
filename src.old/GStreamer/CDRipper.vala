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

using Gst;

public class BeatBox.CDRipper : GLib.Object {
	public dynamic Gst.Pipeline pipeline;
	public dynamic Gst.Element src;
	public dynamic Gst.Element queue;
	public dynamic Gst.Element filter;
	public dynamic Gst.Element sink;
	
	Media current_media; // media currently being processed/ripped
	private string _device;
	public int track_count;
	private Format _format;
	
	public signal void media_ripped(Media s, bool success);
	public signal void progress_notification(double progress);
	public signal void error(string err, Message message);
	
	public CDRipper(string device, int count) {
		_device = device;
		track_count = count;
	}
	
	public bool initialize() {
		pipeline = new Gst.Pipeline("pipeline");
		src = ElementFactory.make("cdparanoiasrc", "mycdparanoia");
		queue = ElementFactory.make("queue", "queue");
		filter = ElementFactory.make("lame", "encoder");
		sink = ElementFactory.make("filesink", "filesink");
		
		if(src == null || queue == null || filter == null || sink == null) {
			stdout.printf("Could not create GST Elements for ripping.\n");
			return false;
		}
		
		queue.set("max-size-time", 120 * Gst.SECOND);
		
		_format = Gst.format_get_by_nick("track");
		
		((Gst.Bin)pipeline).add_many(src, queue, filter, sink);
		if(!src.link_many(queue, filter, sink)) {
			stdout.printf("CD Ripper link_many failed\n");
			return false;
		}
		
		pipeline.bus.add_watch(busCallback);
		
		Timeout.add(500, doPositionUpdate);
		
		return true;
	}
	
	public bool doPositionUpdate() {
		progress_notification((double)getPosition()/getDuration());
		
		if(getDuration() <= 0)
			return false;
		else
			return true;
	}
	
	public int64 getPosition() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		src.query_position(ref f, out rv);
		
		return rv;
	}
	
	public int64 getDuration() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		src.query_duration(ref f, out rv);
		
		return rv;
	}
	
	private bool busCallback(Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
			/*case Gst.MessageType.STATE_CHANGED:
				Gst.State oldstate;
				Gst.State newstate;
				Gst.State pending;
				message.parse_state_changed (out oldstate, out newstate,
											 out pending);
				if(oldstate == Gst.State.READY && newstate == Gst.State.PAUSED && pending == Gst.State.PLAYING) {
					var mimetype = "FIX THIS";// probeMimeType();
					
					if(mimetype != null && mimetype != "") {
						stdout.printf("Detected mimetype of %s\n", mimetype);
					}
					else {
						stdout.printf("Could not detect mimetype\n");
					}
				}
				
				break;*/
			case Gst.MessageType.ERROR:
				GLib.Error err;
				string debug;
				message.parse_error (out err, out debug);
				stdout.printf ("Error: %s!:%s\n", err.message, debug);
				break;
			case Gst.MessageType.ELEMENT:
				stdout.printf("missing element\n");
				error("missing element", message);
				
				break;
			case Gst.MessageType.EOS:
				pipeline.set_state(Gst.State.NULL);
				current_media.uri = File.new_for_path(sink.location).get_uri();
				media_ripped(current_media, true);
				
				break;
			default:
				break;
		}
 
        return true;
    }
    
    public void ripMedia(uint track, Media s) {
		File f = App.files.get_new_destination(s);
		
		sink.set_state(Gst.State.NULL);
		sink.set("location", f.get_path());
		src.set("track", track);
		current_media = s;
		
		/*Iterator<Gst.Element> tagger = ((Gst.Bin)converter).iterate_all_by_interface(typeof(TagSetter));
		tagger.foreach( (el) => {
			
			((Gst.TagSetter)el).add_tags(Gst.TagMergeMode.REPLACE_ALL,
										Gst.TAG_ENCODER, "BeatBox");
			
		});*/
		
		pipeline.set_state(Gst.State.PLAYING);
	}
}
