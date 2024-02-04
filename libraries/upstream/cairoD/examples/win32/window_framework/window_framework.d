module window_framework;

/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

/+
 + Shows one way to implement Widgets on top of WinAPI's
 + windowing framework. Makes use of Johannes Phauf's
 + updated std.signals module (renamed to signals.d to
 + avoid clashes).
 +
 + Demonstrates simple MenuBar and Menu widgets, as well
 + as mouse-enter and mouse-leave behavior.
 +/

/*
 * Major todo: We need to decouple assigning parents from construction,
 * otherwise we can't reparent or new() a widget and append
 * it to a container widget. So maybe only appending would create
 * the backbuffer.
 *
 * Major todo: Fork the Widget project and separate initialization
 * routines.
 */

import core.memory;
import core.runtime;
import core.thread;
import core.stdc.config;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.functional;
import std.math;
import std.random;
import std.range;
import std.stdio;
// import std.signals;  // outdated
import util.signals;  // new
import std.string;
import std.traits;
import std.utf;

pragma(lib, "gdi32.lib");

import windows.windef;
import windows.winuser;
import windows.wingdi;

alias std.algorithm.min min;
alias std.algorithm.max max;

import cairo.c.cairo;
import cairo.cairo;
import cairo.win32;

import util.rounded_rectangle;

struct StateContext
{
    // maybe add a scale() call, althought that wouldn't work good on specific shapes.
    Context ctx;

    this(Context ctx)
    {
        this.ctx = ctx;
        ctx.save();
    }

    ~this()
    {
        ctx.restore();
    }

    alias ctx this;
}

class PaintBuffer
{
    /* Each window with paintbuffer consumes 3 GDI objects (hBuffer, hBitmap, and hdc of the window). */
    this(HDC localHdc, int cxClient, int cyClient)
    {
        width  = cxClient;
        height = cyClient;

        hBuffer     = CreateCompatibleDC(localHdc);
        hBitmap     = CreateCompatibleBitmap(localHdc, cxClient, cyClient);
        hOldBitmap  = SelectObject(hBuffer, hBitmap);

        surf        = new Win32Surface(hBuffer);
        ctx         = Context(surf);
        initialized = true;
    }

    ~this()
    {
        if (initialized)
        {
            initialized = false;
            clear();
        }
    }

    void clear()
    {
        //~ surf.dispose();
        //~ ctx.dispose();
        //~ surf.finish();  // @BUG@: runtime exceptions

        SelectObject(hBuffer, hOldBitmap);
        DeleteObject(hBitmap);
        DeleteDC(hBuffer);

        initialized = false;
    }

    bool initialized;
    int  width, height;
    HDC  hBuffer;
    HBITMAP hBitmap;
    HBITMAP hOldBitmap;
    Context ctx;
    Surface surf;
}

HANDLE makeWindow(HWND hwnd, int childID = 1, string classname = WidgetClass, string description = null)
{
    return CreateWindow(classname.toUTF16z, description.toUTF16z,
                        WS_CHILDWINDOW | WS_VISIBLE | WS_CLIPCHILDREN,        // WS_CLIPCHILDREN is necessary
                        0, 0, 0, 0,                                           // Size!int and Position are set by MoveWindow
                        hwnd, cast(HANDLE)childID,                            // child ID
                        cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE), // hInstance
                        null);
}

abstract class Widget
{
    TRACKMOUSEEVENT mouseTrack;
    Widget parent;
    HWND hwnd;
    PaintBuffer paintBuffer;
    PAINTSTRUCT ps;

    int xOffset;
    int yOffset;
    int width, height;

    bool needsRedraw = true;
    bool isHidden;
    bool mouseEntered;

    Signal!() MouseLDown;
    alias MouseLDown MouseClick;

    Signal!(int, int) MouseMove;
    Signal!() MouseEnter;
    Signal!() MouseLeave;

    this(Widget parent, int xOffset = 0, int yOffset = 0, int width = 0, int height = 0)
    {
        this.parent  = parent;
        this.xOffset = xOffset;
        this.yOffset = yOffset;
        this.width   = width;
        this.height  = height;

        assert(parent !is null);
        hwnd = makeWindow(parent.hwnd);
        WidgetHandles[hwnd] = this;

        this.hwnd = hwnd;
        MoveWindow(hwnd, 0, 0, size.width, size.height, true);

        mouseTrack = TRACKMOUSEEVENT(TRACKMOUSEEVENT.sizeof, TME_LEAVE, hwnd, 0);
    }

    // children of the main window use this as the main window isn't a Widget type yet (to be done)
    this(HWND hParentWindow, int xOffset = 0, int yOffset = 0, int width = 0, int height = 0)
    {
        this.parent  = null;
        this.xOffset = xOffset;
        this.yOffset = yOffset;
        this.width   = width;
        this.height  = height;

        hwnd = makeWindow(hParentWindow);
        WidgetHandles[hwnd] = this;

        this.hwnd = hwnd;
        MoveWindow(hwnd, 0, 0, size.width, size.height, true);
    }

    @property Size!int size()
    {
        return Size!int(width, height);
    }

    @property void size(Size!int newsize)
    {
        width  = newsize.width;
        height = newsize.height;

        auto localHdc = GetDC(hwnd);

        if (paintBuffer !is null)
        {
            paintBuffer.clear();
        }

        paintBuffer = new PaintBuffer(localHdc, width, height);
        ReleaseDC(hwnd, localHdc);

        MoveWindow(hwnd, xOffset, yOffset, width, height, true);

        needsRedraw = true;
        blit();
    }

    void moveTo(int newXOffset, int newYOffset)
    {
        xOffset = newXOffset;
        yOffset = newYOffset;
        MoveWindow(hwnd, xOffset, yOffset, width, height, true);
    }

    void show()
    {
        if (isHidden)
        {
            ShowWindow(hwnd, true);
            isHidden = false;
        }
    }

    void hide()
    {
        if (!isHidden)
        {
            ShowWindow(hwnd, false);
            isHidden = true;
        }
    }

    LRESULT process(UINT message, WPARAM wParam, LPARAM lParam)
    {
        switch (message)
        {
            case WM_ERASEBKGND:
            {
                return 1;
            }

            case WM_PAINT:
            {
                OnPaint(hwnd, message, wParam, lParam);
                return 0;
            }

            case WM_SIZE:
            {
                width  = LOWORD(lParam);
                height = HIWORD(lParam);

                size(Size!int(width, height));
                return 0;
            }

            case WM_LBUTTONDOWN:
            {
                MouseLDown.emit();
                return 0;
            }

            case WM_MOUSELEAVE:
            {
                MouseLeave.emit();
                mouseEntered = false;
                return 0;
            }

            case WM_MOUSEMOVE:
            {
                TrackMouseEvent(&mouseTrack);

                // @BUG@ WinAPI bug, calling ShowWindow in succession can create
                // an infinite loop due to an odd WM_MOUSEMOVE call to the window
                // which issued the ShowWindow call to other windows.
                static LPARAM oldPosition;
                if (lParam != oldPosition)
                {
                    if (!mouseEntered)
                    {
                        MouseEnter.emit();
                        mouseEntered = true;
                    }

                    oldPosition = lParam;
                    auto xMousePos = cast(short)LOWORD(lParam);
                    auto yMousePos = cast(short)HIWORD(lParam);

                    MouseMove.emit(xMousePos, yMousePos);
                }

                return 0;
            }

            //~ case WM_TIMER:
            //~ {
                //~ blit();
                //~ return 0;
            //~ }

            case WM_DESTROY:
            {
                // @BUG@
                // Not doing this here causes exceptions being thrown from within cairo
                // when calling surface.dispose(). I'm not sure why yet.
                paintBuffer.clear();
                return 0;
            }

            default:
        }

        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    void redraw()
    {
        needsRedraw = true;
        blit();
    }

    void blit()
    {
        InvalidateRect(hwnd, null, true);
    }

    void OnPaint(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        auto ctx       = &paintBuffer.ctx;
        auto hBuffer   = paintBuffer.hBuffer;
        auto hdc       = BeginPaint(hwnd, &ps);
        auto boundRect = ps.rcPaint;

        if (needsRedraw)
        {
            draw(StateContext(*ctx));
            needsRedraw = false;
        }

        with (boundRect)
        {
            BitBlt(hdc, left, top, right - left, bottom - top, hBuffer, left, top, SRCCOPY);
        }

        EndPaint(hwnd, &ps);
    }

    void draw(StateContext ctx) { }
}

enum Alignment
{
    left,
    right,
    center,
    top,
    bottom,
}

class Button : Widget
{
    string name;
    string fontName;
    int fontSize;
    Alignment alignment;
    bool selected = true;

    this(Widget parent, string name, string fontName, int fontSize,
         Alignment alignment = Alignment.center, int xOffset = 0, int yOffset = 0, int width = 0, int height = 0)
    {
        auto textWidth = name.length * fontSize;
        width = textWidth;
        height = fontSize * 2;
        this.name = name;
        this.fontName = fontName;
        this.fontSize = fontSize;
        this.alignment = alignment;

        super(parent, xOffset, yOffset, width, height);
    }

    override void draw(StateContext ctx)
    {
        ctx.setSourceRGB(1, 1, 0);
        ctx.paint();

        ctx.setSourceRGB(0, 0, 0);
        ctx.selectFontFace(fontName, FontSlant.CAIRO_FONT_SLANT_NORMAL, FontWeight.CAIRO_FONT_WEIGHT_NORMAL);
        ctx.setFontSize(fontSize);

        final switch (alignment)
        {
            case Alignment.left:
            {
                ctx.moveTo(0, fontSize);
                break;
            }

            case Alignment.right:
            {
                break;
            }

            case Alignment.center:
            {
                // todo
                auto centerPos = (width - (name.length * 6)) / 2;
                //~ ctx.moveTo(centerPos, fontSize);
                ctx.moveTo(0, fontSize);
                break;
            }

            case Alignment.top:
            {
                break;
            }

            case Alignment.bottom:
            {
                break;
            }
        }

        ctx.showText(name);
    }
}

class MenuItem : Widget
{
    string name;
    string fontName;
    int fontSize;
    bool selected;

    this(Widget parent, string name, string fontName, int fontSize,
         int xOffset = 0, int yOffset = 0, int width = 0, int height = 0)
    {
        auto textWidth = name.length * fontSize;
        width = textWidth;

        height = fontSize * 2;
        this.name = name;
        this.fontName = fontName;
        this.fontSize = fontSize;

        super(parent, xOffset, yOffset, width, height);

        this.MouseEnter.connect({ selected = true; redraw(); });
        this.MouseLeave.connect({ selected = false; redraw(); });
    }

    override void draw(StateContext ctx)
    {
        if (selected)
            ctx.setSourceRGB(1, 0.9, 0);
        else
            ctx.setSourceRGB(1, 1, 0);

        ctx.paint();

        ctx.setSourceRGB(0, 0, 0);
        ctx.selectFontFace(fontName, FontSlant.CAIRO_FONT_SLANT_NORMAL, FontWeight.CAIRO_FONT_WEIGHT_NORMAL);
        ctx.setFontSize(fontSize);
        ctx.moveTo(0, fontSize);
        ctx.showText(name);
    }
}

class Menu : Widget
{
    MenuItem[] menuItems;
    size_t lastYOffset;

    // todo: main window will have to be a widget
    //~ this(Widget parent, MenuType menuType, int xOffset = 0, int yOffset = 0, int width = 0, int height = 0)
    //~ {
        //~ super(parent, xOffset, yOffset, width, height);
        //~ this.menuType = menuType;
    //~ }

    this(HWND hParentWindow, int xOffset = 0, int yOffset = 0, int width = 0, int height = 0)
    {
        super(hParentWindow, xOffset, yOffset, width, height);
    }

    void append(MenuItem menuItem)
    {
        width = max(width, menuItem.name.length * menuItem.fontSize);
        menuItems ~= menuItem;
        menuItem.moveTo(0, lastYOffset);

        this.size = Size!int(width, menuItems.length * menuItem.height);
        lastYOffset += menuItem.height;
    }

    MenuItem append(string name, string fontName, int fontSize)
    {
        auto textWidth = name.length * fontSize;
        width = max(width, textWidth);

        auto menuItem = new MenuItem(this, name, fontName, fontSize, 0);
        menuItem.moveTo(0, lastYOffset);
        menuItems ~= menuItem;

        this.size = Size!int(width, menuItems.length * menuItem.height);
        lastYOffset += menuItem.height;

        return menuItem;
    }

    override void draw(StateContext ctx)
    {
        // todo: draw bg and separators
        ctx.setSourceRGB(0.8, 0.8, 0.8);
        ctx.paint();
    }
}

class MenuBar : Widget
{
    Menu[] menus;
    Button[] buttons;
    size_t lastXOffset;
    Menu activeMenu;
    bool isMenuOpened;

    // todo: main window will have to be a widget
    //~ this(Widget parent, int xOffset = 0, int yOffset = 0, int width = 0, int height = 0)
    //~ {
        //~ super(parent, xOffset, yOffset, width, height);
    //~ }

    this(HWND hParentWindow, int xOffset = 0, int yOffset = 0, int width = 0, int height = 0)
    {
        super(hParentWindow, xOffset, yOffset, width, height);
    }

    void showMenu(size_t index)
    {
        assert(index < menus.length);

        if (activeMenu !is null)
            activeMenu.hide();

        activeMenu = menus[index];

        if (isMenuOpened)
            activeMenu.show();
        else
            activeMenu.hide();
    }

    void append(Menu menu, string name)
    {
        static size_t menuIndex;
        enum fontSize = 10;
        enum fontName = "Arial";
        immutable yOffset = 2 * fontSize;

        auto button = new Button(this, name, fontName, fontSize);
        this.size = Size!int(width + button.width, yOffset);

        int frameIndex = menuIndex++;

        buttons ~= button;
        button.moveTo(lastXOffset, 0);

        button.MouseLDown.connect({ this.isMenuOpened ^= 1; this.showMenu(frameIndex); });
        button.MouseEnter.connect({ this.showMenu(frameIndex); });

        menus ~= menu;
        menu.hide();
        menu.moveTo(lastXOffset, yOffset);

        lastXOffset += button.width;
    }

    override void draw(StateContext ctx)
    {
        ctx.setSourceRGB(0, 1, 1);
        ctx.paint();
    }
}

/* A place to hold Widget objects. Since each window has a unique HWND,
 * we can use this hash type to store references to Widgets and call
 * their window processing methods.
 */
Widget[HWND] WidgetHandles;

/*
 * All Widget windows have this window procedure registered via RegisterClass(),
 * we use it to dispatch to the appropriate Widget window processing method.
 *
 * A similar technique is used in the DFL and DGUI libraries for all of its
 * windows and widgets.
 */
extern (Windows)
LRESULT winDispatch(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    auto widget = hwnd in WidgetHandles;

    if (widget !is null)
    {
        return widget.process(message, wParam, lParam);
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
LRESULT mainWinProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static PaintBuffer paintBuffer;
    static int width, height;

    void draw(StateContext ctx)
    {
        ctx.setSourceRGB(1, 1, 1);
        ctx.paint();
    }

    switch (message)
    {
        case WM_CREATE:
        {
            auto hDesk = GetDesktopWindow();
            RECT rc;
            GetClientRect(hDesk, &rc);

            auto localHdc = GetDC(hwnd);
            paintBuffer = new PaintBuffer(localHdc, rc.right, rc.bottom);

            auto menuBar = new MenuBar(hwnd);

            // todo
            //~ auto fontSettings = FontSettings("Arial", 10);

            auto fileMenu = new Menu(hwnd);

            auto item = fileMenu.append("item1", "Arial", 10);
            item.MouseLDown.connect( { writeln("Clicked."); } );

            menuBar.append(fileMenu, "File");

            return 0;
        }

        case WM_LBUTTONDOWN:
        {
            SetFocus(hwnd);
            return 0;
        }

        case WM_SIZE:
        {
            width  = LOWORD(lParam);
            height = HIWORD(lParam);
            return 0;
        }

        case WM_PAINT:
        {
            auto ctx     = paintBuffer.ctx;
            auto hBuffer = paintBuffer.hBuffer;
            PAINTSTRUCT ps;
            auto hdc       = BeginPaint(hwnd, &ps);
            auto boundRect = ps.rcPaint;

            draw(StateContext(paintBuffer.ctx));

            with (boundRect)
            {
                BitBlt(hdc, left, top, right - left, bottom - top, paintBuffer.hBuffer, left, top, SRCCOPY);
            }

            EndPaint(hwnd, &ps);
            return 0;
        }

        case WM_TIMER:
        {
            InvalidateRect(hwnd, null, true);
            return 0;
        }

        case WM_MOUSEWHEEL:
        {
            return 0;
        }

        case WM_DESTROY:
        {
            PostQuitMessage(0);
            return 0;
        }

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

string WidgetClass = "WidgetClass";

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "Window Framework";

    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    /* One class for the main window */
    wndclass.lpfnWndProc   = &mainWinProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(null, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(null, IDC_ARROW);
    wndclass.hbrBackground = null;
    wndclass.lpszMenuName  = null;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(null, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    /* Separate window class for Widgets. */
    wndclass.hbrBackground = null;
    wndclass.lpfnWndProc   = &winDispatch;
    wndclass.cbWndExtra    = 0;
    wndclass.hIcon         = null;
    wndclass.lpszClassName = WidgetClass.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(null, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z, "step sequencer",
                        WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,  // WS_CLIPCHILDREN is necessary
                        cast(int)(1680 / 3.3), 1050 / 3,
                        400, 400,
                        null, null, hInstance, null);

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, null, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    int result;


    try
    {
        Runtime.initialize();
        myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate();
    }
    catch (Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = -1;
    }

    return result;
}
