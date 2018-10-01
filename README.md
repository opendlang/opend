# `printed`

Low-level API to generate self-contained PDF/SVG/HTML documents suitable for print.

`printed` provides an immediate graphical context API for drawing vectorial content inside a multi-page PDF, HTML or SVG.
It is intended to provide a barebones API, and need text-aware APIs on top of it. 

Its API is similar to the HTML5 Canvas 2D API.

_The ultimate goal would be to generate technical documentation or user manuals with it, but for that you 
would need a text layout library._

## Features

- [x] **TrueType and OpenType font embedding** in order to have fully reproducible vectors
- [x] PDF 1.7 output
- [x] SVG 1.1 output
- [x] HTML5 output through SVG embedding

[See features of the 2D renderer...](https://github.com/p0nce/printed/blob/master/canvas/printed/canvas/irenderer.d)

## Goals

- Simplicity
- Reproducibility
- Common denominator API, support many vectorial formats before being a rich API.

