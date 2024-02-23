module round_rect;

/+
 + This tutorial is derived from: http://cairographics.org/cookbook/win32quickstart/
 + Translated to D2 by Andrej Mitrovic, 2011.
 +/

import core.runtime;
import std.utf;
import std.traits;

pragma(lib, "gdi32.lib");
import windows.windef;
import windows.winuser;
import windows.wingdi;

string appName     = "CairoWindow";
string description = "Rounded Rectangles";
HINSTANCE hinst;

import cairo.cairo;
import cairo.win32;

alias cairo.cairo.RGB RGB;  // conflicts with win32.wingdi.RGB

import util.rounded_rectangle;

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

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(null, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(null, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
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
                        CW_USEDEFAULT,                 // initial x position
                        CW_USEDEFAULT,                 // initial y position
                        650,                           // initial x size
                        250,                           // initial y size
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

class Window
{
    int  x, y;
    HWND hwnd;
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rc;
    HDC _buffer;
    HBITMAP hBitmap;
    HBITMAP hOldBitmap;

    this(HWND hwnd)
    {
        this.hwnd = hwnd;
    }

    LRESULT process(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        switch (message)
        {
            case WM_DESTROY:
                return OnDestroy(hwnd, message, wParam, lParam);

            case WM_PAINT:
                return OnPaint(hwnd, message, wParam, lParam);

            case WM_ERASEBKGND:
                return 0;

            default:
        }

        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    auto OnPaint(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        hdc = BeginPaint(hwnd, &ps);
        GetClientRect(hwnd, &rc);

        auto left = rc.left;
        auto top = rc.top;
        auto right = rc.right;
        auto bottom = rc.bottom;

        auto width  = right - left;
        auto height = bottom - top;
        x = left;
        y = top;

        _buffer    = CreateCompatibleDC(hdc);
        hBitmap    = CreateCompatibleBitmap(hdc, width, height);
        hOldBitmap = SelectObject(_buffer, hBitmap);

        auto surf = new Win32Surface(_buffer);
        auto ctx = Context(surf);

        ctx.setSourceRGB(1, 1, 1);
        ctx.paint();
        ctx.translate(50, 40);
        int xPos = 150;
        int yPos = 10;

        foreach (index, method; EnumMembers!RoundMethod)
        {
            roundedRectangle!(method)(ctx, index * xPos, yPos, 100, 100, 10, 10);

            auto clr = RGB(0.9411764705882353, 0.996078431372549, 0.9137254901960784);
            ctx.setSourceRGB(clr);
            ctx.fillPreserve();

            clr = RGB(0.7019607843137254, 1.0, 0.5529411764705883);
            ctx.setSourceRGB(clr);
            ctx.stroke();
        }

        surf.finish();
        BitBlt(hdc, 0, 0, width, height, _buffer, x, y, SRCCOPY);

        SelectObject(_buffer, hOldBitmap);
        DeleteObject(hBitmap);
        DeleteDC(_buffer);

        EndPaint(hwnd, &ps);
        return 0;
    }

    auto OnDestroy(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        PostQuitMessage(0);
        return 0;
    }
}
