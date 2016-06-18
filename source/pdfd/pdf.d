module pdfd.pdf;

import std.string;
import std.typecons;

import pdfd.objects;

///
class PDF
{
public:

    this()
    {
        _nullObject = new NullObject();
    }

    ubyte[] toBytes()
    {
        auto output = scoped!PDFSerializer();

        // header
        output.put("%PDF-1.1\n");

        // "If a PDF file contains binary data, as most do (see 7.2, "Lexical Conventions"), 
        // the header line shall be immediately followed by a comment line containing at least 
        // four binary characters—that is, characters whose codes are 128 or greater.
        // This ensures proper behaviour of file transfer applications that inspect data near 
        // the beginning of a file to determine whether to treat the file’s contents as text or as binary."
        output.put("%¥±ë\n");

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
                output.put(format("%010zu 00000d n \n",  offsetsOfIndirectObjects[i]));
                obj.toBytesDirect(output);
            }
        }

        output.put("trailer\n");
        {
            auto trailer = scoped!DictionaryObject();
            trailer.add(nameObject("Root"), _nullObject);
            trailer.add(nameObject("Size"), new NumericObject(labelledObjects.length+1));
            trailer.toBytes(output);
            output.put("\n");
        }

        output.put("startxref\n");
        output.put(format("%s\n", offsetOfLastXref));
        output.put("%%EOF\n");
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


    NameObject[string] nameObjectsCache;

    // Return an existing name object or a cached one
    NameObject nameObject(string name)
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

    NullObject _nullObject;
}
