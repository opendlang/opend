# pdf-d

pdf-d provides an immediate graphical context API for drawing vectorial content inside a multi-page PDF, HTML or SVG.
It is intended to provide a barebones API, in order to build text-aware APIs on top of it. 

Its API is similar to the HTML5 Canvas API.

_The ultimate goal would be to generate technical documentation or user manuals with it, but for that you 
would need a text layout library._

## Goals

- Simplicity
- Reproducibility: pdf-d provides **TrueType and OpenType font embedding** in order to have fully reproducible vectors.
- Common denominator API, support many vectorial formats before being a rich API.

