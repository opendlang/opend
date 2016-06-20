module pdfd.objectpool;

import pdfd.objects;

/// Generates identifier
class PDFObjectPool
{
    this()
    {
        _nullObject = new NullObject;
    }

    // Find a label for this object and register it in the list.
    // Returns wrapped object.
    IndirectObject toReference(PDFObject obj)
    {
        int* pId = obj in _idOfObjects;
        if (pId == null)
        {
            int id = generateNewObjectIdentifier();
            _idOfObjects[obj] = id;

            IndirectObject result = new IndirectObject(obj, id);
            _labelledObjects ~= result; // guaranteed contiguous        
            return result;
        }
        else
        {
            int id = *pId;
            assert(id != 0);
            return _labelledObjects[id-1];
        }
    }

    IndirectObject[] allIndirectObjects()
    {
        return _labelledObjects;
    }

    NullObject nullObject()
    {
        return _nullObject;
    }
    
private:

    /// The array of all labelled objects in the PDF
    /// Except object 0
    IndirectObject[] _labelledObjects;

    /// Mapping from object to ID
    int[PDFObject] _idOfObjects;

    /// A unique null object
    NullObject _nullObject;

    /// Next identifier to give
    int _nextObjectIdentifier = 1;

    int generateNewObjectIdentifier()
    {
        int result = _nextObjectIdentifier;
        _nextObjectIdentifier += 1;
        return result;
    }
    
}

   

    