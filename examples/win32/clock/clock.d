module clock;

/+
 + Original author: Brad Elliott (20 Jan 2008)
 + Derived from http://code.google.com/p/wxcairo
 +
 + Ported to D2 by Andrej Mitrovic, 2011.
 + Using CairoD and win32.
 +/

import core.memory;
import core.runtime;
import core.thread;
import core.stdc.config;

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
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

import windows.winbase;
import windows.windef;
import windows.winuser;
import windows.wingdi;

alias std.algorithm.min min; // conflict resolution
alias std.algorithm.max max; // conflict resolution

import cairo.cairo;
import cairo.win32;

alias cairo.cairo.RGB RGB;   // conflict resolution

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


class PaintBuffer
{
    this(HDC localHdc, int cxClient, int cyClient)
    {
        hdc    = localHdc;
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
        ctx.dispose();
        surf.finish();
        surf.dispose();

        SelectObject(hBuffer, hOldBitmap);
        DeleteObject(hBitmap);
        DeleteDC(hBuffer);
        initialized = false;
    }

    HDC  hdc;
    bool initialized;
    int  width, height;
    HDC  hBuffer;
    HBITMAP hBitmap;
    HBITMAP hOldBitmap;
    Context ctx;
    Surface surf;
}

abstract class Widget
{
    Widget parent;
    PAINTSTRUCT ps;
    PaintBuffer mainPaintBuff;
    PaintBuffer paintBuffer;
    HWND hwnd;
    int  width, height;
    int  xOffset, yOffset;
    bool needsRedraw = true;

    this(HWND hwnd, int width, int height)
    {
        this.hwnd   = hwnd;
        this.width  = width;
        this.height = height;

        //~ SetTimer(hwnd, 100, 1, null);
    }

    @property Size!int size()
    {
        return Size!int (width, height);
    }

    void blit()
    {
        InvalidateRect(hwnd, null, true);
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
                OnTimer();
                return 0;
            }

            case WM_MOVE:
            {
                xOffset = LOWORD(lParam);
                yOffset = HIWORD(lParam);
                return 0;
            }

            case WM_DESTROY:
            {
                paintBuffer.clear();
                return 0;
            }

            default:
        }

        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    void OnTimer();
    abstract void OnPaint(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    abstract void draw(StateContext ctx);
}

class CairoClock : Widget
{
    enum TimerID = 100;

    this(HWND hwnd, int width, int height)
    {
        super(hwnd, width, height);
        SetTimer(hwnd, TimerID, 1000, null);

        // Grab the current time
        GrabCurrentTime();
    }

    override LRESULT process(UINT message, WPARAM wParam, LPARAM lParam)
    {
        return super.process(message, wParam, lParam);
    }

    override void OnPaint(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        auto ctx       = paintBuffer.ctx;
        auto hBuffer   = paintBuffer.hBuffer;
        auto hdc       = BeginPaint(hwnd, &ps);
        auto boundRect = ps.rcPaint;

        if (needsRedraw)
        {
            draw(StateContext(ctx));
            needsRedraw = false;
        }

        with (boundRect)
        {
            BitBlt(hdc, left, top, right - left, bottom - top, paintBuffer.hBuffer, left, top, SRCCOPY);
        }

        EndPaint(hwnd, &ps);
    }

    void GrabCurrentTime()
    {
        auto currentTime = Clock.currTime();

        if (currentTime.hour >= 12)
        {
            m_hour_angle = (currentTime.hour - 12) * PI / 15 + PI / 2;
        }
        else
        {
            m_hour_angle = currentTime.hour * PI / 15 + PI / 2;
        }

        m_minute_angle = (currentTime.minute) * PI / 30 - PI / 2;
        m_second_angle = (currentTime.second) * PI / 30 - PI / 2 + PI / 30;
    }

    override void OnTimer()
    {
        GrabCurrentTime();
        needsRedraw = true;
        blit();
    }

    override void draw(StateContext ctx)
    {
        double cx     = width / 2;
        double cy     = height / 2;
        double radius = height / 2 - 60;

        ctx.setLineWidth(0.7);

        double sin_of_hour_angle   = sin(m_hour_angle);
        double cos_of_hour_angle   = cos(m_hour_angle);
        double sin_of_minute_angle = sin(m_minute_angle);
        double cos_of_minute_angle = cos(m_minute_angle);
        double sin_of_second_angle = sin(m_second_angle);
        double cos_of_second_angle = cos(m_second_angle);

        // Draw a white background for the clock
        ctx.setSourceRGB(1, 1, 1);
        ctx.rectangle(0, 0, width, height);
        ctx.fill();
        ctx.stroke();

        // Draw the outermost circle which forms the
        // black radius of the clock.
        ctx.setSourceRGB(0, 0, 0);
        ctx.arc(cx,
                cy,
                radius + 30,
                0 * PI,
                2 * PI);
        ctx.fill();

        ctx.setSourceRGB(1, 1, 1);
        ctx.arc(cx,
                cy,
                radius + 25,
                0 * PI,
                2 * PI);
        ctx.fill();

        ctx.setSourceRGB(0xC0 / 256.0, 0xC0 / 256.0, 0xC0 / 256.0);
        ctx.arc(cx,
                cy,
                radius,
                0 * PI,
                2 * PI);
        ctx.fill();

        ctx.setSourceRGB(0xE0 / 256.0, 0xE0 / 256.0, 0xE0 / 256.0);
        ctx.arc(cx,
                cy,
                radius - 10,
                0 * PI,
                2 * PI);
        ctx.fill();

        // Finally draw the border in black
        ctx.setLineWidth(0.7);
        ctx.setSourceRGB(0, 0, 0);
        ctx.arc(cx,
                cy,
                radius,
                0 * PI,
                2 * PI);
        ctx.stroke();

        // Now draw the hour arrow
        ctx.setSourceRGB(0, 0, 0);
        ctx.newPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx - radius * 0.05 * sin_of_hour_angle,
                   cy + radius * 0.05 * cos_of_hour_angle);
        ctx.lineTo(cx + radius * 0.55 * cos_of_hour_angle,
                   cy + radius * 0.55 * sin_of_hour_angle);
        ctx.lineTo(cx + radius * 0.05 * sin_of_hour_angle,
                   cy - radius * 0.05 * cos_of_hour_angle);
        ctx.lineTo(cx - radius * 0.05 * cos_of_hour_angle,
                   cy - radius * 0.05 * sin_of_hour_angle);
        ctx.lineTo(cx - radius * 0.05 * sin_of_hour_angle,
                   cy + radius * 0.05 * cos_of_hour_angle);
        ctx.closePath();
        ctx.fill();

        // Minute arrow
        ctx.setSourceRGB(0, 0, 0);
        ctx.newPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx - radius * 0.04 * sin_of_minute_angle,
                   cy + radius * 0.04 * cos_of_minute_angle);
        ctx.lineTo(cx + radius * 0.95 * cos_of_minute_angle,
                   cy + radius * 0.95 * sin_of_minute_angle);
        ctx.lineTo(cx + radius * 0.04 * sin_of_minute_angle,
                   cy - radius * 0.04 * cos_of_minute_angle);
        ctx.lineTo(cx - radius * 0.04 * cos_of_minute_angle,
                   cy - radius * 0.04 * sin_of_minute_angle);
        ctx.lineTo(cx - radius * 0.04 * sin_of_minute_angle,
                   cy + radius * 0.04 * cos_of_minute_angle);
        ctx.closePath();
        ctx.fill();

        // Draw the second hand in red
        ctx.setSourceRGB(0x70 / 256.0, 0, 0);
        ctx.newPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx - radius * 0.02 * sin_of_second_angle,
                   cy + radius * 0.02 * cos_of_second_angle);
        ctx.lineTo(cx + radius * 0.98 * cos_of_second_angle,
                   cy + radius * 0.98 * sin_of_second_angle);
        ctx.lineTo(cx + radius * 0.02 * sin_of_second_angle,
                   cy - radius * 0.02 * cos_of_second_angle);
        ctx.lineTo(cx - radius * 0.02 * cos_of_second_angle,
                   cy - radius * 0.02 * sin_of_second_angle);
        ctx.lineTo(cx - radius * 0.02 * sin_of_second_angle,
                   cy + radius * 0.02 * cos_of_second_angle);
        ctx.closePath();
        ctx.fill();

        // now draw the circle inside the arrow
        ctx.setSourceRGB(1, 1, 1);
        ctx.arc(cx,
                cy,
                radius * 0.02,
                0 * PI,
                2.0 * PI);
        ctx.fill();

        // now draw the small minute markers
        ctx.setLineWidth(1.2);
        ctx.setSourceRGB(0, 0, 0);

        for (double index = 0; index < PI / 2; index += (PI / 30))
        {
            double start = 0.94;

            // draw the markers at the bottom right half of the clock
            ctx.newPath();
            ctx.moveTo(cx + radius * start * cos(index),
                       cy + radius * start * sin(index));
            ctx.lineTo(cx + radius * cos(index - PI / 240),
                       cy + radius * sin(index - PI / 240));
            ctx.lineTo(cx + radius * cos(index + PI / 240),
                       cy + radius * sin(index + PI / 240));
            ctx.closePath();
            ctx.fill();

            // draw the markers at the bottom left half of the clock
            ctx.newPath();
            ctx.moveTo(cx - radius * start * cos(index),
                       cy + radius * start * sin(index));
            ctx.lineTo(cx - radius * cos(index - PI / 240),
                       cy + radius * sin(index - PI / 240));
            ctx.lineTo(cx - radius * cos(index + PI / 240),
                       cy + radius * sin(index + PI / 240));
            ctx.closePath();
            ctx.fill();

            // draw the markers at the top left half of the clock
            ctx.newPath();
            ctx.moveTo(cx - radius * start * cos(index),
                       cy - radius * start * sin(index));
            ctx.lineTo(cx - radius * cos(index - PI / 240),
                       cy - radius * sin(index - PI / 240));
            ctx.lineTo(cx - radius * cos(index + PI / 240),
                       cy - radius * sin(index + PI / 240));
            ctx.closePath();
            ctx.fill();

            // draw the markers at the top right half of the clock
            ctx.newPath();
            ctx.moveTo(cx + radius * start * cos(index),
                       cy - radius * start * sin(index));
            ctx.lineTo(cx + radius * cos(index - PI / 240),
                       cy - radius * sin(index - PI / 240));
            ctx.lineTo(cx + radius * cos(index + PI / 240),
                       cy - radius * sin(index + PI / 240));
            ctx.closePath();
            ctx.fill();
        }

        // now draw the markers
        ctx.setLineWidth(1.2);
        ctx.setSourceRGB(0.5, 0.5, 0.5);

        for (double index = 0; index <= PI / 2; index += (PI / 6))
        {
            double start = 0.86;

            // draw the markers at the bottom right half of the clock
            ctx.newPath();
            ctx.moveTo(cx + radius * start * cos(index),
                       cy + radius * start * sin(index));
            ctx.lineTo(cx + radius * cos(index - PI / 200),
                       cy + radius * sin(index - PI / 200));
            ctx.lineTo(cx + radius * cos(index + PI / 200),
                       cy + radius * sin(index + PI / 200));
            ctx.closePath();
            ctx.fill();

            // draw the markers at the bottom left half of the clock
            ctx.newPath();
            ctx.moveTo(cx - radius * start * cos(index),
                       cy + radius * start * sin(index));
            ctx.lineTo(cx - radius * cos(index - PI / 200),
                       cy + radius * sin(index - PI / 200));
            ctx.lineTo(cx - radius * cos(index + PI / 200),
                       cy + radius * sin(index + PI / 200));
            ctx.closePath();
            ctx.fill();

            // draw the markers at the top left half of the clock
            ctx.newPath();
            ctx.moveTo(cx - radius * start * cos(index),
                       cy - radius * start * sin(index));
            ctx.lineTo(cx - radius * cos(index - PI / 200),
                       cy - radius * sin(index - PI / 200));
            ctx.lineTo(cx - radius * cos(index + PI / 200),
                       cy - radius * sin(index + PI / 200));
            ctx.closePath();
            ctx.fill();

            // draw the markers at the top right half of the clock
            ctx.newPath();
            ctx.moveTo(cx + radius * start * cos(index),
                       cy - radius * start * sin(index));
            ctx.lineTo(cx + radius * cos(index - PI / 200),
                       cy - radius * sin(index - PI / 200));
            ctx.lineTo(cx + radius * cos(index + PI / 200),
                       cy - radius * sin(index + PI / 200));
            ctx.closePath();
            ctx.fill();
        }
    }

    // The angle of each of each clock hand.
    double m_hour_angle;
    double m_minute_angle;
    double m_second_angle;
}

/* A place to hold Widget objects. Since each window has a unique HWND,
 * we can use this hash type to store references to Widgets and call
 * their window processing methods.
 */
__gshared Widget[HWND] WidgetHandles;

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

    static HMENU widgetID = cast(HMENU)0;

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

            auto hWindow = CreateWindow(WidgetClass.toUTF16z, null,
                                        WS_CHILDWINDOW | WS_VISIBLE | WS_CLIPCHILDREN,        // WS_CLIPCHILDREN is necessary
                                        0, 0, 0, 0,
                                        hwnd, widgetID,                                       // child ID
                                        cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE), // hInstance
                                        null);

            GetClientRect(hwnd, &rc);
            auto widget = new CairoClock(hWindow, 400, 400);
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
            paintBuffer.clear();
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
    string appName = "CairoClock";

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
        auto lastErr = GetLastError();
        auto lastError = toUTFz!(const(wchar)*)(format("Error: %s", lastErr));
        MessageBox(null, lastError, appName.toUTF16z, MB_ICONERROR);
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

    hwnd = CreateWindow(appName.toUTF16z, "CairoD Clock",
                        WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,  // WS_CLIPCHILDREN is necessary
                        CW_USEDEFAULT, CW_USEDEFAULT,
                        420, 420,
                        null, null, hInstance, null);

    auto hDesk = GetDesktopWindow();
    RECT rc;
    GetClientRect(hDesk, &rc);
    MoveWindow(hwnd, rc.right / 3, rc.bottom / 3, 420, 420, true);

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
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate();
    }
    catch (Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}
