module pdfd.pdf;

import std.string;
import std.typecons;

import pdfd.objects;
import pdfd.objectpool;

///
class PDF
{
public:



    this(int pageWidthMm, int pageHeightMm)
    {
        _pool = new PDFObjectPool();

        _pagesArray = new ArrayObject(); // empty at first

        _pages = new DictionaryObject;
        _pages.add(name("Type"), name("Pages"));
        _pages.add(name("Kids"), _pagesArray);
        _pages.add(name("MediaBox"), new ArrayObject([number(0), number(0), number(pageWidthMm), number(pageHeightMm)]));

        _catalog = new DictionaryObject;
        _catalog.add(name("Type"), name("Catalog"));
        _catalog.add(name("Pages"), toRef(_pages));
        
        // register
        toRef(_catalog);
/+

        1 0 obj
            << /Type /Catalog
            /Pages 2 0 R
            >>
            endobj

            2 0 obj
            << /Type /Pages
            /Kids [3 0 R]
            /Count 1
            /MediaBox [0 0 300 144]
            >>
            endobj

            3 0 obj
            <<  /Type /Page
            /Parent 2 0 R
            /Resources
            << /Font
            << /F1
            << /Type /Font
            /Subtype /Type1
            /BaseFont /Times-Roman
            >>
            >>
            >>
            /Contents 4 0 R
            >>
            endobj+/
    }


    void newPage()
    {        
        _lastPage = new DictionaryObject;
        _lastPage.add(name("Type"), name("Page"));
        _lastPage.add(name("Parent"), toRef(_pages));

        _pagesArray.add(toRef(_lastPage));
    }

    ubyte[] toBytes()
    {
        auto output = scoped!PDFSerializer();

        _pages.add(name("Count"), number(cast(double)(_pagesArray.items.length)));

        // header
        output.put("%PDF-1.1\n");

        // "If a PDF file contains binary data, as most do (see 7.2, "Lexical Conventions"), 
        // the header line shall be immediately followed by a comment line containing at least 
        // four binary characters—that is, characters whose codes are 128 or greater.
        // This ensures proper behaviour of file transfer applications that inspect data near 
        // the beginning of a file to determine whether to treat the file’s contents as text or as binary."
        output.put("%¥±ë\n");

        auto labelledObjects = _pool.allIndirectObjects();

        size_t[] offsetsOfIndirectObjects = new size_t[labelledObjects.length];

        // put all labelled objects in there, keep their offset
        foreach(size_t i, obj; labelledObjects)
        {
            offsetsOfIndirectObjects[i] = output.currentOffset();
            obj.toBytesDirect(output);
        }

        // generate the xref table
        size_t offsetOfLastXref = output.currentOffset();
        {
            output.put("xref\n");
            output.put(format("0 %s\n", labelledObjects.length));
        
            // special object 0, head of the freelist of objects
            output.put("0000000000 65535 f \n");

            // writes all labelled objects
            foreach(size_t i, obj; labelledObjects)
            {
                assert(obj.generation == 0);
                // Writing offset to object (i+1), not (i)
                output.put(format("%010s 000000 n \n",  offsetsOfIndirectObjects[i]));
             //   obj.toBytesDirect(output);
            }
        }

        output.put("trailer\n");
        {
            auto trailer = scoped!DictionaryObject();
            trailer.add(name("Root"), toRef(_catalog));
            trailer.add(name("Size"), number(labelledObjects.length+1));
            trailer.toBytes(output);
            output.put("\n");
        }

        output.put("startxref\n");

        output.put(format("%s\n", offsetOfLastXref));
        output.put("%%EOF\n");
        return output.buffer;
    }


private:

    PDFObjectPool _pool;

    ArrayObject _pagesArray;

    DictionaryObject _catalog;

    DictionaryObject _lastPage = null;

    DictionaryObject _pages;

    IndirectObject toRef(PDFObject obj)
    {
        return _pool.toReference(obj);
    }

    // Return an existing name object or a cached one
    NameObject name(string name)
    {
        NameObject* obj = name in nameObjectsCache;
        if (obj)
            return *obj;
        else
        {
            auto nameObj = new NameObject(name);
            nameObjectsCache[name] = nameObj;
            return nameObj;
        }
    }

    NumericObject number(double value)
    {
        return new NumericObject(value);
    }

    NameObject[string] nameObjectsCache;
}
