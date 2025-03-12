version = DComputeTestCUDA;

//import dcompute.tests.test;

import std.algorithm;
import std.stdio;
import std.file;
import std.traits;
import std.meta;
import std.exception : enforce;
import std.experimental.allocator;
import std.array;

import dcompute.tests.dummykernels : saxpy;

version(DComputeTestOpenCL)
    import dcompute.driver.ocl;
else version(DComputeTestCUDA)
    import dcompute.driver.cuda;
else
    static assert(false, "Need to test something!");

// Index of OpenCL 2.1 capable platform returned by Platform.getPlatforms
enum CL_PLATFORM_INDEX = 2;

int main(string[] args)
{
    enum size_t N = 128;
    float alpha = 5.0;
    float[N] res, x,y;
    foreach (i; 0 .. N)
    { 
        x[i] = N - i;
        y[i] = i * i;
    }

    version(DComputeTestOpenCL)
    {
        Platform.initialise();
        onDriverError = (Status _status) { throw new DComputeDriverException(_status); };
        auto platforms = Platform.getPlatforms(theAllocator);
        auto platform = platforms[CL_PLATFORM_INDEX];
        DerelictCL.reload(CLVersion.CL21);
        writeln("Platforms:");
        writeln("\t", platforms.map!(p => p.name));
        writeln("\tChosen: ", platform.name);
        auto devices  = platform.getDevices(theAllocator);
        writeln("Devices:");
        writeln("\t", devices.map!(d => d.name));
        writeln("\tChosen: ", devices[0].name);
        auto plist    = propertyList!(Context.Properties)(Context.Properties.platform, platform.raw);
        writeln(plist);
        auto ctx      = Context(devices[0 ..1],null /*FIXME: plist[]*/);
	// Change the file to the built OpenCL version.
        Program.globalProgram = ctx.createProgram(cast(ubyte[])read("./.dub/obj/kernels_ocl200_64.spv"));

        try
        {
            Program.globalProgram.build(devices,"");
        }
            catch(DComputeDriverException e)
        {
            auto b = Build(Program.globalProgram, devices[0]);
            writeln(b.log);
        }
        
        auto queue    = ctx.createQueue(devices[0],Queue.Properties.outOfOrderExecution);

        Buffer!(float) b_res, b_x, b_y;

        b_res = ctx.createBuffer(res[], Memory.Flags.useHostPointer | Memory.Flags.readWrite);
        b_x = ctx.createBuffer(x[],Memory.Flags.useHostPointer | Memory.Flags.readWrite);
        b_y = ctx.createBuffer(y[],Memory.Flags.useHostPointer | Memory.Flags.readWrite);

        Event e = queue.enqueue!(saxpy)([N])(b_res,alpha,b_x,b_y, N);
        e.wait();
    }

    version(DComputeTestCUDA)
    {
        Platform.initialise();
	
        auto devs = Platform.getDevices(theAllocator);
        auto dev   = devs[0]; 
        auto ctx   = Context(dev); scope(exit) ctx.detach();

        // Change the file to match your GPU.
        Program.globalProgram = Program.fromFile("./.dub/obj/kernels_cuda210_64.ptx");
        auto q = Queue(false);

        Buffer!(float) b_res, b_x, b_y;
        b_res =  Buffer!(float)(res[]); scope(exit) b_res.release();
        b_x   =  Buffer!(float)(x[]);   scope(exit) b_x.release();
        b_y   =  Buffer!(float)(y[]);   scope(exit) b_y.release();

        b_x.copy!(Copy.hostToDevice);
        b_y.copy!(Copy.hostToDevice);

        q.enqueue!(saxpy)
                  ([N,1,1],[1,1,1])
                  (b_res,alpha,b_x,b_y, N);
        b_res.copy!(Copy.deviceToHost);
    }

    foreach(i; 0 .. N)
        enforce(res[i] == alpha * x[i] + y[i]);
    writeln(res[]);
    return 0;
}


