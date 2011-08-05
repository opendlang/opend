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

/**
 * Mixin used by cairoD classes which wrap a reference counted
 * cairo handle.
 */
mixin template CairoCountedClass(T, string prefix)
{
    protected:
        /**
         * Reference count. For use in child classes
         */
        @property uint _count()
        {
            mixin("return " ~ prefix ~ "get_reference_count(this.nativePointer);");
        }

        /**
         * Increase reference count. For use in child classes
         */
        void _reference()
        {
            mixin(prefix ~ "reference(this.nativePointer);");
        }

        /**
         * Decrease reference count. For use in child classes
         */
        void _dereference()
        {
            mixin(prefix ~ "destroy(this.nativePointer);");
        }
    
    public:
        /**
         * The underlying $(T) handle
         */
        T nativePointer;
        version(D_Ddoc)
        {
            /**
             * Enable / disable memory management debugging for this
             * instance. Only available if both cairoD and the cairoD user
             * code were compiled with "debug=RefCounted"
             *
             * Output is written to stdout, see 
             * $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#debugging)
             * for more information
             */
            bool debugging;
        }
        else debug(RefCounted)
        {
            bool debugging;
        }

        /**
         * Explicitly drecrease the reference count.
         *
         * See $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#3-RC-class)
         * for more information.
         */
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

        /**
         * Destructor. Call $(D dispose()) if it hasn't been called manually.
         */
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
