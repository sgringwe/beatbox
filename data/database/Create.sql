CREATE TABLE known_libraries (
	'key' TEXT
);

CREATE TABLE songs (
	'uri' TEXT,
	'file_size' INT,
	'title' TEXT,
	'artist' TEXT,
	'composer' TEXT,
	'album_artist' TEXT,
	'album' TEXT,
	'grouping' TEXT,
	'genre' TEXT,
	'comment' TEXT,
	'lyrics' TEXT,
	'album_path' TEXT,
	'has_embedded' INT,
	'year' INT,
	'track' INT,
	'track_count' INT,
	'album_number' INT,
	'album_count' INT,
	'bitrate' INT,
	'length' INT,
	'samplerate' INT,
	'rating' INT,
	'playcount' INT,
	'skipcount' INT,
	'dateadded' INT,
	'lastplayed' INT,
	'lastmodified' INT,
	'mediatype' INT,
	'podcast_rss' TEXT,
	'podcast_url' TEXT,
	'podcast_date' INT,
	'is_new_podcast' INT,
	'resume_pos' INT,
	'is_video' INT
);

CREATE TABLE podcasts (
	'uri' TEXT,
	'file_size' INT,
	'title' TEXT,
	'artist' TEXT,
	'composer' TEXT,
	'album_artist' TEXT,
	'album' TEXT,
	'grouping' TEXT,
	'genre' TEXT,
	'comment' TEXT,
	'lyrics' TEXT,
	'album_path' TEXT,
	'has_embedded' INT,
	'year' INT,
	'track' INT,
	'track_count' INT,
	'album_number' INT,
	'album_count' INT,
	'bitrate' INT,
	'length' INT,
	'samplerate' INT,
	'rating' INT,
	'playcount' INT,
	'skipcount' INT,
	'dateadded' INT,
	'lastplayed' INT,
	'lastmodified' INT,
	'mediatype' INT,
	'podcast_rss' TEXT,
	'podcast_url' TEXT,
	'podcast_date' INT,
	'is_new_podcast' INT,
	'resume_pos' INT,
	'is_video' INT
);

CREATE TABLE stations (
	'uri' TEXT,
	'file_size' INT,
	'title' TEXT,
	'artist' TEXT,
	'composer' TEXT,
	'album_artist' TEXT,
	'album' TEXT,
	'grouping' TEXT,
	'genre' TEXT,
	'comment' TEXT,
	'lyrics' TEXT,
	'album_path' TEXT,
	'has_embedded' INT,
	'year' INT,
	'track' INT,
	'track_count' INT,
	'album_number' INT,
	'album_count' INT,
	'bitrate' INT,
	'length' INT,
	'samplerate' INT,
	'rating' INT,
	'playcount' INT,
	'skipcount' INT,
	'dateadded' INT,
	'lastplayed' INT,
	'lastmodified' INT,
	'mediatype' INT,
	'podcast_rss' TEXT,
	'podcast_url' TEXT,
	'podcast_date' INT,
	'is_new_podcast' INT,
	'resume_pos' INT,
	'is_video' INT
);

CREATE TABLE playlists (
	'name' TEXT,
	'medias' TEXT
);

CREATE TABLE smart_playlists (
	'name' TEXT,
	'and_or' INT,
	'queries' TEXT,
	'limit_results' INT,
	'limit_amount' INT
);
				
CREATE TABLE devices (
	'unique_id' TEXT,
	'sync_when_mounted' INT,
	'sync_music' INT,
	'sync_podcasts' INT,
	'sync_audiobooks' INT,
	'sync_all_music' INT,
	'sync_all_podcasts' INT,
	'sync_all_audiobooks' INT,
	'music_playlist' TEXT,
	'podcast_playlist' TEXT,
	'audiobook_playlist' TEXT,
	'last_sync_time' INT
);
				
CREATE TABLE artists (
	'artist' TEXT,
	'full_desc' TEXT,
	'short_desc' TEXT,
	'merged_desc' TEXT,
	'tags' TEXT,
	'more_info_urls' TEXT,
	'similar_artists' TEXT,
	'photo_uri' TEXT
);

CREATE TABLE albums (
	'album' TEXT,
	'album_artist' TEXT,
	'full_desc' TEXT,
	'short_desc' TEXT,
	'merged_desc' TEXT,
	'tags' TEXT,
	'more_info_urls' TEXT,
	'release_date' TEXT,
	'similar_albums' TEXT,
	'art_uri' TEXT
);

CREATE TABLE tracks (
	'title' TEXT,
	'artist' TEXT,
	'full_desc' TEXT,
	'short_desc' TEXT,
	'merged_desc' TEXT,
	'tags' TEXT,
	'more_info_urls' TEXT,
	'lyrics' TEXT
);

CREATE TABLE list_setups (
	'key' TEXT,
	'hint' INT,
	'sort_column_id' INT,
	'sort_direction' TEXT,
	'columns' TEXT
);
