module ggplotd.theme;

import ggplotd.colourspace : RGBA;

alias ThemeFunction = Theme delegate(Theme);

/// Theme holding background colour
struct Theme
{
    /// The background colour
    RGBA backgroundColour = RGBA(1,1,1,1);
}

/// Return function that sets bacground colour
ThemeFunction background( RGBA colour )
{
    return delegate(Theme t) { t.backgroundColour = colour; return t; };
}


/++
    Return function that sets bacground colour

    Examples:
    ----------------
    GGPlotD().put( background( "black" );
    ----------------
+/
ThemeFunction background( string colour )
{
    import ggplotd.colour : namedColours;
    return delegate(Theme t) { t.backgroundColour = namedColours[colour]; 
        return t; };
}



