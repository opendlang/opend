/**
 * License:
 * $(BOOKTABLE ,
 *   $(TR $(TD cairoD wrapper/bindings)
 *     $(TD $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)))
 *   $(TR $(TD $(LINK2 http://cgit.freedesktop.org/cairo/tree/COPYING, _cairo))
 *     $(TD $(LINK2 http://cgit.freedesktop.org/cairo/tree/COPYING-LGPL-2.1, LGPL 2.1) /
 *     $(LINK2 http://cgit.freedesktop.org/cairo/plain/COPYING-MPL-1.1, MPL 1.1)))
 * )
 * Authors:
 * $(BOOKTABLE ,
 *   $(TR $(TD Johannes Pfau) $(TD cairoD))
 *   $(TR $(TD $(LINK2 http://cairographics.org, _cairo team)) $(TD _cairo))
 * )
 */
/*
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
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
