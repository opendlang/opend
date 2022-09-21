
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.internal.yaml.test.tokens;

@safe unittest
{
    import std.array : split;
    import mir.format : text;
    import std.file : readText;

    import mir.internal.yaml.test.common : run;
    import mir.internal.yaml.reader : Reader;
    import mir.internal.yaml.scanner : Scanner;
    import mir.internal.yaml.token : TokenID;

    // Read and scan a YAML doc, returning a range of tokens.
    static auto scanTestCommon(string filename) @safe
    {
        auto yamlData = readText(filename);
        return Scanner(Reader(yamlData));
    }

    /**
    Test tokens output by scanner.

    Params:
        dataFilename = File to scan.
        tokensFilename = File containing expected tokens.
    */
    static void testTokens(string dataFilename, string tokensFilename) @safe
    {
        //representations of YAML tokens in tokens file.
        auto replace = [
            TokenID.directive: "%",
            TokenID.documentStart: "---",
            TokenID.documentEnd: "...",
            TokenID.alias_: "*",
            TokenID.anchor: "&",
            TokenID.tag: "!",
            TokenID.scalar: "_",
            TokenID.blockSequenceStart: "[[",
            TokenID.blockMappingStart: "{{",
            TokenID.blockEnd: "]}",
            TokenID.flowSequenceStart: "[",
            TokenID.flowSequenceEnd: "]",
            TokenID.flowMappingStart: "{",
            TokenID.flowMappingEnd: "}",
            TokenID.blockEntry: ",",
            TokenID.flowEntry: ",",
            TokenID.key: "?",
            TokenID.value: ":"
        ];

        string[] tokens;
        string[] expectedTokens = readText(tokensFilename).split();

        foreach (token; scanTestCommon(dataFilename))
        {
            if (token.id != TokenID.streamStart && token.id != TokenID.streamEnd)
            {
                tokens ~= replace[token.id];
            }
        }

        assert(tokens == expectedTokens,
            text("In token test for '", tokensFilename, "', expected '", expectedTokens, "', got '", tokens, "'"));
    }

    /**
    Test scanner by scanning a file, expecting no errors.

    Params:
        dataFilename = File to scan.
        canonicalFilename = Another file to scan, in canonical YAML format.
    */
    static void testScanner(string dataFilename, string canonicalFilename) @safe
    {
        foreach (filename; [dataFilename, canonicalFilename])
        {
            string[] tokens;
            foreach (token; scanTestCommon(filename))
            {
                tokens ~= token.id.text;
            }
        }
    }
    run(&testTokens, ["data", "tokens"]);
    run(&testScanner, ["data", "canonical"]);
}
