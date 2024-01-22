module double_buffer;

/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

/+
 + Demonstrates the usage of a double-buffer using Cairo and win32.
 + Also shows how to avoid re-blitting an area by simply using the
 + ps.rcPaint bounding rectangle field, and removing redrawing of
 + the entire window when it is resized.
 +
 + For more info on double-buffering and avoiding screen flicker, see:
 + http://wiki.osdev.org/Double_Buffering
 + http://www.catch22.net/tuts/flicker
 +/

import core.runtime;
import std.process;
import std.stdio;
import std.string;
import std.utf;

pragma(lib, "gdi32.lib");
import windows.winbase;
import windows.windef;
import windows.winuser;
import windows.wingdi;

string appName     = "CairoWindow";
string description = "A simple win32 window with Cairo drawing";

import cairo.cairo;
import cairo.win32;

alias cairo.cairo.RGB RGB;  // conflicts with win32.wingdi.RGB

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

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    HACCEL hAccel;
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    // commented out so we do not redraw the entire screen on resize
    // wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    // wndclass.style         = WS_CLIPCHILDREN;

    wndclass.lpfnWndProc   = &WndProc;
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

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        description.toUTF16z,          // window caption
                        WS_OVERLAPPEDWINDOW,           // window style
                        CW_USEDEFAULT,                 // initial x position
                        CW_USEDEFAULT,                 // initial y position
                        200,                 // initial x size
                        200,                 // initial y size
                        null,                          // parent window handle
                        null,                          // window menu handle
                        hInstance,                     // program instance handle
                        null);                         // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, null, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

void roundedRectangle(Context ctx, int x, int y, int w, int h, int radius_x = 5, int radius_y = 5)
{
    enum ARC_TO_BEZIER = 0.55228475;

    if (radius_x > w - radius_x)
        radius_x = w / 2;

    if (radius_y > h - radius_y)
        radius_y = h / 2;

    // approximate (quite close) the arc using a bezier curve
    auto c1 = ARC_TO_BEZIER * radius_x;
    auto c2 = ARC_TO_BEZIER * radius_y;

    ctx.newPath();
    ctx.moveTo(x + radius_x, y);
    ctx.relLineTo(w - 2 * radius_x, 0.0);
    ctx.relCurveTo(c1, 0.0, radius_x, c2, radius_x, radius_y);
    ctx.relLineTo(0, h - 2 * radius_y);
    ctx.relCurveTo(0.0, c2, c1 - radius_x, radius_y, -radius_x, radius_y);
    ctx.relLineTo(-w + 2 * radius_x, 0);
    ctx.relCurveTo(-c1, 0, -radius_x, -c2, -radius_x, -radius_y);
    ctx.relLineTo(0, -h + 2 * radius_y);
    ctx.relCurveTo(0.0, -c2, radius_x - c1, -radius_y, radius_x, -radius_y);
    ctx.closePath();
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_CREATE:
        {
            window = new Window(hwnd);
            return 0;
        }

        default:
    }

    if (window)
        return window.process(hwnd, message, wParam, lParam);
    else
        return DefWindowProc(hwnd, message, wParam, lParam);
}

Window window;

struct PaintBuffer
{
    int width, height;

    this(HDC localHdc, int cxClient, int cyClient)
    {
        width  = cxClient;
        height = cyClient;

        hBuffer    = CreateCompatibleDC(localHdc);
        hBitmap    = CreateCompatibleBitmap(localHdc, cxClient, cyClient);
        hOldBitmap = SelectObject(hBuffer, hBitmap);

        surf = new Win32Surface(hBuffer);
        ctx = Context(surf);
        initialized = true;
    }

    ~this()
    {
        if (initialized)  // struct dtors are still buggy sometimes
        {
            ctx.dispose();
            surf.finish();
            surf.dispose();

            SelectObject(hBuffer, hOldBitmap);
            DeleteObject(hBitmap);
            DeleteDC(hBuffer);
            initialized = false;
        }
    }

    bool initialized;
    HDC hBuffer;
    HBITMAP hBitmap;
    HBITMAP hOldBitmap;
    Context ctx;
    Surface surf;
}

class Window
{
    int width, height;
    HWND hwnd;
    PAINTSTRUCT ps;
    PaintBuffer paintBuffer;
    bool needsRedraw;

    this(HWND hwnd)
    {
        this.hwnd = hwnd;

        auto hDesk = GetDesktopWindow();
        RECT rc;
        GetClientRect(hDesk, &rc);

        auto localHdc = GetDC(hwnd);
        paintBuffer = PaintBuffer(localHdc, rc.right, rc.bottom);
        needsRedraw = true;
    }

    LRESULT process(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        switch (message)
        {
            case WM_DESTROY:
            {
                paintBuffer.clear();
                PostQuitMessage(0);
                return 0;
            }

            case WM_PAINT:
                OnPaint(hwnd, message, wParam, lParam);
                return 0;

            case WM_ERASEBKGND:
                return 1;

            case WM_SIZE:
            {
                width  = LOWORD(lParam);
                height = HIWORD(lParam);
                return 0;
            }

            default:
        }

        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    void OnPaint(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        static int blitCount;
        auto hdc = BeginPaint(hwnd, &ps);
        auto ctx = paintBuffer.ctx;
        auto hBuffer = paintBuffer.hBuffer;

        auto boundRect = ps.rcPaint;

        if (needsRedraw)  // cairo needs to redraw
        {
            draw(ctx);
            needsRedraw = false;
        }

        with (boundRect)  // blit only required areas
        {
            BitBlt(hdc, left, top, right, bottom, hBuffer, left, top, SRCCOPY);
        }

        EndPaint(hwnd, &ps);
    }

    void draw(Context ctx)
    {
        ctx.setSourceRGB(1, 1, 1);
        ctx.paint();

        ctx.rectangle(0, 0, 120, 90);
        ctx.setSourceRGBA(0.7, 0, 0, 0.8);
        ctx.fill();

        ctx.rectangle(40, 30, 120, 90);
        ctx.setSourceRGBA(0, 0, 0.9, 0.4);
        ctx.fill();
    }
}
