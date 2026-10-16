#!/usr/bin/env python3
"""X11/XWayland window helpers via libX11 (no third-party deps).

Commands:
    iconify <window-id>   minimize the window (ICCCM WM_CHANGE_STATE IconicState)
    map     <window-id>   map the window without raising or activating it

Used by scripts/run-integration-tests.sh. On GNOME Wayland:
  - minimized (unmapped) windows throttle the game loop to ~1 fps, so test
    suites must run while the window is mapped on the active workspace
  - wmctrl's _NET_WM_STATE requests are ignored; the raw Xlib calls work

Exit codes: 0 on success, 1 if the request failed, 2 on invalid arguments.
"""
import ctypes
import sys


def open_display(x11):
    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    dpy = x11.XOpenDisplay(None)
    if not dpy:
        print("cannot open X display", file=sys.stderr)
        sys.exit(1)
    return dpy


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in ("iconify", "map"):
        print(f"usage: {sys.argv[0]} <iconify|map> <window-id>", file=sys.stderr)
        return 2

    cmd, arg = sys.argv[1], sys.argv[2]
    try:
        wid = int(arg, 16) if arg.lower().startswith("0x") else int(arg)
    except ValueError:
        print(f"invalid window id: {arg!r}", file=sys.stderr)
        return 2

    x11 = ctypes.CDLL("libX11.so.6")
    x11.XDefaultScreen.restype = ctypes.c_int
    x11.XDefaultScreen.argtypes = [ctypes.c_void_p]
    x11.XIconifyWindow.restype = ctypes.c_int
    x11.XIconifyWindow.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int]
    x11.XMapWindow.restype = ctypes.c_int
    x11.XMapWindow.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
    x11.XFlush.argtypes = [ctypes.c_void_p]
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]

    dpy = open_display(x11)
    try:
        if cmd == "iconify":
            ok = x11.XIconifyWindow(dpy, wid, x11.XDefaultScreen(dpy))
        else:
            ok = x11.XMapWindow(dpy, wid)
        x11.XFlush(dpy)
    finally:
        x11.XCloseDisplay(dpy)

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
