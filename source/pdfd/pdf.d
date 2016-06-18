module pdfd.pdf;

import std.string;

import pdfd.objects;

///
class PDF
{
public:

    ubyte[] toBytes()
    {
        auto output = new PDFSerializer();

        output.put("%PDF-1.1\n");

        // "If a PDF file contains binary data, as most do (see 7.2, "Lexical Conventions"), 
        // the header line shall be immediately followed by a comment line containing at least 
        // four binary characters—that is, characters whose codes are 128 or greater.
        // This ensures proper behaviour of file transfer applications that inspect data near 
        // the beginning of a file to determine whether to treat the file’s contents as text or as binary."
        output.put("%¥±ë\n");

        size_t[] offsetsOfIndirectObjects = new size_t[labelledObjects.length];

        // put all labelled objects in there
        foreach(size_t i, obj; labelledObjects)
        {
            offsetsOfIndirectObjects[i] = output.currentOffset();
            obj.toBytesDirect(output);
        }

        // generate the xref table
        size_t offsetOfLastXref = output.currentOffset();
        output.put("xref\n");

        output.put(format("0 %s\n", labelledObjects.length));
        
        // special object 0, head of the freelist of objects
        output.put("0000000000 65535 f \n");

        // writes all labelled objects
        foreach(size_t i, obj; labelledObjects)
        {    
            assert(obj.generation == 0);
            // Writing offset to object (i+1), not (i)
            output.put(format("%010zu 00000d n \n",  offsetsOfIndirectObjects[i]));
            obj.toBytesDirect(output);
        }


/*
        appendString("trailer\n");
        appendString("  <<  /Root 1 0 R\n");
        appendString("      /Size 5\n");
        appendString("  >>\n");
        appendString("startxref\n");
        appendString("565\n");
        appendString("%%EOF\n");*/

        return output.buffer;
    }


private:

    /// The array of all labelled objects in the PDF
    IndirectObject[] labelledObjects;


    int generateNewObjectIdentifier()
    {
        int result = _nextObjectIdentifier;
        _nextObjectIdentifier += 1;
        return result;
    }

    int _nextObjectIdentifier = 1;
}
