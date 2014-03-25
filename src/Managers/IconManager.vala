/*
 * IconManager.vala
 * ================
 * Store and manage application-wide icons.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

namespace Beatbox {

	/*** Resource Strings for Icons Begin ***/

	// decoration
	public static const string ICON_ALBUM_SHADOW	= "album_shadow";
	
	// 128 x 128
	public static const string ICON_DEFAULT_ALBUM_ART 	= "default_album_art";
	public static const string ICON_DROP_ALBUM			= "drop_album";
	public static const string ICON_MUSIC_FOLDER		= "music_folder";

	// 22 x 22
	public static const string ICON_HISTORY			= "history";

	// 16 x 16
	public static const string ICON_BEATBOX			= "beatbox";
	public static const string ICON_STATION			= "station";
	public static const string ICON_MUSIC 			= "music";
	public static const string ICON_PODCAST			= "podcast";
	public static const string ICON_AUDIOBOOK		= "audiobook";
	public static const string ICON_AUDIO_CD		= "audio_cd";
	public static const string ICON_PLAYLIST		= "playlist";
	public static const string ICON_SMART_PLAYLIST	= "smart_playlist";
	public static const string ICON_LASTFM_LOVE		= "lastfm_love";	// TODO: move me to plugin-specific code
	public static const string ICON_LASTFM_BAN		= "lastfm_ban";		// TODO: move me to plugin-specific code
	public static const string ICON_STARRED			= "starred";
	public static const string ICON_NOT_STARRED		= "not_starred";
	public static const string ICON_NEW_PODCAST		= "new_podcast";

	// Symbolic icons
	public static const string ICON_PANE_HIDE_SYMBOLIC		= "pane_hide_symbolic";
	public static const string ICON_PANE_SHOW_SYMBOLIC		= "pane_show_symbolic";
	public static const string ICON_MEDIA_PLAY_SYMBOLIC		= "media_play_symbolic";
	public static const string ICON_MEDIA_PAUSE_SYMBOLIC	= "media_pause_symbolic";
	public static const string ICON_STARRED_SYMBOLIC		= "starred_symbolic";
	public static const string ICON_NOT_STARRED_SYMBOLIC	= "not_starred_symbolic";
	public static const string ICON_PROCESS_COMPLETED		= "process_completed";
	public static const string ICON_PROCESS_ERROR			= "process_error";
	public static const string ICON_PROCESS_STOP			= "process_stop";
	public static const string ICON_SHUFFLE_ON				= "shuffle_on";
	public static const string ICON_SHUFFLE_OFF				= "shuffle_off";
	public static const string ICON_REPEAT_ON				= "repeat_on";
	public static const string ICON_REPEAT_OFF				= "repeat_off";
	public static const string ICON_REPEAT_ONCE				= "repeat_once";
	public static const string ICON_EQ						= "eq";
	public static const string ICON_VIEW_COLUMN				= "view_column";
	public static const string ICON_VIEWS					= "views";
	public static const string ICON_VIEW_DETAILS			= "view_details";
	public static const string ICON_VIEW_ICONS				= "view_icons";
	public static const string ICON_VIEW_VIDEO				= "view_video";
	public static const string ICON_INFO					= "info";
	public static const string ICON_GO_NEXT					= "go_next";
	public static const string ICON_GO_HOME					= "go_home";

	// Folders
	public static const string ICON_FOLDER_MIMETYPES	= "mimetypes";
    public static const string ICON_FOLDER_ACTIONS		= "actions";
    public static const string ICON_FOLDER_STATUS		= "status";
    public static const string ICON_FOLDER_APPS			= "apps";
    public static const string ICON_FOLDER_OTHER		= "other";

    // Image Extensions
    public static const string ICON_EXT_PNG = ".png";
    public static const string ICON_EXT_SVG = ".svg";

	/*** Resource Strings for Icons End ***/

	public class IconManager : GLib.Object, IconInterface {
		public const int ALBUM_VIEW_IMAGE_SIZE = 140;

		public HashTable<string, Icon> 			icon_table;
		public HashTable<string, Gdk.Pixbuf>	pixbuf_table;

		public IconManager() {
			icon_table = new HashTable<string, Icon>(str_hash, str_equal);
			pixbuf_table = new HashTable<string, Gdk.Pixbuf>(str_hash, str_equal);

			// TODO: Load default icons.
			debug("Loading default icon resources...");

			register_icon(ICON_DEFAULT_ALBUM_ART,
				new Icon("albumart", 138, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));

			// 128 x 128
			register_icon(ICON_DROP_ALBUM,
				new Icon("drop-album", 128, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));
			register_icon(ICON_MUSIC_FOLDER,
				new Icon("folder-music", 128, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));

			// 22 x 22
			register_icon(ICON_HISTORY,
				new Icon("document-open-recent", 22, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));

			// 16 x 16
			register_icon(ICON_BEATBOX,
				new Icon("beatbox", 16, 
					Icon.Type.APPS, Icon.FileType.NONE, true));
			register_icon(ICON_STATION,
				new Icon("internet-radio", 16, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));
			register_icon(ICON_MUSIC,
				new Icon("library-music", 16, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));
			register_icon(ICON_PODCAST,
				new Icon("library-podcast", 16, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));
			register_icon(ICON_AUDIOBOOK,
				new Icon("library-audiobook", 16, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));
			register_icon(ICON_AUDIO_CD,
				new Icon("media-cdrom-audio", 16, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));
			register_icon(ICON_PLAYLIST,
				new Icon("playlist", 16, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));
			register_icon(ICON_SMART_PLAYLIST,
				new Icon("playlist-automatic", 16, 
					Icon.Type.MIMETYPE, Icon.FileType.NONE, true));
			register_icon(ICON_LASTFM_LOVE,
				new Icon("lastfm-love", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, true));
			register_icon(ICON_LASTFM_BAN,
				new Icon("lastfm-ban", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, true));
			register_icon(ICON_STARRED,
				new Icon("starred", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, true));
			register_icon(ICON_NOT_STARRED,
				new Icon("non-starred", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, true));
			register_icon(ICON_NEW_PODCAST,
				new Icon("podcast-new", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, true));

			// SYMBOLIC ICONS (16 x 16)
			register_icon(ICON_PANE_SHOW_SYMBOLIC,
				new Icon("pane-show-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, true));
			register_icon(ICON_PANE_HIDE_SYMBOLIC,
				new Icon("pane-hide-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, true));
			register_icon(ICON_REPEAT_ONCE,
				new Icon("media-playlist-repeat-one-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, true));
			register_icon(ICON_REPEAT_OFF,
				new Icon("media-playlist-no-repeat-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, true));
			register_icon(ICON_SHUFFLE_OFF,
				new Icon("media-playlist-no-shuffle-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, true));
			register_icon(ICON_EQ,
				new Icon("media-eq-symbolic", 16, Icon.Type.STATUS, 
					Icon.FileType.NONE, true));

			register_icon(ICON_MEDIA_PLAY_SYMBOLIC,
				new Icon("media-playback-start-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_MEDIA_PAUSE_SYMBOLIC,
				new Icon("media-playback-pause-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_STARRED_SYMBOLIC,
				new Icon("starred-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, false));
			register_icon(ICON_NOT_STARRED_SYMBOLIC,
				new Icon("non-starred-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, false));
			register_icon(ICON_PROCESS_COMPLETED,
				new Icon("process-completed-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, false));
			register_icon(ICON_PROCESS_ERROR,
				new Icon("process-error-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, false));
			register_icon(ICON_PROCESS_STOP,
				new Icon("process-stop-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_SHUFFLE_ON,
				new Icon("media-playlist-shuffle-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, false));
			register_icon(ICON_REPEAT_ON,
				new Icon("media-playlist-repeat-symbolic", 16, 
					Icon.Type.STATUS, Icon.FileType.NONE, false));
			register_icon(ICON_VIEW_COLUMN,
				new Icon("view-column-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_VIEW_DETAILS,
				new Icon("view-list-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_VIEW_ICONS,
				new Icon("view-grid-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_VIEW_VIDEO,
				new Icon("view-video-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_VIEWS,
				new Icon("view-grid-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_INFO,
				new Icon("info-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_GO_NEXT,
				new Icon("go-next-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));
			register_icon(ICON_GO_HOME,
				new Icon("go-home-symbolic", 16, 
					Icon.Type.ACTION, Icon.FileType.NONE, false));

			/* Render Pixbufs */
			register_prerendered_icon(ICON_DEFAULT_ALBUM_ART,
				get_icon(ICON_DEFAULT_ALBUM_ART).render(null));
			register_prerendered_icon(ICON_DROP_ALBUM,
				get_icon(ICON_DROP_ALBUM).render(null));
			register_prerendered_icon(ICON_ALBUM_SHADOW,
				(new Icon("albumart-shadow", 168, 
					Icon.Type.OTHER, Icon.FileType.PNG, true)).render(null));

			debug("Icon resources loaded.");
		}

		public int size_of_album_view_image() {
			return ALBUM_VIEW_IMAGE_SIZE;
		}

		public bool register_icon(string resource_name, Icon icon) {
			if(icon_table.lookup(resource_name) != null) {
				warning("Icon %s has alreay been registered.", resource_name);
				return false;
			} else {
				icon_table.set(resource_name, icon);
			}
			return true;
		}

		public bool unregister_icon(string resource_name) {
			if(icon_table.lookup(resource_name) == null) {
				warning("Icon %s is not registered.", resource_name);
				return false;
			} else {
				icon_table.remove(resource_name);
			}
			return true;
		}

		public bool register_prerendered_icon(string resource_name, Gdk.Pixbuf buf) {
			if(pixbuf_table.lookup(resource_name) != null) {
				warning("Prerendered icon %s has alreay been registered.", resource_name);
				return false;
			} else {
				pixbuf_table.set(resource_name, buf);
			}
			return true;
		}

		public bool unregister_prerendered_icon(string resource_name) {
			if(pixbuf_table.lookup(resource_name) == null) {
				warning("Prerendered icon %s is not registered.", resource_name);
				return false;
			} else {
				pixbuf_table.remove(resource_name);
			}
			return true;
		}

		public unowned Gdk.Pixbuf?	get_prerendered_icon(string resource_name) {
			return pixbuf_table.lookup(resource_name);
		}

		public unowned Icon? get_icon(string resource_name) {
			return icon_table.lookup(resource_name);
		}
	}
}