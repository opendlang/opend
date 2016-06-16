module pdfd.pdf;

///
class PDF
{
	ubyte[] toBytes()
	{
        ubyte[] buffer;

        void appendString(string s)
        {
            buffer ~= cast(ubyte[])s;
        }

        appendString("%PDF-1.1\n");

        // "If a PDF file contains binary data, as most do (see 7.2, "Lexical Conventions"), 
        // the header line shall be immediately followed by a comment line containing at least 
        // four binary characters—that is, characters whose codes are 128 or greater.
        // This ensures proper behaviour of file transfer applications that inspect data near 
        // the beginning of a file to determine whether to treat the file’s contents as text or as binary."
        appendString("%¥±ë\n");       
        appendString("\n");
        appendString("1 0 obj\n");
        appendString("  << /Type /Catalog\n");
        appendString("     /Pages 2 0 R\n");
        appendString("  >>\n");
        appendString("endobj\n");
        appendString("\n");
        appendString("2 0 obj\n");
        appendString("  << /Type /Pages\n");
        appendString("     /Kids [3 0 R]\n");
        appendString("     /Count 1\n");
        appendString("     /MediaBox [0 0 300 144]\n");
        appendString("  >>\n");
        appendString("endobj\n");
        appendString("\n");
        appendString("3 0 obj\n");
        appendString("  <<  /Type /Page\n");
        appendString("      /Parent 2 0 R\n");
        appendString("      /Resources\n");
        appendString("       << /Font\n");
        appendString("           << /F1\n");
        appendString("               << /Type /Font\n");
        appendString("                  /Subtype /Type1\n");
        appendString("                  /BaseFont /Times-Roman\n");
        appendString("               >>\n");
        appendString("           >>\n");
        appendString("       >>\n");
        appendString("       /Contents 4 0 R\n");
        appendString("  >>\n");
        appendString("endobj\n");
        appendString("\n");
        appendString("4 0 obj\n");
        appendString("  << /Length 55 >>\n");
        appendString("stream\n");
        appendString("  BT\n");
        appendString("    /F1 18 Tf\n");
        appendString("    0 0 Td\n");
        appendString("    (Hello World) Tj\n");
        appendString("  ET\n");
        appendString("endstream\n");
        appendString("endobj\n");
        appendString("\n");
        appendString("xref\n");
        appendString("0 5\n");
        appendString("0000000000 65535 f \n");
        appendString("0000000018 00000 n \n");
        appendString("0000000077 00000 n \n");
        appendString("0000000178 00000 n \n");
        appendString("0000000457 00000 n \n");
        appendString("trailer\n");
        appendString("  <<  /Root 1 0 R\n");
        appendString("      /Size 5\n");
        appendString("  >>\n");
        appendString("startxref\n");
        appendString("565\n");
        appendString("%%EOF\n");
		return buffer;
	}
}
