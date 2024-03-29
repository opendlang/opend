/**
Flow document.

Copyright: Guillaume Piolat 2022.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.flow.document;

import std.conv: to;
import printed.canvas.irenderer;
import printed.canvas.image;
import printed.flow.style;

/// A Flow Document produces output without any box model, in a streamed manner.
/// If something fits, it is included.
/// Honestly, it's already complicated and having boxes and defering rendering is probably better
/// for better results.
/// For example, this rendere can't ever support hyphenation or text justifying.
/// The interface is thought to be able to render Markdown quickly.
interface IFlowDocument
{
    /// Output text.
    void text(const(char)[] s);

    /// Line break.
    void br();

    /// Next page.
    void pageSkip();

    /// Enter <h1> title.
    void enterH1();

    /// Exit </h1> title.
    void exitH1();

    /// Enter <h2> title.
    void enterH2();

    /// Exit </h2> title.
    void exitH2();

    /// Enter <h3> title.
    void enterH3();

    /// Exit </h3> title.
    void exitH3();

    /// Enter <h4> title.
    void enterH4();

    /// Exit </h4> title.
    void exitH4();

    /// Enter <h5> title.
    void enterH5();

    /// Exit </h5> title.
    void exitH5();

    /// Enter <h6> title.
    void enterH6();

    /// Exit </h6> title.
    void exitH6();

    /// Enter <b>.
    void enterB();

    /// Exit </b>.
    void exitB();

    /// Enter <strong>.
    void enterStrong();

    /// Exit </strong>.
    void exitStrong();

    /// Enter <i>.
    void enterI();

    /// Exit </i>.
    void exitI();

    /// Enter <em>.
    void enterEm();

    /// Exit </em>.
    void exitEm();

    /// Enter <p>.
    void enterParagraph();

    /// Exit </p>.
    void exitParagraph();

    /// Enter <pre>.
    void enterPre();

    /// Exit </pre>.
    void exitPre();

    /// Enter <code>.
    void enterCode();

    /// Exit </code>.
    void exitCode();

    /// Enter <ol>.
    void enterOrderedList();

    /// Exit </ol>.
    void exitOrderedList();

    /// Enter <ul>.
    void enterUnorderedList();

    /// Exit </ul>.
    void exitUnorderedList();

    /// Enter <li>.
    void enterListItem();

    /// Exit </li>.
    void exitListItem();

    /// Enter <img>.
    void enterImage(const(char)[] relativePath);

    /// Exit </img>.
    void exitImage();

    /// You MUST make that call before getting the bytes output of the renderer.
    /// No subsequent can be made with that `IFlowDocument`.
    void finalize();
}

/// Concrete implementation of `IFlowDocument` using a `
class FlowDocument : IFlowDocument
{    
    /// A `FlowDocument` needs an already created renderer, and style options.
    this(IRenderingContext2D renderer, StyleOptions options = StyleOptions.init)
    {
        _W = renderer.pageWidth();
        _H = renderer.pageHeight();
        _r = renderer;
        _o = options;

        // Create default state (will be _stateStack[0] throughout)
        int listItemNumber = 0;
        float leftMarginMm = _o.pageLeftMarginMm;
        _stateStack ~= State(_o.color, 
                             _o.fontSizePt, 
                             _o.fontFace, 
                             _o.fontWeight, 
                             _o.fontStyle, 
                             _o.textAlign,
                             ListStyleType.disc,
                             listItemNumber,
                             leftMarginMm);
        decoratePage();
        resetCursorTopLeft();
    }    

    // Each word is split independently. 
    // \n is a special character for forcing a line break.
    override void text(const(char)[] s)
    {
        // TODO: preserve spaces in <pre>, CSS white-space: pre;
        string[] words = splitIntoWords(s);

        foreach(size_t i, word; words)
        {
            outputWord(word);
        }
    }

    override void br()
    {
        _cursorX = currentState.leftMargin;

        TextMetrics m = _r.measureText("A");
        _cursorY += m.lineGap;
        checkPageEnded();        
    }

    override void pageSkip()
    {
        _r.newPage;
        _pageCount += 1;
        decoratePage();
        resetCursorTopLeft();
    }

    override void enterH1()
    {
        enterStyle(_o.h1);
    }

    override void exitH1()
    {
        exitStyle(_o.h1);
    }

    override void enterH2()
    {
        enterStyle(_o.h2);
    }

    override void exitH2()
    {
        exitStyle(_o.h2);
    }

    override void enterH3()
    {
        enterStyle(_o.h3);
    }

    override void exitH3()
    {
        exitStyle(_o.h3);
    }

    override void enterH4()
    {
        enterStyle(_o.h4);
    }

    override void exitH4()
    {
        exitStyle(_o.h4);
    }

    override void enterH5()
    {
        enterStyle(_o.h5);
    }

    override void exitH5()
    {
        exitStyle(_o.h5);
    }

    override void enterH6()
    {
        enterStyle(_o.h6);
    }

    override void exitH6()
    {
        exitStyle(_o.h6);
    }

    override void enterB()
    {
        enterStyle(_o.b);
    }

    override void exitB()
    {
        exitStyle(_o.b);
    }

    override void enterStrong()
    {
        enterStyle(_o.strong);
    }

    override void exitStrong()
    {
        exitStyle(_o.strong);
    }

    override void enterI()
    {
        enterStyle(_o.i);
    }

    override void exitI()
    {
        exitStyle(_o.i);
    }

    override void enterEm()
    {
        enterStyle(_o.em);
    }

    override void exitEm()
    {
        exitStyle(_o.em);
    }

    override void enterParagraph()
    {
        enterStyle(_o.p);
        _cursorX += _o.paragraphTextIndentMm;
    }

    override void exitParagraph()
    {
        exitStyle(_o.p);
    }

    override void enterPre()
    {
        enterStyle(_o.pre);
    }

    override void exitPre()
    {
        exitStyle(_o.pre);
    }

    override void enterCode()
    {
        enterStyle(_o.code);
    }

    override void exitCode()
    {
        exitStyle(_o.code);
    }

    override void enterOrderedList()
    {
        enterStyle(_o.ol);
    }

    override void exitOrderedList()
    {
        exitStyle(_o.ol);
    }

    override void enterUnorderedList()
    {
        enterStyle(_o.ul);
    }

    override void exitUnorderedList()
    {
        exitStyle(_o.ul);
    }

    override void enterListItem()
    {
        enterStyle(_o.li);
    }

    override void exitListItem()
    {
        exitStyle(_o.li);
    }

    void enterImage(const(char)[] relativePath)
    {
        enterStyle(_o.img);
        Image image = loadImageLazily(relativePath);

        // hard-wired center in page
        float w = image.printWidth();
        float h = image.printHeight();
        
        float maxWidth = _W - _o.pageLeftMarginMm -  _o.pageRightMarginMm;

        // Can't exceed available page width.
        if (w > maxWidth)
        {
            h *= (maxWidth / w);
            w = maxWidth;
        }

        if (remainPageHeight() < h) 
            pageSkip();
        
        _r.drawImage(image, (_W - w) / 2, _cursorY, w, h);
        _cursorY += h;
        _lastBoxY = _cursorY;
    }

    void exitImage()
    {
        exitStyle(_o.img);
    }

    override void finalize()
    {
        _finalized = true;
        assert(_stateStack.length == 1); // must close any tag entry
        _stateStack = [];
    }

    void checkPageEnded()
    {
        if (_cursorY >= _H - _o.pageBottomMarginMm)
        {
            pageSkip();
        }
    }

private:
    // 2D Renderer.
    IRenderingContext2D _r;

    // Document page width (in mm)
    float _W;

    // Document page height (in mm)
    float _H;

    // Style options.
    StyleOptions _o;

    // position of next thing thing to include (in millimeters)
    float _cursorX;
    float _cursorY;

    // position of bottom-right of the last box inserted,
    // not counting the margins
    float _lastBoxX;
    float _lastBoxY;

    int _pageCount = 1;
    bool _finalized = false;

    // called when page is created
    void decoratePage()
    {
        _r.save();
        if (_o.onEnterPage !is null) _o.onEnterPage(_r, _pageCount);
        _r.restore();
    }

    void resetCursorTopLeft()
    {
        _lastBoxX = 0;
        _lastBoxY = 0;
        _cursorX = currentState.leftMargin;
        _cursorY = _o.pageTopMarginMm;
    }

    // Insert word s, + a whitespace ' ' afterwards.
    void outputWord(const(char)[] s)
    {
        TextMetrics metricsWithoutSpace = _r.measureText(s);
        TextMetrics metricsWithSpace = _r.measureText(s ~ ' ');

        float bbright = metricsWithoutSpace.width; // TODO: have correct actualBoundingBoxRight; 
        float horzAdvance = metricsWithSpace.width;

        // Will it fit? Trailing space doesn't cause breaking a line.
        bool fit = _cursorX + bbright < _W - _o.pageRightMarginMm;
        if (!fit)
            br();

        _r.fillText(s, _cursorX, _cursorY);
        _lastBoxX = _cursorX + bbright;
        _lastBoxY = _cursorY + metricsWithoutSpace.fontBoundingBoxDescent;

        _cursorX += horzAdvance;
        if (_cursorX >= _W - _o.pageRightMarginMm)
        {
            br(); // line break
        }
    }

    // State management.
    // At any point there must be at least one item in here.
    // The last item holds the current font size.

    static struct State
    {
        string color;
        float fontSize;
        string fontFace;
        FontWeight fontWeight;
        FontStyle fontStyle;
        TextAlign textAlign;
        ListStyleType listStyleType;
        int listItemNumber;
        float leftMargin; // margin applied by every item, in millimeters
    }

    State[] _stateStack;

    ref State currentState()
    {
        return _stateStack[$-1];
    }

    // Pushes (context information + fontSize).
    // This duplicate the top state, but doesn't change it.
    void pushState()
    {
        assert(_stateStack.length != 0);
        _stateStack ~= _stateStack[$-1];
    }

    // Pop (context information + fontSize).
    void popState()
    {
        assert(_stateStack.length >= 2);
        _stateStack = _stateStack[0..$-1];

        // Apply former state to context
        updateRendererStateWithStyleState();
    }

    // Apply a TagStyle to the given state.
    // Set context values with the given state.
    void enterStyle(const(TagStyle) style)
    {
        if (style.display == DisplayStyle.listItem)
        {
            currentState().listItemNumber += 1;
        }

        pushState();

        if (style.listStyleType != ListStyleType.inherit)
        {
            // if it's a <ul> or <ol> tag, reset item number.
            currentState().listItemNumber = 0;
        }

        // Update state, applying style.
        State* state = &currentState();
        state.fontSize *= style.fontSizeEm;
        if (style.fontFace !is null) state.fontFace = style.fontFace;
        if (style.fontWeight != -1) state.fontWeight = style.fontWeight; 
        if (style.fontStyle != -1) state.fontStyle = style.fontStyle;
        if (style.textAlign != -1) state.textAlign = style.textAlign;
        if (style.color != "") state.color = style.color;
        if (style.listStyleType != ListStyleType.inherit) state.listStyleType = style.listStyleType;

        // margin left
        {
            state.leftMargin += style.marginLeftMm;
            _cursorX += style.marginLeftMm;
        }

        updateRendererStateWithStyleState();

        // Margins: this must be done after fontSize is updated.
        if (style.hasBlockDisplay())
        {
            // ensure top margin
            float desiredMarginMin = convertPointsToMillimeters(currentState().fontSize * style.marginTopEm);
   
            // What would be the top-margin if a 'A' were to be drawn here?
            auto m = _r.measureText("A");
            float marginTop = _cursorY - m.fontBoundingBoxAscent - _lastBoxY;
            if (marginTop < desiredMarginMin)
            {
                _cursorY += (desiredMarginMin - marginTop);
            }   
            checkPageEnded();
            _cursorX = currentState.leftMargin; // Always set at beginning of a line.
        }

        // list-item display
        if (style.display == DisplayStyle.listItem)
        {
            final switch(state.listStyleType)
            {
                case ListStyleType.inherit: break;
                case ListStyleType.disc: 
                {
                    float emSizeMm = convertPointsToMillimeters( currentState().fontSize );
                    float discRadius = 0.17 * emSizeMm;
                    float discOffsetY = -0.23f * emSizeMm;

                    // TODO: implement a disc with a disc, not a rectangle
                    float x = _cursorX + discRadius;
                    float y = _cursorY + discOffsetY;
                    _r.fillRect(x - discRadius, y - discRadius, discRadius * 2, discRadius * 2);

                    float advance = _r.measureText("1. ").width;
                    _cursorX += advance;
                    break;
                }
                case ListStyleType.decimal: text(to!string(state.listItemNumber) ~ ". "); break;
            }
        }
    }

    void updateRendererStateWithStyleState()
    {
        // Update rendering with top state values.
        State* state = &currentState();
        _r.fillStyle(brush(state.color));
        _r.fontSize(state.fontSize);
        _r.fontWeight(state.fontWeight);
        _r.fontStyle(state.fontStyle);
        _r.fontFace(state.fontFace);
        _r.textAlign(state.textAlign);
    }

    void exitStyle(const(TagStyle) style)
    {
        if (style.hasBlockDisplay())
        {
            // ensure bottom margin
            float desiredMarginBottomMm = convertPointsToMillimeters(currentState().fontSize * style.marginBottomEm);

            // What would be the bottom-margin if a 'A' were to be drawn here?
            auto m = _r.measureText("A");
            float marginBottom = _cursorY - m.fontBoundingBoxAscent - _lastBoxY;

            float insertGap = 0;
            if (desiredMarginBottomMm > marginBottom)
                insertGap = (desiredMarginBottomMm - marginBottom);

            _cursorX = currentState.leftMargin;
            _cursorY += insertGap;
            checkPageEnded();
        }
        popState();
    }

    alias ImageKey = const(char)[];

    Image[ ImageKey ] _imageCache;

    Image loadImageLazily(ImageKey relativePath)
    {
        if (relativePath !in _imageCache)
        {
            _imageCache[relativePath] = new Image(relativePath);
        }
        return _imageCache[relativePath]; 
    }

    float remainPageHeight()
    {
        return _H - _o.pageBottomMarginMm - _cursorY;
    }
}

// Whitespace processing in normal HTML mode:
// " - Any sequence of collapsible spaces and tabs immediately preceding or 
//      following a segment break is removed.
//   - Collapsible segment breaks are transformed for rendering according to 
//     the segment break transformation rules.
//   - Every collapsible tab is converted to a collapsible space (U+0020).
//   - Any collapsible space immediately following another collapsible space—even 
//     one outside the boundary of the inline containing that space, provided both
//     spaces are within the same inline formatting context—is collapsed to have 
//     zero advance width. (It is invisible, but retains its soft wrap opportunity, 
//     if any.)
// What we do as a simplifcation => collapse strings of white space into a single char ' '.
string[] splitIntoWords(const(char)[] sentence)
{
    // PERF: this is rather bad

    bool isWhitespace(char ch)
    {
        return ch == '\n' || ch == ' ' || ch == '\t' || ch == '\r';
    }

    int index = 0;
    char peek() 
    { 
       // assert(sentence[index] != '\n');
        return sentence[index]; 
    }
    void next() { index++; }
    bool empty() { return index >= sentence.length; }

    bool stateInWord = false;

    string[] res;

    void parseWord()
    {
        assert(!empty);
        while(!empty && isWhitespace(peek))
            next;
        if (empty) return;
        assert(!isWhitespace(peek));

        // start of word is here
        string word;
        while(!empty && !isWhitespace(peek))
        {
            word ~= peek;
            next;
        }
        // word parsed here, push it
        res ~= word;
    }

    while (!empty)
    {
        parseWord;
    }
    assert(empty);
    return res;
}


