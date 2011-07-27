module cairo.util;

mixin template CairoCountedClass(T, string prefix)
{
    protected:
        @property uint _count()
        {
            mixin("return " ~ prefix ~ "get_reference_count(this.nativePointer);");
        }

        void _reference()
        {
            mixin(prefix ~ "reference(this.nativePointer);");
        }

        void _dereference()
        {
            mixin(prefix ~ "destroy(this.nativePointer);");
        }
    
    public:
        T nativePointer;
        debug(RefCounted)
        {
            bool debugging;
        }
        
        void dispose()
        {
            debug(RefCounted)
            {
                if(this.debugging && this.nativePointer is null)
                    writeln(typeof(this).stringof,
                    "@", cast(void*)this, ": dispose() Already disposed");
            }
            if(this.nativePointer !is null)
            {
                debug(RefCounted)
                {
                    if(this.debugging)
                        writeln(typeof(this).stringof,
                        "@", cast(void*)this, ": dispose() Cairo reference count is: ",
                        this._count);
                }
                mixin(prefix ~ "destroy(this.nativePointer);");
                this.nativePointer = null;
            }
        }

        ~this()
        {
            debug(RefCounted)
            {
                if(this.debugging)
                    writeln(typeof(this).stringof,
                    "@", cast(void*)this, ": Destructor called");
            }
            dispose();
        }
}
