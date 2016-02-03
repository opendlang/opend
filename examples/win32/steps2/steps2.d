module steps2;

/+
 + A prototype step-sequencer Widget example. You can press and hold
 + the left mouse button and drag the mouse to activate multiple steps.
 + If you first clicked on an active step, the mode is changed to
 + deactivating, so the steps you drag over will be deactivated.
 +
 + Extended version has a timer, time steps, and is heavily refactored.
 +/

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
import std.string;
import std.traits;
import std.utf;

pragma(lib, "gdi32.lib");

import windows.windef;
import windows.winuser;
import windows.wingdi;

alias std.algorithm.min min;
alias std.algorithm.max max;

import cairo.cairo;
import cairo.win32;

alias cairo.cairo.RGB RGB;

import util.rounded_rectangle;

struct StateContext
{
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

/* Each allocation consumes 3 GDI objects. */
class PaintBuffer
{
    this(HDC localHdc, int cxClient, int cyClient)
    {
        width  = cxClient;
        height = cyClient;

        hBuffer    = CreateCompatibleDC(localHdc);
        hBitmap    = CreateCompatibleBitmap(localHdc, cxClient, cyClient);
        hOldBitmap = SelectObject(hBuffer, hBitmap);

        surf        = new Win32Surface(hBuffer);
        ctx         = Context(surf);
        initialized = true;
    }

    ~this()
    {
        if (initialized)
        {
            clear();
        }
    }

    void clear()
    {
        SelectObject(hBuffer, hOldBitmap);
        DeleteObject(hBitmap);
        DeleteDC(hBuffer);

        //~ surf.dispose();
        //~ ctx.dispose();
        //~ surf.finish();

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

enum RoundingMethod = RoundMethod.C;

abstract class Widget
{
    Widget parent;
    PaintBuffer paintBuffer;
    PAINTSTRUCT ps;

    HWND hwnd;
    int  width, height;
    bool needsRedraw = true;

    this(Widget parent, HWND hwnd, int width, int height)
    {
        this.parent = parent;
        this.hwnd   = hwnd;
        this.width  = width;
        this.height = height;
    }

    @property Size!int size()
    {
        return Size!int(width, height);
    }

    abstract LRESULT process(UINT message, WPARAM wParam, LPARAM lParam)
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

                auto localHdc = GetDC(hwnd);

                if (paintBuffer !is null)
                {
                    paintBuffer.clear();
                }

                paintBuffer = new PaintBuffer(localHdc, width, height);
                ReleaseDC(hwnd, localHdc);

                needsRedraw = true;
                blit();
                return 0;
            }

            case WM_TIMER:
            {
                blit();
                return 0;
            }

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

    abstract void draw(StateContext ctx);
}

class StepWidget : Widget
{
    static size_t curBeat;
    static bool selectState;

    this(Widget parent, HWND hwnd, int width, int height)
    {
        super(parent, hwnd, width, height);
    }
}

class Step : StepWidget
{
    bool  _selected;
    size_t beatIndex;

    @property void selected(bool state)
    {
        _selected = state;
        redraw();
    }

    @property bool selected()
    {
        return _selected;
    }

    this(Widget parent, size_t beatIndex, HWND hwnd, int width, int height)
    {
        this.beatIndex = beatIndex;
        super(parent, hwnd, width, height);
    }

    override LRESULT process(UINT message, WPARAM wParam, LPARAM lParam)
    {
        switch (message)
        {
            case WM_LBUTTONDOWN:
            {
                selected = !selected;
                selectState = selected;
                break;
            }

            case WM_MOUSEMOVE:
            {
                if (wParam & MK_LBUTTON)
                {
                    selected = selectState;
                }

                break;
            }

            default:
        }

        return super.process(message, wParam, lParam);
    }

    override void draw(StateContext ctx)
    {
        ctx.rectangle(1, 1, width - 2, height - 2);
        ctx.setSourceRGB(0, 0, 0.8);
        ctx.fill();

        if (selected)
        {
            auto darkCyan = RGB(0, 0.6, 1);
            ctx.setSourceRGB(darkCyan);
            int index, xPos, yPos;

            // @BUG@ 6569: alias this not usable with template overloads, cast needed.
            roundedRectangle!(RoundingMethod)(cast(Context)ctx, 5.0, 5.0, width - 10.0, height - 10.0, 15.0);
            ctx.fill();

            if (beatIndex == curBeat)
            {
                ctx.setSourceRGB(1, 1, 0);
            }
            else
            {
                ctx.setSourceRGB(brightness(darkCyan, + 0.4));
            }

            roundedRectangle!(RoundingMethod)(cast(Context)ctx, 10, 10, width - 20, height - 20, 15);
            ctx.fill();
        }
    }
}

class TimeStep : StepWidget
{
    size_t beatIndex;

    this(Widget parent, size_t beatIndex, HWND hwnd, int width, int height)
    {
        this.beatIndex = beatIndex;
        super(parent, hwnd, width, height);
    }

    override LRESULT process(UINT message, WPARAM wParam, LPARAM lParam)
    {
        return super.process(message, wParam, lParam);
    }

    override void draw(StateContext ctx)
    {
        ctx.rectangle(1, 1, width - 2, height - 2);
        ctx.setSourceRGB(0, 0, 0.6);
        ctx.fill();

        if (beatIndex == curBeat)
        {
            auto darkBlue = RGB(0, 0, 0.8);
            ctx.setSourceRGB(darkBlue);
            roundedRectangle!(RoundingMethod)(cast(Context)ctx, 5, 5, width - 10, height - 10, 15);
            ctx.fill();

            ctx.setSourceRGB(brightness(darkBlue, + 0.2));
            roundedRectangle!(RoundingMethod)(cast(Context)ctx, 10, 10, width - 20, height - 20, 15);
            ctx.fill();
        }
    }
}

class Steps : Widget
{
    enum BeatCount = 6;  // horizontal steps
    enum StepCount = 6;  // vertical steps

    TimeStep[BeatCount] timeSteps;
    Step[StepCount][BeatCount] steps;
    size_t curBeat;

    int stepWidth;
    int stepHeight;

    // note: the main window is still not a Widget class, so parent is null
    this(Widget parent, HWND hwnd, int width, int height)
    {
        super(parent, hwnd, width, height);

        stepWidth  = width / BeatCount;
        stepHeight = height / 10;

        createWidgets!TimeStep();
        createWidgets!Step(stepHeight);

        StepWidget.curBeat = curBeat;

        enum TimerID = 500;
        SetTimer(hwnd, TimerID, 1000 / 4, null);
    }

    // todo: figure out how to remove code duplication here. The root cause is
    // the 1 vs 2 foreach loops.
    void createWidgets(WidgetType)(size_t vOffset = 0) if (is(WidgetType == TimeStep))
    {
        foreach (beatIndex; 0 .. BeatCount)
        {
            auto hWindow = makeWindow(hwnd);
            auto widget = new WidgetType(this, beatIndex, hWindow, stepWidth, stepHeight);
            WidgetHandles[hWindow] = widget;
            timeSteps[beatIndex]   = widget;

            auto size = widget.size;
            MoveWindow(hWindow, beatIndex * stepWidth, 0, size.width, size.height, true);
        }
    }

    void createWidgets(WidgetType)(size_t vOffset = 0) if (is(WidgetType == Step))
    {
        foreach (beatIndex; 0 .. BeatCount)
        {
            foreach (stepIndex; 0 .. StepCount)
            {
                auto hWindow = makeWindow(hwnd);
                auto widget = new WidgetType(this, beatIndex, hWindow, stepWidth, stepHeight);
                WidgetHandles[hWindow]      = widget;
                steps[beatIndex][stepIndex] = widget;

                auto size = widget.size;
                MoveWindow(hWindow, beatIndex * stepWidth, vOffset + (stepIndex * stepHeight), size.width, size.height, true);
            }
        }
    }

    void redrawSteps(size_t beatIndex)
    {
        timeSteps[beatIndex].redraw();
        foreach (step; steps[beatIndex])
            step.redraw();
    }

    override LRESULT process(UINT message, WPARAM wParam, LPARAM lParam)
    {
        switch (message)
        {
            case WM_TIMER:
            {
                redrawSteps(curBeat);

                curBeat = (curBeat + 1) % BeatCount;
                StepWidget.curBeat = curBeat;

                redrawSteps(curBeat);
                return 0;
            }

            default:
        }

        return super.process(message, wParam, lParam);
    }

    override void draw(StateContext ctx)
    {
        ctx.setSourceRGB(1, 1, 1);
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

            auto hWindow = makeWindow(hwnd);
            auto widget = new Steps(null, hWindow, 400, 400);
            WidgetHandles[hWindow] = widget;

            auto size = widget.size;
            MoveWindow(hWindow, 0, 0, size.width, size.height, true);

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
    string appName = "Step Sequencer";

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
