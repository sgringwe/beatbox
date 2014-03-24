using Gtk;

public class Store.ClickableImage : EventBox {
	Image image;
	string url;
	
	public signal bool activated(string url);
	
	public ClickableImage(Gdk.Pixbuf pix, string url) {
		image = new Gtk.Image.from_pixbuf(pix);
		this.url = url;
		
		add(image);
		
		button_press_event.connect (on_click);
		enter_notify_event.connect (on_enter);
		leave_notify_event.connect (on_leave);
	}
	
	bool on_click (Gdk.EventButton button) {
		activated(url);
		
		return true;
	}
	
	bool on_enter (Gdk.EventCrossing event) {
		this.get_window ().set_cursor (null);
		
		return false;
	}
	
	bool on_leave (Gdk.EventCrossing event) {
		this.get_window ().set_cursor (new Gdk.Cursor (Gdk.CursorType.HAND1));
		
		return false;
	}
}

