using Gtk;

public class Store.FancyButton : Gtk.Button {
	string WIDGET_STYLESHEET = """
		.FancyButton {
            border-radius: 40 40 40 40;

            -unico-inner-stroke-width: 1px;
            -unico-outer-stroke-width: 1px;

            -GtkButton-default-border           : 0;
            -GtkButton-image-spacing            : 0;
            -GtkButton-inner-border             : 0;
            -GtkButton-interior-focus           : false;


            -unico-border-gradient: -gtk-gradient (linear, left top, left bottom,
                                                   from (alpha (#fff, 0.9)),
                                                   to (alpha (#fff, 0.5)));

            -unico-outer-stroke-gradient: -gtk-gradient (linear, left top, left bottom,
                                                         from (alpha (#000, 0.04)),
                                                         to (alpha (#000, 0.12)));
        }

        .blue {
            background-image: -gtk-gradient (linear,
                                             left top, left bottom,
                                             from (shade (#4b91dd, 1.10) ),
                                             to (#4b91dd));
        }
    """;
    
    public FancyButton(string label) {
		var style_provider = new CssProvider();

        try  {
            style_provider.load_from_data (WIDGET_STYLESHEET, -1);
        } catch (Error e) {
            warning("Couldn't load style provider.\n");
        }

        get_style_context().add_class("FancyButton");
        get_style_context().add_class("blue");
        get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        set_label(label);
	}
}
