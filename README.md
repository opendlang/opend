# pdf-d

pdf-d provides an immediate graphical context API for drawing vectorial content inside a multi-page PDF, HTML or SVG.
It is intended to provide a barebones API, in order to build text-aware APIs on top of it. 

Its API is similar to the HTML5 Canvas 2D API.

_The ultimate goal would be to generate technical documentation or user manuals with it, but for that you 
would need a text layout library._

## Features

- [x] PDF 1.7 output
- [x] SVG 1.1 output
- [x] HTML5 output through SVG embedding

[See features of the 2D renderer...](https://github.com/p0nce/pdf-d/blob/master/source/pdfd/irenderer.d)

## Goals

- Simplicity
- Reproducibility: pdf-d provides **TrueType and OpenType font embedding** in order to have fully reproducible vectors.
- Common denominator API, support many vectorial formats before being a rich API.

