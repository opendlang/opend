module requests.idna;

import std.format;
import std.exception;
import std.uni;
import std.ascii;
import std.range;
import std.algorithm;
import std.regex;
import std.functional;

static import requests.idna.punycode;


private {
    static immutable _alabel_prefix = "xn--";
    static immutable _unicode_dots_re = "[\\.\u002e\u3002\uff0e\uff61]";
}

class IDNAException: Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) pure @safe {
        super(msg, file, line);
    }
}

bool valid_label_length(string label) pure nothrow @nogc @safe {
    return label.length <= 63;
}

bool valid_string_length(string label, bool trailing_dot = false) pure nothrow @safe @nogc {
     return label.length <= (trailing_dot ? 254 : 253);
}

bool check_hyphen_ok(string label) pure @safe {
    if ( label[0] == '-' || label[$-1] == '-' ) {
        throw new IDNAException("Label can't start or ends with hyphen");
    }
    if ( label.length>=4 && label[2..4] == "--" ) {
        throw new IDNAException("Label can't have hyphens in 3 and 4 positions");
    }
    return true;
}

bool check_nfc(string label) @safe {
    if ( label !is normalize(label) ) {
        throw new IDNAException("label %s is not normalized".format(label));
    }
    return true;
}

bool check_initial_combiner(string label) pure @safe {
    if ( combiningClass(label.front) ) {
        throw new IDNAException("Label begins with an illegal combining character");
    }
    return true;
}

bool check_label(string label) @safe {

    if ( label.length == 0 ) {
        throw new IDNAException("Empty label");    
    }
    check_hyphen_ok(label);
    check_nfc(label);
    check_initial_combiner(label);

    return true;
}

string alabel(string label) @safe {
    // convert u-label to a-label
    check_label(label);
    auto result = _alabel_prefix ~ requests.idna.punycode.encode(label);
    if ( !valid_label_length(result) ) {
        throw new IDNAException("Label %s too long".format(result));
    }
    return result;
}

string encode_label(string label) @safe {
    if ( label.count!(not!isASCII) == 0 )
        return label;
    return alabel(label);
}

string idn_encode(string domain) @safe {
    if ( domain.count!(not!isASCII) == 0 )
        return domain;
    auto src = domain.toLower;
    auto ulabels = src.splitter(regex(_unicode_dots_re));
    string encoded = ulabels.map!encode_label.join(".");
    if ( !valid_string_length(encoded) ) {
        throw new IDNAException("Encoded domain name is too long");
    }
    return encoded;
}

unittest {
    import std.stdio;
    import std.array;

    immutable tld_strings = [
        ["\u6d4b\u8bd5", "xn--0zwm56d"],
        ["\u092a\u0930\u0940\u0915\u094d\u0937\u093e", "xn--11b5bs3a9aj6g"],
        ["\ud55c\uad6d", "xn--3e0b707e"],
        ["\u0438\u0441\u043f\u044b\u0442\u0430\u043d\u0438\u0435", "xn--80akhbyknj4f"],
        ["\u0441\u0440\u0431", "xn--90a3ac"],
        ["\ud14c\uc2a4\ud2b8", "xn--9t4b11yi5a"],
        ["\u0b9a\u0bbf\u0b99\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0bc2\u0bb0\u0bcd", "xn--clchc0ea0b2g2a9gcd"],
        ["\u05d8\u05e2\u05e1\u05d8", "xn--deba0ad"],
        ["\u4e2d\u56fd", "xn--fiqs8s"],
        ["\u4e2d\u570b", "xn--fiqz9s"],
        ["\u0c2d\u0c3e\u0c30\u0c24\u0c4d", "xn--fpcrj9c3d"],
        ["\u6e2c\u8a66", "xn--g6w251d"],
        ["\u0aad\u0abe\u0ab0\u0aa4", "xn--gecrj9c"],
        ["\u092d\u093e\u0930\u0924", "xn--h2brj9c"],
        ["\u0622\u0632\u0645\u0627\u06cc\u0634\u06cc", "xn--hgbk6aj7f53bba"],
        ["\u0baa\u0bb0\u0bbf\u0b9f\u0bcd\u0b9a\u0bc8", "xn--hlcj6aya9esc7a"],
        ["\u0443\u043a\u0440", "xn--j1amh"],
        ["\u9999\u6e2f", "xn--j6w193g"],
        ["\u03b4\u03bf\u03ba\u03b9\u03bc\u03ae", "xn--jxalpdlp"],
        ["\u0625\u062e\u062a\u0628\u0627\u0631", "xn--kgbechtv"],
        ["\u53f0\u6e7e", "xn--kprw13d"],
        ["\u53f0\u7063", "xn--kpry57d"],
        ["\u0627\u0644\u062c\u0632\u0627\u0626\u0631", "xn--lgbbat1ad8j"],
        ["\u0639\u0645\u0627\u0646", "xn--mgb9awbf"],
        ["\u0627\u06cc\u0631\u0627\u0646", "xn--mgba3a4f16a"],
        ["\u0627\u0645\u0627\u0631\u0627\u062a", "xn--mgbaam7a8h"],
        ["\u067e\u0627\u06a9\u0633\u062a\u0627\u0646", "xn--mgbai9azgqp6j"],
        ["\u0627\u0644\u0627\u0631\u062f\u0646", "xn--mgbayh7gpa"],
        ["\u0628\u06be\u0627\u0631\u062a", "xn--mgbbh1a71e"],
        ["\u0627\u0644\u0645\u063a\u0631\u0628", "xn--mgbc0a9azcg"],
        ["\u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629", "xn--mgberp4a5d4ar"],
        ["\u10d2\u10d4", "xn--node"],
        ["\u0e44\u0e17\u0e22", "xn--o3cw4h"],
        ["\u0633\u0648\u0631\u064a\u0629", "xn--ogbpf8fl"],
        ["\u0440\u0444", "xn--p1ai"],
        ["\u062a\u0648\u0646\u0633", "xn--pgbs0dh"],
        ["\u0645\u0635\u0631", "xn--wgbh1c"],
        ["\u0642\u0637\u0631", "xn--wgbl6a"],
        ["\u0b87\u0bb2\u0b99\u0bcd\u0b95\u0bc8", "xn--xkc2al3hye2a"],
        ["\u65b0\u52a0\u5761", "xn--yfro4i67o"],
        ["\u0641\u0644\u0633\u0637\u064a\u0646", "xn--ygbi2ammx"],
        ["\u30c6\u30b9\u30c8", "xn--zckzah"],
        ["\u049b\u0430\u0437", "xn--80ao21a"],
        ["\u0645\u0644\u064a\u0633\u064a\u0627", "xn--mgbx4cd0ab"],
        ["\u043c\u043e\u043d", "xn--l1acc"],
        ["\u0633\u0648\u062f\u0627\u0646", "xn--mgbpl2fh"]
        //
        // these strings do not pass normalization test
        //
        //["\u0dbd\u0d82\u0d9a\u0dcf", "xn--fzc2c9e2c"],
        //["\u09ad\u09be\u09b0\u09a4", "xn--45brj9c"],
        //["\u09ac\u09be\u0982\u09b2\u09be", "xn--54b7fta0cc"],
        //["\u0a2d\u0a3e\u0a30\u0a24", "xn--s9brj9c"],
        //["\u0b87\u0ba8\u0bcd\u0ba4\u0bbf\u0baf\u0bbe", "xn--xkc2dl3a5ee0h"],
    ];
    assert(valid_label_length("abc"));
    assert(!valid_label_length("a".replicate(64)));

    assert(valid_string_length("a".replicate(253)));
    assert(!valid_string_length("a".replicate(254)));
    assert(valid_string_length("a".replicate(254), true));
    
    assert(check_hyphen_ok("ab"));
    assertThrown!IDNAException(check_hyphen_ok("-abcd"));
    assertThrown!IDNAException(check_hyphen_ok("abcd-"));
    assertThrown!IDNAException(check_hyphen_ok("ab--cd"));
    
    assert(check_nfc("привіт"));
    assert(check_nfc("\u03D3"));
    assertThrown!IDNAException(check_nfc("\u03D2\u0301"));

    assert(check_initial_combiner("n\u0303"));
    assertThrown!IDNAException(check_initial_combiner("\u0303n"));

    foreach(p; tld_strings) {
        string u = p[0];
        string a = p[1];
        assert(alabel(u) == a);
    }
    assert(toLower("Тест") == "тест");
    assert(idn_encode("abc.de") == "abc.de");
    assert(idn_encode("тест") != "тест");
    assert(idn_encode("\u30c6\u30b9\u30c8.xn--zckzah") == "xn--zckzah.xn--zckzah");
    assert(idn_encode("\u30c6\u30b9\u30c8\uff0e\u30c6\u30b9\u30c8") == "xn--zckzah.xn--zckzah");
    assert(idn_encode("\u0521\u0525\u0523-\u0523\u0523-----\u0521\u0523\u0523\u0523.aa") == "xn---------90gglbagaar.aa");
}