module ggplotd.guide;

/++
Support of different guides, i.e. continuous or discrete

T is the type that should always be returned (double for location, 
U is the "native" type
F is a special function that overwrites the default conversion. This is for example
    used in colours to support named colours. It should return a Nullable!T.

For continuous, both U and T should support arithmetic (- and /) operations? (one of them is enough?) aor provide a function that returns a T based on U and two breaks.
+/

Guide(T, U, F) {
    /// Continuous or discrete
    string type;

    /// Here we control the scaling between breaks. Each break is equal distance in T
    U[] breaks
}
