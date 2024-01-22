module operators;

/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

import std.conv;
import std.utf;

/+
 + Demonstrates the usage of Cairo compositing operators and alpha-blitting.
 +
 + Note: Other samples in this directory do not use alpha-blending, and should
 + probably be rewritten. Sorry for that! :)
 +
 + Notes:
 + You have to use an RGB32 surface type, otherwise you won't be able
 + to use numerous alpha-blending operators (you will get a runtime exception).
 +
 + I'm using CairoD's Win32Surface ctor that can create a surface type
 + based on the format enum supplied. Alternatively I could have manually
 + created a DIBSection and constructed a Win32Surface with that.
 +
 + I'm using AlphaBlend (symbol name is actually 'GdiAlphaBlend' in Gdi32.lib),
 + if you get undefined symbol errors it could mean the Gdi32.lib import lib
 + distributed with DMD/GDC is outdated. You can create a new OMF-compatible
 + one by grabbing the Windows SDK, downloading coffimplib
 + (ftp://ftp.digitalmars.com/coffimplib.zip), and browsing to
 + where Gdi32.lib is located, e.g.:
 +
 +      C:\Program Files\Microsoft SDKs\Windows\v7.1\Lib
 +
 + and calling:
 +      coffimplib Gdi32_coff.lib gdi32.lib
 +
 + Then copy 'Gdi32_coff.lib' to DMD\dmd2\windows\lib\, delete the old 'gdi32.lib',
 + and rename 'Gdi32_coff.lib' to 'gdi32.lib'.
 +
 + I use 2 paint buffers, one is the foreground that only paints to certain
 + regions and has an alpha, the other acts as a background with its entire
 + surface painted white with alpha 1.0 (max).
 +
 + I use AlphaBlit to blit the foreground to the background. AlphaBlit is set
 + to blit by using per-pixel alpha values (this is configurable to other settings).
 +
 + The reason I'm using 2 paint buffers and not just 1 foreground buffer and
 + a white pre-painted window device context is because the latter usually introduces
 + graphical glitches. For example, painting the window white directly via a
 + device context (and e.g. the GDI FillRect function) and then alpha-blitting the
 + foreground results in 2 refresh events. This would introduce flicker effects,
 + so it's better to keep a separate background buffer to blend with when drawing,
 + and then blit to the screen as necessary.
 +/

import core.runtime;
import std.exception;
import std.process;
import std.stdio;

pragma(lib, "gdi32.lib");
import windows.windef;
import windows.winuser;
import windows.wingdi;

string appName     = "CairoWindow";
string description = "A simple win32 window with Cairo drawing";
HINSTANCE hinst;

import cairo.cairo;
import cairo.win32;

alias cairo.cairo.RGB RGB;  // conflicts with win32.wingdi.RGB

struct AlphaBlendType
{
    static normal = BLENDFUNCTION(AC_SRC_OVER, 0, 255, AC_SRC_ALPHA);
}

extern(Windows) BOOL GdiAlphaBlend(HDC, int, int, int, int, HDC, int, int, int, int, BLENDFUNCTION);
void AlphaBlit(HDC dstHdc, HDC srcHdc, int width, int height, BLENDFUNCTION blendType = AlphaBlendType.normal)
{
    auto result = GdiAlphaBlend(dstHdc, 0, 0, width, height,
                                srcHdc, 0, 0, width, height, blendType);
    // enforce(result != 0);
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

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    hinst = hInstance;
    HACCEL hAccel;
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    // commented out so we do not redraw the entire screen on resize
    // wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.style         = WS_CLIPCHILDREN;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(null, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(null, IDC_ARROW);
    wndclass.hbrBackground = null;
    wndclass.lpszMenuName  = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(null, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        description.toUTF16z,          // window caption
                        WS_OVERLAPPEDWINDOW,           // window style
                        (1680 - 900) / 2,                 // initial x position
                        (1050 - 700) / 2,                 // initial y position
                        1100,                 // initial x size
                        800,                 // initial y size
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
        surf = new Win32Surface(Format.CAIRO_FORMAT_ARGB32, cxClient, cyClient);
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
            initialized = false;
        }
    }

    bool initialized;
    Context ctx;
    Win32Surface surf;
}

class Window
{
    int width, height;
    HWND hwnd;
    PAINTSTRUCT ps;
    PaintBuffer foreBuffer;  // drawing buffer
    PaintBuffer backBuffer;  // white background, alpha-blended over with foreBuffer
    bool needsRedraw;  // if false we only blit, otherwise we re-draw via cairo

    this(HWND hwnd)
    {
        this.hwnd = hwnd;

        auto hDesk = GetDesktopWindow();
        RECT rc;
        GetClientRect(hDesk, &rc);

        auto localHdc = GetDC(hwnd);
        foreBuffer = PaintBuffer(localHdc, rc.right, rc.bottom);
        backBuffer = PaintBuffer(localHdc, rc.right, rc.bottom);
        needsRedraw = true;
    }

    LRESULT process(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        switch (message)
        {
            case WM_DESTROY:
                foreBuffer.clear();
                PostQuitMessage(0);
                return 0;

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
        HDC winHDC = BeginPaint(hwnd, &ps);

        // find visible window area
        RECT boundRect = ps.rcPaint;

        if (needsRedraw)  // need to redraw with cairo
        {
            // paint backround buffer white
            backBuffer.ctx.setSourceRGBA(1, 1, 1, 1);
            backBuffer.ctx.paint();

            // draw foreground
            draw(foreBuffer.ctx);

            // blit bg to fg only in exposed area
            with (boundRect)
            {
                // blit fg HDC to bg HDC
                AlphaBlit(backBuffer.surf.getDC(), foreBuffer.surf.getDC(), right - left, bottom - top);
            }

            needsRedraw = false;
        }

        with (boundRect)  // blit only exposed area of window
        {
            // blit backBuffer to window
            BitBlt(winHDC, left, top, right, bottom, backBuffer.surf.getDC(), left, top, SRCCOPY);
        }

        EndPaint(hwnd, &ps);
    }

    void draw(Context ctx)
    {
        static immutable ops =
        [
            Operator.CAIRO_OPERATOR_CLEAR,
            Operator.CAIRO_OPERATOR_SOURCE,
            Operator.CAIRO_OPERATOR_OVER,
            Operator.CAIRO_OPERATOR_IN,
            Operator.CAIRO_OPERATOR_OUT,
            Operator.CAIRO_OPERATOR_ATOP,
            Operator.CAIRO_OPERATOR_DEST,
            Operator.CAIRO_OPERATOR_DEST_OVER,
            Operator.CAIRO_OPERATOR_DEST_IN,
            Operator.CAIRO_OPERATOR_DEST_OUT,
            Operator.CAIRO_OPERATOR_DEST_ATOP,
            Operator.CAIRO_OPERATOR_XOR,
            Operator.CAIRO_OPERATOR_ADD,
            Operator.CAIRO_OPERATOR_SATURATE,

            // note: not supported on RGB24, only RGB32 with alpha.
            Operator.CAIRO_OPERATOR_MULTIPLY,
            Operator.CAIRO_OPERATOR_SCREEN,
            Operator.CAIRO_OPERATOR_OVERLAY,
            Operator.CAIRO_OPERATOR_DARKEN,
            Operator.CAIRO_OPERATOR_LIGHTEN,
            Operator.CAIRO_OPERATOR_COLOR_DODGE,
            Operator.CAIRO_OPERATOR_COLOR_BURN,
            Operator.CAIRO_OPERATOR_HARD_LIGHT,
            Operator.CAIRO_OPERATOR_SOFT_LIGHT,
            Operator.CAIRO_OPERATOR_DIFFERENCE,
            Operator.CAIRO_OPERATOR_EXCLUSION,
            Operator.CAIRO_OPERATOR_HSL_HUE,
            Operator.CAIRO_OPERATOR_HSL_SATURATION,
            Operator.CAIRO_OPERATOR_HSL_COLOR,
            Operator.CAIRO_OPERATOR_HSL_LUMINOSITY
        ];

        size_t colIdx;
        size_t rowIdx;
        foreach (op; ops)
        {
            ctx.save();

            ctx.rectangle(colIdx * 180, (rowIdx * 140), 160, 120);
            ctx.clip();

            ctx.rectangle(colIdx * 180, (rowIdx * 140), 120, 90);
            ctx.setSourceRGBA(0.7, 0, 0, 0.8);
            ctx.fill();

            ctx.setOperator(op);

            ctx.rectangle((colIdx * 180) + 40, (rowIdx * 140) + 30, 120, 90);
            ctx.setSourceRGBA(0, 0, 0.9, 0.4);
            ctx.fill();

            rowIdx++;

            if (rowIdx == 5)  // 5 examples in a row
            {
                rowIdx = 0;
                colIdx++;
            }

            ctx.restore();

            ctx.save();
            ctx.setOperator(Operator.CAIRO_OPERATOR_OVER);
            ctx.setSourceRGBA(0, 0, 0, 1);
            ctx.selectFontFace("Verdana", FontSlant.CAIRO_FONT_SLANT_NORMAL, FontWeight.CAIRO_FONT_WEIGHT_NORMAL);
            ctx.setFontSize(10);
            ctx.moveTo(10 + (colIdx * 180), 20 + ((rowIdx * 140)));
            ctx.showText(to!string(op));
            ctx.restore();
        }
    }
}
