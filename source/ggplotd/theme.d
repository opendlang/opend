module ggplotd.theme;

import cairo.cairo : RGBA;

alias ThemeFunction = Theme delegate(Theme);

struct Theme
{
    RGBA backgroundColour;
}

///
ThemeFunction background( RGBA colour )
{
    return delegate(Theme t) { t.backgroundColour = colour; return t; };
}


