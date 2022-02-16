/**
Simple "style" API for Flow Document.

Copyright: Guillaume Piolat 2022.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.flow.style;

import printed.canvas.irenderer;

/// Similar intent than CSS display property.
/// Only outside display is considered.
enum DisplayStyle
{
    inline,   /// Insert in same line flow.
    block,    /// Insert line-break before and after.
    listItem, /// Same as block but also display ListStyleType
}

/// More or less similar to CSS list-style-type 
enum ListStyleType
{
    inherit,
    disc,
    decimal
}

struct TagStyle
{
public:
    /// Text color. "" means "inherit".
    string color = "";

    /// Display inline or block.
    DisplayStyle display = DisplayStyle.inline;

    /// Font size in em. 1.0f means "inherit"
    float fontSizeEm = 1.0f;  

    /// Font face. `null` means "inherit"
    string fontFace = null;   

    /// Font weight. -1 means "inherit"
    FontWeight fontWeight = cast(FontWeight)-1; 

    /// Font style. -1 means "inherit"
    FontStyle fontStyle = cast(FontStyle)-1;

    /// Margins, in em (unused)
    float marginTopEm = 0;    /// Only used when hasBlockDisplay() 
    float marginRightMm = 0;  /// Unused.
    float marginBottomEm = 0; /// Only used when hasBlockDisplay()
    float marginLeftMm = 0;   /// Warning: in mm not em.

    ListStyleType listStyleType;

    bool hasBlockDisplay() pure const
    {
        return display == DisplayStyle.block || display == DisplayStyle.listItem;
    }
}

/// Style options for various tags.
/// Helpful reference: https://www.w3.org/TR/CSS22/sample.html
/// Note: there is no <b> and <i> style, as commonmark-d doesn't generate them.
struct StyleOptions
{
    string color = "black";                    /// Default text color.
    float fontSizePt = 10.0f;                  /// Default font size, in points.
    string fontFace = "Helvetica";             /// Default font face.
    FontWeight fontWeight = FontWeight.normal; /// Default font weight.
    FontStyle fontStyle = FontStyle.normal;    /// Default font italic-ness
    
    float pageLeftMarginMm   = 19;   /// Left margin, in millimeters.
    float pageRightMarginMm  = 19;   /// Right margin, in millimeters.
    float pageTopMarginMm    = 25.4; /// Top margin, in millimeters.
    float pageBottomMarginMm = 36.7; /// Bottom margin, in millimeters.

    float paragraphTextIndentMm = 5; /// <p> first line text indentation, in millimeters.

    /// An empty callback you can override to decorate each page of the document.
    /// You cannot call other `FlowDocument` function from inside this callback.
    /// `pageCount` is the page number, starting with 1.
    /// This is called before anything else is drawn on a page.
    void delegate (IRenderingContext2D context, int pageCount) onEnterPage = null;

    TagStyle p      = TagStyle("", DisplayStyle.block,  1.0f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  1.12, 0, 1.12,   0, ListStyleType.inherit);
    TagStyle strong = TagStyle("", DisplayStyle.inline, 1.0f,  null, FontWeight.bold,    cast(FontStyle)-1,     0, 0,    0,   0, ListStyleType.inherit);
    TagStyle em     = TagStyle("", DisplayStyle.inline, 1.0f,  null, cast(FontWeight)-1, FontStyle.italic,      0, 0,    0,   0, ListStyleType.inherit);
    TagStyle h1     = TagStyle("", DisplayStyle.block,  2.0f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  0.67, 0, 0.67,   0, ListStyleType.inherit);
    TagStyle h2     = TagStyle("", DisplayStyle.block,  1.5f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  0.75, 0, 0.75,   0, ListStyleType.inherit);
    TagStyle h3     = TagStyle("", DisplayStyle.block, 1.17f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  0.83, 0, 0.83,   0, ListStyleType.inherit);
    TagStyle h4     = TagStyle("", DisplayStyle.block,  1.0f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  1.12, 0, 1.12,   0, ListStyleType.inherit);
    TagStyle h5     = TagStyle("", DisplayStyle.block, 0.83f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  1.50, 0,  1.5,   0, ListStyleType.inherit);
    TagStyle h6     = TagStyle("", DisplayStyle.block, 0.75f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  1.67, 0, 1.67,   0, ListStyleType.inherit);

    TagStyle pre    = TagStyle("", DisplayStyle.inline, 1.0f,"Courier New",cast(FontWeight)-1,cast(FontStyle)-1,0, 0,    0,   0, ListStyleType.inherit);
    TagStyle code   = TagStyle("", DisplayStyle.inline, 1.0f,"Courier New",cast(FontWeight)-1, cast(FontStyle)-1,0,0,    0,   0, ListStyleType.inherit);

    TagStyle ol     = TagStyle("", DisplayStyle.block,  1.0f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  1.12, 0, 1.12,   0, ListStyleType.decimal);
    TagStyle ul     = TagStyle("", DisplayStyle.block,  1.0f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  1.12, 0, 1.12,   0, ListStyleType.disc);
    TagStyle li     = TagStyle("",DisplayStyle.listItem,1.0f,  null, cast(FontWeight)-1, cast(FontStyle)-1,     0, 0,    0,10.5, ListStyleType.inherit);
    TagStyle img    = TagStyle("", DisplayStyle.block,  1.0f,  null, cast(FontWeight)-1, cast(FontStyle)-1,  1.12, 0, 1.12,   0, ListStyleType.inherit);
}