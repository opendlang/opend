module util.signals;

/**
 * Signals and Slots are an implementation of the Observer Pattern.
 * Essentially, when a Signal is emitted, a list of connected Observers
 * (called slots) are called.
 *
 * There have been several D implementations of Signals and Slots.
 * This version makes use of several new features in D, which make
 * using it simpler and less error prone. In particular, it is no
 * longer necessary to instrument the slots.
 *
 * References:
 *      $(LINK2 http://scottcollins.net/articles/a-deeper-look-at-_signals-and-slots.html, A Deeper Look at Signals and Slots)$(BR)
 *      $(LINK2 http://en.wikipedia.org/wiki/Observer_pattern, Observer pattern)$(BR)
 *      $(LINK2 http://en.wikipedia.org/wiki/Signals_and_slots, Wikipedia)$(BR)
 *      $(LINK2 http://boost.org/doc/html/$(SIGNALS).html, Boost Signals)$(BR)
 *      $(LINK2 http://doc.trolltech.com/4.1/signalsandslots.html, Qt)$(BR)
 *
 *      There has been a great deal of discussion in the D newsgroups
 *      over this, and several implementations:
 *
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/announce/signal_slots_library_4825.html, signal slots library)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/Signals_and_Slots_in_D_42387.html, Signals and Slots in D)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/Dynamic_binding_--_Qt_s_Signals_and_Slots_vs_Objective-C_42260.html, Dynamic binding -- Qt's Signals and Slots vs Objective-C)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/Dissecting_the_SS_42377.html, Dissecting the SS)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/dwt/about_harmonia_454.html, about harmonia)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/announce/1502.html, Another event handling module)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/41825.html, Suggestion: signal/slot mechanism)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/13251.html, Signals and slots?)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/10714.html, Signals and slots ready for evaluation)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/1393.html, Signals &amp; Slots for Walter)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/28456.html, Signal/Slot mechanism?)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/19470.html, Modern Features?)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/16592.html, Delegates vs interfaces)$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/16583.html, The importance of component programming (properties, signals and slots, etc))$(BR)
 *      $(LINK2 http://www.digitalmars.com/d/archives/16368.html, signals and slots)$(BR)
 *
 * Bugs:
 *      Not safe for multiple threads operating on the same signals
 *      or slots.
 * 
 *      Safety of handlers is not yet enforced
 * Macros:
 *      WIKI = Phobos/StdSignals
 *      SIGNALS=signals
 *
 * Copyright: Copyright Digital Mars 2000 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   $(WEB digitalmars.com, Walter Bright), 
 *            Johannes Pfau
 */
/*          Copyright Digital Mars 2000 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
//~ module signals;

import std.algorithm; //find
import std.container; //SList
import std.functional; //toDelegate
import std.range; //take
import std.traits; //isPointer, isSafe

//Bug 4536
private template Init(T...)
{
    T Init;
}

template isHandlerDelegate(T, Types...)
{
    static if(is(T == delegate))
    {
        enum bool isHandlerDelegate = (is(typeof(T.init(Init!(Types))))
                            && (is(ReturnType!(T) == void)
                            || is(ReturnType!(T) == bool)));
    }
    else
    {
        enum bool isHandlerDelegate = false;
    }
}

template isHandlerFunction(T, Types...)
{
    static if(isPointer!(T))
    {
        enum bool isHandlerFunction = (isPointer!(T) && is(pointerTarget!(T) == function)
                            && is(typeof(T.init(Init!(Types))))
                            && (is(ReturnType!(T) == void)
                            || is(ReturnType!(T) == bool)));
    }
    else
    {
        enum bool isHandlerFunction = false;
    }
}

template isHandlerStruct(T, Types...)
{
    static if(isPointer!(T))
    {
        enum bool isHandlerStruct = (is(pointerTarget!(T) == struct)
                        //&& (isSafe!(pointerTarget!(T).init))
                        && is(typeof(pointerTarget!(T).init.opCall(Init!(Types))))
                        && (is(ReturnType!(T) == void)
                        || is(ReturnType!(T) == bool))); 
    }
    else
    {
        enum bool isHandlerStruct = false;
    }
}

unittest
{
    struct tmp
    {
        @safe bool opCall() {return false;}
    }
    tmp* a = new tmp();
    
    assert(isHandlerStruct!(typeof(a)));
    tmp b;
    assert(!isHandlerStruct!(typeof(b)));
}

//Checking for unsafe handlers is not yet implemented
/*
unittest
{
    struct tmp
    {
        bool opCall() {return false;}
    }
    tmp* a = new tmp();
    
    assert(!isHandlerStruct!(typeof(a)));
    tmp b;
    assert(!isHandlerStruct!(typeof(b)));
}
*/

template isHandlerClass(T, Types...)
{
    enum bool isHandlerClass = (is(T == class)
                        && is(typeof(T.init.opCall(Init!(Types))))
                        && (is(ReturnType!(T) == void)
                        || is(ReturnType!(T) == bool)));
}

template isHandler(T, Types...)
{
    enum bool isHandler = isHandlerDelegate!(T, Types) || isHandlerFunction!(T, Types)
        || isHandlerClass!(T, Types) || isHandlerStruct!(T, Types);
}

unittest
{
    struct tmp
    {
        @safe void opCall(){}
    }
    struct tmp2
    {
        @safe char opCall(){ return 'c';}
    }
    struct tmp3
    {
        @safe bool opCall(){ return true;}
    }
    tmp* a = new tmp();

    assert(isHandler!(typeof(a)));
    assert(!isHandler!(typeof(a), int));
    assert(!isHandler!(typeof(a), int, bool));
    assert(!isHandler!(typeof(a), int, bool, string));

    tmp b;
    assert(!isHandler!(typeof(b)));
    assert(!isHandler!(typeof(b), int));
    assert(!isHandler!(typeof(b), int, bool));
    assert(!isHandler!(typeof(b), int, bool, string));

    tmp2 c;
    assert(!isHandler!(typeof(c)));
    assert(!isHandler!(typeof(c), int));
    assert(!isHandler!(typeof(c), int, bool));
    assert(!isHandler!(typeof(c), int, bool, string));

    tmp3* d = new tmp3();
    assert(isHandler!(typeof(d)));
    assert(!isHandler!(typeof(d), int));
    assert(!isHandler!(typeof(d), int, bool));
    assert(!isHandler!(typeof(d), int, bool, string));
}

unittest
{
    class tmp
    {
        @safe void opCall(int i){}
    }
    class tmp2
    {
        @safe char opCall(string a, bool b){ return 'c';}
    }
    class tmp3
    {
        @safe bool opCall(char b){ return true;}
    }
    tmp a = new tmp();

    assert(!isHandler!(typeof(a)));
    assert(isHandler!(typeof(a), int));
    assert(!isHandler!(typeof(a), int, bool));
    assert(!isHandler!(typeof(a), int, bool, string));

    tmp2 b = new tmp2();
    assert(!isHandler!(typeof(b)));
    assert(!isHandler!(typeof(b), string, bool));
    assert(!isHandler!(typeof(b), int, bool));
    assert(!isHandler!(typeof(b), int, bool, string));

    tmp3 c = new tmp3();
    assert(!isHandler!(typeof(c)));
    assert(isHandler!(typeof(c), char));
    assert(!isHandler!(typeof(c), int, bool));
    assert(!isHandler!(typeof(c), int, bool, string));
}

unittest
{
    static @safe void test(int a, int b) {};
    static @safe void test2(int b) {};
    static @safe bool test3(int a, int b) {return true;};
    static @safe bool test4(int b) {return true;};
    assert(isHandler!(typeof(&test), int, int));
    assert(!isHandler!(typeof(&test)));
    assert(isHandler!(typeof(&test2), int));
    assert(!isHandler!(typeof(&test2, string)));
    assert(isHandler!(typeof(&test3), int, int));
    assert(!isHandler!(typeof(&test3), bool));
    assert(isHandler!(typeof(&test4), int));
    assert(!isHandler!(typeof(&test4)));
}

unittest
{
    @safe void test(int a, int b) {};
    @safe void test2(int b) {};
    @safe bool test3(int a, int b) {return true;};
    @safe bool test4(int b) {return true;};

    assert(isHandler!(typeof(&test), int, int));
    assert(!isHandler!(typeof(&test)));
    assert(isHandler!(typeof(&test2), int));
    assert(!isHandler!(typeof(&test2, string)));
    assert(isHandler!(typeof(&test3), int, int));
    assert(!isHandler!(typeof(&test3), bool));
    assert(isHandler!(typeof(&test4), int));
    assert(!isHandler!(typeof(&test4)));
}

/**
 * This Signal struct is an implementation of the Observer pattern.
 *
 * All D callable types (functions, delegates, structs with opCall,
 * classes with opCall) can be registered with a signal. When the signal
 * occurs all assigned callables are called.
 *
 * Structs with opCall are only supported if they're passed by pointer. These
 * structs are then expected to be allocated on the heap.
 *
 * Delegates to struct instances or nested functions are supported. You
 * have to make sure to disconnect these delegates from the Signal before
 * they go out of scope though.
 *
 * The return type of the handlers must be void or bool. If the return
 * type is bool and the handler returns false the remaining handlers are
 * not called. If true is returned or the type is void the remaining
 * handlers are called.
 * 
 * SafeD:
 * This Signal template can be used in safeD; all public functions
 * are @safe or @trusted. All handlers connected to
 * a signal must be @safe or @trusted. It's currently not possible to
 * enforce the safety of the handlers, but it will be enforced as soon
 * as possible.
 * 
 * Examples:
 * -------------------------------------------------------------------
 * import std.stdio;
 * import std.signals;
 *
 * //same for classes
 * struct A
 * {
 *     string payload;
 *     @safe bool opCall(float f, string s)
 *     {
 *         writefln("A: %f:%s:%s", f, s, payload);
 *         return true;
 *     }
 * }
 * 
 * @safe void testFunc(float f, string s)
 * {
 *      writefln("Function: %f:%s", f, s);
 * }
 *
 * Signal!(float, string) onTest;
 *
 * void main()
 * {
 *     A* a = new A();
 *     a.payload = "test payload";
 *     onTest.connect(a);
 *     onTest ~= &testFunc;
 *     onTest(0.123f, "first call");
 * }
 * -------------------------------------------------------------------
 */
public struct Signal(Types...)
{
    private:
        //A slot is implemented as a delegate. The slot_t is the type of the delegate.
        alias bool delegate(Types) slot_t;
        //Same as slot_t but with void return type
        alias void delegate(Types) void_slot_t;

        /* This struct stores one delegate and information whether the
         * delegate returns a bool or void */
        static struct Callable
        {
            //The void_slot_t delegate
            slot_t deleg;
            bool returnsBool = true;

            this(void_slot_t del)
            {
                this.deleg = cast(slot_t)del;
                this.returnsBool = false;
            }
            this(slot_t del)
            {
                this.deleg = del;
            }
        }
        
        SList!(Callable) handlers;

        /*
         * Get a Callable for the handler.
         * Handler can be a void function, void delegate, bool
         * function, bool delegate, class with opCall or a pointer to
         * a struct with opCall.
         */
        @trusted Callable getCallable(T)(T handler) if(isHandler!(T, Types))
        {
            static if(isHandlerDelegate!(T, Types) && is(ReturnType!(T) == void))
            {
                return Callable(cast(void_slot_t)handler);
            }
            else static if(isHandlerFunction!(T, Types) && is(ReturnType!(T) == void))
            {
                void delegate(Types) call = toDelegate(cast(void function(Types))handler);
                return Callable(call);
            }
            else static if(isHandlerDelegate!(T, Types) && is(ReturnType!(T) == bool))
            {
                return Callable(cast(slot_t)handler);
            }
            else static if(isHandlerFunction!(T, Types) && is(ReturnType!(T) == bool))
            {
                return Callable(toDelegate(cast(bool function(Types))handler));
            }
            else static if(isHandlerStruct!(T, Types))
            {
                static if(is(ReturnType!(T) == void))
                {
                    return Callable(cast(void_slot_t)&handler.opCall);
                }
                else static if(is(ReturnType!(T) == bool))
                {
                    return Callable(cast(slot_t)&handler.opCall);
                }
                else
                {
                    static assert(false, "BUG: Internal error");
                }
            }
            else static if(isHandlerClass!(T, Types))
            {
                static if(is(ReturnType!(T) == void))
                {
                    return Callable(cast(void_slot_t)&handler.opCall);
                }
                else static if(is(ReturnType!(T) == bool))
                {
                    return Callable(cast(slot_t)&handler.opCall);
                }
                else
                {
                    static assert(false, "BUG: Internal error");
                }
            }
            else
            {
                static assert(false, "BUG: Input type not supported. "
                    "Please file a bug report.");
            }
        }

    public:
        /**
         * Set to false to disable signal emission
         * 
         * Examples:
         * --------------------------------
         * bool called = false;
         * @safe void handler() { called = true; }
         * Signal!() onTest;
         * onTest ~= &handler;
         * onTest();
         * assert(called);
         * called = false;
         * onTest.enabled = false;
         * onTest();
         * assert(!called);
         * onTest.enabled = true;
         * onTest();
         * assert(called);
         * --------------------------------
         */
        @safe bool enabled = true;

        /**
         * Check whether a handler is already connected
         * 
         * Examples:
         * --------------------------------
         * @safe void handler() {};
         * Signal!() onTest;
         * assert(!onTest.isConnected(&handler));
         * onTest ~= &handler;
         * assert(onTest.isConnected(&handler));
         * onTest();
         * --------------------------------
         */
        @trusted bool isConnected(T)(T handler) if(isHandler!(T, Types))
        {
            Callable call = getCallable(handler);
            return !find(handlers[], call).empty;
        }

        /**
         * Add a handler to the list of handlers to be called when emit() is called.
         * The handler is added at the end of the list.
         * 
         * Throws:
         * Exception if handler is already registered
         * (Only if asserts are enabled! Does not throw
         * in release mode!)
         * 
         * Returns:
         * The handler that was passed in as a paramter
         * 
         * Examples:
         * --------------------------------
         * int val;
         * string text;
         * @safe void handler(int i, string t)
         * {
         *     val = i;
         *     text = t;
         * }
         * 
         * Signal!(int, string) onTest;
         * onTest.connect(&handler);
         * onTest(1, "test");
         * assert(val == 1);
         * assert(text == "test");
         * --------------------------------
         */
        @trusted T connect(T)(T handler) if(isHandler!(T, Types))
        {
            Callable call = getCallable(handler);
            assert(find(handlers[], call).empty, "Handler is already registered!");
            handlers.stableInsertAfter(handlers[], call);
            return handler;
        }

        /**
         * Add a handler to the list of handlers to be called when emit() is called.
         * Add this handler at the top of the list, so it will be called before all
         * other handlers.
         * 
         * Throws:
         * Exception if handler is already registered
         * (Only if asserts are enabled! Does not throw
         * in release mode!)
         * 
         * Returns:
         * The handler that was passed in as a paramter
         * 
         * --------------------------------
         * bool firstCalled, secondCalled;
         * @safe void handler1() {firstCalled = true;}
         * @safe void handler2()
         * {
         *     secondCalled = true;
         *     assert(firstCalled);
         * }
         * Signal!() onTest;
         * onTest ~= &handler2;
         * onTest.connectFirst(&handler1);
         * onTest();
         * assert(firstCalled && secondCalled);
         * --------------------------------
         */
        @trusted T connectFirst(T)(T handler) if(isHandler!(T, Types))
        {
            Callable call = getCallable(handler);
            assert(find(handlers[], call).empty, "Handler is already registered!");
            handlers.stableInsertFront(call);
            return handler;
        }

        /**
         * Add a handler to be called after another handler.
         * Params:
         *     afterThis = The new attached handler will be called after this handler
         *     handler = The handler to be attached
         * 
         * Throws:
         * Exception if handler is already registered
         * (Only if asserts are enabled! Does not throw
         * in release mode!)
         * 
         * Exception if afterThis is not registered
         * (Always, even if asserts are disabled)
         * 
         * Returns:
         * The handler that has been connected
         * 
         * Examples:
         * --------------------------------
         * bool firstCalled, secondCalled, thirdCalled;
         * @safe void handler1() {firstCalled = true;}
         * @safe void handler2()
         * {
         *     secondCalled = true;
         *     assert(firstCalled);
         *     assert(thirdCalled);
         * }
         * @safe void handler3()
         * {
         *     thirdCalled = true;
         *     assert(firstCalled);
         *     assert(!secondCalled);
         * }
         * Signal!() onTest;
         * onTest ~= &handler1;
         * onTest ~= &handler2;
         * auto h = onTest.connectAfter(&handler1, &handler3);
         * assert(h == &handler3);
         * onTest();
         * assert(firstCalled && secondCalled && thirdCalled);
         * --------------------------------
         */
        @trusted T connectAfter(T, U)(T afterThis, U handler)
            if(isHandler!(T, Types) && isHandler!(U, Types))
        {
            Callable after = getCallable(afterThis);
            Callable call = getCallable(handler);
            auto location = find(handlers[], after);
            if(location.empty)
            {
                 throw new Exception("Handler 'afterThis' is not registered!");
            }
            assert(find(handlers[], call).empty, "Handler is already registered!");
            handlers.stableInsertAfter(take(location, 1), call);
            return handler;
        }

        /**
         * Add a handler to be called before another handler.
         * Params:
         *     beforeThis = The new attached handler will be called after this handler
         *     handler = The handler to be attached
         * 
         * Throws:
         * Exception if handler is already registered
         * (Only if asserts are enabled! Does not throw
         * in release mode!)
         * 
         * Returns:
         * The handler that has been connected
         * 
         * Exception if beforeThis is not registered
         * (Always, even if asserts are disabled)
         * 
         * Examples:
         * --------------------------------
         * bool firstCalled, secondCalled, thirdCalled;
         * @safe void handler1() {firstCalled = true;}
         * @safe void handler2()
         * {
         *     secondCalled = true;
         *     assert(firstCalled);
         *     assert(!thirdCalled);
         * }
         * @safe void handler3()
         * {
         *     thirdCalled = true;
         *     assert(firstCalled);
         *     assert(secondCalled);
         * }
         * Signal!() onTest;
         * onTest ~= &handler1;
         * onTest ~= &handler3;
         * onTest.connectBefore(&handler3, &handler2);
         * onTest();
         * assert(firstCalled && secondCalled && thirdCalled);
         * --------------------------------
         */
        @trusted T connectBefore(T, U)(T beforeThis, U handler)
            if(isHandler!(T, Types) && isHandler!(U, Types))
        {
            Callable before = getCallable(beforeThis);
            Callable call = getCallable(handler);
            auto location = find(handlers[], before);
            if(location.empty)
            {
                 throw new Exception("Handler 'beforeThis' is not registered!");
            }
            assert(find(handlers[], call).empty, "Handler is already registered!");
            //not exactly fast
            uint length = walkLength(handlers[]);
            uint pos = walkLength(location);
            uint new_location = length - pos;
            location = handlers[];
            if(new_location == 0)
                handlers.stableInsertFront(call);
            else
                handlers.stableInsertAfter(take(location, new_location), call);
            return handler;
        }

        /**
         * Remove a handler from the list of handlers to be called when emit() is called.
         * 
         * Throws:
         * Exception if handler is not registered
         * (Always, even if asserts are disabled)
         * 
         * Returns:
         * The handler that has been disconnected
         * 
         * Examples:
         * --------------------------------
         * @safe void handler() {};
         * Signal!() onTest;
         * onTest.connect(&handler);
         * onTest.disconnect(&handler);
         * onTest.connect(&handler);
         * onTest();
         * --------------------------------
         */
        @trusted T disconnect(T)(T handler) if(isHandler!(T, Types))
        {
            Callable call = getCallable(handler);
            auto pos = find(handlers[], call);
            if(pos.empty)
            {
                throw new Exception("Handler is not connected");
            }
            handlers.stableLinearRemove(take(pos, 1));
            return handler;
        }

        /**
         * Remove all handlers from the signal
         * 
         * Examples:
         * --------------------------------
         * @safe void handler() {};
         * Signal!() onTest;
         * assert(onTest.calculateLength() == 0);
         * onTest.connect(&handler);
         * assert(onTest.calculateLength() == 1);
         * onTest.clear();
         * assert(onTest.calculateLength() == 0);
         * onTest();
         * --------------------------------
         */
        @trusted void clear()
        {
            handlers.clear();
        }

        /**
         * Calculate the number of registered handlers
         *
         * Complexity: $(BIGOH n)
         * 
         * Examples:
         * --------------------------------
         * @safe void handler() {};
         * @safe void handler2() {};
         * Signal!() onTest;
         * assert(onTest.calculateLength() == 0);
         * onTest.connect(&handler);
         * assert(onTest.calculateLength() == 1);
         * onTest.connect(&handler2);
         * assert(onTest.calculateLength() == 2);
         * onTest.clear();
         * assert(onTest.calculateLength() == 0);
         * onTest();
         * --------------------------------
         */
        @trusted uint calculateLength()
        {
            return walkLength(handlers[]);
        }

        /**
         * Just like Signal.connect()
         */
        @safe T opOpAssign(string op, T)(T rhs) if(op == "~" && isHandler!(T, Types))
        {
            return connect!(T)(rhs);
        }

        /**
         * Call the connected handlers as explained in the documentation
         * for the signal struct.
         * 
         * Throws:
         * Exceptions thrown in the signal handlers
         * 
         * Examples:
         * --------------------------------
         * @safe void handler() {};
         * Signal!() onTest;
         * onTest.connect(&handler);
         * onTest.emit();
         * --------------------------------
         */
        @trusted void emit(Types params)
        {
            if(this.enabled)
            {
                foreach(callable; handlers[])
                {
                    if(callable.returnsBool)
                    {
                        slot_t del = cast(slot_t)callable.deleg;
                        if(!del(params))
                            return;
                    }
                    else
                    {
                        void_slot_t del = cast(void_slot_t)callable.deleg;
                        del(params);
                    }
                }
            }
        }

        /**
         * Just like emit()
         */
        @trusted void opCall(Types params)
        {
            emit(params);
        }
}

//unit tests
unittest
{
    int val;
    string text;
    @safe void handler(int i, string t)
    {
        val = i;
        text = t;
    }
    @safe static void handler2(int i, string t)
    {
    }

    Signal!(int, string) onTest;
    onTest.connect(&handler);
    onTest.connect(&handler2);
    onTest(1, "test");
    assert(val == 1);
    assert(text == "test");
    onTest(99, "te");
    assert(val == 99);
    assert(text == "te");
}

unittest
{
    @safe void handler() {}
    Signal!() onTest;
    onTest.connect(&handler);
    bool thrown = false;
    try
        onTest.connect(&handler);
    catch(Throwable)
        thrown = true;

    assert(thrown);
}

unittest
{
    @safe void handler() {};
    Signal!() onTest;
    onTest.connect(&handler);
    onTest.disconnect(&handler);
    onTest.connect(&handler);
    onTest();
}

unittest
{
    bool called = false;
    @safe void handler() { called = true; };
    Signal!() onTest;
    onTest ~= &handler;
    onTest.disconnect(&handler);
    onTest ~= &handler;
    onTest();
    assert(called);
}

unittest
{
    class handler
    {
        @safe void opCall(int i) {}
    }
    
    struct handler2
    {
        @safe void opCall(int i) {}
    }
    Signal!(int) onTest;
    onTest ~= new handler;
    auto h = onTest ~= new handler2;
    onTest(0);
    onTest.disconnect(h);
}

unittest
{
    __gshared bool called = false;

    struct A
    {
        string payload;

        @trusted void opCall(float f, string s)
        {
            assert(payload == "payload");
            assert(f == 0.1234f);
            assert(s == "test call");
            called = true;
        }
    }

    A* a = new A();
    a.payload = "payload";

    Signal!(float, string) onTest;
    onTest.connect(a);
    onTest(0.1234f, "test call");
    assert(called);
}

unittest
{
    __gshared bool called;
    struct A
    {
        string payload;
        @trusted void opCall(float f, string s)
        {
            assert(payload == "payload 2");
            called = true;
        }
    }

    A* a = new A();
    a.payload = "payload";

    Signal!(float, string) onTest;
    onTest.connect(a);
    A* b = new A();
    b.payload = "payload 2";
    onTest.connect(b);
    onTest.disconnect(a);
    onTest(0.1234f, "test call");
    assert(called);
}

unittest
{
    struct A
    {
        @safe void opCall() {}
    }
    A* a = new A();

    Signal!() onTest;
    onTest.connect(a);
    bool thrown = false;
    try
        onTest.connect(a);
    catch(Throwable)
        thrown = true;

    assert(thrown);
}

unittest
{
    struct A
    {
        @safe void opCall() {}
    }
    A* a = new A();

    Signal!() onTest;
    onTest.connect(a);
    onTest.disconnect(a);
    bool thrown = false;
    try
        onTest.disconnect(a);
    catch(Throwable)
        thrown = true;

    assert(thrown);
}

unittest
{
    struct A
    {
        @safe void opCall() {}
    }
    A* a = new A();

    Signal!() onTest;
    bool thrown = false;
    try
        onTest.disconnect(a);
    catch(Throwable)
        thrown = true;

    assert(thrown);
}

unittest
{
    bool secondCalled = false;
    @safe bool first(int i) {return false;}
    @safe void second(int i) {secondCalled = true;}
    Signal!(int) onTest;
    onTest ~= &first;
    onTest ~= &second;
    onTest(0);
    assert(!secondCalled);
    onTest.disconnect(&first);
    onTest ~= &first;
    onTest(0);
    assert(secondCalled);
}

unittest
{
    @safe void second(int i) {}
    Signal!(int) onTest;
    auto t1 = onTest.getCallable(&second);
    auto t2 = onTest.getCallable(&second);
    auto t3 = onTest.getCallable(&second);
    assert(t1 == t2);
    assert(t2 == t3);
}

unittest
{
    bool called = false;
    @safe void handler() { called = true; };
    Signal!() onTest;
    onTest ~= &handler;
    onTest();
    assert(called);
    called = false;
    onTest.enabled = false;
    onTest();
    assert(!called);
    onTest.enabled = true;
    onTest();
    assert(called);
}

unittest
{
    @safe void handler() {};
    Signal!() onTest;
    assert(!onTest.isConnected(&handler));
    onTest ~= &handler;
    assert(onTest.isConnected(&handler));
    onTest();
    assert(onTest.isConnected(&handler));
    onTest.disconnect(&handler);
    assert(!onTest.isConnected(&handler));
    onTest();
    assert(!onTest.isConnected(&handler));
}

unittest
{
    bool firstCalled, secondCalled, thirdCalled;
    @safe void handler1() {firstCalled = true;}
    @safe void handler2()
    {
        secondCalled = true;
        assert(firstCalled);
        assert(thirdCalled);
    }
    @safe void handler3()
    {
        thirdCalled = true;
        assert(firstCalled);
        assert(!secondCalled);
    }
    Signal!() onTest;
    onTest ~= &handler1;
    onTest ~= &handler2;
    auto h = onTest.connectAfter(&handler1, &handler3);
    assert(h == &handler3);
    onTest();
    assert(firstCalled && secondCalled && thirdCalled);
}

unittest
{
    bool firstCalled, secondCalled;
    @safe void handler1() {firstCalled = true;}
    @safe void handler2()
    {
        secondCalled = true;
        assert(firstCalled);
    }
    Signal!() onTest;
    onTest ~= &handler2;
    onTest.connectFirst(&handler1);
    onTest();
    assert(firstCalled && secondCalled);
}

unittest
{
    bool firstCalled, secondCalled, thirdCalled;
    @safe void handler1() {firstCalled = true;}
    @safe void handler2()
    {
        secondCalled = true;
        assert(firstCalled);
        assert(!thirdCalled);
    }
    @safe void handler3()
    {
        thirdCalled = true;
        assert(firstCalled);
        assert(secondCalled);
    }
    Signal!() onTest;
    onTest ~= &handler2;
    auto h = onTest.connectAfter(&handler2, &handler3);
    assert(h == &handler3);
    auto h2 = onTest.connectBefore(&handler2, &handler1);
    assert(h2 == &handler1);
    onTest();
    assert(firstCalled && secondCalled && thirdCalled);
    firstCalled = secondCalled = thirdCalled = false;
    onTest.disconnect(h);
    onTest.disconnect(h2);
    onTest.disconnect(&handler2);
    onTest ~= &handler1;
    onTest ~= &handler3;
    onTest.connectBefore(&handler3, &handler2);
    onTest();
    assert(firstCalled && secondCalled && thirdCalled);
}

unittest
{
    @safe void handler() {};
    Signal!() onTest;
    assert(onTest.calculateLength() == 0);
    onTest.connect(&handler);
    assert(onTest.calculateLength() == 1);
    onTest.clear();
    assert(onTest.calculateLength() == 0);
    onTest();
}
