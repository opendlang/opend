# commonmark-d

## Example

`commonmark-d` is a D translation of [MD4C](https://github.com/mity/md4c), a fast SAX-like Markdown parser.
MD4C achieves remarkable parsing speed through the lack of AST and careful memory usage.

```d

// Parse CommonMark, generate HTML
import commonmarkd;
string html = convertMarkdownToHTML(markdown);

// Parse Github Flavoured Markdown, generate HTML
string html = convertMarkdownToHTML(markdown, MarkdownFlag.dialectGitHub);

// Parse CommonMark without HTML support, generate HTML
import commonmarkd;
string html = convertMarkdownToHTML(markdown, MarkdownFlag.noHTML);


```

## Changes versus original parser

- Only UTF-8 input is supported
- `malloc` and `realloc` failures are not considered, because in Out Of Memory situations crashing is a reasonable solution.