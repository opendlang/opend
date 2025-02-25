module dcompute.driver.cuda;

public import ldc.dcompute;
public import derelict.cuda.driverapi;

public import dcompute.driver.error;

public import dcompute.driver.cuda.buffer;
public import dcompute.driver.cuda.context;
public import dcompute.driver.cuda.device;
public import dcompute.driver.cuda.event;
public import dcompute.driver.cuda.kernel;
public import dcompute.driver.cuda.memory;
public import dcompute.driver.cuda.platform;
public import dcompute.driver.cuda.program;
public import dcompute.driver.cuda.queue;

enum Copy
{
    hostToDevice,
    deviceToHost,
    array,
}

enum MemoryBankConfig : int
{
    default_,
    fourBytes,
    eightBytes,
}
template HostArgsOf(F) {
    import std.meta, std.traits;
    alias HostArgsOf = staticMap!(ReplaceTemplate!(Pointer, Buffer), Parameters!F);
}
private template ReplaceTemplate(alias needle, alias replacement) {
    template ReplaceTemplate(T) {
        static if (is(T : needle!Args, Args...)) {
            alias ReplaceTemplate = replacement!(Args[1]);
        } else {
            alias ReplaceTemplate = T;
        }
    }
}
