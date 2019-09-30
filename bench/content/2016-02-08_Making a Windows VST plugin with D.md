# Making a Windows VST plugin with D

_In this tutorial, you'll learn how to make a VST plugin without UI using the D programming language, for Windows. The Mac OS X version would bring a bit more complexity and will be investigated in another blog post._
_Update: this tutorial is now obsolete._

## Introducing the `dplug` library

`dplug` is a library that wraps plugin formats and manages the UI if needed. It's source code is available on [Github](https://github.com/p0nce/dplug).

![dplug logo](images/dplug-logo.png)

It is most similar to [IPlug](https://github.com/olilarkin/wdl-ol) and [JUCE](http://www.juce.com/), two C++ alternatives you should absolutely consider when making plugins. Only a subset of JUCE and IPlug features are supported. If you need VST3 or AAX support, use them instead. AudioUnit support isn't there yet either, but will probably happen this year.

`dplug` also offers a way to render your plugin UI with a depth map and fancy lighting, but this is out-of-scope for this tutorial. We'll focus on getting something on the table as quickly as possible.


## Setting up the environment

- This tutorial assumes `git` is installed and ready-to-run. [Get it here otherwise.](https://git-scm.com/)

- For 64-bit support, it is recommended to **install Visual Studio** before the D compiler (for example Visual Studio 2013 Community Edition). This is necessary because the DMD compiler uses the Microsoft's linker when building 64-bit binaries. You can skip this step if you don't want 64-bit support.

- **Install DMD:** go to the [D compiler downloads](https://dlang.org/download.html). The easiest way is to download and execute the installer. If you choose so, [VisualD](http://rainers.github.io/visuald/visuald/StartPage.html) will also be installed. It allows to edit and debug D code from within Visual Studio. DMD should be in your PATH environment variable afterwards. Type `dmd --version` in a command prompt to check for correct setup.

- **Install DUB:** go to the [D package manager downloads](https://code.dlang.org/download). You will find releases there. DUB must be in your PATH environment variable. Type `dub help` in a command prompt to check for correct installation.

## Build the M/S Encoder example

_For the sake of brevity, the effect we'll create is a simple M/S encoder plugin._

You can find the [full source code here](https://github.com/p0nce/dplug/tree/master/examples/ms-encode).
I recommend you copy this example to start creating your own plugins.

- Checkout dplug: `git clone https://github.com/p0nce/dplug.git`

- Go to the M/S encoder directory: `cd dplug\examples\ms-encode`

- Build the plugin by typing: `dub`

**This will create a DLL which can be used in a host as a VST2 plugin.**
Now let's get into details and see what files were necessary.


## What is the file `dub.json` for?

[See its content here.](https://github.com/p0nce/dplug/blob/master/examples/ms-encode/dub.json)

DUB needs a project description file to work its magic.

![DUB logo](images/dub-logo.png)

Let's explain all of the JSON keys:
- `name` is necessary for every DUB project. In some cases it is even the only mandatory key.
- `importPaths`: this list of paths is passed to the D compiler with the `-I` switch, so that you can `import` from them.
- `sourcePaths`: this list of paths is scanned for .d files to pass to the compiler. The D compilation model is similar to the C++ compilation model: there is a distinction between source _files_ and import _paths_.
- `targetType` must be set to `dynamicLibrary`.
- `sourceFiles-windows` will provide `module.def` to the linker, when on Windows. Without that exported symbol, the VST host wouldn't be able to load your plugin.
- `dependencies` lists all dependencies needed by this project. Only `dplug:vst` is needed here.
- `CFBundleIdentifierPrefix` will only be useful for the Mac version.

## What is the file `msencode.d` for?

[See its content here.](https://github.com/p0nce/dplug/blob/master/examples/ms-encode/msencode.d)

This is the main source file for our M/S encoder. Like in JUCE or IPlug, it is a matter of subclassing a plugin client class and overloading some functions.

- audio processing happens in the `processAudio()` overload. This is pretty straightforward to understand, you get a number of input pointers, a number of ouput pointers, and a number of samples. The interesting things happen here!

- The `reset()` overload is called at initialization time or whenever the sampling rate changes. Since our M/S encoder has no state, this is left empty.

- `buildParams()` is where you define plugin parameters. We have only one boolean parameter here, "On/Off". In `processAudio()` this parameter is read with `readBoolParamValue(paramOnOff)`.

- The `buildLegalIO()` overload is there to define which combination of input and output channels are allowed. In this example, stereo to stereo is the only legal combination.

- Finally, the `buildPluginInfo()` overload allows to define the plugin identity and some options.


## How do I debug it?

If you have Visual Studio and [VisualD](http://rainers.github.io/visuald/visuald/StartPage.html) installed, you can generate an IDE project using the command: `dub generate visuald`.
This will create a solution able to build your project, and suitable for debugging (much like CMake or premake do).

## Getting an optimized build

To build our M/S encoder with optimizations, you can do:

`dub -b release-nobounds -f --combined`

or

`dub -b release-nobounds -f --combined -a x86_64` for a 64-bit plugin.

Speed-wise, this plugin should then be about 2500x real-time. Which is expected since it doesn't do much in the first place.


## Why the D programming language?

Indeed. Why use D over the obvious alternative: C++?

![dplug logo](images/dlang.jpg)

This is a touchy topic that already has filled entire blog posts. Virtually everyone in real-time audio is using C++ and it's probably still the sanest choice to make.

We are a handful of people using D though. Prior work with VST and D include:

- vstd: [http://le-son666.com/software/vstd/](http://le-son666.com/software/vstd/)

- The Opossum synthesizer: [http://bazaar.launchpad.net/~ace17/opossum/trunk/view/head:/README](http://bazaar.launchpad.net/~ace17/opossum/trunk/view/head:/README)


I worked with both languages for years and felt qualified enough for the inevitable [bullet point comparison](http://p0nce.github.io/d-idioms/#How-does-D-improve-on-C++17?). The most enabling thing is the D ecosystem and package management through DUB, which makes messing with dependencies basically a solved problem. Development seems to "flow" way more, and I tend to like the end result better in a way that is undoubtedly personal.

## Isn't Garbage Collection at odds with real-time audio?

This will be counter-intuitive to many programmers, but the D GC isn't even given a chance to be a problem. The ways to avoid the dreaded GC pauses are [well known](http://p0nce.github.io/d-idioms/#The-impossible-real-time-thread) within the community.

In our plugins the GC is used in the UI but not in audio processing. No collection happens after UI initialization. If there was some, the audio thread wouldn't get stopped thanks to being unregistered to the runtime.

The mere presence of a GC doesn't prevent you to do real-time audio, provided you are given the means to control it and avoid it as needed.

## Conclusions

Making VST plugins with D isn't terribly involved. I hope you find the process enjoyable and most importantly, easy.


