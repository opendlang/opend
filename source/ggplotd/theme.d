module ggplotd.theme;

import cairo.cairo : RGBA;

alias ThemeFunction = Theme delegate(Theme);

struct Theme
{
    RGBA backgroundColour = RGBA(1,1,1,1);
}

///
ThemeFunction background( RGBA colour )
{
    return delegate(Theme t) { t.backgroundColour = colour; return t; };
}


///
ThemeFunction background( string colour )
{
    import ggplotd.colour;
    auto namedColours = createNamedColours();
    return delegate(Theme t) { t.backgroundColour = namedColours[colour]; 
        return t; };
}



