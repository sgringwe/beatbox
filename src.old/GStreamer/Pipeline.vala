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

// Gstreamer playbin GstPlayFlag enum
private enum Gst.PlayFlag {
	VIDEO         = (1 << 0),
	AUDIO         = (1 << 1),
	TEXT          = (1 << 2),
	VIS           = (1 << 3),
	SOFT_VOLUME   = (1 << 4),
	NATIVE_AUDIO  = (1 << 5),
	NATIVE_VIDEO  = (1 << 6),
	DOWNLOAD      = (1 << 7),
	BUFFERING     = (1 << 8),
	DEINTERLACE   = (1 << 9)
}

public class BeatBox.Pipeline : GLib.Object {
	public Gst.Pipeline pipe;
	public Equalizer eq;
	public CDDA cdda;
	public ReplayGain gapless;
	public Video video;
	
	public dynamic Gst.Bus bus;
	//Pad teepad;
	Pad pad;
	
	dynamic Element audiosink;
	dynamic Element audiosinkqueue;
	dynamic Element eq_audioconvert;
	dynamic Element eq_audioconvert2; 
	 
	public dynamic Gst.Element playbin;
	dynamic Gst.Element audiotee;
	dynamic Gst.Element audiobin;
	dynamic Gst.Element preamp;
	//dynamic Gst.Element volume;
	//dynamic Gst.Element rgvolume;
	
	public Pipeline() {
		gapless = new ReplayGain();
		
		pipe = new Gst.Pipeline("pipeline");
		playbin = ElementFactory.make("playbin2", null);
		
		audiosink = ElementFactory.make("autoaudiosink", null);
		//audiosink.set("profile", 1); // says we handle music and movies
		
		audiobin = new Gst.Bin("audiobin"); // this holds the real primary sink
		
		audiotee = ElementFactory.make("tee", null);
		audiosinkqueue = ElementFactory.make("queue", null);
		
		eq = new Equalizer();
		if(eq.element != null) {
			eq_audioconvert = ElementFactory.make("audioconvert", null);
			eq_audioconvert2 = ElementFactory.make("audioconvert", null);
			preamp = ElementFactory.make("volume", "preamp");
			
			((Gst.Bin)audiobin).add_many(eq.element, eq_audioconvert, eq_audioconvert2, preamp);
		}
		
		((Gst.Bin)audiobin).add_many(audiotee, audiosinkqueue, audiosink);
		
		audiobin.add_pad(new GhostPad("sink", audiotee.get_pad("sink")));
		
		if (eq.element != null)
			audiosinkqueue.link_many(eq_audioconvert, preamp, eq.element, eq_audioconvert2, audiosink);
		else
			audiosinkqueue.link_many(audiosink); // link the queue with the real audio sink
		
		playbin.set("audio-sink", audiobin); 
		bus = playbin.get_bus();
		
		// Link the first tee pad to the primary audio sink queue
		Gst.Pad sinkpad = audiosinkqueue.get_pad("sink");
		pad = audiotee.get_request_pad("src%d");
		audiotee.set("alloc-pad", pad);
		pad.link(sinkpad);
		
		// now add CDDA and Video
		cdda = new CDDA();
		video = new Video();
		if(video.element != null) {
			audiosinkqueue.link_many(video.element);
			//((Gst.Bin)audiobin).add_many(video.element);
			playbin.set("video-sink", video.element);
		}
		
		// Don't enable video for now
		Gst.PlayFlag flags;
		playbin.get("flags", out flags);
		flags = 			(Gst.PlayFlag.AUDIO);
		((Gst.Element)playbin).set("flags", flags);
		
		//bus.add_watch(busCallback);
		/*play.audio_tags_changed.connect(audioTagsChanged);
		play.text_tags_changed.connect(textTagsChanged);
		play.video_tags_changed.connect(videoTagsChanged);*/
	}
	
	/*private void videoTagsChanged(Gst.Element sender, int stream_number) {
		
	}

	private void audioTagsChanged(Gst.Element sender, int stream_number) {
		
	}

	/*private void textTagsChanged(Gst.Element sender, int stream_number) {
		
	}*/
	
	public void enableEqualizer() {
		if (eq.element != null) {
			audiosinkqueue.unlink_many(audiosink); // link the queue with the real audio sink
			audiosinkqueue.link_many(eq_audioconvert, preamp, eq.element, eq_audioconvert2, audiosink);
		}
	}
	
	public void disableEqualizer() {
		if (eq.element != null) {
			audiosinkqueue.unlink_many(eq_audioconvert, preamp, eq.element, eq_audioconvert2, audiosink);
			audiosinkqueue.link_many(audiosink); // link the queue with the real audio sink
		}
	}
	
	public int videoStreamCount() {
		return playbin.n_video;
	}
}
