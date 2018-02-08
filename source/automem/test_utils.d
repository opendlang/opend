module automem.test_utils;

mixin template TestUtils() {
    version(unittest) {
        import unit_threaded;
        import test_allocator;

        /**
           Returns an object that, while in scope, replaces whatever
           theAllocator was with TestAllocator.
         */
        auto theTestAllocator() {
            static struct Context {
                import std.experimental.allocator: theAllocator;

                TestAllocator testAllocator;
                typeof(theAllocator) oldAllocator;

                static auto create() {
                    import std.experimental.allocator: allocatorObject;

                    Context ctx;

                    ctx.oldAllocator = theAllocator;
                    theAllocator = allocatorObject(ctx.testAllocator);

                    return ctx;
                }

                ~this() {
                    import std.experimental.allocator: dispose;

                    // 2.079.0 changed the API - we check here
                    static if(__traits(compiles, testAllocator.dispose(theAllocator)))
                        testAllocator.dispose(theAllocator);

                    theAllocator = oldAllocator;
                }
            }

            return Context.create;
        }

        @Setup
        void before() {
        }

        @Shutdown
        void after() {
            reset;
        }

        void reset() {
            Struct.numStructs = 0;
            Class.numClasses = 0;
            SharedStruct.numStructs = 0;
            NoGcStruct.numStructs = 0;
        }


        void _writelnUt(T...)(T args) {
            try {
                () @trusted { writelnUt(args); }();
            } catch(Exception ex) {
                assert(false);
            }
        }

        private struct Struct {
            int i;
            static int numStructs = 0;

            this(int i) @safe nothrow {
                this.i = i;

                ++numStructs;
                _writelnUt("Struct ", &this, " normal   ctor, i=", i, ", N=", numStructs);
            }

            this(this) @safe nothrow {
                ++numStructs;
                _writelnUt("Struct ", &this, " postBlit ctor, i=", i, ", N=", numStructs);
            }

            ~this() @safe nothrow const {
                --numStructs;
                _writelnUt("Struct ", &this, "          dtor, i=", i, ", N=", numStructs);
            }

            int twice() @safe pure const nothrow {
                return i * 2;
            }
        }

        private struct SharedStruct {
            int i;
            static int numStructs = 0;

            this(int i) @safe nothrow shared {
                this.i = i;

                ++numStructs;
                try () @trusted {
                        _writelnUt("Struct normal ctor ", &this, ", i=", i, ", N=", numStructs);
                    }();
                catch(Exception ex) {}
            }

            this(this) @safe nothrow shared {
                ++numStructs;
                try () @trusted {
                        _writelnUt("Struct postBlit ctor ", &this, ", i=", i, ", N=", numStructs);
                    }();
                catch(Exception ex) {}
            }

            ~this() @safe nothrow shared {
                --numStructs;
                try () @trusted { _writelnUt("Struct dtor ", &this, ", i=", i, ", N=", numStructs); }();
                catch(Exception ex) {}
            }

            int twice() @safe pure const nothrow shared {
                return i * 2;
            }
        }

        private class Class {
            int i;
            static int numClasses = 0;

            this(int i) @safe nothrow {
                this.i = i;
                ++numClasses;
            }

            ~this() @safe nothrow {
                --numClasses;
            }

            int twice() @safe pure const nothrow {
                return i * 2;
            }
        }

        private struct SafeAllocator {

            import std.experimental.allocator.mallocator: Mallocator;

            void[] allocate(this T)(size_t i) @trusted nothrow @nogc {
                return Mallocator.instance.allocate(i);
            }

            void deallocate(this T)(void[] bytes) @trusted nothrow @nogc {
                Mallocator.instance.deallocate(bytes);
            }
        }

        private struct NoGcStruct {
            int i;

            static int numStructs = 0;

            this(int i) @safe @nogc nothrow {
                this.i = i;

                ++numStructs;
            }

            this(this) @safe @nogc nothrow {
                ++numStructs;
            }

            ~this() @safe @nogc nothrow {
                --numStructs;
            }

        }

        private class NoGcClass {
            int i;
            static int numClasses = 0;

            this(int i) @safe @nogc nothrow {
                this.i = i;
                ++numClasses;
            }

            ~this() @safe @nogc nothrow {
                --numClasses;
            }
        }
    }
}
