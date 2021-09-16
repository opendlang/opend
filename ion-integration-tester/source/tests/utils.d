module tests.utils;

__gshared bool disableColors = false;

static string emphasizeText(string s) {
    if (disableColors) return s;
    return "\033[1m" ~ s ~ "\033[m";
}

static string okayText(string s) {
    if (disableColors) return s;
    return "\033[32m" ~ s ~ "\033[m";
}

static string failText(string s) {
    if (disableColors) return s;
    return "\033[31m" ~ s ~ "\033[m";
}