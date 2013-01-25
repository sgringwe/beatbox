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

public class BeatBox.FilesOperation : Operation {
	public Library library { get; set; }
	public Collection<File> files { get; set; }
	public Collection<Media> imports { get; set; }
	public Collection<string> failed_imports { get; set; }
	public ImportType import_type { get; set; }
	
	public enum ImportType  {
		SET,
		RESCAN,
		PLAYLIST,
		IMPORT,
		COMMANDLINE_IMPORT
	}
	
	public FilesOperation(Library library, Operation.OperationFunc sync_start, Operation.OperationFunc async_start, Operation.OperationFunc cancel, string desc) {
		base(sync_start, async_start, cancel, desc);
		this.library = library;
		
		files = new LinkedList<File>();
		imports = new LinkedList<Media>();
		failed_imports = new LinkedList<string>();
		import_type = ImportType.IMPORT; // A sane default
	}
	
	public bool should_copy() {
		return 	import_type == ImportType.PLAYLIST ||
				import_type == ImportType.IMPORT;
	}
}
