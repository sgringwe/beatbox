// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Granite Developers (http://launchpad.net/granite)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 * 
 * The BeatBox project hereby grant permission for non-gpl compatible GStreamer
 * plugins to be used and distributed together with GStreamer and BeatBox. This
 * permission is above and beyond the permissions granted by the GPL license
 * BeatBox is covered by.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class BeatBox.EmbeddedAlert : Gtk.EventBox {

    const string INFO_ICON = "dialog-information";
    const string WARNING_ICON = "dialog-warning";
    const string QUESTION_ICON = "dialog-question";
    const string ERROR_ICON = "dialog-error";

    const string PRIMARY_TEXT_MARKUP = "<span weight=\"bold\" size=\"larger\">%s</span>";

    private Gtk.Box content_hbox;

    protected Gtk.Label primary_text_label;
    protected Gtk.Label secondary_text_label;
    protected Gtk.Image image;
    protected Gtk.ButtonBox action_button_box;

    const int MIN_HORIZONTAL_MARGIN = 84;
    const int MIN_VERTICAL_MARGIN = 48;

    public EmbeddedAlert () {
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        // get_style_context ().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);

        action_button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        action_button_box.valign = Gtk.Align.START;

        primary_text_label = new Gtk.Label (null);
        primary_text_label.margin_bottom = 12;

        secondary_text_label = new Gtk.Label (null);
        secondary_text_label.margin_bottom = 18;

        primary_text_label.use_markup = secondary_text_label.use_markup = true;

        primary_text_label.wrap = secondary_text_label.wrap = true;
        primary_text_label.valign = secondary_text_label.valign = Gtk.Align.START;

        image = new Gtk.Image ();
        image.pixel_size = 64;
        image.halign = Gtk.Align.END;
        image.valign = Gtk.Align.START;
        image.margin_right = 12;

        // Init stuff
        set_alert ("", "", null, false);

        var message_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        message_vbox.pack_start (primary_text_label, false, false, 0);
        message_vbox.pack_start (secondary_text_label, false, false, 0);
        message_vbox.pack_end (action_button_box, false, false, 0);

        content_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_hbox.halign = content_hbox.valign = Gtk.Align.CENTER; // center-align the content
        content_hbox.margin_top = content_hbox.margin_bottom = MIN_VERTICAL_MARGIN;
        content_hbox.margin_left = content_hbox.margin_right = MIN_HORIZONTAL_MARGIN;

        content_hbox.pack_start (image, false, false, 0);
        content_hbox.pack_end (message_vbox, true, true, 0);

        add (content_hbox);
    }


    public void set_alert (string primary_text, string secondary_text, Gtk.Action[] ? actions = null,
                             bool show_icon = true, Gtk.MessageType type = Gtk.MessageType.WARNING)
    {
        // Reset size request
        set_size_request (0, 0);

        if (primary_text == null)
            primary_text = "";

        if (secondary_text == null)
            secondary_text = "";

        set_primary_text_visible (primary_text != "");
        set_secondary_text_visible (secondary_text != "");

        // We force the HIG here. Whenever show_icon is true, the title has to be left-aligned.
        if (show_icon) {
            primary_text_label.halign = secondary_text_label.halign = Gtk.Align.START;
            primary_text_label.justify = Gtk.Justification.LEFT;
            secondary_text_label.justify = Gtk.Justification.FILL;
            image.set_from_icon_name (get_icon_name_for_message_type (type), Gtk.IconSize.DIALOG);
        }
        else {
            primary_text_label.halign = secondary_text_label.halign = Gtk.Align.CENTER;
            primary_text_label.justify = secondary_text_label.justify = Gtk.Justification.CENTER;
        }

        // Make sure the text is selectable if the level is WARNING, ERROR or QUESTION
        bool text_selectable = (type == Gtk.MessageType.WARNING)
                               || (type == Gtk.MessageType.ERROR)
                               || (type == Gtk.MessageType.QUESTION);
        primary_text_label.selectable = secondary_text_label.selectable = text_selectable;

        set_icon_visible (show_icon);

        // clear button box
        foreach (var button in action_button_box.get_children ()) {
            action_button_box.remove (button);
        }

        // Add a button for each action
        if (actions != null && actions.length > 0) {
            for (int i = 0; i < actions.length; i++) {
                var action_item = actions[i];
                if (action_item != null) {
                    var action_button = new_button_from_action (action_item);
                    if (action_button != null) {
                        // Pack into the button box
                        action_button_box.pack_start (action_button, false, false, 0);

                        action_button.button_release_event.connect ( () => {
                            action_item.activate ();
                            return false;
                        });
                    }
                }
            }

            if (show_icon) {
                action_button_box.set_layout (Gtk.ButtonBoxStyle.END);
                action_button_box.halign = Gtk.Align.END;
            }
            else {
                action_button_box.set_layout (Gtk.ButtonBoxStyle.CENTER);
                action_button_box.halign = Gtk.Align.CENTER;
            }

            set_buttons_visible (true);
        }
        else {
            action_button_box.set_no_show_all (true);
            set_buttons_visible (false);
        }

        primary_text_label.set_markup (PRIMARY_TEXT_MARKUP.printf (Markup.escape_text (primary_text, -1)));
        secondary_text_label.set_markup (secondary_text);
    }

    public void set_primary_text_visible (bool visible) {
        set_widget_visible (primary_text_label, visible);
    }

    public void set_secondary_text_visible (bool visible) {
        set_widget_visible (secondary_text_label, visible);
    }

    public void set_icon_visible (bool visible) {
        set_widget_visible (image, visible);
    }

    public void set_buttons_visible (bool visible) {
        set_widget_visible (action_button_box, visible);
    }

    private static string get_icon_name_for_message_type (Gtk.MessageType message_type) {
        string icon_name = "";

        switch (message_type) {
            case Gtk.MessageType.ERROR:
                icon_name = ERROR_ICON;
                break;
            case Gtk.MessageType.WARNING:
                icon_name = WARNING_ICON;
                break;
            case Gtk.MessageType.QUESTION:
                icon_name = QUESTION_ICON;
                break;
            default:
                icon_name = INFO_ICON;
                break;
        }

        return icon_name;
    }

    private static void set_widget_visible (Gtk.Widget widget, bool visible) {
        widget.set_no_show_all (!visible);
        widget.set_visible (visible);
    }

    private static Gtk.Button? new_button_from_action (Gtk.Action action) {
        if (action == null)
            return null;

        bool has_label = action.label != null;
        bool has_stock = action.stock_id != null;
        bool has_gicon = action.gicon != null;
        bool has_tooltip = action.tooltip != null;

        Gtk.Button? action_button = null;

        // Prefer label over stock_id
        if (has_label)
            action_button = new Gtk.Button.with_label (action.label);
        else if (has_stock)
            action_button = new Gtk.Button.from_stock (action.stock_id);
        else
            action_button = new Gtk.Button ();

        // Prefer stock_id over gicon
        if (has_stock)
            action_button.set_image (new Gtk.Image.from_stock (action.stock_id, Gtk.IconSize.BUTTON));
        else if (has_gicon)
            action_button.set_image (new Gtk.Image.from_gicon (action.gicon, Gtk.IconSize.BUTTON));

        if (has_tooltip)
            action_button.set_tooltip_text (action.tooltip);

        return action_button;
    }
}
