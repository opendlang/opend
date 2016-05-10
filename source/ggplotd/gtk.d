module ggplotd.gtk;

version(ggplotdGTK):

import cairod = cairo.cairo;
import gtk.DrawingArea : DrawingArea;

class SurfaceArea : DrawingArea
{
    import gtkc = cairo.Context;
    import gtk.Widget : GtkAllocation, Widget;
    import glib.Timeout : Scoped, Timeout;

    public:
    this()
	{
        surface = new cairod.ImageSurface(cairod.Format.CAIRO_FORMAT_ARGB32, width, height);
		//Attach our expose callback, which will draw the window.
		addOnDraw(&drawCallback);
	}

protected:
	//Override default signal handler:
	bool drawCallback(Scoped!(gtkc.Context) cr, Widget widget)
	{
        import gtkp = cairo.Pattern;

		if ( m_timeout is null )
		{
			// Create a new timeout that will ask the window to be drawn 2 times 
            // every second.
			m_timeout = new Timeout( 500, &onElapsed, false );
		}

		// This is where we draw on the window
		GtkAllocation size;

		getAllocation(size);

        /*
           Surface to pattern. Scale it appropiatly and then use setSource.
           */
        cairod.SurfacePattern pattern = new cairod.SurfacePattern( surface );
        cairod.Matrix matrix;
        import std.conv : to;
        matrix.initScale( width.to!double/size.width, height.to!double/size.height );
        pattern.setMatrix( matrix );

        /*
           gtk-d cairo interface and cairod both wrap the same C cairo_pattern_t
           so this cast should be save.
        */
        gtkp.Pattern gtkPattern = new gtkp.Pattern(cast (gtkp.cairo_pattern_t*) pattern.nativePointer);

        cr.setSource(gtkPattern);
        cr.paint();
		return true;
	}

	bool onElapsed()
	{
		//force our program to redraw the entire clock once per every second.
		GtkAllocation area;
		getAllocation(area);

		queueDrawArea(area.x, area.y, area.width, area.height);
		
		return true;
	}

	Timeout m_timeout;

    cairod.Surface surface;

    int width = 470;
    int height = 470;
}

import core.thread;
/**
* Helper class to open a GTK window and draw to it
*
* Examples:
* --------------------
* // Code to create the aes here
* // ...
*
* // Start gtk window.
* const width = 470;
* const height = 470;
* auto gd = new GTKWindow();
* auto tid = new Thread(() { gd.run("plotcli", width, height); }).start();
* auto gg = GGPlotD().put( geomHist2D( aes ) );
* gd.draw( gg, width, height );
* Thread.sleep( dur!("seconds")( 2 ) ); // sleep for 5 seconds
* 
* gg = GGPlotD().put( geomPoint( aes ) );
* gd.clearWindow();
* gd.draw( gg, width, height );
* 
* // Wait for gtk thread to finish (Window closed)
* tid.join();
* --------------------
*/
class GTKWindow
{
    import gtk.MainWindow : MainWindow;
    import gtk.Main : Main;
    import ggplotd.ggplotd : GGPlotD;

    this() {
        string[] args;
        Main.init(args);
        sa = new SurfaceArea();
        sa.surface = new cairod.ImageSurface(cairod.Format.CAIRO_FORMAT_ARGB32, 470, 470);
    }

    ///
    void draw(T)( T gg, int width, int height )
    {
        // Testing seems to indicate this doesn't need a mutex?
        sa.width = width;
        sa.height = height;
        // Writing to cairo surfaces should be safe. Displayer only reads from it.
        sa.surface = new cairod.ImageSurface(cairod.Format.CAIRO_FORMAT_ARGB32, width, height);
        gg.drawToSurface( sa.surface, width, height );
    }
 
    ///
    void clearWindow()
    {
        cairod.RGBA colour = cairod.RGBA(1,1,1,1);
        auto backcontext = cairod.Context(sa.surface);
        backcontext.setSourceRGBA(colour);
        backcontext.paint;
    }

    /**
    * Open the window and run the mainloop. This is blocking, due to the mainloop.
    *
    * It should be safe to run threaded though
    */
    void run(string title, int width = 470, int height = 470)
    {
        MainWindow win = new MainWindow(title);

        win.setDefaultSize( width, height );

        win.add(sa);
        sa.show();
        win.showAll();

        Main.run();
    }

    SurfaceArea sa;
}
