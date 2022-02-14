/**
Flow document.

Copyright: Guillaume Piolat 2022.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.flow.document;

import printed.canvas.irenderer;
import printed.flow.style;

/// A Flow Document produces output without any bo model, in a streamed manner.
/// If something fits, it is included.

/// The interface is thought to be able to render Markdown (without embedded HTML).
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

    /// Enter <strong>.
    void enterBold();

    /// Exit </strong>.
    void exitBold();

    /// Enter <em>.
    void enterEmph();

    /// Exit </em>.
    void exitEmph();

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
        _stateStack ~= State(_o.color, _o.fontSizePt, _o.fontFace, _o.fontWeight, _o.fontStyle);

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
        _cursorX = _o.pageLeftMarginMm;

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

    override void enterBold()
    {
        enterStyle(_o.strong);
    }

    override void exitBold()
    {
        exitStyle(_o.strong);
    }

    override void enterEmph()
    {
        enterStyle(_o.em);
    }

    override void exitEmph()
    {
        exitStyle(_o.em);
    }

    override void enterParagraph()
    {
        enterStyle(_o.p);
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
        _cursorX = _o.pageLeftMarginMm;
        _cursorY = _o.pageTopMarginMm;
    }

    // Insert word s, + a whitespace ' ' afterwards.
    void outputWord(const(char)[] s)
    {
        // TODO: fix TextMetric to return both horizontal advance, and extent

        TextMetrics metricsWithoutSpace = _r.measureText(s);
        TextMetrics metricsWithSpace = _r.measureText(s ~ ' ');

        float width = metricsWithoutSpace.width; 
        float horzAdvance = metricsWithSpace.width;

        // Will it fit? Trailing space doesn't cause breaking a line.
        bool fit = _cursorX + width < _W - _o.pageRightMarginMm;
        if (!fit)
            br();

        _r.fillText(s, _cursorX, _cursorY);
        _lastBoxX = _cursorX + width;
        _lastBoxY = _cursorY; // MAYDO: should be bottom-most point of the word, instead of baseline? Not sure.

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
        _r.save();
    }

    // Pop (context information + fontSize).
    void popState()
    {
        assert(_stateStack.length >= 2);
        _stateStack = _stateStack[0..$-1];
        _r.restore();

        // Apply former state to context
        applyCurrentState();
    }

    // Apply a TagStyle to the given state.
    // Set context values with the given state.
    void enterStyle(const(TagStyle) style)
    {
        pushState();

        // Update state
        State* state = &currentState();
        state.fontSize *= style.fontSizeEm;
        if (style.fontFace !is null) state.fontFace = style.fontFace;
        if (style.fontWeight != -1) state.fontWeight = style.fontWeight; 
        if (style.fontStyle != -1) state.fontStyle = style.fontStyle;
        if (style.color != "") state.color = style.color;
        applyCurrentState();

        // Margins: this must be done after fontSize is updated.
        if (style.display == DisplayStyle.block)
        {
            // ensure top margin
            float desiredMarginMin = currentState().fontSize * style.marginTopEm;
            float marginTop = _cursorY - _lastBoxY;
            if (marginTop < desiredMarginMin)
            {
                _cursorY += (desiredMarginMin - marginTop);
            }   
            checkPageEnded();
            _cursorX = _o.pageLeftMarginMm; // Always set at beginning of a line.
        }
    }

    void applyCurrentState()
    {
        // Update rendering with top state values.
        State* state = &currentState();
        _r.fillStyle(brush(state.color));
        _r.fontSize(state.fontSize);
        _r.fontWeight(state.fontWeight);
        _r.fontStyle(state.fontStyle);
        _r.fontFace(state.fontFace);
    }

    void exitStyle(const(TagStyle) style)
    {
        if (style.display == DisplayStyle.block)
        {
            // ensure bottom margin
            float desiredMarginBottom = currentState().fontSize * style.marginBottomEm;
            _cursorX = _o.pageLeftMarginMm;
            _cursorY = _lastBoxY + desiredMarginBottom;
            checkPageEnded();
        }
        popState();
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
    char peek() { return sentence[index]; }
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