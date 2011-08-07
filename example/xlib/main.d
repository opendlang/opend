import std.string;
import std.stdio;

import cairo.cairo;
import cairo.xlib;

import std.c.linux.X11.Xlib;
import std.c.linux.X11.X;

/*
 * Warning:
 * This example is more a proof of concept than a tutorial how
 * xlib should be used. Please look at a xlib tutorial to learn
 * how to use it correctly.
 *
 * Among other things, this example doesn't handle window-close
 * events correctly.
 *
 * Original code from:
 * http://en.literateprograms.org/Hello_World_(C,_Cairo)#Xlib_backend
 */
void main()
{
    showXLIB();
}

bool showXLIB()
{
    auto dpy = XOpenDisplay(null);

    if(dpy is null)
    {
        stderr.writeln("ERROR: Could not open display");
        return false;
    }

    auto scr = XDefaultScreen(dpy);
    if(scr < 0)
    {
        stderr.writeln("ERROR: Could not open screen");
        return false;
    }
    auto rootwin = XRootWindow(dpy, scr);

    auto win = XCreateSimpleWindow(dpy, rootwin, 1, 1, 400, 200, 0, 
               XBlackPixel(dpy, scr), XBlackPixel(dpy, scr));

    //Hack, xlib bindings should be fixed
    char* winName = cast(char*)(toStringz("CairoD XLIB example".dup));
    XStoreName(dpy, win, winName);
    XSelectInput(dpy, win, EventMask.ExposureMask | EventMask.ButtonPressMask);
    XMapWindow(dpy, win);

    auto surface = new XlibSurface(dpy, win, XDefaultVisual(dpy, 0), 400, 200);
    auto ctx = Context(surface);

    XEvent e;
    while(true)
    {
        XNextEvent(dpy, &e);
        if(e.type == EventType.Expose && e.xexpose.count < 1)
        {
            paint(ctx);
        }
        else if(e.type == EventType.ButtonPress)
            break;
    }

    surface.dispose();
    XCloseDisplay(dpy);
    return true;
}

void paint(Context ctx)
{
    ctx.rectangle(Rectangle(Point(0, 0), 400, 200));
    ctx.setSourceRGB(1, 1, 1); 
    ctx.fill();
    ctx.moveTo(Point(50.0, 50.0));
    ctx.setSourceRGB(0, 0, 0);
    ctx.setFontSize(50);
    ctx.showText("Hello XLIB!");
}
