/**
 * Minimal GTK bindings by Steve Teale
 *
 * License: Boost License 1.0
 *
 * Warning:
 * The GTK here is as simple as possible, but not useable for real world code.
 * At least the following features are missing:
 * * Drawing should be done to a Pixmap, then clipped onto the GTKWindow
 * * We always draw everything! Real code should determine the area that needs to be redrawn!
 * * Resizing support
 */
module cairo.examples.gtk;

version(GTK):

import cairo, cairo.c;
import core.stdc.config;
import cairo.example;

struct GtkWidget;
struct GtkWindow;
struct GtkContainer;
struct GdkWindow;
enum GTK_WINDOW_TOPLEVEL = 0;
enum GTK_WIN_POS_CENTER = 1;

extern(C) GtkWidget* gtk_window_new (int type);
extern(C) GtkWidget* gtk_drawing_area_new();
extern(C) void gtk_container_add(GtkContainer *container, GtkWidget *widget);
extern(C) c_ulong g_signal_connect_data (void* instance,
                       const char *detailed_signal,
                       void* c_handler,
                       void* data,
                       void* destroy_data,
                       int connect_flags);
extern(C) void gtk_window_set_position (GtkWindow *window, int position);
extern(C) void gtk_window_set_default_size (GtkWindow *window, int width, int height);
extern(C) void gtk_window_set_title (GtkWindow *window, const char *title);
extern(C) void gtk_widget_show_all (GtkWidget *widget);
extern(C) void gtk_main();
extern(C) void gtk_init(int*, char***);
extern(C) void gtk_main_quit();
extern(C) cairo_t* gdk_cairo_create (GdkWindow *window);
extern(C) GdkWindow * gtk_widget_get_window (GtkWidget *widget);

version(GTK3)
{
    extern(C) nothrow bool on_draw_event(GtkWidget *widget, cairo_t *cr, void* user_data)
    {
        import std.stdio;

        try
        {
            cairo_reference(cr);
            auto ctx = Context(cr);
            (cast(DrawFunction)user_data)(ctx);
        }
        catch(Throwable t)
        {
            import std.stdio;
            try{writefln("Unhandled exception: %s", t);}catch(Throwable){}
        }
        return false;
    }
}
else
{
    extern(C) nothrow bool on_draw_event(GtkWidget *widget, void * event, void* user_data)
    {
        import std.stdio;

        try
        {
            auto cr = gdk_cairo_create(gtk_widget_get_window (widget));
            //cairo_reference(cr);
            auto ctx = Context(cr);
            (cast(DrawFunction)user_data)(ctx);
        }
        catch(Throwable t)
        {
            import std.stdio;
            try{writefln("Unhandled exception: %s", t);}catch(Throwable){}
        }
        return false;
    }
}

void gtkRunExample(DrawFunction draw)
{
    import std.stdio;
    version(GTK3)
        writeln("Using GTK3");
    else
        writeln("Using GTK2");
    import core.runtime;
    int argc = Runtime.cArgs.argc;
    char** argv = Runtime.cArgs.argv;
    
    gtk_init(&argc, &argv);

    auto window = cast(GtkWindow*)gtk_window_new(GTK_WINDOW_TOPLEVEL);

    auto darea = gtk_drawing_area_new();
    gtk_container_add(cast(GtkContainer*)window, darea);

    version(GTK3)
    {
        g_signal_connect_data(darea, "draw".ptr, 
            &on_draw_event, draw, null, 1);
    }
    else
    {
        g_signal_connect_data(darea, "expose_event".ptr, 
            &on_draw_event, draw, null, 1);
    }
    g_signal_connect_data(window, "destroy".ptr,
        &gtk_main_quit, null, null, 1);

    gtk_window_set_position(window, GTK_WIN_POS_CENTER);
    gtk_window_set_default_size(window, 400, 400); 
    gtk_window_set_title(window, "GTK window");

    gtk_widget_show_all(cast(GtkWidget*)window);

    gtk_main();
}
