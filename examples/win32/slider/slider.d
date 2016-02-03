module slider;

/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

/+
 + This is an example of a custom Slider widget implemented with
 + CairoD with the help of the Win32 API.
 + You can change the orientation of the slider, its colors,
 + its maximum value and the extra padding that allows selection
 + of the slider within extra bounds.
 +
 + Currently it doesn't instantiate multiple sliders.
 +
 + It relies heavily on Win32 features, such as widgets being
 + implemented as windows (windows, buttons, menus, and even the
 + desktop window are all windows) which have X and Y points relative
 + to their own window, the ability to capture the mouse position
 + even when it goes outside a window area, and some other features.
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

alias std.algorithm.min min;  // conflict resolution
alias std.algorithm.max max;  // conflict resolution

import cairo.c.cairo;
import cairo.cairo;
import cairo.win32;

alias cairo.cairo.RGB RGB;  // conflict resolution

/*
 * These should be tracked in one place for the entire app,
 * otherwise you might end up having multiple widgets with
 * their own control/shift key states.
 */
__gshared bool shiftState;
__gshared bool controlState;
__gshared bool mouseTrack;

/* Used in painting the slider background/foreground/thumb */
struct SliderColors
{
    RGBA thumbActive;
    RGBA thumbHover;
    RGBA thumbIdle;

    RGBA fill;
    RGBA back;
    RGBA window;
}

/* Two types of sliders */
enum Axis
{
    vertical,
    horizontal
}

class SliderWindow
{
    int cxClient, cyClient;  /* width, height */
    HWND hwnd;
    RGBA thumbColor;      // current active thumb color
    Axis axis;            // slider orientation
    SliderColors colors;  // initialized colors
    int thumbPos;
    int size;
    int thumbSize;
    int offset;           // since round caps add additional pixels, we offset the drawing
    int step;             // used when control key is held
    bool isActive;

    this(HWND hwnd, Axis axis, int size, int thumbSize, int padding, SliderColors colors)
    {
        this.hwnd = hwnd;
        this.colors = colors;
        this.axis = axis;
        this.size = size;
        this.thumbSize = thumbSize;
        offset = padding / 2;

        thumbPos = (axis == Axis.horizontal) ? 0 : size - thumbSize;
        step     = (axis == Axis.horizontal) ? 2 : -2;
    }

    /* Get the mouse offset based on slider orientation */
    short getTrackPos(LPARAM lParam)
    {
        final switch (axis)
        {
            case Axis.vertical:
            {
                return cast(short)HIWORD(lParam);
            }

            case Axis.horizontal:
            {
                return cast(short)LOWORD(lParam);
            }
        }
    }

    /* Flips x and y based on slider orientation */
    void axisFlip(ref int x, ref int y)
    {
        final switch (axis)
        {
            case Axis.vertical:
            {
                break;
            }

            case Axis.horizontal:
            {
                std.algorithm.swap(x, y);
                break;
            }
        }
    }

    /* Update the thumb position based on mouse position */
    void mouseTrackPos(LPARAM lParam)
    {
        auto trackPos = getTrackPos(lParam);

        /* steps:
         * 1. compensate for offseting the slider drawing
         * (we do not draw from Point(0, 0) because round caps add more pixels).
         * 2. position the thumb so its center is at the mouse cursor position.
         * 3. limit the final value between the minimum and maximum position.
         */
        thumbPos = (max(0, min(trackPos - offset - (thumbSize / 2), size)));
    }

    /* Get the neutral value (calculated based on axis orientation.) */
    int getValue()
    {
        final switch (axis)
        {
            // vertical sliders have a more natural minimum position at the bottom,
            // and since the Y axis increases towards the bottom we have to invert
            // this value.
            case Axis.vertical:
            {
                return (retro(iota(0, size + 1)))[thumbPos];
            }

            case Axis.horizontal:
            {
                return thumbPos;
            }
        }
    }

    /* Process window messages for this slider */
    LRESULT process(UINT message, WPARAM wParam, LPARAM lParam)
    {
        HDC hdc;
        PAINTSTRUCT ps;
        RECT rc;
        HDC  _buffer;
        HBITMAP hBitmap;
        HBITMAP hOldBitmap;
        switch (message)
        {
            case WM_SIZE:
            {
                cxClient = LOWORD(lParam);
                cyClient = HIWORD(lParam);
                InvalidateRect(hwnd, null, FALSE);
                return 0;
            }

            /* We're selected, capture the mouse and track its position,
             * focus our window (this unfocuses all other windows).
             */
            case WM_LBUTTONDOWN:
            {
                mouseTrackPos(lParam);
                SetCapture(hwnd);
                mouseTrack = true;
                SetFocus(hwnd);

                InvalidateRect(hwnd, null, FALSE);
                return 0;
            }

            /*
             * End any mouse tracking.
             */
            case WM_LBUTTONUP:
            {
                if (mouseTrack)
                {
                    ReleaseCapture();
                    mouseTrack = false;
                }

                InvalidateRect(hwnd, null, FALSE);
                return 0;
            }

            /*
             * We're focused, change slider settings.
             */
            case WM_SETFOCUS:
            {
                isActive = true;
                thumbColor = colors.thumbActive;
                InvalidateRect(hwnd, null, FALSE);
                return 0;
            }

            /*
             * We've lost focus, change slider settings.
             */
            case WM_KILLFOCUS:
            {
                isActive = false;
                thumbColor = colors.thumbIdle;
                InvalidateRect(hwnd, null, FALSE);
                return 0;
            }

            /*
             * If we're tracking the mouse update the
             * slider thumb position.
             */
            case WM_MOUSEMOVE:
            {
                if (mouseTrack)  // move thumb
                {
                    //~ writeln(getValue());
                    mouseTrackPos(lParam);
                    InvalidateRect(hwnd, null, FALSE);
                }

                return 0;
            }

            /*
             * Mouse wheel can control the slider position too.
             */
            case WM_MOUSEWHEEL:
            {
                if (isActive)
                {
                    OnMouseWheel(cast(short)HIWORD(wParam));
                    InvalidateRect(hwnd, null, FALSE);
                }

                return 0;
            }

            /*
             * Various keys such as Up/Down/Left/Right/PageUp/
             * PageDown/Tab/ and the Shift state can control
             * the slider thumb position.
             */
            case WM_KEYDOWN:
            case WM_KEYUP:
            case WM_CHAR:
            case WM_DEADCHAR:
            case WM_SYSKEYDOWN:
            case WM_SYSKEYUP:
            case WM_SYSCHAR:
            case WM_SYSDEADCHAR:
            {
                // message: key state, wParam: key ID
                keyUpdate(message, wParam);
                InvalidateRect(hwnd, null, FALSE);
                return 0;
            }

            /*
             * The paint routine recreates the Cairo context and double-buffering
             * mechanism on each WM_PAINT message. You could set up context recreation
             * only when it's necessary (e.g. on a WM_SIZE message), however this quickly
             * gets complicated due to Cairo's stateful API.
             */
            case WM_PAINT:
            {
                hdc = BeginPaint(hwnd, &ps);
                GetClientRect(hwnd, &rc);

                auto left   = rc.left;
                auto top    = rc.top;
                auto right  = rc.right;
                auto bottom = rc.bottom;

                auto width  = right - left;
                auto height = bottom - top;
                auto x      = left;
                auto y      = top;

                /* Double buffering */
                _buffer    = CreateCompatibleDC(hdc);
                hBitmap    = CreateCompatibleBitmap(hdc, width, height);
                hOldBitmap = SelectObject(_buffer, hBitmap);

                auto surf = new Win32Surface(_buffer);
                auto ctx  = Context(surf);

                drawSlider(ctx);

                // Blit the texture to the screen
                BitBlt(hdc, 0, 0, width, height, _buffer, x, y, SRCCOPY);

                surf.finish();
                surf.dispose();
                ctx.dispose();

                SelectObject(_buffer, hOldBitmap);
                DeleteObject(hBitmap);
                DeleteDC(_buffer);

                EndPaint(hwnd, &ps);

                return 0;
            }

            default:
        }

        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    void drawSlider(Context ctx)
    {
        /* window backround */
        ctx.setSourceRGBA(colors.window);
        ctx.paint();

        ctx.translate(offset, offset);

        ctx.setLineWidth(10);
        ctx.setLineCap(LineCap.CAIRO_LINE_CAP_ROUND);

        /* slider backround */
        auto begX = 0;
        auto begY = 0;
        auto endX = 0;
        auto endY = size + thumbSize;

        axisFlip(begX, begY);
        axisFlip(endX, endY);

        ctx.setSourceRGBA(colors.back);
        ctx.moveTo(begX, begY);
        ctx.lineTo(endX, endY);
        ctx.stroke();

        /* slider value fill */
        begX = 0;
        // vertical sliders have a minimum position at the bottom.
        begY = (axis == Axis.horizontal) ? 0 : size + thumbSize;
        endX = 0;
        endY = thumbPos + thumbSize;

        axisFlip(begX, begY);
        axisFlip(endX, endY);

        ctx.setSourceRGBA(colors.fill);
        ctx.moveTo(begX, begY);
        ctx.lineTo(endX, endY);
        ctx.stroke();

        /* slider thumb */
        begX = 0;
        begY = thumbPos;
        endX = 0;
        endY = thumbPos + thumbSize;

        axisFlip(begX, begY);
        axisFlip(endX, endY);

        ctx.setSourceRGBA(thumbColor);
        ctx.moveTo(begX, begY);
        ctx.lineTo(endX, endY);
        ctx.stroke();
    }

    /*
     * Process various keys.
     * This function is continuously called when a key is held,
     * but we only update the slider position when a key is pressed
     * down (WM_KEYDOWN), and not when it's released.
     */
    void keyUpdate(UINT keyState, WPARAM wParam)
    {
        switch (wParam)
        {
            case VK_LEFT:
            {
                if (keyState == WM_KEYDOWN)
                {
                    if (controlState)
                        thumbPos -= step * 2;
                    else
                        thumbPos -= step;
                }
                break;
            }

            case VK_RIGHT:
            {
                if (keyState == WM_KEYDOWN)
                {
                    if (controlState)
                        thumbPos += step * 2;
                    else
                        thumbPos += step;
                }
                break;
            }

            case VK_SHIFT:
            {
                shiftState = (keyState == WM_KEYDOWN);
                break;
            }

            case VK_CONTROL:
            {
                controlState = (keyState == WM_KEYDOWN);
                break;
            }

            case VK_UP:
            {
                if (keyState == WM_KEYDOWN)
                {
                    if (controlState)
                        thumbPos += step * 2;
                    else
                        thumbPos += step;
                }
                break;
            }

            case VK_DOWN:
            {
                if (keyState == WM_KEYDOWN)
                {
                    if (controlState)
                        thumbPos -= step * 2;
                    else
                        thumbPos -= step;
                }
                break;
            }

            case VK_HOME:
            {
                thumbPos = 0;
                break;
            }

            case VK_END:
            {
                thumbPos = size;
                break;
            }

            case VK_PRIOR:  // page up
            {
                thumbPos += step * 2;
                break;
            }

            case VK_NEXT:  // page down
            {
                thumbPos -= step * 2;
                break;
            }

            /*
             * this can be used to switch between different slider windows.
             * However this should ideally be handled in a main window, not here.
             * We could pass this message back to the main window.
             * Currently unimplemented.
             */
            case VK_TAB:
            {
                //~ if (shiftState)  // shift+tab means go the other way
                    //~ SetFocus(slidersRange.back);
                //~ else
                    //~ SetFocus(slidersRange.front);
                //~ break;
            }

            default:
        }

        // normalize the thumb position
        thumbPos = (max(0, min(thumbPos, size)));
    }

    void OnMouseWheel(sizediff_t nDelta)
    {
        if (-nDelta/120 > 0)
            thumbPos -= step;
        else
            thumbPos += step;

        thumbPos = (max(0, min(thumbPos, size)));
    }
}

/*
 * A place to hold Slider objects. Since each window has a unique HWND,
 * we can use this hash type to store references to objects and call
 * their window processing methods.
 */
SliderWindow[HWND] SliderHandles;

/*
 * All Slider windows will have this same window procedure registered via
 * RegisterClass(), we use it to dispatch to the appropriate class window
 * processing method. We could also place this inside the Slider class as
 * a static method, however this kind of dispatch function is actually
 * useful for dispatching to any number and types of windows.
 *
 * A similar technique is used in the DFL and DGUI libraries for all of its
 * windows and widgets.
 */
extern (Windows)
LRESULT winDispatch(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    auto slider = hwnd in SliderHandles;

    if (slider !is null)
    {
        return slider.process(message, wParam, lParam);
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
LRESULT mainWinProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int size = 100;
    static int padding = 20;
    static int thumbSize = 20;
    static HWND hSlider;
    static axis = Axis.vertical;  /* vertical or horizontal orientation */

    switch (message)
    {
        case WM_CREATE:
        {
            hSlider = CreateWindow(sliderClass.toUTF16z, null,
                      WS_CHILDWINDOW | WS_VISIBLE,
                      0, 0, 0, 0,
                      hwnd,
                      cast(HMENU)(0),                                  // child ID
                      cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE),  // hInstance
                      null);

            SliderColors colors;
            with (colors)
            {
                thumbActive = RGBA(1, 1, 1, 1);
                thumbHover  = RGBA(1, 1, 0, 1);
                thumbIdle   = RGBA(1, 0, 0, 1);

                fill        = RGBA(1, 0, 0, 1);
                back        = RGBA(1, 0, 0, 0.5);
                window      = RGBA(0, 0, 0, 0);
            }

            SliderHandles[hSlider] = new SliderWindow(hSlider, axis, size, thumbSize, padding, colors);
            return 0;
        }

        /* The main window creates the child window and has to set the position and size. */
        case WM_SIZE:
        {
            auto sliderWidth  = size + padding + thumbSize;
            auto sliderHeight = padding;

            if (axis == Axis.vertical)
                std.algorithm.swap(sliderWidth, sliderHeight);

            MoveWindow(hSlider, 0, 0, sliderWidth, sliderHeight, true);
            return 0;
        }

        /* Focus main window, this kills any active child window focus. */
        case WM_LBUTTONDOWN:
        {
            SetFocus(hwnd);
            return 0;
        }

        case WM_KEYDOWN:
        {
            if (wParam == VK_ESCAPE)
                goto case WM_DESTROY;

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

string sliderClass = "SliderClass";

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "sliders";

    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style       = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc = &mainWinProc;
    wndclass.cbClsExtra  = 0;
    wndclass.cbWndExtra  = 0;
    wndclass.hInstance   = hInstance;
    wndclass.hIcon       = LoadIcon(null, IDI_APPLICATION);
    wndclass.hCursor     = LoadCursor(null, IDC_ARROW);
    wndclass.hbrBackground = null;  // todo: replace with null, paint bg with cairo
    wndclass.lpszMenuName  = null;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(null, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    /* Separate window class for all widgets, in this case only Sliders. */
    wndclass.hbrBackground = null;
    wndclass.lpfnWndProc   = &winDispatch;
    wndclass.cbWndExtra    = 0;
    wndclass.hIcon         = null;
    wndclass.lpszClassName = sliderClass.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(null, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z, "sliders example",
                        WS_OVERLAPPEDWINDOW,
                        400, 400,
                        50, 200,
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
