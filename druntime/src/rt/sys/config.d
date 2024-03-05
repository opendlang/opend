module rt.sys.config;


version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Windows)
{
    public import rt.sys.windows.config;
}
else version (linux)
{
    public import rt.sys.linux.config;
}
else version (Darwin)
{
    public import rt.sys.darwin.config;
}
else version (DragonFlyBSD)
{
    public import rt.sys.dragonflybsd.config;
}
else version (FreeBSD)
{
    public import rt.sys.freebsd.config;
}
else version (NetBSD)
{
    public import rt.sys.netbsd.config;
}
else version (OpenBSD)
{
    public import rt.sys.openbsd.config;
}
else version (Solaris)
{
    public import rt.sys.solaris.config;
}
else
{
    static assert(false, "Platform not supported");
}