# A Consequential Update

Today we update our plug-ins to: 
- **Graillon v2.2**
- **Panagement v1.4**
- **Couture v1.2**

_Let's describe what changed in that update. Reading time: 3 min._


## NEW in all Auburn Sounds plug-ins

### VST3 format

We added support for the VST3 format.

![VST Compatible Logo](images/vst-compatible.png)


### Mac installer

Our plug-ins were difficult to install on Mac. You would copy the right bundle into the right plug-in folder.

Now you just click on the `.pkg` file.


![Mac installer](images/mac-installer.png)


### -40% CPU reduction from an open UI

An open GUI now uses less CPU. The updated plug-ins also play nicer with multiple instances, by launching less threads.

![CPU usage of open UI](images/cpu-usage-open-ui.png)


### ALT + click to reset parameters

All controls now accept ALT + click as a way to reset a parameter. Most also accept double-click.


### Fix OBS Studio and Audio Hijack compatibility

![Logos of OBS Studio and Audio Hijack](images/obs-studio-and-audio-hijack.png)


### Removed Mac 32-bit support

We do not provide 32-bit plug-ins for Mac anymore. 32-bit builds are still provided for Windows. If you do need 32-bit Mac builds, please [contact us](faq/Help!-My-problem-isn't-listed-in-the-FAQ!.html).



## NEW in Graillon v2.2

### Stereo support in Graillon

A popular request!

Graillon will now act as a mono or stereo effect depending on the track.
In stereo mode, **operation is internally dual-mono apart from the pitch detection**, which has linked behaviour.

![Graillon v2.2 stereo](images/graillon-2.2-stereo.jpg)

_What's the consequence on CPU consumption?_ Well we optimized Graillon further. 
- Graillon v2.2 in mono uses 25% less CPU than Graillon v2.1 in mono. 
- Graillon v2.2 in stereo uses 25% more CPU than Graillon v2.1 in mono. 

So you should still be able to afford many instances.


### Visualize input MIDI notes

Many users don't realize Graillon can ingest MIDI input. We made it more visual with the MIDI view. **The active MIDI note is displayed in green.** We also display a small text on the pitch wheel when Pitch Correction is doing something.

![Graillon v2.2 stereo](images/graillon-2.2-midi-view.gif)

MIDI input still need the Pitch Correction to be enabled in order to have an effect, and that's why we...

### Invert Correction Amount and Inertia knob

Many users did not understand whether Pitch Correction were enabled. 
We swapped the "Inertia" and "Correction Amount" knob, to make that parameter more visually close to the section title. **"Correction Amount" is now named "Enable".**

![Graillon v2.2 stereo](images/graillon-2.2-swap-knobs.jpg)


### Fixed noise burst after silence

Graillon's silence detection was broken: it would make illogical noises after inaudible input. Now fixed.


### Fixed buffering bug in FLStudio

Occasionally Graillon's output would become wrong in FLStudio after tweaking buffer size. Now fixed.




## NEW in Panagement v1.4


### The Panagement Cheat Sheet

![panagement cheat sheet small](images/panagement-1.4-cheat-sheet-small.jpg)

Like our other plug-ins, Panagement now has a Cheat Sheet.

- [Panagement Cheat Sheet](../downloads/panagement-cheat-sheet.jpg)
- [Graillon Cheat Sheet](../downloads/graillon-cheat-sheet.jpg)
- [Couture Cheat Sheet](../downloads/couture-cheat-sheet.jpg)



### Zooming in Panagement

A common complaint with Panagement was that Far is too Far, and small Distance values were most useful. Thus recording automation was too blunt.

To solve that, **you can now zoom in Panagement using the Mouse Wheel.**

![Panagement zoom](images/panagement-1.4-zoom.gif)

Default zoom level is `x2`. At `x4` zoom level, you can set a source precisely inside the listener's head.

### Level panning

You can set from 0% to 200% the level panning within Panagement, which was previously hidden. 

This just scales interaural level difference; as such it is the most mono-compatible panning mode.
Useful if you disagree with the default pan tuning in Panagement!

![Panagement level panning](images/panagement-1.4-level-pan.jpg)


### More readable Phase Display

- Left-click on the Phase Display doubles its intensity.
- Right-click on the Phase Display disables it.

This was already available before, but with no visual feedback.

![Panagement level panning](images/panagement-1.4-phase-display.jpg)





## NEW in Couture v1.2


### A more solid peak detection

Couture transient detection was made more systematic with respect to short events.

![Couture Oversampling](images/couture-1.2-detection.jpg)

The difference is usually subtle, but is easiest to hear with the shortest attack times. You'll find that the gain change feels more "solid", as the peaks are processed more evenly.


### Tunable Oversampling

![Couture Oversampling](images/couture-1.2-oversampling.jpg)

If you are a Couture FULL customer you can change the oversampling in Couture, for an extra-edge:

- `x1` oversampling can be useful to have a very dry transient shaping,
- `x2` is the default oversampling in Couture,
- `x4` is an intermediate which is more CPU-conscious than `x8`,
- `x8` is a bit expensive CPU-wise but makes aliasing disappear.

`x4` and `x8` are a bit darker and analog-sounding than other oversampling rates. This is on purpose!

**This parameter is only available in the FULL Edition of Couture.** The FREE Edition is always oversampled `x2`.
This oversampling applies to both saturation and transient shaping.



### Dry Mix knob

![Couture Oversampling](images/couture-1.2-dry-mix.jpg)

You can now mix Dry unprocessed input alongside with the Wet signal.

Such Dry input will not have the phase change caused by the oversampling stage and/or distortion filters: 
as such it can be used as a kind of "New York transient shaping".


### Faster audio processing

At `x2` oversampling, Couture v1.2 goes 40% faster than Couture v1.1.


### Fix volume spikes at startup

Couture used to have long and wild volume spikes on instantiation.
Sonic outbursts will now stabilize faster at startup.


## Get the new downloads!

**If you are a customer,** you may find the newest downloads thanks to our [support FAQ](../faq/I'm-a-customer.-How-to-download-the-latest-plug-ins.html).

**If you are a free user,** you may find the new FREE downloads, User Manuals and Cheat Sheets on the product pages:
  * [Couture page](../products/Couture.html)
  * [Graillon page](../products/Graillon.html)  
  * [Panagement page](../products/Panagement.html).

**This is a backwards-compatible, free update**. Unless you were using 32-bit plug-ins on macOS, your sessions should keep working as intended, and you can safely overwrite the older plug-ins with the new ones.
