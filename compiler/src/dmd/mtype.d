/**
 * Defines a D type.
 *
 * Copyright:   Copyright (C) 1999-2024 by The D Language Foundation, All Rights Reserved
 * Authors:     $(LINK2 https://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/src/dmd/mtype.d, _mtype.d)
 * Documentation:  https://dlang.org/phobos/dmd_mtype.html
 * Coverage:    https://codecov.io/gh/dlang/dmd/src/master/src/dmd/mtype.d
 */

module dmd.mtype;

import core.checkedint;
import core.stdc.stdarg;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

import dmd.aggregate;
import dmd.attrib;
import dmd.arraytypes;
import dmd.astenums;
import dmd.ast_node;
import dmd.gluelayer;
import dmd.dclass;
import dmd.dcast;
import dmd.declaration;
import dmd.denum;
import dmd.dmangle;
import dmd.dscope;
import dmd.dstruct;
import dmd.dsymbol;
import dmd.dsymbolsem;
import dmd.dtemplate;
import dmd.errors;
import dmd.expression;
import dmd.func;
import dmd.globals;
import dmd.hdrgen;
import dmd.id;
import dmd.identifier;
import dmd.init;
import dmd.location;
import dmd.opover;
import dmd.root.ctfloat;
import dmd.common.outbuffer;
import dmd.root.rmem;
import dmd.rootobject;
import dmd.root.stringtable;
import dmd.target;
import dmd.tokens;
import dmd.typesem;
import dmd.visitor;

enum LOGDOTEXP = 0;         // log ::dotExp()
enum LOGDEFAULTINIT = 0;    // log ::defaultInit()

enum SIZE_INVALID = (~cast(uinteger_t)0);   // error return from size() functions


/***************************
 * Return !=0 if modfrom can be implicitly converted to modto
 */
bool MODimplicitConv(MOD modfrom, MOD modto) pure nothrow @nogc @safe
{
    if (modfrom == modto)
        return true;

    //printf("MODimplicitConv(from = %x, to = %x)\n", modfrom, modto);
    auto X(T, U)(T m, U n)
    {
        return ((m << 4) | n);
    }

    switch (X(modfrom & ~MODFlags.shared_, modto & ~MODFlags.shared_))
    {
    case X(0, MODFlags.const_):
    case X(MODFlags.wild, MODFlags.const_):
    case X(MODFlags.wild, MODFlags.wildconst):
    case X(MODFlags.wildconst, MODFlags.const_):
        return (modfrom & MODFlags.shared_) == (modto & MODFlags.shared_);

    case X(MODFlags.immutable_, MODFlags.const_):
    case X(MODFlags.immutable_, MODFlags.wildconst):
        return true;
    default:
        return false;
    }
}

/***************************
 * Return MATCH.exact or MATCH.constant if a method of type '() modfrom' can call a method of type '() modto'.
 */
MATCH MODmethodConv(MOD modfrom, MOD modto) pure nothrow @nogc @safe
{
    if (modfrom == modto)
        return MATCH.exact;
    if (MODimplicitConv(modfrom, modto))
        return MATCH.constant;

    auto X(T, U)(T m, U n)
    {
        return ((m << 4) | n);
    }

    switch (X(modfrom, modto))
    {
    case X(0, MODFlags.wild):
    case X(MODFlags.immutable_, MODFlags.wild):
    case X(MODFlags.const_, MODFlags.wild):
    case X(MODFlags.wildconst, MODFlags.wild):
    case X(MODFlags.shared_, MODFlags.shared_ | MODFlags.wild):
    case X(MODFlags.shared_ | MODFlags.immutable_, MODFlags.shared_ | MODFlags.wild):
    case X(MODFlags.shared_ | MODFlags.const_, MODFlags.shared_ | MODFlags.wild):
    case X(MODFlags.shared_ | MODFlags.wildconst, MODFlags.shared_ | MODFlags.wild):
        return MATCH.constant;

    default:
        return MATCH.nomatch;
    }
}

/***************************
 * Merge mod bits to form common mod.
 */
MOD MODmerge(MOD mod1, MOD mod2) pure nothrow @nogc @safe
{
    if (mod1 == mod2)
        return mod1;

    //printf("MODmerge(1 = %x, 2 = %x)\n", mod1, mod2);
    MOD result = 0;
    if ((mod1 | mod2) & MODFlags.shared_)
    {
        // If either type is shared, the result will be shared
        result |= MODFlags.shared_;
        mod1 &= ~MODFlags.shared_;
        mod2 &= ~MODFlags.shared_;
    }
    if (mod1 == 0 || mod1 == MODFlags.mutable || mod1 == MODFlags.const_ || mod2 == 0 || mod2 == MODFlags.mutable || mod2 == MODFlags.const_)
    {
        // If either type is mutable or const, the result will be const.
        result |= MODFlags.const_;
    }
    else
    {
        // MODFlags.immutable_ vs MODFlags.wild
        // MODFlags.immutable_ vs MODFlags.wildconst
        //      MODFlags.wild vs MODFlags.wildconst
        assert(mod1 & MODFlags.wild || mod2 & MODFlags.wild);
        result |= MODFlags.wildconst;
    }
    return result;
}

/*********************************
 * Store modifier name into buf.
 */
void MODtoBuffer(ref OutBuffer buf, MOD mod) nothrow @safe
{
    buf.writestring(MODtoString(mod));
}

/*********************************
 * Returns:
 *   a human readable representation of `mod`,
 *   which is the token `mod` corresponds to
 */
const(char)* MODtoChars(MOD mod) nothrow pure
{
    /// Works because we return a literal
    return MODtoString(mod).ptr;
}

/// Ditto
string MODtoString(MOD mod) nothrow pure @safe
{
    final switch (mod)
    {
    case 0:
        return "";

    case MODFlags.immutable_:
        return "immutable";

    case MODFlags.shared_:
        return "shared";

    case MODFlags.shared_ | MODFlags.const_:
        return "shared const";

    case MODFlags.const_:
        return "const";

    case MODFlags.shared_ | MODFlags.wild:
        return "shared inout";

    case MODFlags.wild:
        return "inout";

    case MODFlags.shared_ | MODFlags.wildconst:
        return "shared inout const";

    case MODFlags.wildconst:
        return "inout const";
    }
}

/*************************************************
 * Pick off one of the trust flags from trust,
 * and return a string representation of it.
 */
string trustToString(TRUST trust) pure nothrow @nogc @safe
{
    final switch (trust)
    {
    case TRUST.default_:
        return null;
    case TRUST.system:
        return "@system";
    case TRUST.trusted:
        return "@trusted";
    case TRUST.safe:
        return "@safe";
    }
}

unittest
{
    assert(trustToString(TRUST.default_) == "");
    assert(trustToString(TRUST.system) == "@system");
    assert(trustToString(TRUST.trusted) == "@trusted");
    assert(trustToString(TRUST.safe) == "@safe");
}

/************************************
 * Convert MODxxxx to STCxxx
 */
StorageClass ModToStc(uint mod) pure nothrow @nogc @safe
{
    StorageClass stc = 0;
    if (mod & MODFlags.immutable_)
        stc |= STC.immutable_;
    if (mod & MODFlags.const_)
        stc |= STC.const_;
    if (mod & MODFlags.wild)
        stc |= STC.wild;
    if (mod & MODFlags.shared_)
        stc |= STC.shared_;
    return stc;
}

///Returns true if ty is char, wchar, or dchar
bool isSomeChar(TY ty) pure nothrow @nogc @safe
{
    return ty == Tchar || ty == Twchar || ty == Tdchar;
}

/************************************
 * Determine mutability of indirections in (ref) t.
 *
 * Returns: When the type has any mutable indirections, returns 0.
 * When all indirections are immutable, returns 2.
 * Otherwise, when the type has const/inout indirections, returns 1.
 *
 * Params:
 *      isref = if true, check `ref t`; otherwise, check just `t`
 *      t = the type that is being checked
 */
int mutabilityOfType(bool isref, Type t)
{
    if (isref)
    {
        if (t.mod & MODFlags.immutable_)
            return 2;
        if (t.mod & (MODFlags.const_ | MODFlags.wild))
            return 1;
        return 0;
    }

    t = t.baseElemOf();

    if (!t.hasPointers() || t.mod & MODFlags.immutable_)
        return 2;

    /* Accept immutable(T)[] and immutable(T)* as being strongly pure
     */
    if (t.ty == Tarray || t.ty == Tpointer)
    {
        Type tn = t.nextOf().toBasetype();
        if (tn.mod & MODFlags.immutable_)
            return 2;
        if (tn.mod & (MODFlags.const_ | MODFlags.wild))
            return 1;
    }

    /* The rest of this is too strict; fix later.
     * For example, the only pointer members of a struct may be immutable,
     * which would maintain strong purity.
     * (Just like for dynamic arrays and pointers above.)
     */
    if (t.mod & (MODFlags.const_ | MODFlags.wild))
        return 1;

    /* Should catch delegates and function pointers, and fold in their purity
     */
    return 0;
}

/****************
 * dotExp() bit flags
 */
enum DotExpFlag
{
    none    = 0,
    gag     = 1,    // don't report "not a property" error and just return null
    noDeref = 2,    // the use of the expression will not attempt a dereference
    noAliasThis = 4, // don't do 'alias this' resolution
}

/// Result of a check whether two types are covariant
enum Covariant
{
    distinct = 0, /// types are distinct
    yes = 1, /// types are covariant
    no = 2, /// arguments match as far as overloading goes, but types are not covariant
    fwdref = 3, /// cannot determine covariance because of forward references
}

/***********************************************************
 */
extern (C++) abstract class Type : ASTNode
{
    TY ty;
    MOD mod; // modifiers MODxxxx
    char* deco;

    static struct Mcache
    {
        /* These are cached values that are lazily evaluated by constOf(), immutableOf(), etc.
         * They should not be referenced by anybody but mtype.d.
         * They can be null if not lazily evaluated yet.
         * Note that there is no "shared immutable", because that is just immutable
         * The point of this is to reduce the size of each Type instance as
         * we bank on the idea that usually only one of variants exist.
         * It will also speed up code because these are rarely referenced and
         * so need not be in the cache.
         */
        Type cto;       // MODFlags.const_
        Type ito;       // MODFlags.immutable_
        Type sto;       // MODFlags.shared_
        Type scto;      // MODFlags.shared_ | MODFlags.const_
        Type wto;       // MODFlags.wild
        Type wcto;      // MODFlags.wildconst
        Type swto;      // MODFlags.shared_ | MODFlags.wild
        Type swcto;     // MODFlags.shared_ | MODFlags.wildconst
    }
    private Mcache* mcache;

    Type pto;       // merged pointer to this type
    Type rto;       // reference to this type
    Type arrayof;   // array of this type

    TypeInfoDeclaration vtinfo;     // TypeInfo object for this Type

    type* ctype;                    // for back end

    extern (C++) __gshared Type tvoid;
    extern (C++) __gshared Type tint8;
    extern (C++) __gshared Type tuns8;
    extern (C++) __gshared Type tint16;
    extern (C++) __gshared Type tuns16;
    extern (C++) __gshared Type tint32;
    extern (C++) __gshared Type tuns32;
    extern (C++) __gshared Type tint64;
    extern (C++) __gshared Type tuns64;
    extern (C++) __gshared Type tint128;
    extern (C++) __gshared Type tuns128;
    extern (C++) __gshared Type tfloat32;
    extern (C++) __gshared Type tfloat64;
    extern (C++) __gshared Type tfloat80;
    extern (C++) __gshared Type timaginary32;
    extern (C++) __gshared Type timaginary64;
    extern (C++) __gshared Type timaginary80;
    extern (C++) __gshared Type tcomplex32;
    extern (C++) __gshared Type tcomplex64;
    extern (C++) __gshared Type tcomplex80;
    extern (C++) __gshared Type tbool;
    extern (C++) __gshared Type tchar;
    extern (C++) __gshared Type twchar;
    extern (C++) __gshared Type tdchar;

    // Some special types
    extern (C++) __gshared Type tshiftcnt;
    extern (C++) __gshared Type tvoidptr;    // void*
    extern (C++) __gshared Type tstring;     // immutable(char)[]
    extern (C++) __gshared Type twstring;    // immutable(wchar)[]
    extern (C++) __gshared Type tdstring;    // immutable(dchar)[]
    extern (C++) __gshared Type terror;      // for error recovery
    extern (C++) __gshared Type tnull;       // for null type
    extern (C++) __gshared Type tnoreturn;   // for bottom type typeof(*null)

    extern (C++) __gshared Type tsize_t;     // matches size_t alias
    extern (C++) __gshared Type tptrdiff_t;  // matches ptrdiff_t alias
    extern (C++) __gshared Type thash_t;     // matches hash_t alias

    extern (C++) __gshared ClassDeclaration dtypeinfo;
    extern (C++) __gshared ClassDeclaration typeinfoclass;
    extern (C++) __gshared ClassDeclaration typeinfointerface;
    extern (C++) __gshared ClassDeclaration typeinfostruct;
    extern (C++) __gshared ClassDeclaration typeinfopointer;
    extern (C++) __gshared ClassDeclaration typeinfoarray;
    extern (C++) __gshared ClassDeclaration typeinfostaticarray;
    extern (C++) __gshared ClassDeclaration typeinfoassociativearray;
    extern (C++) __gshared ClassDeclaration typeinfovector;
    extern (C++) __gshared ClassDeclaration typeinfoenum;
    extern (C++) __gshared ClassDeclaration typeinfofunction;
    extern (C++) __gshared ClassDeclaration typeinfodelegate;
    extern (C++) __gshared ClassDeclaration typeinfotypelist;
    extern (C++) __gshared ClassDeclaration typeinfoconst;
    extern (C++) __gshared ClassDeclaration typeinfoinvariant;
    extern (C++) __gshared ClassDeclaration typeinfoshared;
    extern (C++) __gshared ClassDeclaration typeinfowild;

    extern (C++) __gshared TemplateDeclaration rtinfo;
version (IN_LLVM)
{
    extern (C++) __gshared TemplateDeclaration rtinfoImpl;
}

    extern (C++) __gshared Type[TMAX] basic;

    extern (D) __gshared StringTable!Type stringtable;
    extern (D) private static immutable ubyte[TMAX] sizeTy = ()
        {
            ubyte[TMAX] sizeTy = __traits(classInstanceSize, TypeBasic);
            sizeTy[Tsarray] = __traits(classInstanceSize, TypeSArray);
            sizeTy[Tarray] = __traits(classInstanceSize, TypeDArray);
            sizeTy[Taarray] = __traits(classInstanceSize, TypeAArray);
            sizeTy[Tpointer] = __traits(classInstanceSize, TypePointer);
            sizeTy[Treference] = __traits(classInstanceSize, TypeReference);
            sizeTy[Tfunction] = __traits(classInstanceSize, TypeFunction);
            sizeTy[Tdelegate] = __traits(classInstanceSize, TypeDelegate);
            sizeTy[Tident] = __traits(classInstanceSize, TypeIdentifier);
            sizeTy[Tinstance] = __traits(classInstanceSize, TypeInstance);
            sizeTy[Ttypeof] = __traits(classInstanceSize, TypeTypeof);
            sizeTy[Tenum] = __traits(classInstanceSize, TypeEnum);
            sizeTy[Tstruct] = __traits(classInstanceSize, TypeStruct);
            sizeTy[Tclass] = __traits(classInstanceSize, TypeClass);
            sizeTy[Ttuple] = __traits(classInstanceSize, TypeTuple);
            sizeTy[Tslice] = __traits(classInstanceSize, TypeSlice);
            sizeTy[Treturn] = __traits(classInstanceSize, TypeReturn);
            sizeTy[Terror] = __traits(classInstanceSize, TypeError);
            sizeTy[Tnull] = __traits(classInstanceSize, TypeNull);
            sizeTy[Tvector] = __traits(classInstanceSize, TypeVector);
            sizeTy[Ttraits] = __traits(classInstanceSize, TypeTraits);
            sizeTy[Tmixin] = __traits(classInstanceSize, TypeMixin);
            sizeTy[Tnoreturn] = __traits(classInstanceSize, TypeNoreturn);
            sizeTy[Ttag] = __traits(classInstanceSize, TypeTag);
            return sizeTy;
        }();

    final extern (D) this(TY ty) scope @safe
    {
        this.ty = ty;
    }

    const(char)* kind() const nothrow pure @nogc @safe
    {
        assert(false); // should be overridden
    }

    final Type copy() nothrow const
    {
        Type t = cast(Type)mem.xmalloc(sizeTy[ty]);
        memcpy(cast(void*)t, cast(void*)this, sizeTy[ty]);
        return t;
    }

    Type syntaxCopy()
    {
        fprintf(stderr, "this = %s, ty = %d\n", toChars(), ty);
        assert(0);
    }

    override bool equals(const RootObject o) const
    {
        Type t = cast(Type)o;
        //printf("Type::equals(%s, %s)\n", toChars(), t.toChars());
        // deco strings are unique
        // and semantic() has been run
        if (this == o || ((t && deco == t.deco) && deco !is null))
        {
            //printf("deco = '%s', t.deco = '%s'\n", deco, t.deco);
            return true;
        }
        //if (deco && t && t.deco) printf("deco = '%s', t.deco = '%s'\n", deco, t.deco);
        return false;
    }

    final bool equivalent(Type t)
    {
        return immutableOf().equals(t.immutableOf());
    }

    // kludge for template.isType()
    override final DYNCAST dyncast() const
    {
        return DYNCAST.type;
    }

    /// Returns a non-zero unique ID for this Type, or returns 0 if the Type does not (yet) have a unique ID.
    /// If `semantic()` has not been run, 0 is returned.
    final size_t getUniqueID() const
    {
        return cast(size_t) deco;
    }

    extern (D)
    final Mcache* getMcache()
    {
        if (!mcache)
            mcache = cast(Mcache*) mem.xcalloc(Mcache.sizeof, 1);
        return mcache;
    }

    /********************************
     * For pretty-printing a type.
     */
    final override const(char)* toChars() const
    {
        return dmd.hdrgen.toChars(this);
    }

    /// ditto
    final char* toPrettyChars(bool QualifyTypes = false)
    {
        OutBuffer buf;
        buf.reserve(16);
        HdrGenState hgs;
        hgs.fullQual = QualifyTypes;

        toCBuffer(this, buf, null, hgs);
        return buf.extractChars();
    }

    static void _init() @system
    {
        stringtable._init(14_000);

        // Set basic types
        __gshared TY* basetab =
        [
            Tvoid,
            Tint8,
            Tuns8,
            Tint16,
            Tuns16,
            Tint32,
            Tuns32,
            Tint64,
            Tuns64,
            Tint128,
            Tuns128,
            Tfloat32,
            Tfloat64,
            Tfloat80,
            Timaginary32,
            Timaginary64,
            Timaginary80,
            Tcomplex32,
            Tcomplex64,
            Tcomplex80,
            Tbool,
            Tchar,
            Twchar,
            Tdchar,
            Terror
        ];

        for (size_t i = 0; basetab[i] != Terror; i++)
        {
            Type t = new TypeBasic(basetab[i]);
            t = t.merge();
            basic[basetab[i]] = t;
        }
        basic[Terror] = new TypeError();

        tnoreturn = new TypeNoreturn();
        tnoreturn.deco = tnoreturn.merge().deco;
        basic[Tnoreturn] = tnoreturn;

        tvoid = basic[Tvoid];
        tint8 = basic[Tint8];
        tuns8 = basic[Tuns8];
        tint16 = basic[Tint16];
        tuns16 = basic[Tuns16];
        tint32 = basic[Tint32];
        tuns32 = basic[Tuns32];
        tint64 = basic[Tint64];
        tuns64 = basic[Tuns64];
        tint128 = basic[Tint128];
        tuns128 = basic[Tuns128];
        tfloat32 = basic[Tfloat32];
        tfloat64 = basic[Tfloat64];
        tfloat80 = basic[Tfloat80];

        timaginary32 = basic[Timaginary32];
        timaginary64 = basic[Timaginary64];
        timaginary80 = basic[Timaginary80];

        tcomplex32 = basic[Tcomplex32];
        tcomplex64 = basic[Tcomplex64];
        tcomplex80 = basic[Tcomplex80];

        tbool = basic[Tbool];
        tchar = basic[Tchar];
        twchar = basic[Twchar];
        tdchar = basic[Tdchar];

        tshiftcnt = tint32;
        terror = basic[Terror];
        tnoreturn = basic[Tnoreturn];
        tnull = new TypeNull();
        tnull.deco = tnull.merge().deco;

        tvoidptr = tvoid.pointerTo();
        tstring = tchar.immutableOf().arrayOf();
        twstring = twchar.immutableOf().arrayOf();
        tdstring = tdchar.immutableOf().arrayOf();

        const isLP64 = target.isLP64;

        tsize_t    = basic[isLP64 ? Tuns64 : Tuns32];
        tptrdiff_t = basic[isLP64 ? Tint64 : Tint32];
        thash_t = tsize_t;
    }

    /**
     * Deinitializes the global state of the compiler.
     *
     * This can be used to restore the state set by `_init` to its original
     * state.
     */
    static void deinitialize()
    {
        stringtable = stringtable.init;
    }

    final uinteger_t size()
    {
        return size(Loc.initial);
    }

    uinteger_t size(const ref Loc loc)
    {
        error(loc, "no size for type `%s`", toChars());
        return SIZE_INVALID;
    }

    uint alignsize()
    {
        return cast(uint)size(Loc.initial);
    }

    final Type trySemantic(const ref Loc loc, Scope* sc)
    {
        //printf("+trySemantic(%s) %d\n", toChars(), global.errors);

        // Needed to display any deprecations that were gagged
        auto tcopy = this.syntaxCopy();

        const errors = global.startGagging();
        Type t = typeSemantic(this, loc, sc);
        if (global.endGagging(errors) || t.ty == Terror) // if any errors happened
        {
            t = null;
        }
        else
        {
            // If `typeSemantic` succeeded, there may have been deprecations that
            // were gagged due the `startGagging` above.  Run again to display
            // those deprecations.  https://issues.dlang.org/show_bug.cgi?id=19107
            if (global.gaggedWarnings > 0)
                typeSemantic(tcopy, loc, sc);
        }
        //printf("-trySemantic(%s) %d\n", toChars(), global.errors);
        return t;
    }

    /*************************************
     * This version does a merge even if the deco is already computed.
     * Necessary for types that have a deco, but are not merged.
     */
    final Type merge2()
    {
        //printf("merge2(%s)\n", toChars());
        Type t = this;
        assert(t);
        if (!t.deco)
            return t.merge();

        auto sv = stringtable.lookup(t.deco, strlen(t.deco));
        if (sv && sv.value)
        {
            t = sv.value;
            assert(t.deco);
        }
        else
            assert(0);
        return t;
    }

    /*********************************
     * Store this type's modifier name into buf.
     */
    final void modToBuffer(ref OutBuffer buf) nothrow const
    {
        if (mod)
        {
            buf.writeByte(' ');
            MODtoBuffer(buf, mod);
        }
    }

    /*********************************
     * Return this type's modifier name.
     */
    final char* modToChars() nothrow const
    {
        OutBuffer buf;
        buf.reserve(16);
        modToBuffer(buf);
        return buf.extractChars();
    }

    bool isintegral()
    {
        return false;
    }

    // real, imaginary, or complex
    bool isfloating()
    {
        return false;
    }

    bool isreal()
    {
        return false;
    }

    bool isimaginary()
    {
        return false;
    }

    bool iscomplex()
    {
        return false;
    }

    bool isscalar()
    {
        return false;
    }

    bool isunsigned()
    {
        return false;
    }

    bool isscope()
    {
        return false;
    }

    bool isString()
    {
        return false;
    }

    /**************************
     * When T is mutable,
     * Given:
     *      T a, b;
     * Can we bitwise assign:
     *      a = b;
     * ?
     */
    bool isAssignable()
    {
        return true;
    }

    /**************************
     * Returns true if T can be converted to boolean value.
     */
    bool isBoolean()
    {
        return isscalar();
    }

    final bool isConst() const nothrow pure @nogc @safe
    {
        return (mod & MODFlags.const_) != 0;
    }

    final bool isImmutable() const nothrow pure @nogc @safe
    {
        return (mod & MODFlags.immutable_) != 0;
    }

    final bool isMutable() const nothrow pure @nogc @safe
    {
        return (mod & (MODFlags.const_ | MODFlags.immutable_ | MODFlags.wild)) == 0;
    }

    final bool isShared() const nothrow pure @nogc @safe
    {
        return (mod & MODFlags.shared_) != 0;
    }

    final bool isSharedConst() const nothrow pure @nogc @safe
    {
        return (mod & (MODFlags.shared_ | MODFlags.const_)) == (MODFlags.shared_ | MODFlags.const_);
    }

    final bool isWild() const nothrow pure @nogc @safe
    {
        return (mod & MODFlags.wild) != 0;
    }

    final bool isWildConst() const nothrow pure @nogc @safe
    {
        return (mod & MODFlags.wildconst) == MODFlags.wildconst;
    }

    final bool isSharedWild() const nothrow pure @nogc @safe
    {
        return (mod & (MODFlags.shared_ | MODFlags.wild)) == (MODFlags.shared_ | MODFlags.wild);
    }

    final bool isNaked() const nothrow pure @nogc @safe
    {
        return mod == 0;
    }

    /********************************
     * Return a copy of this type with all attributes null-initialized.
     * Useful for creating a type with different modifiers.
     */
    final Type nullAttributes() nothrow const
    {
        uint sz = sizeTy[ty];
        Type t = cast(Type)mem.xmalloc(sz);
        memcpy(cast(void*)t, cast(void*)this, sz);
        // t.mod = NULL;  // leave mod unchanged
        t.deco = null;
        t.arrayof = null;
        t.pto = null;
        t.rto = null;
        t.vtinfo = null;
        t.ctype = null;
        t.mcache = null;
        if (t.ty == Tstruct)
            (cast(TypeStruct)t).att = AliasThisRec.fwdref;
        if (t.ty == Tclass)
            (cast(TypeClass)t).att = AliasThisRec.fwdref;
        return t;
    }

    /********************************
     * Convert to 'const'.
     */
    final Type constOf()
    {
        //printf("Type::constOf() %p %s\n", this, toChars());
        if (mod == MODFlags.const_)
            return this;
        if (mcache && mcache.cto)
        {
            assert(mcache.cto.mod == MODFlags.const_);
            return mcache.cto;
        }
        Type t = makeConst();
        t = t.merge();
        t.fixTo(this);
        //printf("-Type::constOf() %p %s\n", t, t.toChars());
        return t;
    }

    /********************************
     * Convert to 'immutable'.
     */
    final Type immutableOf()
    {
        //printf("Type::immutableOf() %p %s\n", this, toChars());
        if (isImmutable())
            return this;
        if (mcache && mcache.ito)
        {
            assert(mcache.ito.isImmutable());
            return mcache.ito;
        }
        Type t = makeImmutable();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p\n", t);
        return t;
    }

    /********************************
     * Make type mutable.
     */
    final Type mutableOf()
    {
        //printf("Type::mutableOf() %p, %s\n", this, toChars());
        Type t = this;
        if (isImmutable())
        {
            getMcache();
            t = mcache.ito; // immutable => naked
            assert(!t || (t.isMutable() && !t.isShared()));
        }
        else if (isConst())
        {
            getMcache();
            if (isShared())
            {
                if (isWild())
                    t = mcache.swcto; // shared wild const -> shared
                else
                    t = mcache.sto; // shared const => shared
            }
            else
            {
                if (isWild())
                    t = mcache.wcto; // wild const -> naked
                else
                    t = mcache.cto; // const => naked
            }
            assert(!t || t.isMutable());
        }
        else if (isWild())
        {
            getMcache();
            if (isShared())
                t = mcache.sto; // shared wild => shared
            else
                t = mcache.wto; // wild => naked
            assert(!t || t.isMutable());
        }
        if (!t)
        {
            t = makeMutable();
            t = t.merge();
            t.fixTo(this);
        }
        else
            t = t.merge();
        assert(t.isMutable());
        return t;
    }

    final Type sharedOf()
    {
        //printf("Type::sharedOf() %p, %s\n", this, toChars());
        if (mod == MODFlags.shared_)
            return this;
        if (mcache && mcache.sto)
        {
            assert(mcache.sto.mod == MODFlags.shared_);
            return mcache.sto;
        }
        Type t = makeShared();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p\n", t);
        return t;
    }

    final Type sharedConstOf()
    {
        //printf("Type::sharedConstOf() %p, %s\n", this, toChars());
        if (mod == (MODFlags.shared_ | MODFlags.const_))
            return this;
        if (mcache && mcache.scto)
        {
            assert(mcache.scto.mod == (MODFlags.shared_ | MODFlags.const_));
            return mcache.scto;
        }
        Type t = makeSharedConst();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p\n", t);
        return t;
    }

    /********************************
     * Make type unshared.
     *      0            => 0
     *      const        => const
     *      immutable    => immutable
     *      shared       => 0
     *      shared const => const
     *      wild         => wild
     *      wild const   => wild const
     *      shared wild  => wild
     *      shared wild const => wild const
     */
    final Type unSharedOf()
    {
        //printf("Type::unSharedOf() %p, %s\n", this, toChars());
        Type t = this;

        if (isShared())
        {
            getMcache();
            if (isWild())
            {
                if (isConst())
                    t = mcache.wcto; // shared wild const => wild const
                else
                    t = mcache.wto; // shared wild => wild
            }
            else
            {
                if (isConst())
                    t = mcache.cto; // shared const => const
                else
                    t = mcache.sto; // shared => naked
            }
            assert(!t || !t.isShared());
        }

        if (!t)
        {
            t = this.nullAttributes();
            t.mod = mod & ~MODFlags.shared_;
            t.ctype = ctype;
            t = t.merge();
            t.fixTo(this);
        }
        else
            t = t.merge();
        assert(!t.isShared());
        return t;
    }

    /********************************
     * Convert to 'wild'.
     */
    final Type wildOf()
    {
        //printf("Type::wildOf() %p %s\n", this, toChars());
        if (mod == MODFlags.wild)
            return this;
        if (mcache && mcache.wto)
        {
            assert(mcache.wto.mod == MODFlags.wild);
            return mcache.wto;
        }
        Type t = makeWild();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p %s\n", t, t.toChars());
        return t;
    }

    final Type wildConstOf()
    {
        //printf("Type::wildConstOf() %p %s\n", this, toChars());
        if (mod == MODFlags.wildconst)
            return this;
        if (mcache && mcache.wcto)
        {
            assert(mcache.wcto.mod == MODFlags.wildconst);
            return mcache.wcto;
        }
        Type t = makeWildConst();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p %s\n", t, t.toChars());
        return t;
    }

    final Type sharedWildOf()
    {
        //printf("Type::sharedWildOf() %p, %s\n", this, toChars());
        if (mod == (MODFlags.shared_ | MODFlags.wild))
            return this;
        if (mcache && mcache.swto)
        {
            assert(mcache.swto.mod == (MODFlags.shared_ | MODFlags.wild));
            return mcache.swto;
        }
        Type t = makeSharedWild();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p %s\n", t, t.toChars());
        return t;
    }

    final Type sharedWildConstOf()
    {
        //printf("Type::sharedWildConstOf() %p, %s\n", this, toChars());
        if (mod == (MODFlags.shared_ | MODFlags.wildconst))
            return this;
        if (mcache && mcache.swcto)
        {
            assert(mcache.swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            return mcache.swcto;
        }
        Type t = makeSharedWildConst();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p %s\n", t, t.toChars());
        return t;
    }

    /**********************************
     * For our new type 'this', which is type-constructed from t,
     * fill in the cto, ito, sto, scto, wto shortcuts.
     */
    extern (D) final void fixTo(Type t)
    {
        // If fixing this: immutable(T*) by t: immutable(T)*,
        // cache t to this.xto won't break transitivity.
        Type mto = null;
        Type tn = nextOf();
        if (!tn || ty != Tsarray && tn.mod == t.nextOf().mod)
        {
            switch (t.mod)
            {
            case 0:
                mto = t;
                break;

            case MODFlags.const_:
                getMcache();
                mcache.cto = t;
                break;

            case MODFlags.wild:
                getMcache();
                mcache.wto = t;
                break;

            case MODFlags.wildconst:
                getMcache();
                mcache.wcto = t;
                break;

            case MODFlags.shared_:
                getMcache();
                mcache.sto = t;
                break;

            case MODFlags.shared_ | MODFlags.const_:
                getMcache();
                mcache.scto = t;
                break;

            case MODFlags.shared_ | MODFlags.wild:
                getMcache();
                mcache.swto = t;
                break;

            case MODFlags.shared_ | MODFlags.wildconst:
                getMcache();
                mcache.swcto = t;
                break;

            case MODFlags.immutable_:
                getMcache();
                mcache.ito = t;
                break;

            default:
                break;
            }
        }
        assert(mod != t.mod);

        if (mod)
        {
            getMcache();
            t.getMcache();
        }
        switch (mod)
        {
        case 0:
            break;

        case MODFlags.const_:
            mcache.cto = mto;
            t.mcache.cto = this;
            break;

        case MODFlags.wild:
            mcache.wto = mto;
            t.mcache.wto = this;
            break;

        case MODFlags.wildconst:
            mcache.wcto = mto;
            t.mcache.wcto = this;
            break;

        case MODFlags.shared_:
            mcache.sto = mto;
            t.mcache.sto = this;
            break;

        case MODFlags.shared_ | MODFlags.const_:
            mcache.scto = mto;
            t.mcache.scto = this;
            break;

        case MODFlags.shared_ | MODFlags.wild:
            mcache.swto = mto;
            t.mcache.swto = this;
            break;

        case MODFlags.shared_ | MODFlags.wildconst:
            mcache.swcto = mto;
            t.mcache.swcto = this;
            break;

        case MODFlags.immutable_:
            t.mcache.ito = this;
            if (t.mcache.cto)
                t.mcache.cto.getMcache().ito = this;
            if (t.mcache.sto)
                t.mcache.sto.getMcache().ito = this;
            if (t.mcache.scto)
                t.mcache.scto.getMcache().ito = this;
            if (t.mcache.wto)
                t.mcache.wto.getMcache().ito = this;
            if (t.mcache.wcto)
                t.mcache.wcto.getMcache().ito = this;
            if (t.mcache.swto)
                t.mcache.swto.getMcache().ito = this;
            if (t.mcache.swcto)
                t.mcache.swcto.getMcache().ito = this;
            break;

        default:
            assert(0);
        }

        check();
        t.check();
        //printf("fixTo: %s, %s\n", toChars(), t.toChars());
    }

    /***************************
     * Look for bugs in constructing types.
     */
    extern (D) final void check()
    {
        if (mcache)
        with (mcache)
        switch (mod)
        {
        case 0:
            if (cto)
                assert(cto.mod == MODFlags.const_);
            if (ito)
                assert(ito.mod == MODFlags.immutable_);
            if (sto)
                assert(sto.mod == MODFlags.shared_);
            if (scto)
                assert(scto.mod == (MODFlags.shared_ | MODFlags.const_));
            if (wto)
                assert(wto.mod == MODFlags.wild);
            if (wcto)
                assert(wcto.mod == MODFlags.wildconst);
            if (swto)
                assert(swto.mod == (MODFlags.shared_ | MODFlags.wild));
            if (swcto)
                assert(swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            break;

        case MODFlags.const_:
            if (cto)
                assert(cto.mod == 0);
            if (ito)
                assert(ito.mod == MODFlags.immutable_);
            if (sto)
                assert(sto.mod == MODFlags.shared_);
            if (scto)
                assert(scto.mod == (MODFlags.shared_ | MODFlags.const_));
            if (wto)
                assert(wto.mod == MODFlags.wild);
            if (wcto)
                assert(wcto.mod == MODFlags.wildconst);
            if (swto)
                assert(swto.mod == (MODFlags.shared_ | MODFlags.wild));
            if (swcto)
                assert(swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            break;

        case MODFlags.wild:
            if (cto)
                assert(cto.mod == MODFlags.const_);
            if (ito)
                assert(ito.mod == MODFlags.immutable_);
            if (sto)
                assert(sto.mod == MODFlags.shared_);
            if (scto)
                assert(scto.mod == (MODFlags.shared_ | MODFlags.const_));
            if (wto)
                assert(wto.mod == 0);
            if (wcto)
                assert(wcto.mod == MODFlags.wildconst);
            if (swto)
                assert(swto.mod == (MODFlags.shared_ | MODFlags.wild));
            if (swcto)
                assert(swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            break;

        case MODFlags.wildconst:
            assert(!cto || cto.mod == MODFlags.const_);
            assert(!ito || ito.mod == MODFlags.immutable_);
            assert(!sto || sto.mod == MODFlags.shared_);
            assert(!scto || scto.mod == (MODFlags.shared_ | MODFlags.const_));
            assert(!wto || wto.mod == MODFlags.wild);
            assert(!wcto || wcto.mod == 0);
            assert(!swto || swto.mod == (MODFlags.shared_ | MODFlags.wild));
            assert(!swcto || swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            break;

        case MODFlags.shared_:
            if (cto)
                assert(cto.mod == MODFlags.const_);
            if (ito)
                assert(ito.mod == MODFlags.immutable_);
            if (sto)
                assert(sto.mod == 0);
            if (scto)
                assert(scto.mod == (MODFlags.shared_ | MODFlags.const_));
            if (wto)
                assert(wto.mod == MODFlags.wild);
            if (wcto)
                assert(wcto.mod == MODFlags.wildconst);
            if (swto)
                assert(swto.mod == (MODFlags.shared_ | MODFlags.wild));
            if (swcto)
                assert(swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            break;

        case MODFlags.shared_ | MODFlags.const_:
            if (cto)
                assert(cto.mod == MODFlags.const_);
            if (ito)
                assert(ito.mod == MODFlags.immutable_);
            if (sto)
                assert(sto.mod == MODFlags.shared_);
            if (scto)
                assert(scto.mod == 0);
            if (wto)
                assert(wto.mod == MODFlags.wild);
            if (wcto)
                assert(wcto.mod == MODFlags.wildconst);
            if (swto)
                assert(swto.mod == (MODFlags.shared_ | MODFlags.wild));
            if (swcto)
                assert(swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            break;

        case MODFlags.shared_ | MODFlags.wild:
            if (cto)
                assert(cto.mod == MODFlags.const_);
            if (ito)
                assert(ito.mod == MODFlags.immutable_);
            if (sto)
                assert(sto.mod == MODFlags.shared_);
            if (scto)
                assert(scto.mod == (MODFlags.shared_ | MODFlags.const_));
            if (wto)
                assert(wto.mod == MODFlags.wild);
            if (wcto)
                assert(wcto.mod == MODFlags.wildconst);
            if (swto)
                assert(swto.mod == 0);
            if (swcto)
                assert(swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            break;

        case MODFlags.shared_ | MODFlags.wildconst:
            assert(!cto || cto.mod == MODFlags.const_);
            assert(!ito || ito.mod == MODFlags.immutable_);
            assert(!sto || sto.mod == MODFlags.shared_);
            assert(!scto || scto.mod == (MODFlags.shared_ | MODFlags.const_));
            assert(!wto || wto.mod == MODFlags.wild);
            assert(!wcto || wcto.mod == MODFlags.wildconst);
            assert(!swto || swto.mod == (MODFlags.shared_ | MODFlags.wild));
            assert(!swcto || swcto.mod == 0);
            break;

        case MODFlags.immutable_:
            if (cto)
                assert(cto.mod == MODFlags.const_);
            if (ito)
                assert(ito.mod == 0);
            if (sto)
                assert(sto.mod == MODFlags.shared_);
            if (scto)
                assert(scto.mod == (MODFlags.shared_ | MODFlags.const_));
            if (wto)
                assert(wto.mod == MODFlags.wild);
            if (wcto)
                assert(wcto.mod == MODFlags.wildconst);
            if (swto)
                assert(swto.mod == (MODFlags.shared_ | MODFlags.wild));
            if (swcto)
                assert(swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            break;

        default:
            assert(0);
        }

        Type tn = nextOf();
        if (tn && ty != Tfunction && tn.ty != Tfunction && ty != Tenum)
        {
            // Verify transitivity
            switch (mod)
            {
            case 0:
            case MODFlags.const_:
            case MODFlags.wild:
            case MODFlags.wildconst:
            case MODFlags.shared_:
            case MODFlags.shared_ | MODFlags.const_:
            case MODFlags.shared_ | MODFlags.wild:
            case MODFlags.shared_ | MODFlags.wildconst:
            case MODFlags.immutable_:
                assert(tn.mod == MODFlags.immutable_ || (tn.mod & mod) == mod);
                break;

            default:
                assert(0);
            }
            tn.check();
        }
    }

    /*************************************
     * Apply STCxxxx bits to existing type.
     * Use *before* semantic analysis is run.
     */
    extern (D) final Type addSTC(StorageClass stc)
    {
        Type t = this;
        if (t.isImmutable())
        {
        }
        else if (stc & STC.immutable_)
        {
            t = t.makeImmutable();
        }
        else
        {
            if ((stc & STC.shared_) && !t.isShared())
            {
                if (t.isWild())
                {
                    if (t.isConst())
                        t = t.makeSharedWildConst();
                    else
                        t = t.makeSharedWild();
                }
                else
                {
                    if (t.isConst())
                        t = t.makeSharedConst();
                    else
                        t = t.makeShared();
                }
            }
            if ((stc & STC.const_) && !t.isConst())
            {
                if (t.isShared())
                {
                    if (t.isWild())
                        t = t.makeSharedWildConst();
                    else
                        t = t.makeSharedConst();
                }
                else
                {
                    if (t.isWild())
                        t = t.makeWildConst();
                    else
                        t = t.makeConst();
                }
            }
            if ((stc & STC.wild) && !t.isWild())
            {
                if (t.isShared())
                {
                    if (t.isConst())
                        t = t.makeSharedWildConst();
                    else
                        t = t.makeSharedWild();
                }
                else
                {
                    if (t.isConst())
                        t = t.makeWildConst();
                    else
                        t = t.makeWild();
                }
            }
        }
        return t;
    }

    /************************************
     * Apply MODxxxx bits to existing type.
     */
    final Type castMod(MOD mod)
    {
        Type t;
        switch (mod)
        {
        case 0:
            t = unSharedOf().mutableOf();
            break;

        case MODFlags.const_:
            t = unSharedOf().constOf();
            break;

        case MODFlags.wild:
            t = unSharedOf().wildOf();
            break;

        case MODFlags.wildconst:
            t = unSharedOf().wildConstOf();
            break;

        case MODFlags.shared_:
            t = mutableOf().sharedOf();
            break;

        case MODFlags.shared_ | MODFlags.const_:
            t = sharedConstOf();
            break;

        case MODFlags.shared_ | MODFlags.wild:
            t = sharedWildOf();
            break;

        case MODFlags.shared_ | MODFlags.wildconst:
            t = sharedWildConstOf();
            break;

        case MODFlags.immutable_:
            t = immutableOf();
            break;

        default:
            assert(0);
        }
        return t;
    }

    /************************************
     * Add MODxxxx bits to existing type.
     * We're adding, not replacing, so adding const to
     * a shared type => "shared const"
     */
    final Type addMod(MOD mod)
    {
        /* Add anything to immutable, and it remains immutable
         */
        Type t = this;
        if (!t.isImmutable())
        {
            //printf("addMod(%x) %s\n", mod, toChars());
            switch (mod)
            {
            case 0:
                break;

            case MODFlags.const_:
                if (isShared())
                {
                    if (isWild())
                        t = sharedWildConstOf();
                    else
                        t = sharedConstOf();
                }
                else
                {
                    if (isWild())
                        t = wildConstOf();
                    else
                        t = constOf();
                }
                break;

            case MODFlags.wild:
                if (isShared())
                {
                    if (isConst())
                        t = sharedWildConstOf();
                    else
                        t = sharedWildOf();
                }
                else
                {
                    if (isConst())
                        t = wildConstOf();
                    else
                        t = wildOf();
                }
                break;

            case MODFlags.wildconst:
                if (isShared())
                    t = sharedWildConstOf();
                else
                    t = wildConstOf();
                break;

            case MODFlags.shared_:
                if (isWild())
                {
                    if (isConst())
                        t = sharedWildConstOf();
                    else
                        t = sharedWildOf();
                }
                else
                {
                    if (isConst())
                        t = sharedConstOf();
                    else
                        t = sharedOf();
                }
                break;

            case MODFlags.shared_ | MODFlags.const_:
                if (isWild())
                    t = sharedWildConstOf();
                else
                    t = sharedConstOf();
                break;

            case MODFlags.shared_ | MODFlags.wild:
                if (isConst())
                    t = sharedWildConstOf();
                else
                    t = sharedWildOf();
                break;

            case MODFlags.shared_ | MODFlags.wildconst:
                t = sharedWildConstOf();
                break;

            case MODFlags.immutable_:
                t = immutableOf();
                break;

            default:
                assert(0);
            }
        }
        return t;
    }

    /************************************
     * Add storage class modifiers to type.
     */
    Type addStorageClass(StorageClass stc)
    {
        /* Just translate to MOD bits and let addMod() do the work
         */
        MOD mod = 0;
        if (stc & STC.immutable_)
            mod = MODFlags.immutable_;
        else
        {
            if (stc & (STC.const_ | STC.in_))
                mod |= MODFlags.const_;
            if (stc & STC.wild)
                mod |= MODFlags.wild;
            if (stc & STC.shared_)
                mod |= MODFlags.shared_;
        }
        return addMod(mod);
    }

    final Type pointerTo()
    {
        if (ty == Terror)
            return this;
        if (!pto)
        {
            Type t = new TypePointer(this);
            if (ty == Tfunction)
            {
                t.deco = t.merge().deco;
                pto = t;
            }
            else
                pto = t.merge();
        }
        return pto;
    }

    final Type referenceTo()
    {
        if (ty == Terror)
            return this;
        if (!rto)
        {
            Type t = new TypeReference(this);
            rto = t.merge();
        }
        return rto;
    }

    final Type arrayOf()
    {
        if (ty == Terror)
            return this;
        if (!arrayof)
        {
            Type t = new TypeDArray(this);
            arrayof = t.merge();
        }
        return arrayof;
    }

    // Make corresponding static array type without semantic
    final Type sarrayOf(dinteger_t dim)
    {
        assert(deco);
        Type t = new TypeSArray(this, new IntegerExp(Loc.initial, dim, Type.tsize_t));
        // according to TypeSArray::semantic()
        t = t.addMod(mod);
        t = t.merge();
        return t;
    }

    final bool hasDeprecatedAliasThis()
    {
        auto ad = isAggregate(this);
        return ad && ad.aliasthis && (ad.aliasthis.isDeprecated || ad.aliasthis.sym.isDeprecated);
    }

    final Type aliasthisOf()
    {
        auto ad = isAggregate(this);
        if (!ad || !ad.aliasthis)
            return null;

        auto s = ad.aliasthis.sym;
        if (s.isAliasDeclaration())
            s = s.toAlias();

        if (s.isTupleDeclaration())
            return null;

        if (auto vd = s.isVarDeclaration())
        {
            auto t = vd.type;
            if (vd.needThis())
                t = t.addMod(this.mod);
            return t;
        }
        Dsymbol callable = s.isFuncDeclaration();
        callable = callable ? callable : s.isTemplateDeclaration();
        if (callable)
        {
            auto fd = resolveFuncCall(Loc.initial, null, callable, null, this, ArgumentList(), FuncResolveFlag.quiet);
            if (!fd || fd.errors || !fd.functionSemantic())
                return Type.terror;

            auto t = fd.type.nextOf();
            if (!t) // https://issues.dlang.org/show_bug.cgi?id=14185
                return Type.terror;
            t = t.substWildTo(mod == 0 ? MODFlags.mutable : mod);
            return t;
        }
        if (auto d = s.isDeclaration())
        {
            assert(d.type);
            return d.type;
        }
        if (auto ed = s.isEnumDeclaration())
        {
            return ed.type;
        }

        //printf("%s\n", s.kind());
        return null;
    }

    /**
     * Check whether this type has endless `alias this` recursion.
     * Returns:
     *   `true` if this type has an `alias this` that can be implicitly
     *    converted back to this type itself.
     */
    extern (D) final bool checkAliasThisRec()
    {
        Type tb = toBasetype();
        AliasThisRec* pflag;
        if (tb.ty == Tstruct)
            pflag = &(cast(TypeStruct)tb).att;
        else if (tb.ty == Tclass)
            pflag = &(cast(TypeClass)tb).att;
        else
            return false;

        AliasThisRec flag = cast(AliasThisRec)(*pflag & AliasThisRec.typeMask);
        if (flag == AliasThisRec.fwdref)
        {
            Type att = aliasthisOf();
            flag = att && att.implicitConvTo(this) ? AliasThisRec.yes : AliasThisRec.no;
        }
        *pflag = cast(AliasThisRec)(flag | (*pflag & ~AliasThisRec.typeMask));
        return flag == AliasThisRec.yes;
    }

    Type makeConst()
    {
        //printf("Type::makeConst() %p, %s\n", this, toChars());
        if (mcache && mcache.cto)
            return mcache.cto;
        Type t = this.nullAttributes();
        t.mod = MODFlags.const_;
        //printf("-Type::makeConst() %p, %s\n", t, toChars());
        return t;
    }

    Type makeImmutable()
    {
        if (mcache && mcache.ito)
            return mcache.ito;
        Type t = this.nullAttributes();
        t.mod = MODFlags.immutable_;
        return t;
    }

    Type makeShared()
    {
        if (mcache && mcache.sto)
            return mcache.sto;
        Type t = this.nullAttributes();
        t.mod = MODFlags.shared_;
        return t;
    }

    Type makeSharedConst()
    {
        if (mcache && mcache.scto)
            return mcache.scto;
        Type t = this.nullAttributes();
        t.mod = MODFlags.shared_ | MODFlags.const_;
        return t;
    }

    Type makeWild()
    {
        if (mcache && mcache.wto)
            return mcache.wto;
        Type t = this.nullAttributes();
        t.mod = MODFlags.wild;
        return t;
    }

    Type makeWildConst()
    {
        if (mcache && mcache.wcto)
            return mcache.wcto;
        Type t = this.nullAttributes();
        t.mod = MODFlags.wildconst;
        return t;
    }

    Type makeSharedWild()
    {
        if (mcache && mcache.swto)
            return mcache.swto;
        Type t = this.nullAttributes();
        t.mod = MODFlags.shared_ | MODFlags.wild;
        return t;
    }

    Type makeSharedWildConst()
    {
        if (mcache && mcache.swcto)
            return mcache.swcto;
        Type t = this.nullAttributes();
        t.mod = MODFlags.shared_ | MODFlags.wildconst;
        return t;
    }

    Type makeMutable()
    {
        Type t = this.nullAttributes();
        t.mod = mod & MODFlags.shared_;
        return t;
    }

    Dsymbol toDsymbol(Scope* sc)
    {
        return null;
    }

    /*******************************
     * If this is a shell around another type,
     * get that other type.
     */
    final Type toBasetype()
    {
        /* This function is used heavily.
         * De-virtualize it so it can be easily inlined.
         */
        TypeEnum te;
        return ((te = isTypeEnum()) !is null) ? te.toBasetype2() : this;
    }

    bool isBaseOf(Type t, int* poffset)
    {
        return 0; // assume not
    }

    /********************************
     * Determine if 'this' can be implicitly converted
     * to type 'to'.
     * Returns:
     *      MATCH.nomatch, MATCH.convert, MATCH.constant, MATCH.exact
     */
    MATCH implicitConvTo(Type to)
    {
        //printf("Type::implicitConvTo(this=%p, to=%p)\n", this, to);
        //printf("from: %s\n", toChars());
        //printf("to  : %s\n", to.toChars());
        if (this.equals(to))
            return MATCH.exact;
        return MATCH.nomatch;
    }

    /*******************************
     * Determine if converting 'this' to 'to' is an identity operation,
     * a conversion to const operation, or the types aren't the same.
     * Returns:
     *      MATCH.exact      'this' == 'to'
     *      MATCH.constant      'to' is const
     *      MATCH.nomatch    conversion to mutable or invariant
     */
    MATCH constConv(Type to)
    {
        //printf("Type::constConv(this = %s, to = %s)\n", toChars(), to.toChars());
        if (equals(to))
            return MATCH.exact;
        if (ty == to.ty && MODimplicitConv(mod, to.mod))
            return MATCH.constant;
        return MATCH.nomatch;
    }

    /***************************************
     * Compute MOD bits matching `this` argument type to wild parameter type.
     * Params:
     *  t = corresponding parameter type
     *  isRef = parameter is `ref` or `out`
     * Returns:
     *  MOD bits
     */
    MOD deduceWild(Type t, bool isRef)
    {
        //printf("Type::deduceWild this = '%s', tprm = '%s'\n", toChars(), tprm.toChars());
        if (t.isWild())
        {
            if (isImmutable())
                return MODFlags.immutable_;
            else if (isWildConst())
            {
                if (t.isWildConst())
                    return MODFlags.wild;
                else
                    return MODFlags.wildconst;
            }
            else if (isWild())
                return MODFlags.wild;
            else if (isConst())
                return MODFlags.const_;
            else if (isMutable())
                return MODFlags.mutable;
            else
                assert(0);
        }
        return 0;
    }

    Type substWildTo(uint mod)
    {
        //printf("+Type::substWildTo this = %s, mod = x%x\n", toChars(), mod);
        Type t;

        if (Type tn = nextOf())
        {
            // substitution has no effect on function pointer type.
            if (ty == Tpointer && tn.ty == Tfunction)
            {
                t = this;
                goto L1;
            }

            t = tn.substWildTo(mod);
            if (t == tn)
                t = this;
            else
            {
                if (ty == Tpointer)
                    t = t.pointerTo();
                else if (ty == Tarray)
                    t = t.arrayOf();
                else if (ty == Tsarray)
                    t = new TypeSArray(t, (cast(TypeSArray)this).dim.syntaxCopy());
                else if (ty == Taarray)
                {
                    t = new TypeAArray(t, (cast(TypeAArray)this).index.syntaxCopy());
                }
                else if (ty == Tdelegate)
                {
                    t = new TypeDelegate(t.isTypeFunction());
                }
                else
                    assert(0);

                t = t.merge();
            }
        }
        else
            t = this;

    L1:
        if (isWild())
        {
            if (mod == MODFlags.immutable_)
            {
                t = t.immutableOf();
            }
            else if (mod == MODFlags.wildconst)
            {
                t = t.wildConstOf();
            }
            else if (mod == MODFlags.wild)
            {
                if (isWildConst())
                    t = t.wildConstOf();
                else
                    t = t.wildOf();
            }
            else if (mod == MODFlags.const_)
            {
                t = t.constOf();
            }
            else
            {
                if (isWildConst())
                    t = t.constOf();
                else
                    t = t.mutableOf();
            }
        }
        if (isConst())
            t = t.addMod(MODFlags.const_);
        if (isShared())
            t = t.addMod(MODFlags.shared_);

        //printf("-Type::substWildTo t = %s\n", t.toChars());
        return t;
    }

    final Type unqualify(uint m)
    {
        Type t = mutableOf().unSharedOf();

        Type tn = ty == Tenum ? null : nextOf();
        if (tn && tn.ty != Tfunction)
        {
            Type utn = tn.unqualify(m);
            if (utn != tn)
            {
                if (ty == Tpointer)
                    t = utn.pointerTo();
                else if (ty == Tarray)
                    t = utn.arrayOf();
                else if (ty == Tsarray)
                    t = new TypeSArray(utn, (cast(TypeSArray)this).dim);
                else if (ty == Taarray)
                {
                    t = new TypeAArray(utn, (cast(TypeAArray)this).index);
                }
                else
                    assert(0);

                t = t.merge();
            }
        }
        t = t.addMod(mod & ~m);
        return t;
    }

    /**************************
     * Return type with the top level of it being mutable.
     */
    inout(Type) toHeadMutable() inout
    {
        if (!mod)
            return this;
        Type unqualThis = cast(Type) this;
        // `mutableOf` needs a mutable `this` only for caching
        return cast(inout(Type)) unqualThis.mutableOf();
    }

    inout(ClassDeclaration) isClassHandle() inout
    {
        return null;
    }

    /************************************
     * Return alignment to use for this type.
     */
    structalign_t alignment()
    {
        structalign_t s;
        s.setDefault();
        return s;
    }

    /***************************************
     * Use when we prefer the default initializer to be a literal,
     * rather than a global immutable variable.
     */
    Expression defaultInitLiteral(const ref Loc loc)
    {
        static if (LOGDEFAULTINIT)
        {
            printf("Type::defaultInitLiteral() '%s'\n", toChars());
        }
        return defaultInit(this, loc);
    }

    // if initializer is 0
    bool isZeroInit(const ref Loc loc)
    {
        return false; // assume not
    }

    final Identifier getTypeInfoIdent()
    {
        // _init_10TypeInfo_%s
        OutBuffer buf;
        buf.reserve(32);
        mangleToBuffer(this, buf);

        const slice = buf[];

        // Allocate buffer on stack, fail over to using malloc()
        char[128] namebuf;

        // Hash long symbol names
        char* name;
        int length;
        if (IN_LLVM && global.params.hashThreshold && (slice.length > global.params.hashThreshold))
        {
            version(IN_LLVM) {
                import std.digest.md;
                auto md5hash = md5Of(slice);
                auto hashedname = toHexString(md5hash);
                static assert(hashedname.length < namebuf.length-30);
                name = namebuf.ptr;
                length = snprintf(name, namebuf.length, "_D%lluTypeInfo_%.*s6__initZ",
                    9LU + hashedname.length, cast(int) hashedname.length, hashedname.ptr);
            }
        }
        else
        {
        // else path is DDMD original:

        const namelen = 19 + size_t.sizeof * 3 + slice.length + 1;
        name = namelen <= namebuf.length ? namebuf.ptr : cast(char*)Mem.check(malloc(namelen));

        length = snprintf(name, namelen, "_D%lluTypeInfo_%.*s6__initZ",
                cast(ulong)(9 + slice.length), cast(int)slice.length, slice.ptr);
        //printf("%p %s, deco = %s, name = %s\n", this, toChars(), deco, name);
        assert(0 < length && length < namelen); // don't overflow the buffer

        }

        auto id = Identifier.idPool(name[0 .. length]);

        if (name != namebuf.ptr)
            free(name);
        return id;
    }

    /***************************************
     * Return !=0 if the type or any of its subtypes is wild.
     */
    int hasWild() const
    {
        return mod & MODFlags.wild;
    }

    /*************************************
     * Detect if type has pointer fields that are initialized to void.
     * Local stack variables with such void fields can remain uninitialized,
     * leading to pointer bugs.
     * Returns:
     *  true if so
     */
    bool hasVoidInitPointers()
    {
        return false;
    }

    /*************************************
     * Detect if this is an unsafe type because of the presence of `@system` members
     * Returns:
     *  true if so
     */
    bool hasSystemFields()
    {
        return false;
    }

    /***************************************
     * Returns: true if type has any invariants
     */
    bool hasInvariant()
    {
        //printf("Type::hasInvariant() %s, %d\n", toChars(), ty);
        return false;
    }

    /*************************************
     * If this is a type of something, return that something.
     */
    Type nextOf()
    {
        return null;
    }

    /*************************************
     * If this is a type of static array, return its base element type.
     */
    final Type baseElemOf()
    {
        Type t = toBasetype();
        TypeSArray tsa;
        while ((tsa = t.isTypeSArray()) !is null)
            t = tsa.next.toBasetype();
        return t;
    }

    /*******************************************
     * Compute number of elements for a (possibly multidimensional) static array,
     * or 1 for other types.
     * Params:
     *  loc = for error message
     * Returns:
     *  number of elements, uint.max on overflow
     */
    final uint numberOfElems(const ref Loc loc)
    {
        //printf("Type::numberOfElems()\n");
        uinteger_t n = 1;
        Type tb = this;
        while ((tb = tb.toBasetype()).ty == Tsarray)
        {
            bool overflow = false;
            n = mulu(n, (cast(TypeSArray)tb).dim.toUInteger(), overflow);
            if (overflow || n >= uint.max)
            {
                error(loc, "static array `%s` size overflowed to %llu", toChars(), cast(ulong)n);
                return uint.max;
            }
            tb = (cast(TypeSArray)tb).next;
        }
        return cast(uint)n;
    }

    /****************************************
     * Return the mask that an integral type will
     * fit into.
     */
    extern (D) final uinteger_t sizemask()
    {
        uinteger_t m;
        switch (toBasetype().ty)
        {
        case Tbool:
            m = 1;
            break;
        case Tchar:
        case Tint8:
        case Tuns8:
            m = 0xFF;
            break;
        case Twchar:
        case Tint16:
        case Tuns16:
            m = 0xFFFFU;
            break;
        case Tdchar:
        case Tint32:
        case Tuns32:
            m = 0xFFFFFFFFU;
            break;
        case Tint64:
        case Tuns64:
            m = 0xFFFFFFFFFFFFFFFFUL;
            break;
        default:
            assert(0);
        }
        return m;
    }

    /********************************
     * true if when type goes out of scope, it needs a destructor applied.
     * Only applies to value types, not ref types.
     */
    bool needsDestruction()
    {
        return false;
    }

    /********************************
     * true if when type is copied, it needs a copy constructor or postblit
     * applied. Only applies to value types, not ref types.
     */
    bool needsCopyOrPostblit()
    {
        return false;
    }

    /*********************************
     *
     */
    bool needsNested()
    {
        return false;
    }

    /*************************************
     * https://issues.dlang.org/show_bug.cgi?id=14488
     * Check if the inner most base type is complex or imaginary.
     * Should only give alerts when set to emit transitional messages.
     * Params:
     *  loc = The source location.
     *  sc = scope of the type
     */
    extern (D) final bool checkComplexTransition(const ref Loc loc, Scope* sc)
    {
        if (sc.isDeprecated())
            return false;
        // Don't complain if we're inside a template constraint
        // https://issues.dlang.org/show_bug.cgi?id=21831
        if (sc.flags & SCOPE.constraint)
            return false;

        Type t = baseElemOf();
        while (t.ty == Tpointer || t.ty == Tarray)
            t = t.nextOf().baseElemOf();

        // Basetype is an opaque enum, nothing to check.
        if (t.ty == Tenum && !(cast(TypeEnum)t).sym.memtype)
            return false;

        if (t.isimaginary() || t.iscomplex())
        {
            if (sc.flags & SCOPE.Cfile)
                return true;            // complex/imaginary not deprecated in C code
            Type rt;
            switch (t.ty)
            {
            case Tcomplex32:
            case Timaginary32:
                rt = Type.tfloat32;
                break;

            case Tcomplex64:
            case Timaginary64:
                rt = Type.tfloat64;
                break;

            case Tcomplex80:
            case Timaginary80:
                rt = Type.tfloat80;
                break;

            default:
                assert(0);
            }
            // @@@DEPRECATED_2.117@@@
            // Deprecated in 2.097 - Can be made an error from 2.117.
            // The deprecation period is longer than usual as `cfloat`,
            // `cdouble`, and `creal` were quite widely used.
            if (t.iscomplex())
            {
                deprecation(loc, "use of complex type `%s` is deprecated, use `std.complex.Complex!(%s)` instead",
                    toChars(), rt.toChars());
                return true;
            }
            else
            {
                deprecation(loc, "use of imaginary type `%s` is deprecated, use `%s` instead",
                    toChars(), rt.toChars());
                return true;
            }
        }
        return false;
    }

    // For eliminating dynamic_cast
    TypeBasic isTypeBasic()
    {
        return null;
    }

    final pure inout nothrow @nogc
    {
        /****************
         * Is this type a pointer to a function?
         * Returns:
         *  the function type if it is
         */
        inout(TypeFunction) isPtrToFunction()
        {
            return (ty == Tpointer && (cast(TypePointer)this).next.ty == Tfunction)
                ? cast(typeof(return))(cast(TypePointer)this).next
                : null;
        }

        /*****************
         * Is this type a function, delegate, or pointer to a function?
         * Returns:
         *  the function type if it is
         */
        inout(TypeFunction) isFunction_Delegate_PtrToFunction()
        {
            return ty == Tfunction ? cast(typeof(return))this :

                   ty == Tdelegate ? cast(typeof(return))(cast(TypePointer)this).next :

                   ty == Tpointer && (cast(TypePointer)this).next.ty == Tfunction ?
                        cast(typeof(return))(cast(TypePointer)this).next :

                   null;
        }
    }

    final pure inout nothrow @nogc @trusted
    {
        inout(TypeError)      isTypeError()      { return ty == Terror     ? cast(typeof(return))this : null; }
        inout(TypeVector)     isTypeVector()     { return ty == Tvector    ? cast(typeof(return))this : null; }
        inout(TypeSArray)     isTypeSArray()     { return ty == Tsarray    ? cast(typeof(return))this : null; }
        inout(TypeDArray)     isTypeDArray()     { return ty == Tarray     ? cast(typeof(return))this : null; }
        inout(TypeAArray)     isTypeAArray()     { return ty == Taarray    ? cast(typeof(return))this : null; }
        inout(TypePointer)    isTypePointer()    { return ty == Tpointer   ? cast(typeof(return))this : null; }
        inout(TypeReference)  isTypeReference()  { return ty == Treference ? cast(typeof(return))this : null; }
        inout(TypeFunction)   isTypeFunction()   { return ty == Tfunction  ? cast(typeof(return))this : null; }
        inout(TypeDelegate)   isTypeDelegate()   { return ty == Tdelegate  ? cast(typeof(return))this : null; }
        inout(TypeIdentifier) isTypeIdentifier() { return ty == Tident     ? cast(typeof(return))this : null; }
        inout(TypeInstance)   isTypeInstance()   { return ty == Tinstance  ? cast(typeof(return))this : null; }
        inout(TypeTypeof)     isTypeTypeof()     { return ty == Ttypeof    ? cast(typeof(return))this : null; }
        inout(TypeReturn)     isTypeReturn()     { return ty == Treturn    ? cast(typeof(return))this : null; }
        inout(TypeStruct)     isTypeStruct()     { return ty == Tstruct    ? cast(typeof(return))this : null; }
        inout(TypeEnum)       isTypeEnum()       { return ty == Tenum      ? cast(typeof(return))this : null; }
        inout(TypeClass)      isTypeClass()      { return ty == Tclass     ? cast(typeof(return))this : null; }
        inout(TypeTuple)      isTypeTuple()      { return ty == Ttuple     ? cast(typeof(return))this : null; }
        inout(TypeSlice)      isTypeSlice()      { return ty == Tslice     ? cast(typeof(return))this : null; }
        inout(TypeNull)       isTypeNull()       { return ty == Tnull      ? cast(typeof(return))this : null; }
        inout(TypeMixin)      isTypeMixin()      { return ty == Tmixin     ? cast(typeof(return))this : null; }
        inout(TypeTraits)     isTypeTraits()     { return ty == Ttraits    ? cast(typeof(return))this : null; }
        inout(TypeNoreturn)   isTypeNoreturn()   { return ty == Tnoreturn  ? cast(typeof(return))this : null; }
        inout(TypeTag)        isTypeTag()        { return ty == Ttag       ? cast(typeof(return))this : null; }
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }

    final TypeFunction toTypeFunction()
    {
        if (ty != Tfunction)
            assert(0);
        return cast(TypeFunction)this;
    }

    extern (D) static Types* arraySyntaxCopy(Types* types)
    {
        Types* a = null;
        if (types)
        {
            a = new Types(types.length);
            foreach (i, t; *types)
            {
                (*a)[i] = t ? t.syntaxCopy() : null;
            }
        }
        return a;
    }
}

/***********************************************************
 */
extern (C++) final class TypeError : Type
{
    extern (D) this() @safe
    {
        super(Terror);
    }

    override const(char)* kind() const
    {
        return "error";
    }

    override TypeError syntaxCopy()
    {
        // No semantic analysis done, no need to copy
        return this;
    }

    override uinteger_t size(const ref Loc loc)
    {
        return SIZE_INVALID;
    }

    override Expression defaultInitLiteral(const ref Loc loc)
    {
        return ErrorExp.get();
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) abstract class TypeNext : Type
{
    Type next;

    final extern (D) this(TY ty, Type next) @safe
    {
        super(ty);
        this.next = next;
    }

    override final int hasWild() const
    {
        if (ty == Tfunction)
            return 0;
        if (ty == Tdelegate)
            return Type.hasWild();
        return mod & MODFlags.wild || (next && next.hasWild());
    }

    /*******************************
     * For TypeFunction, nextOf() can return NULL if the function return
     * type is meant to be inferred, and semantic() hasn't yet ben run
     * on the function. After semantic(), it must no longer be NULL.
     */
    override final Type nextOf()
    {
        return next;
    }

    override final Type makeConst()
    {
        //printf("TypeNext::makeConst() %p, %s\n", this, toChars());
        if (mcache && mcache.cto)
        {
            assert(mcache.cto.mod == MODFlags.const_);
            return mcache.cto;
        }
        TypeNext t = cast(TypeNext)Type.makeConst();
        if (ty != Tfunction && next.ty != Tfunction && !next.isImmutable())
        {
            if (next.isShared())
            {
                if (next.isWild())
                    t.next = next.sharedWildConstOf();
                else
                    t.next = next.sharedConstOf();
            }
            else
            {
                if (next.isWild())
                    t.next = next.wildConstOf();
                else
                    t.next = next.constOf();
            }
        }
        //printf("TypeNext::makeConst() returns %p, %s\n", t, t.toChars());
        return t;
    }

    override final Type makeImmutable()
    {
        //printf("TypeNext::makeImmutable() %s\n", toChars());
        if (mcache && mcache.ito)
        {
            assert(mcache.ito.isImmutable());
            return mcache.ito;
        }
        TypeNext t = cast(TypeNext)Type.makeImmutable();
        if (ty != Tfunction && next.ty != Tfunction && !next.isImmutable())
        {
            t.next = next.immutableOf();
        }
        return t;
    }

    override final Type makeShared()
    {
        //printf("TypeNext::makeShared() %s\n", toChars());
        if (mcache && mcache.sto)
        {
            assert(mcache.sto.mod == MODFlags.shared_);
            return mcache.sto;
        }
        TypeNext t = cast(TypeNext)Type.makeShared();
        if (ty != Tfunction && next.ty != Tfunction && !next.isImmutable())
        {
            if (next.isWild())
            {
                if (next.isConst())
                    t.next = next.sharedWildConstOf();
                else
                    t.next = next.sharedWildOf();
            }
            else
            {
                if (next.isConst())
                    t.next = next.sharedConstOf();
                else
                    t.next = next.sharedOf();
            }
        }
        //printf("TypeNext::makeShared() returns %p, %s\n", t, t.toChars());
        return t;
    }

    override final Type makeSharedConst()
    {
        //printf("TypeNext::makeSharedConst() %s\n", toChars());
        if (mcache && mcache.scto)
        {
            assert(mcache.scto.mod == (MODFlags.shared_ | MODFlags.const_));
            return mcache.scto;
        }
        TypeNext t = cast(TypeNext)Type.makeSharedConst();
        if (ty != Tfunction && next.ty != Tfunction && !next.isImmutable())
        {
            if (next.isWild())
                t.next = next.sharedWildConstOf();
            else
                t.next = next.sharedConstOf();
        }
        //printf("TypeNext::makeSharedConst() returns %p, %s\n", t, t.toChars());
        return t;
    }

    override final Type makeWild()
    {
        //printf("TypeNext::makeWild() %s\n", toChars());
        if (mcache && mcache.wto)
        {
            assert(mcache.wto.mod == MODFlags.wild);
            return mcache.wto;
        }
        TypeNext t = cast(TypeNext)Type.makeWild();
        if (ty != Tfunction && next.ty != Tfunction && !next.isImmutable())
        {
            if (next.isShared())
            {
                if (next.isConst())
                    t.next = next.sharedWildConstOf();
                else
                    t.next = next.sharedWildOf();
            }
            else
            {
                if (next.isConst())
                    t.next = next.wildConstOf();
                else
                    t.next = next.wildOf();
            }
        }
        //printf("TypeNext::makeWild() returns %p, %s\n", t, t.toChars());
        return t;
    }

    override final Type makeWildConst()
    {
        //printf("TypeNext::makeWildConst() %s\n", toChars());
        if (mcache && mcache.wcto)
        {
            assert(mcache.wcto.mod == MODFlags.wildconst);
            return mcache.wcto;
        }
        TypeNext t = cast(TypeNext)Type.makeWildConst();
        if (ty != Tfunction && next.ty != Tfunction && !next.isImmutable())
        {
            if (next.isShared())
                t.next = next.sharedWildConstOf();
            else
                t.next = next.wildConstOf();
        }
        //printf("TypeNext::makeWildConst() returns %p, %s\n", t, t.toChars());
        return t;
    }

    override final Type makeSharedWild()
    {
        //printf("TypeNext::makeSharedWild() %s\n", toChars());
        if (mcache && mcache.swto)
        {
            assert(mcache.swto.isSharedWild());
            return mcache.swto;
        }
        TypeNext t = cast(TypeNext)Type.makeSharedWild();
        if (ty != Tfunction && next.ty != Tfunction && !next.isImmutable())
        {
            if (next.isConst())
                t.next = next.sharedWildConstOf();
            else
                t.next = next.sharedWildOf();
        }
        //printf("TypeNext::makeSharedWild() returns %p, %s\n", t, t.toChars());
        return t;
    }

    override final Type makeSharedWildConst()
    {
        //printf("TypeNext::makeSharedWildConst() %s\n", toChars());
        if (mcache && mcache.swcto)
        {
            assert(mcache.swcto.mod == (MODFlags.shared_ | MODFlags.wildconst));
            return mcache.swcto;
        }
        TypeNext t = cast(TypeNext)Type.makeSharedWildConst();
        if (ty != Tfunction && next.ty != Tfunction && !next.isImmutable())
        {
            t.next = next.sharedWildConstOf();
        }
        //printf("TypeNext::makeSharedWildConst() returns %p, %s\n", t, t.toChars());
        return t;
    }

    override final Type makeMutable()
    {
        //printf("TypeNext::makeMutable() %p, %s\n", this, toChars());
        TypeNext t = cast(TypeNext)Type.makeMutable();
        if (ty == Tsarray)
        {
            t.next = next.mutableOf();
        }
        //printf("TypeNext::makeMutable() returns %p, %s\n", t, t.toChars());
        return t;
    }

    override MATCH constConv(Type to)
    {
        //printf("TypeNext::constConv from = %s, to = %s\n", toChars(), to.toChars());
        if (equals(to))
            return MATCH.exact;

        if (!(ty == to.ty && MODimplicitConv(mod, to.mod)))
            return MATCH.nomatch;

        Type tn = to.nextOf();
        if (!(tn && next.ty == tn.ty))
            return MATCH.nomatch;

        MATCH m;
        if (to.isConst()) // whole tail const conversion
        {
            // Recursive shared level check
            m = next.constConv(tn);
            if (m == MATCH.exact)
                m = MATCH.constant;
        }
        else
        {
            //printf("\tnext => %s, to.next => %s\n", next.toChars(), tn.toChars());
            m = next.equals(tn) ? MATCH.constant : MATCH.nomatch;
        }
        return m;
    }

    override final MOD deduceWild(Type t, bool isRef)
    {
        if (ty == Tfunction)
            return 0;

        ubyte wm;

        Type tn = t.nextOf();
        if (!isRef && (ty == Tarray || ty == Tpointer) && tn)
        {
            wm = next.deduceWild(tn, true);
            if (!wm)
                wm = Type.deduceWild(t, true);
        }
        else
        {
            wm = Type.deduceWild(t, isRef);
            if (!wm && tn)
                wm = next.deduceWild(tn, true);
        }

        return wm;
    }

    final void transitive()
    {
        /* Invoke transitivity of type attributes
         */
        next = next.addMod(mod);
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeBasic : Type
{
    const(char)* dstring;
    uint flags;

    extern (D) this(TY ty) scope
    {
        super(ty);
        const(char)* d;
        uint flags = 0;
        switch (ty)
        {
        case Tvoid:
            d = Token.toChars(TOK.void_);
            break;

        case Tint8:
            d = Token.toChars(TOK.int8);
            flags |= TFlags.integral;
            break;

        case Tuns8:
            d = Token.toChars(TOK.uns8);
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        case Tint16:
            d = Token.toChars(TOK.int16);
            flags |= TFlags.integral;
            break;

        case Tuns16:
            d = Token.toChars(TOK.uns16);
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        case Tint32:
            d = Token.toChars(TOK.int32);
            flags |= TFlags.integral;
            break;

        case Tuns32:
            d = Token.toChars(TOK.uns32);
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        case Tfloat32:
            d = Token.toChars(TOK.float32);
            flags |= TFlags.floating | TFlags.real_;
            break;

        case Tint64:
            d = Token.toChars(TOK.int64);
            flags |= TFlags.integral;
            break;

        case Tuns64:
            d = Token.toChars(TOK.uns64);
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        case Tint128:
            d = Token.toChars(TOK.int128);
            flags |= TFlags.integral;
            break;

        case Tuns128:
            d = Token.toChars(TOK.uns128);
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        case Tfloat64:
            d = Token.toChars(TOK.float64);
            flags |= TFlags.floating | TFlags.real_;
            break;

        case Tfloat80:
            d = Token.toChars(TOK.float80);
            flags |= TFlags.floating | TFlags.real_;
            break;

        case Timaginary32:
            d = Token.toChars(TOK.imaginary32);
            flags |= TFlags.floating | TFlags.imaginary;
            break;

        case Timaginary64:
            d = Token.toChars(TOK.imaginary64);
            flags |= TFlags.floating | TFlags.imaginary;
            break;

        case Timaginary80:
            d = Token.toChars(TOK.imaginary80);
            flags |= TFlags.floating | TFlags.imaginary;
            break;

        case Tcomplex32:
            d = Token.toChars(TOK.complex32);
            flags |= TFlags.floating | TFlags.complex;
            break;

        case Tcomplex64:
            d = Token.toChars(TOK.complex64);
            flags |= TFlags.floating | TFlags.complex;
            break;

        case Tcomplex80:
            d = Token.toChars(TOK.complex80);
            flags |= TFlags.floating | TFlags.complex;
            break;

        case Tbool:
            d = "bool";
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        case Tchar:
            d = Token.toChars(TOK.char_);
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        case Twchar:
            d = Token.toChars(TOK.wchar_);
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        case Tdchar:
            d = Token.toChars(TOK.dchar_);
            flags |= TFlags.integral | TFlags.unsigned;
            break;

        default:
            assert(0);
        }
        this.dstring = d;
        this.flags = flags;
        merge(this);
    }

    override const(char)* kind() const
    {
        return dstring;
    }

    override TypeBasic syntaxCopy()
    {
        // No semantic analysis done on basic types, no need to copy
        return this;
    }

    override uinteger_t size(const ref Loc loc)
    {
        uint size;
        //printf("TypeBasic::size()\n");
        switch (ty)
        {
        case Tint8:
        case Tuns8:
            size = 1;
            break;

        case Tint16:
        case Tuns16:
            size = 2;
            break;

        case Tint32:
        case Tuns32:
        case Tfloat32:
        case Timaginary32:
            size = 4;
            break;

        case Tint64:
        case Tuns64:
        case Tfloat64:
        case Timaginary64:
            size = 8;
            break;

        case Tfloat80:
        case Timaginary80:
            size = target.realsize;
            break;

        case Tcomplex32:
            size = 8;
            break;

        case Tcomplex64:
        case Tint128:
        case Tuns128:
            size = 16;
            break;

        case Tcomplex80:
            size = target.realsize * 2;
            break;

        case Tvoid:
            //size = Type::size();      // error message
            size = 1;
            break;

        case Tbool:
            size = 1;
            break;

        case Tchar:
            size = 1;
            break;

        case Twchar:
            size = 2;
            break;

        case Tdchar:
            size = 4;
            break;

        default:
            assert(0);
        }
        //printf("TypeBasic::size() = %d\n", size);
        return size;
    }

    override uint alignsize()
    {
        return target.alignsize(this);
    }

    override bool isintegral()
    {
        //printf("TypeBasic::isintegral('%s') x%x\n", toChars(), flags);
        return (flags & TFlags.integral) != 0;
    }

    override bool isfloating()
    {
        return (flags & TFlags.floating) != 0;
    }

    override bool isreal()
    {
        return (flags & TFlags.real_) != 0;
    }

    override bool isimaginary()
    {
        return (flags & TFlags.imaginary) != 0;
    }

    override bool iscomplex()
    {
        return (flags & TFlags.complex) != 0;
    }

    override bool isscalar()
    {
        return (flags & (TFlags.integral | TFlags.floating)) != 0;
    }

    override bool isunsigned()
    {
        return (flags & TFlags.unsigned) != 0;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeBasic::implicitConvTo(%s) from %s\n", to.toChars(), toChars());
        if (this == to)
            return MATCH.exact;

        if (ty == to.ty)
        {
            if (mod == to.mod)
                return MATCH.exact;
            else if (MODimplicitConv(mod, to.mod))
                return MATCH.constant;
            else if (!((mod ^ to.mod) & MODFlags.shared_)) // for wild matching
                return MATCH.constant;
            else
                return MATCH.convert;
        }

        if (ty == Tvoid || to.ty == Tvoid)
            return MATCH.nomatch;
        if (to.ty == Tbool)
            return MATCH.nomatch;

        TypeBasic tob;
        if (to.ty == Tvector && to.deco)
        {
            TypeVector tv = cast(TypeVector)to;
            tob = tv.elementType();
        }
        else if (auto te = to.isTypeEnum())
        {
            EnumDeclaration ed = te.sym;
            if (ed.isSpecial())
            {
                /* Special enums that allow implicit conversions to them
                 * with a MATCH.convert
                 */
                tob = to.toBasetype().isTypeBasic();
            }
            else
                return MATCH.nomatch;
        }
        else
            tob = to.isTypeBasic();
        if (!tob)
            return MATCH.nomatch;

        if (flags & TFlags.integral)
        {
            // Disallow implicit conversion of integers to imaginary or complex
            if (tob.flags & (TFlags.imaginary | TFlags.complex))
                return MATCH.nomatch;

            // If converting from integral to integral
            if (tob.flags & TFlags.integral)
            {
                const sz = size(Loc.initial);
                const tosz = tob.size(Loc.initial);

                /* Can't convert to smaller size
                 */
                if (sz > tosz)
                    return MATCH.nomatch;
                /* Can't change sign if same size
                 */
                //if (sz == tosz && (flags ^ tob.flags) & TFlags.unsigned)
                //    return MATCH.nomatch;
            }
        }
        else if (flags & TFlags.floating)
        {
            // Disallow implicit conversion of floating point to integer
            if (tob.flags & TFlags.integral)
                return MATCH.nomatch;

            assert(tob.flags & TFlags.floating || to.ty == Tvector);

            // Disallow implicit conversion from complex to non-complex
            if (flags & TFlags.complex && !(tob.flags & TFlags.complex))
                return MATCH.nomatch;

            // Disallow implicit conversion of real or imaginary to complex
            if (flags & (TFlags.real_ | TFlags.imaginary) && tob.flags & TFlags.complex)
                return MATCH.nomatch;

            // Disallow implicit conversion to-from real and imaginary
            if ((flags & (TFlags.real_ | TFlags.imaginary)) != (tob.flags & (TFlags.real_ | TFlags.imaginary)))
                return MATCH.nomatch;
        }
        return MATCH.convert;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        switch (ty)
        {
        case Tchar:
        case Twchar:
        case Tdchar:
        case Timaginary32:
        case Timaginary64:
        case Timaginary80:
        case Tfloat32:
        case Tfloat64:
        case Tfloat80:
        case Tcomplex32:
        case Tcomplex64:
        case Tcomplex80:
            return false; // no
        default:
            return true; // yes
        }
    }

    // For eliminating dynamic_cast
    override TypeBasic isTypeBasic()
    {
        return this;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 * The basetype must be one of:
 *   byte[16],ubyte[16],short[8],ushort[8],int[4],uint[4],long[2],ulong[2],float[4],double[2]
 * For AVX:
 *   byte[32],ubyte[32],short[16],ushort[16],int[8],uint[8],long[4],ulong[4],float[8],double[4]
 */
extern (C++) final class TypeVector : Type
{
    Type basetype;

    extern (D) this(Type basetype) @safe
    {
        super(Tvector);
        this.basetype = basetype;
    }

    static TypeVector create(Type basetype) @safe
    {
        return new TypeVector(basetype);
    }

    override const(char)* kind() const
    {
        return "vector";
    }

    override TypeVector syntaxCopy()
    {
        return new TypeVector(basetype.syntaxCopy());
    }

    override uinteger_t size(const ref Loc loc)
    {
        return basetype.size();
    }

    override uint alignsize()
    {
        return cast(uint)basetype.size();
    }

    override bool isintegral()
    {
        //printf("TypeVector::isintegral('%s') x%x\n", toChars(), flags);
        return basetype.nextOf().isintegral();
    }

    override bool isfloating()
    {
        return basetype.nextOf().isfloating();
    }

    override bool isscalar()
    {
        return basetype.nextOf().isscalar();
    }

    override bool isunsigned()
    {
        return basetype.nextOf().isunsigned();
    }

    override bool isBoolean()
    {
        return false;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeVector::implicitConvTo(%s) from %s\n", to.toChars(), toChars());
        if (this == to)
            return MATCH.exact;
        if (to.ty != Tvector)
            return MATCH.nomatch;

        TypeVector tv = cast(TypeVector)to;
        assert(basetype.ty == Tsarray && tv.basetype.ty == Tsarray);

        // Can't convert to a vector which has different size.
        if (basetype.size() != tv.basetype.size())
            return MATCH.nomatch;

        // Allow conversion to void[]
        if (tv.basetype.nextOf().ty == Tvoid)
            return MATCH.convert;

        // Otherwise implicitly convertible only if basetypes are.
        return basetype.implicitConvTo(tv.basetype);
    }

    override Expression defaultInitLiteral(const ref Loc loc)
    {
        //printf("TypeVector::defaultInitLiteral()\n");
        assert(basetype.ty == Tsarray);
        Expression e = basetype.defaultInitLiteral(loc);
        auto ve = new VectorExp(loc, e, this);
        ve.type = this;
        ve.dim = cast(int)(basetype.size(loc) / elementType().size(loc));
        return ve;
    }

    TypeBasic elementType()
    {
        assert(basetype.ty == Tsarray);
        TypeSArray t = cast(TypeSArray)basetype;
        TypeBasic tb = t.nextOf().isTypeBasic();
        assert(tb);
        return tb;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return basetype.isZeroInit(loc);
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) abstract class TypeArray : TypeNext
{
    final extern (D) this(TY ty, Type next) @safe
    {
        super(ty, next);
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 * Static array, one with a fixed dimension
 */
extern (C++) final class TypeSArray : TypeArray
{
    Expression dim;

    extern (D) this(Type t, Expression dim) @safe
    {
        super(Tsarray, t);
        //printf("TypeSArray(%s)\n", dim.toChars());
        this.dim = dim;
    }

    extern (D) this(Type t)  // for incomplete type
    {
        super(Tsarray, t);
        //printf("TypeSArray()\n");
        this.dim = new IntegerExp(0);
    }

    override const(char)* kind() const
    {
        return "sarray";
    }

    override TypeSArray syntaxCopy()
    {
        Type t = next.syntaxCopy();
        Expression e = dim.syntaxCopy();
        auto result = new TypeSArray(t, e);
        result.mod = mod;
        return result;
    }

    /***
     * C11 6.7.6.2-4 incomplete array type
     * Returns: true if incomplete type
     */
    bool isIncomplete()
    {
        return dim.isIntegerExp() && dim.isIntegerExp().getInteger() == 0;
    }

    override uinteger_t size(const ref Loc loc)
    {
        //printf("TypeSArray::size()\n");
        const n = numberOfElems(loc);
        const elemsize = baseElemOf().size(loc);
        bool overflow = false;
        const sz = mulu(n, elemsize, overflow);
        if (overflow || sz >= uint.max)
        {
            if (elemsize != SIZE_INVALID && n != uint.max)
                error(loc, "static array `%s` size overflowed to %lld", toChars(), cast(long)sz);
            return SIZE_INVALID;
        }
        return sz;
    }

    override uint alignsize()
    {
        return next.alignsize();
    }

    override bool isString()
    {
        TY nty = next.toBasetype().ty;
        return nty.isSomeChar;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return next.isZeroInit(loc);
    }

    override structalign_t alignment()
    {
        return next.alignment();
    }

    override MATCH constConv(Type to)
    {
        if (auto tsa = to.isTypeSArray())
        {
            if (!dim.equals(tsa.dim))
                return MATCH.nomatch;
        }
        return TypeNext.constConv(to);
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeSArray::implicitConvTo(to = %s) this = %s\n", to.toChars(), toChars());
        if (auto ta = to.isTypeDArray())
        {
            if (!MODimplicitConv(next.mod, ta.next.mod))
                return MATCH.nomatch;

            /* Allow conversion to void[]
             */
            if (ta.next.ty == Tvoid)
            {
                return MATCH.convert;
            }

            MATCH m = next.constConv(ta.next);
            if (m > MATCH.nomatch)
            {
                return MATCH.convert;
            }
            return MATCH.nomatch;
        }
        if (auto tsa = to.isTypeSArray())
        {
            if (this == to)
                return MATCH.exact;

            if (dim.equals(tsa.dim))
            {
                MATCH m = next.implicitConvTo(tsa.next);

                /* Allow conversion to non-interface base class.
                 */
                if (m == MATCH.convert &&
                    next.ty == Tclass)
                {
                    if (auto toc = tsa.next.isTypeClass)
                    {
                        if (!toc.sym.isInterfaceDeclaration)
                            return MATCH.convert;
                    }
                }

                /* Since static arrays are value types, allow
                 * conversions from const elements to non-const
                 * ones, just like we allow conversion from const int
                 * to int.
                 */
                if (m >= MATCH.constant)
                {
                    if (mod != to.mod)
                        m = MATCH.constant;
                    return m;
                }
            }
        }
        return MATCH.nomatch;
    }

    override Expression defaultInitLiteral(const ref Loc loc)
    {
        static if (LOGDEFAULTINIT)
        {
            printf("TypeSArray::defaultInitLiteral() '%s'\n", toChars());
        }
        size_t d = cast(size_t)dim.toInteger();
        Expression elementinit;
        if (next.ty == Tvoid)
            elementinit = tuns8.defaultInitLiteral(loc);
        else
            elementinit = next.defaultInitLiteral(loc);
        auto elements = new Expressions(d);
        foreach (ref e; *elements)
            e = null;
        auto ae = new ArrayLiteralExp(Loc.initial, this, elementinit, elements);
        return ae;
    }

    override bool hasSystemFields()
    {
        return next.hasSystemFields();
    }

    override bool hasVoidInitPointers()
    {
        return next.hasVoidInitPointers();
    }

    override bool hasInvariant()
    {
        return next.hasInvariant();
    }

    override bool needsDestruction()
    {
        return next.needsDestruction();
    }

    override bool needsCopyOrPostblit()
    {
        return next.needsCopyOrPostblit();
    }

    /*********************************
     *
     */
    override bool needsNested()
    {
        return next.needsNested();
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 * Dynamic array, no dimension
 */
extern (C++) final class TypeDArray : TypeArray
{
    extern (D) this(Type t) @safe
    {
        super(Tarray, t);
        //printf("TypeDArray(t = %p)\n", t);
    }

    override const(char)* kind() const
    {
        return "darray";
    }

    override TypeDArray syntaxCopy()
    {
        Type t = next.syntaxCopy();
        if (t == next)
            return this;

        auto result = new TypeDArray(t);
        result.mod = mod;
        return result;
    }

    override uinteger_t size(const ref Loc loc)
    {
        //printf("TypeDArray::size()\n");
        return target.ptrsize * 2;
    }

    override uint alignsize()
    {
        // A DArray consists of two ptr-sized values, so align it on pointer size
        // boundary
        return target.ptrsize;
    }

    override bool isString()
    {
        TY nty = next.toBasetype().ty;
        return nty.isSomeChar;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return true;
    }

    override bool isBoolean()
    {
        return true;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeDArray::implicitConvTo(to = %s) this = %s\n", to.toChars(), toChars());
        if (equals(to))
            return MATCH.exact;

        if (auto ta = to.isTypeDArray())
        {
            if (!MODimplicitConv(next.mod, ta.next.mod))
                return MATCH.nomatch; // not const-compatible

            /* Allow conversion to void[]
             */
            if (next.ty != Tvoid && ta.next.ty == Tvoid)
            {
                return MATCH.convert;
            }

            MATCH m = next.constConv(ta.next);
            if (m > MATCH.nomatch)
            {
                if (m == MATCH.exact && mod != to.mod)
                    m = MATCH.constant;
                return m;
            }
        }
        return Type.implicitConvTo(to);
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeAArray : TypeArray
{
    Type index;     // key type
    Loc loc;

    extern (D) this(Type t, Type index) @safe
    {
        super(Taarray, t);
        this.index = index;
    }

    static TypeAArray create(Type t, Type index) @safe
    {
        return new TypeAArray(t, index);
    }

    override const(char)* kind() const
    {
        return "aarray";
    }

    override TypeAArray syntaxCopy()
    {
        Type t = next.syntaxCopy();
        Type ti = index.syntaxCopy();
        if (t == next && ti == index)
            return this;

        auto result = new TypeAArray(t, ti);
        result.mod = mod;
        return result;
    }

    override uinteger_t size(const ref Loc loc)
    {
        return target.ptrsize;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return true;
    }

    override bool isBoolean()
    {
        return true;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeAArray::implicitConvTo(to = %s) this = %s\n", to.toChars(), toChars());
        if (equals(to))
            return MATCH.exact;

        if (auto ta = to.isTypeAArray())
        {
            if (!MODimplicitConv(next.mod, ta.next.mod))
                return MATCH.nomatch; // not const-compatible

            if (!MODimplicitConv(index.mod, ta.index.mod))
                return MATCH.nomatch; // not const-compatible

            MATCH m = next.constConv(ta.next);
            MATCH mi = index.constConv(ta.index);
            if (m > MATCH.nomatch && mi > MATCH.nomatch)
            {
                return MODimplicitConv(mod, to.mod) ? MATCH.constant : MATCH.nomatch;
            }
        }
        return Type.implicitConvTo(to);
    }

    override MATCH constConv(Type to)
    {
        if (auto taa = to.isTypeAArray())
        {
            MATCH mindex = index.constConv(taa.index);
            MATCH mkey = next.constConv(taa.next);
            // Pick the worst match
            return mkey < mindex ? mkey : mindex;
        }
        return Type.constConv(to);
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypePointer : TypeNext
{
    extern (D) this(Type t) @safe
    {
        super(Tpointer, t);
    }

    static TypePointer create(Type t) @safe
    {
        return new TypePointer(t);
    }

    override const(char)* kind() const
    {
        return "pointer";
    }

    override TypePointer syntaxCopy()
    {
        Type t = next.syntaxCopy();
        if (t == next)
            return this;

        auto result = new TypePointer(t);
        result.mod = mod;
        return result;
    }

    override uinteger_t size(const ref Loc loc)
    {
        return target.ptrsize;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypePointer::implicitConvTo(to = %s) %s\n", to.toChars(), toChars());
        if (equals(to))
            return MATCH.exact;

        // Only convert between pointers
        auto tp = to.isTypePointer();
        if (!tp)
            return MATCH.nomatch;

        assert(this.next);
        assert(tp.next);

        // Conversion to void*
        if (tp.next.ty == Tvoid)
        {
            // Function pointer conversion doesn't check constness?
            if (this.next.ty == Tfunction)
                return MATCH.convert;

            if (!MODimplicitConv(next.mod, tp.next.mod))
                return MATCH.nomatch; // not const-compatible

            return this.next.ty == Tvoid ? MATCH.constant : MATCH.convert;
        }

        // Conversion between function pointers
        if (auto thisTf = this.next.isTypeFunction())
            return thisTf.implicitPointerConv(tp.next);

        // Default, no implicit conversion between the pointer targets
        MATCH m = next.constConv(tp.next);

        if (m == MATCH.exact && mod != to.mod)
            m = MATCH.constant;
        return m;
    }

    override MATCH constConv(Type to)
    {
        if (next.ty == Tfunction)
        {
            if (to.nextOf() && next.equals((cast(TypeNext)to).next))
                return Type.constConv(to);
            else
                return MATCH.nomatch;
        }
        return TypeNext.constConv(to);
    }

    override bool isscalar()
    {
        return true;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return true;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeReference : TypeNext
{
    extern (D) this(Type t) @safe
    {
        super(Treference, t);
        // BUG: what about references to static arrays?
    }

    override const(char)* kind() const
    {
        return "reference";
    }

    override TypeReference syntaxCopy()
    {
        Type t = next.syntaxCopy();
        if (t == next)
            return this;

        auto result = new TypeReference(t);
        result.mod = mod;
        return result;
    }

    override uinteger_t size(const ref Loc loc)
    {
        return target.ptrsize;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return true;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

enum RET : int
{
    regs         = 1,    // returned in registers
    stack        = 2,    // returned on stack
}

enum TRUSTformat : int
{
    TRUSTformatDefault,     // do not emit @system when trust == TRUST.default_
    TRUSTformatSystem,      // emit @system when trust == TRUST.default_
}

alias TRUSTformatDefault = TRUSTformat.TRUSTformatDefault;
alias TRUSTformatSystem = TRUSTformat.TRUSTformatSystem;

/***********************************************************
 */
extern (C++) final class TypeFunction : TypeNext
{
    // .next is the return type

    ParameterList parameterList;   // function parameters

    // These flags can be accessed like `bool` properties,
    // getters and setters are generated for them
    private extern (D) static struct BitFields
    {
        bool isnothrow;        /// nothrow
        bool isnogc;           /// is @nogc
        bool isproperty;       /// can be called without parentheses
        bool isref;            /// returns a reference
        bool isreturn;         /// 'this' is returned by ref
        bool isScopeQual;      /// 'this' is scope
        bool isreturninferred; /// 'this' is return from inference
        bool isscopeinferred;  /// 'this' is scope from inference
        bool islive;           /// is @live
        bool incomplete;       /// return type or default arguments removed
        bool isInOutParam;     /// inout on the parameters
        bool isInOutQual;      /// inout on the qualifier
        bool isctor;           /// the function is a constructor
        bool isreturnscope;    /// `this` is returned by value
    }

    import dmd.common.bitfields : generateBitFields;
    mixin(generateBitFields!(BitFields, ushort));

    LINK linkage;               // calling convention
    TRUST trust;                // level of trust
    PURE purity = PURE.impure;
    byte inuse;
    ArgumentList inferenceArguments; // function arguments to determine `auto ref` in type semantic

    extern (D) this(ParameterList pl, Type treturn, LINK linkage, StorageClass stc = 0) @safe
    {
        super(Tfunction, treturn);
        //if (!treturn) *(char*)0=0;
        //    assert(treturn);
        assert(VarArg.none <= pl.varargs && pl.varargs <= VarArg.max);
        this.parameterList = pl;
        this.linkage = linkage;

        if (stc & STC.pure_)
            this.purity = PURE.fwdref;
        if (stc & STC.nothrow_)
            this.isnothrow = true;
        if (stc & STC.nogc)
            this.isnogc = true;
        if (stc & STC.property)
            this.isproperty = true;
        if (stc & STC.live)
            this.islive = true;

        if (stc & STC.ref_)
            this.isref = true;
        if (stc & STC.return_)
            this.isreturn = true;
        if (stc & STC.returnScope)
            this.isreturnscope = true;
        if (stc & STC.returninferred)
            this.isreturninferred = true;
        if (stc & STC.scope_)
            this.isScopeQual = true;
        if (stc & STC.scopeinferred)
            this.isscopeinferred = true;

        this.trust = TRUST.default_;
        if (stc & STC.safe)
            this.trust = TRUST.safe;
        else if (stc & STC.system)
            this.trust = TRUST.system;
        else if (stc & STC.trusted)
            this.trust = TRUST.trusted;
    }

    static TypeFunction create(Parameters* parameters, Type treturn, ubyte varargs, LINK linkage, StorageClass stc = 0) @safe
    {
        return new TypeFunction(ParameterList(parameters, cast(VarArg)varargs), treturn, linkage, stc);
    }

    override const(char)* kind() const
    {
        return "function";
    }

    override TypeFunction syntaxCopy()
    {
        Type treturn = next ? next.syntaxCopy() : null;
        auto t = new TypeFunction(parameterList.syntaxCopy(), treturn, linkage);
        t.mod = mod;
        t.isnothrow = isnothrow;
        t.isnogc = isnogc;
        t.islive = islive;
        t.purity = purity;
        t.isproperty = isproperty;
        t.isref = isref;
        t.isreturn = isreturn;
        t.isreturnscope = isreturnscope;
        t.isScopeQual = isScopeQual;
        t.isreturninferred = isreturninferred;
        t.isscopeinferred = isscopeinferred;
        t.isInOutParam = isInOutParam;
        t.isInOutQual = isInOutQual;
        t.trust = trust;
        t.inferenceArguments = inferenceArguments;
        t.isctor = isctor;
        return t;
    }

    /********************************************
     * Set 'purity' field of 'this'.
     * Do this lazily, as the parameter types might be forward referenced.
     */
    void purityLevel()
    {
        TypeFunction tf = this;
        if (tf.purity != PURE.fwdref)
            return;

        purity = PURE.const_; // assume strong until something weakens it

        /* Evaluate what kind of purity based on the modifiers for the parameters
         */
        foreach (i, fparam; tf.parameterList)
        {
            Type t = fparam.type;
            if (!t)
                continue;

            if (fparam.unpack)
            {
                fparam.unpack.propagateStorageClasses();
                fparam.storageClass |= fparam.unpack.storage_class;
            }

            if (fparam.storageClass & (STC.lazy_ | STC.out_))
            {
                purity = PURE.weak;
                break;
            }
            const pref = (fparam.storageClass & STC.ref_) != 0;
            if (mutabilityOfType(pref, t) == 0)
                purity = PURE.weak;
        }

        tf.purity = purity;
    }

    /********************************************
     * Return true if there are lazy parameters.
     */
    bool hasLazyParameters()
    {
        foreach (i, fparam; parameterList)
        {
            if (fparam.isLazy())
                return true;
        }
        return false;
    }

    /*******************************
     * Check for `extern (D) U func(T t, ...)` variadic function type,
     * which has `_arguments[]` added as the first argument.
     * Returns:
     *  true if D-style variadic
     */
    bool isDstyleVariadic() const pure nothrow
    {
        return linkage == LINK.d && parameterList.varargs == VarArg.variadic;
    }

    override Type addStorageClass(StorageClass stc)
    {
        //printf("addStorageClass(%llx) %d\n", stc, (stc & STC.scope_) != 0);
        TypeFunction t = Type.addStorageClass(stc).toTypeFunction();
        if ((stc & STC.pure_ && !t.purity) ||
            (stc & STC.nothrow_ && !t.isnothrow) ||
            (stc & STC.nogc && !t.isnogc) ||
            (stc & STC.scope_ && !t.isScopeQual) ||
            (stc & STC.safe && t.trust < TRUST.trusted))
        {
            // Klunky to change these
            auto tf = new TypeFunction(t.parameterList, t.next, t.linkage, 0);
            tf.mod = t.mod;
            tf.inferenceArguments = inferenceArguments;
            tf.purity = t.purity;
            tf.isnothrow = t.isnothrow;
            tf.isnogc = t.isnogc;
            tf.isproperty = t.isproperty;
            tf.isref = t.isref;
            tf.isreturn = t.isreturn;
            tf.isreturnscope = t.isreturnscope;
            tf.isScopeQual = t.isScopeQual;
            tf.isreturninferred = t.isreturninferred;
            tf.isscopeinferred = t.isscopeinferred;
            tf.trust = t.trust;
            tf.isInOutParam = t.isInOutParam;
            tf.isInOutQual = t.isInOutQual;
            tf.isctor = t.isctor;

            if (stc & STC.pure_)
                tf.purity = PURE.fwdref;
            if (stc & STC.nothrow_)
                tf.isnothrow = true;
            if (stc & STC.nogc)
                tf.isnogc = true;
            if (stc & STC.safe)
                tf.trust = TRUST.safe;
            if (stc & STC.scope_)
            {
                tf.isScopeQual = true;
                if (stc & STC.scopeinferred)
                    tf.isscopeinferred = true;
            }

            tf.deco = tf.merge().deco;
            t = tf;
        }
        return t;
    }

    override Type substWildTo(uint)
    {
        if (!iswild && !(mod & MODFlags.wild))
            return this;

        // Substitude inout qualifier of function type to mutable or immutable
        // would break type system. Instead substitude inout to the most weak
        // qualifer - const.
        uint m = MODFlags.const_;

        assert(next);
        Type tret = next.substWildTo(m);
        Parameters* params = parameterList.parameters;
        if (mod & MODFlags.wild)
            params = parameterList.parameters.copy();
        for (size_t i = 0; i < params.length; i++)
        {
            Parameter p = (*params)[i];
            Type t = p.type.substWildTo(m);
            if (t == p.type)
                continue;
            if (params == parameterList.parameters)
                params = parameterList.parameters.copy();
            (*params)[i] = new Parameter(p.loc, p.storageClass, t, null, null, null, null);
        }
        if (next == tret && params == parameterList.parameters)
            return this;

        // Similar to TypeFunction::syntaxCopy;
        auto t = new TypeFunction(ParameterList(params, parameterList.varargs), tret, linkage);
        t.mod = ((mod & MODFlags.wild) ? (mod & ~MODFlags.wild) | MODFlags.const_ : mod);
        t.isnothrow = isnothrow;
        t.isnogc = isnogc;
        t.purity = purity;
        t.isproperty = isproperty;
        t.isref = isref;
        t.isreturn = isreturn;
        t.isreturnscope = isreturnscope;
        t.isScopeQual = isScopeQual;
        t.isreturninferred = isreturninferred;
        t.isscopeinferred = isscopeinferred;
        t.isInOutParam = false;
        t.isInOutQual = false;
        t.trust = trust;
        t.inferenceArguments = inferenceArguments;
        t.isctor = isctor;
        return t.merge();
    }

    extern(D) static const(char)* getMatchError(A...)(const(char)* format, A args)
    {
        if (global.gag && !global.params.v.showGaggedErrors)
            return null;
        OutBuffer buf;
        buf.printf(format, args);
        return buf.extractChars();
    }

    /********************************
     * Convert an `argumentList`, which may contain named arguments, into
     * a list of arguments in the order of the parameter list.
     *
     * Params:
     *      argumentList = array of function arguments
     *      pMessage = address to store error message, or `null`
     * Returns: re-ordered argument list, or `null` on error
     */
    extern(D) Expressions* resolveNamedArgs(ArgumentList argumentList, const(char)** pMessage)
    {
        Expression[] args = argumentList.arguments ? (*argumentList.arguments)[] : null;
        Identifier[] names = argumentList.names ? (*argumentList.names)[] : null;
        const nParams = parameterList.length(); // cached because O(n)
        auto newArgs = new Expressions(nParams);
        newArgs.zero();
        size_t ci = 0;
        bool hasNamedArgs = false;
        const bool isVariadic = parameterList.varargs != VarArg.none;
        foreach (i, arg; args)
        {
            if (!arg)
            {
                ci++;
                continue;
            }
            auto name = i < names.length ? names[i] : null;
            if (name)
            {
                hasNamedArgs = true;
                const pi = findParameterIndex(name);
                if (pi == -1)
                {
                    if (pMessage)
                        *pMessage = getMatchError("no parameter named `%s`", name.toChars());
                    return null;
                }
                ci = pi;
            }
            if (ci >= newArgs.length)
            {
                if (!isVariadic)
                {
                    // Without named args, let the caller diagnose argument overflow
                    if (hasNamedArgs && pMessage)
                        *pMessage = getMatchError("argument `%s` goes past end of parameter list", arg.toChars());
                    return null;
                }
                while (ci >= newArgs.length)
                    newArgs.push(null);
            }

            if ((*newArgs)[ci])
            {
                if (pMessage)
                    *pMessage = getMatchError("parameter `%s` assigned twice", parameterList[ci].toChars());
                return null;
            }
            (*newArgs)[ci++] = arg;
        }
        foreach (i, arg; (*newArgs)[])
        {
            if (arg || parameterList[i].defaultArg)
                continue;

            if (isVariadic && i + 1 == newArgs.length)
                continue;

            // dtemplate sets `defaultArg=null` to avoid semantic on default arguments,
            // don't complain about missing arguments in that case
            if (this.incomplete)
                continue;

            if (pMessage)
                *pMessage = getMatchError("missing argument for parameter #%d: `%s`",
                    i + 1, parameterToChars(parameterList[i], this, false));
            return null;
        }
        // strip trailing nulls from default arguments
        size_t e = newArgs.length;
        while (e > 0 && (*newArgs)[e - 1] is null)
        {
            --e;
        }
        newArgs.setDim(e);
        return newArgs;
    }

    /+
     + Checks whether this function type is convertible to ` to`
     + when used in a function pointer / delegate.
     +
     + Params:
     +   to = target type
     +
     + Returns:
     +   MATCH.nomatch: `to` is not a covaraint function
     +   MATCH.convert: `to` is a covaraint function
     +   MATCH.exact:   `to` is identical to this function
     +/
    private MATCH implicitPointerConv(Type to)
    {
        assert(to);

        if (this.equals(to))
            return MATCH.constant;

        if (this.covariant(to) == Covariant.yes)
        {
            Type tret = this.nextOf();
            Type toret = to.nextOf();
            if (tret.ty == Tclass && toret.ty == Tclass)
            {
                /* https://issues.dlang.org/show_bug.cgi?id=10219
                 * Check covariant interface return with offset tweaking.
                 * interface I {}
                 * class C : Object, I {}
                 * I function() dg = function C() {}    // should be error
                 */
                int offset = 0;
                if (toret.isBaseOf(tret, &offset) && offset != 0)
                    return MATCH.nomatch;
            }
            return MATCH.convert;
        }

        return MATCH.nomatch;
    }

    /** Extends TypeNext.constConv by also checking for matching attributes **/
    override MATCH constConv(Type to)
    {
        // Attributes need to match exactly, otherwise it's an implicit conversion
        if (this.ty != to.ty || !this.attributesEqual(cast(TypeFunction) to))
            return MATCH.nomatch;

        return super.constConv(to);
    }

    extern (D) bool checkRetType(const ref Loc loc)
    {
        Type tb = next.toBasetype();
        if (tb.ty == Tfunction)
        {
            error(loc, "functions cannot return a function");
            next = Type.terror;
        }
        if (tb.ty == Ttuple)
        {
            error(loc, "functions cannot return a sequence (use `std.typecons.Tuple`)");
            next = Type.terror;
        }
        if (!isref && (tb.ty == Tstruct || tb.ty == Tsarray))
        {
            if (auto ts = tb.baseElemOf().isTypeStruct())
            {
                if (!ts.sym.members)
                {
                    error(loc, "functions cannot return opaque type `%s` by value", tb.toChars());
                    next = Type.terror;
                }
            }
        }
        if (tb.ty == Terror)
            return true;
        return false;
    }


    /// Returns: `true` the function is `isInOutQual` or `isInOutParam` ,`false` otherwise.
    bool iswild() const pure nothrow @safe @nogc
    {
        return isInOutParam || isInOutQual;
    }

    /// Returns: whether `this` function type has the same attributes (`@safe`,...) as `other`
    extern (D) bool attributesEqual(const scope TypeFunction other, bool trustSystemEqualsDefault = true) const pure nothrow @safe @nogc
    {
        // @@@DEPRECATED_2.112@@@
        // See semantic2.d Semantic2Visitor.visit(FuncDeclaration):
        // Two overloads that are identical except for one having an explicit `@system`
        // attribute is currently in deprecation, and will become an error in 2.104 for
        // `extern(C)`, and 2.112 for `extern(D)` code respectively. Once the deprecation
        // period has passed, the trustSystemEqualsDefault=true behaviour should be made
        // the default, then we can remove the `cannot overload extern(...) function`
        // errors as they will become dead code as a result.
        return (this.trust == other.trust ||
                (trustSystemEqualsDefault && this.trust <= TRUST.system && other.trust <= TRUST.system)) &&
                this.purity == other.purity &&
                this.isnothrow == other.isnothrow &&
                this.isnogc == other.isnogc &&
                this.islive == other.islive;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }

    /**
     * Look for the index of parameter `ident` in the parameter list
     *
     * Params:
     *   ident = identifier of parameter to search for
     * Returns: index of parameter with name `ident` or -1 if not found
     */
    private extern(D) ptrdiff_t findParameterIndex(Identifier ident)
    {
        foreach (i, p; this.parameterList)
        {
            if (p.ident == ident)
                return i;
        }
        return -1;
    }
}

/***********************************************************
 */
extern (C++) final class TypeDelegate : TypeNext
{
    // .next is a TypeFunction

    extern (D) this(TypeFunction t) @safe
    {
        super(Tfunction, t);
        ty = Tdelegate;
    }

    static TypeDelegate create(TypeFunction t) @safe
    {
        return new TypeDelegate(t);
    }

    override const(char)* kind() const
    {
        return "delegate";
    }

    override TypeDelegate syntaxCopy()
    {
        auto tf = next.syntaxCopy().isTypeFunction();
        if (tf == next)
            return this;

        auto result = new TypeDelegate(tf);
        result.mod = mod;
        return result;
    }

    override Type addStorageClass(StorageClass stc)
    {
        TypeDelegate t = cast(TypeDelegate)Type.addStorageClass(stc);
        return t;
    }

    override uinteger_t size(const ref Loc loc)
    {
        return target.ptrsize * 2;
    }

    override uint alignsize()
    {
        return target.ptrsize;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeDelegate.implicitConvTo(this=%p, to=%p)\n", this, to);
        //printf("from: %s\n", toChars());
        //printf("to  : %s\n", to.toChars());
        if (this.equals(to))
            return MATCH.exact;

        if (auto toDg = to.isTypeDelegate())
        {
            MATCH m = this.next.isTypeFunction().implicitPointerConv(toDg.next);

            // Retain the old behaviour for this refactoring
            // Should probably be changed to constant to match function pointers
            if (m > MATCH.convert)
                m = MATCH.convert;

            return m;
        }

        return MATCH.nomatch;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return true;
    }

    override bool isBoolean()
    {
        return true;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/**
 * This is a shell containing a TraitsExp that can be
 * either resolved to a type or to a symbol.
 *
 * The point is to allow AliasDeclarationY to use `__traits()`, see https://issues.dlang.org/show_bug.cgi?id=7804.
 */
extern (C++) final class TypeTraits : Type
{
    Loc loc;
    /// The expression to resolve as type or symbol.
    TraitsExp exp;
    /// Cached type/symbol after semantic analysis.
    RootObject obj;

    final extern (D) this(const ref Loc loc, TraitsExp exp) @safe
    {
        super(Ttraits);
        this.loc = loc;
        this.exp = exp;
    }

    override const(char)* kind() const
    {
        return "traits";
    }

    override TypeTraits syntaxCopy()
    {
        TraitsExp te = exp.syntaxCopy();
        TypeTraits tt = new TypeTraits(loc, te);
        tt.mod = mod;
        return tt;
    }

    override Dsymbol toDsymbol(Scope* sc)
    {
        Type t;
        Expression e;
        Dsymbol s;
        resolve(this, loc, sc, e, t, s);
        if (t && t.ty != Terror)
            s = t.toDsymbol(sc);
        else if (e)
            s = getDsymbol(e);

        return s;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }

    override uinteger_t size(const ref Loc loc)
    {
        return SIZE_INVALID;
    }
}

/******
 * Implements mixin types.
 *
 * Semantic analysis will convert it to a real type.
 */
extern (C++) final class TypeMixin : Type
{
    Loc loc;
    Expressions* exps;
    RootObject obj; // cached result of semantic analysis.

    extern (D) this(const ref Loc loc, Expressions* exps) @safe
    {
        super(Tmixin);
        this.loc = loc;
        this.exps = exps;
    }

    override const(char)* kind() const
    {
        return "mixin";
    }

    override TypeMixin syntaxCopy()
    {
        return new TypeMixin(loc, Expression.arraySyntaxCopy(exps));
    }

   override Dsymbol toDsymbol(Scope* sc)
    {
        Type t;
        Expression e;
        Dsymbol s;
        resolve(this, loc, sc, e, t, s);
        if (t)
            s = t.toDsymbol(sc);
        else if (e)
            s = getDsymbol(e);

        return s;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) abstract class TypeQualified : Type
{
    Loc loc;

    // array of Identifier and TypeInstance,
    // representing ident.ident!tiargs.ident. ... etc.
    Objects idents;

    final extern (D) this(TY ty, Loc loc)
    {
        super(ty);
        this.loc = loc;
    }

    // abstract override so that using `TypeQualified.syntaxCopy` gets
    // us a `TypeQualified`
    abstract override TypeQualified syntaxCopy();

    extern (D) final void syntaxCopyHelper(TypeQualified t)
    {
        //printf("TypeQualified::syntaxCopyHelper(%s) %s\n", t.toChars(), toChars());
        idents.setDim(t.idents.length);
        for (size_t i = 0; i < idents.length; i++)
        {
            RootObject id = t.idents[i];
            with (DYNCAST) final switch (id.dyncast())
            {
            case object:
                break;
            case expression:
                Expression e = cast(Expression)id;
                e = e.syntaxCopy();
                id = e;
                break;
            case dsymbol:
                TemplateInstance ti = cast(TemplateInstance)id;
                ti = ti.syntaxCopy(null);
                id = ti;
                break;
            case type:
                Type tx = cast(Type)id;
                tx = tx.syntaxCopy();
                id = tx;
                break;
            case identifier:
            case tuple:
            case parameter:
            case statement:
            case condition:
            case templateparameter:
            case initializer:
            }
            idents[i] = id;
        }
    }

    extern (D) final void addIdent(Identifier ident)
    {
        idents.push(ident);
    }

    extern (D) final void addInst(TemplateInstance inst)
    {
        idents.push(inst);
    }

    extern (D) final void addIndex(RootObject e)
    {
        idents.push(e);
    }

    override uinteger_t size(const ref Loc loc)
    {
        error(this.loc, "size of type `%s` is not known", toChars());
        return SIZE_INVALID;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeIdentifier : TypeQualified
{
    Identifier ident;

    // The symbol representing this identifier, before alias resolution
    Dsymbol originalSymbol;

    extern (D) this(const ref Loc loc, Identifier ident)
    {
        super(Tident, loc);
        this.ident = ident;
    }

    static TypeIdentifier create(const ref Loc loc, Identifier ident)
    {
        return new TypeIdentifier(loc, ident);
    }

    override const(char)* kind() const
    {
        return "identifier";
    }

    override TypeIdentifier syntaxCopy()
    {
        auto t = new TypeIdentifier(loc, ident);
        t.syntaxCopyHelper(this);
        t.mod = mod;
        return t;
    }

    /*****************************************
     * See if type resolves to a symbol, if so,
     * return that symbol.
     */
    override Dsymbol toDsymbol(Scope* sc)
    {
        //printf("TypeIdentifier::toDsymbol('%s')\n", toChars());
        if (!sc)
            return null;

        Type t;
        Expression e;
        Dsymbol s;
        resolve(this, loc, sc, e, t, s);
        if (t && t.ty != Tident)
            s = t.toDsymbol(sc);
        if (e)
            s = getDsymbol(e);

        return s;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 * Similar to TypeIdentifier, but with a TemplateInstance as the root
 */
extern (C++) final class TypeInstance : TypeQualified
{
    TemplateInstance tempinst;

    extern (D) this(const ref Loc loc, TemplateInstance tempinst)
    {
        super(Tinstance, loc);
        this.tempinst = tempinst;
    }

    override const(char)* kind() const
    {
        return "instance";
    }

    override TypeInstance syntaxCopy()
    {
        //printf("TypeInstance::syntaxCopy() %s, %d\n", toChars(), idents.length);
        auto t = new TypeInstance(loc, tempinst.syntaxCopy(null));
        t.syntaxCopyHelper(this);
        t.mod = mod;
        return t;
    }

    override Dsymbol toDsymbol(Scope* sc)
    {
        Type t;
        Expression e;
        Dsymbol s;
        //printf("TypeInstance::semantic(%s)\n", toChars());
        resolve(this, loc, sc, e, t, s);
        if (t && t.ty != Tinstance)
            s = t.toDsymbol(sc);
        return s;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeTypeof : TypeQualified
{
    Expression exp;
    int inuse;

    extern (D) this(const ref Loc loc, Expression exp)
    {
        super(Ttypeof, loc);
        this.exp = exp;
    }

    override const(char)* kind() const
    {
        return "typeof";
    }

    override TypeTypeof syntaxCopy()
    {
        //printf("TypeTypeof::syntaxCopy() %s\n", toChars());
        auto t = new TypeTypeof(loc, exp.syntaxCopy());
        t.syntaxCopyHelper(this);
        t.mod = mod;
        return t;
    }

    override Dsymbol toDsymbol(Scope* sc)
    {
        //printf("TypeTypeof::toDsymbol('%s')\n", toChars());
        Expression e;
        Type t;
        Dsymbol s;
        resolve(this, loc, sc, e, t, s);
        return s;
    }

    override uinteger_t size(const ref Loc loc)
    {
        if (exp.type)
            return exp.type.size(loc);
        else
            return TypeQualified.size(loc);
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeReturn : TypeQualified
{
    extern (D) this(const ref Loc loc)
    {
        super(Treturn, loc);
    }

    override const(char)* kind() const
    {
        return "return";
    }

    override TypeReturn syntaxCopy()
    {
        auto t = new TypeReturn(loc);
        t.syntaxCopyHelper(this);
        t.mod = mod;
        return t;
    }

    override Dsymbol toDsymbol(Scope* sc)
    {
        Expression e;
        Type t;
        Dsymbol s;
        resolve(this, loc, sc, e, t, s);
        return s;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeStruct : Type
{
    StructDeclaration sym;
    AliasThisRec att = AliasThisRec.fwdref;
    bool inuse = false; // struct currently subject of recursive method call

    extern (D) this(StructDeclaration sym) @safe
    {
        super(Tstruct);
        this.sym = sym;
    }

    static TypeStruct create(StructDeclaration sym) @safe
    {
        return new TypeStruct(sym);
    }

    override const(char)* kind() const
    {
        return "struct";
    }

    override uinteger_t size(const ref Loc loc)
    {
        return sym.size(loc);
    }

    override uint alignsize()
    {
        sym.size(Loc.initial); // give error for forward references
        return sym.alignsize;
    }

    override TypeStruct syntaxCopy()
    {
        return this;
    }

    override Dsymbol toDsymbol(Scope* sc)
    {
        return sym;
    }

    override structalign_t alignment()
    {
        if (sym.alignment.isUnknown())
            sym.size(sym.loc);
        return sym.alignment;
    }

    /***************************************
     * Use when we prefer the default initializer to be a literal,
     * rather than a global immutable variable.
     */
    override Expression defaultInitLiteral(const ref Loc loc)
    {
        static if (LOGDEFAULTINIT)
        {
            printf("TypeStruct::defaultInitLiteral() '%s'\n", toChars());
        }
        sym.size(loc);
        if (sym.sizeok != Sizeok.done)
            return ErrorExp.get();

        auto structelems = new Expressions(sym.nonHiddenFields());
        uint offset = 0;
        foreach (j; 0 .. structelems.length)
        {
            VarDeclaration vd = sym.fields[j];
            Expression e;
            if (vd.inuse)
            {
                error(loc, "circular reference to `%s`", vd.toPrettyChars());
                return ErrorExp.get();
            }
            if (vd.offset < offset || vd.type.size() == 0)
                e = null;
            else if (vd._init)
            {
                if (vd._init.isVoidInitializer())
                    e = null;
                else
                    e = vd.getConstInitializer(false);
            }
            else
                e = vd.type.defaultInitLiteral(loc);
            if (e && e.op == EXP.error)
                return e;
            if (e)
                offset = vd.offset + cast(uint)vd.type.size();
            (*structelems)[j] = e;
        }
        auto structinit = new StructLiteralExp(loc, sym, structelems);

        /* Copy from the initializer symbol for larger symbols,
         * otherwise the literals expressed as code get excessively large.
         */
        if (size(loc) > target.ptrsize * 4 && !needsNested())
            structinit.useStaticInit = true;

        structinit.type = this;
        return structinit;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        // Determine zeroInit here, as this can be called before semantic2
        sym.determineSize(sym.loc);
        return sym.zeroInit;
    }

    override bool isAssignable()
    {
        bool assignable = true;
        uint offset = ~0; // dead-store initialize to prevent spurious warning

        sym.determineSize(sym.loc);

        /* If any of the fields are const or immutable,
         * then one cannot assign this struct.
         */
        for (size_t i = 0; i < sym.fields.length; i++)
        {
            VarDeclaration v = sym.fields[i];
            //printf("%s [%d] v = (%s) %s, v.offset = %d, v.parent = %s\n", sym.toChars(), i, v.kind(), v.toChars(), v.offset, v.parent.kind());
            if (i == 0)
            {
            }
            else if (v.offset == offset)
            {
                /* If any fields of anonymous union are assignable,
                 * then regard union as assignable.
                 * This is to support unsafe things like Rebindable templates.
                 */
                if (assignable)
                    continue;
            }
            else
            {
                if (!assignable)
                    return false;
            }
            assignable = v.type.isMutable() && v.type.isAssignable();
            offset = v.offset;
            //printf(" -> assignable = %d\n", assignable);
        }

        return assignable;
    }

    override bool isBoolean()
    {
        return false;
    }

    override bool needsDestruction()
    {
        return sym.dtor !is null;
    }

    override bool needsCopyOrPostblit()
    {
        return sym.hasCopyCtor || sym.postblit;
    }

    override bool needsNested()
    {
        if (inuse) return false; // circular type, error instead of crashing

        inuse = true;
        scope(exit) inuse = false;

        if (sym.isNested())
            return true;

        for (size_t i = 0; i < sym.fields.length; i++)
        {
            VarDeclaration v = sym.fields[i];
            if (!v.isDataseg() && v.type.needsNested())
                return true;
        }
        return false;
    }

    extern(C++)
    final bool hasPointers()
    {
        return super.hasPointers();
    }

    override bool hasVoidInitPointers()
    {
        sym.size(Loc.initial); // give error for forward references
        sym.determineTypeProperties();
        return sym.hasVoidInitPointers;
    }

    override bool hasSystemFields()
    {
        sym.size(Loc.initial); // give error for forward references
        sym.determineTypeProperties();
        return sym.hasSystemFields;
    }

    override bool hasInvariant()
    {
        sym.size(Loc.initial); // give error for forward references
        sym.determineTypeProperties();
        return sym.hasInvariant() || sym.hasFieldWithInvariant;
    }

    extern (D) MATCH implicitConvToWithoutAliasThis(Type to)
    {
        MATCH m;

        if (ty == to.ty && sym == (cast(TypeStruct)to).sym)
        {
            m = MATCH.exact; // exact match
            if (mod != to.mod)
            {
                m = MATCH.constant;
                if (MODimplicitConv(mod, to.mod))
                {
                }
                else
                {
                    /* Check all the fields. If they can all be converted,
                     * allow the conversion.
                     */
                    uint offset = ~0; // dead-store to prevent spurious warning
                    for (size_t i = 0; i < sym.fields.length; i++)
                    {
                        VarDeclaration v = sym.fields[i];
                        if (i == 0)
                        {
                        }
                        else if (v.offset == offset)
                        {
                            if (m > MATCH.nomatch)
                                continue;
                        }
                        else
                        {
                            if (m == MATCH.nomatch)
                                return m;
                        }

                        // 'from' type
                        Type tvf = v.type.addMod(mod);

                        // 'to' type
                        Type tv = v.type.addMod(to.mod);

                        // field match
                        MATCH mf = tvf.implicitConvTo(tv);
                        //printf("\t%s => %s, match = %d\n", v.type.toChars(), tv.toChars(), mf);

                        if (mf == MATCH.nomatch)
                            return mf;
                        if (mf < m) // if field match is worse
                            m = mf;
                        offset = v.offset;
                    }
                }
            }
        }
        return m;
    }

    extern (D) MATCH implicitConvToThroughAliasThis(Type to)
    {
        MATCH m;
        if (!(ty == to.ty && sym == (cast(TypeStruct)to).sym) && sym.aliasthis && !(att & AliasThisRec.tracing))
        {
            if (auto ato = aliasthisOf())
            {
                att = cast(AliasThisRec)(att | AliasThisRec.tracing);
                m = ato.implicitConvTo(to);
                att = cast(AliasThisRec)(att & ~AliasThisRec.tracing);
            }
            else
                m = MATCH.nomatch; // no match
        }
        return m;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeStruct::implicitConvTo(%s => %s)\n", toChars(), to.toChars());
        MATCH m = implicitConvToWithoutAliasThis(to);
        return m ? m : implicitConvToThroughAliasThis(to);
    }

    override MATCH constConv(Type to)
    {
        if (equals(to))
            return MATCH.exact;
        if (ty == to.ty && sym == (cast(TypeStruct)to).sym && MODimplicitConv(mod, to.mod))
            return MATCH.constant;
        return MATCH.nomatch;
    }

    override MOD deduceWild(Type t, bool isRef)
    {
        if (ty == t.ty && sym == (cast(TypeStruct)t).sym)
            return Type.deduceWild(t, isRef);

        ubyte wm = 0;

        if (t.hasWild() && sym.aliasthis && !(att & AliasThisRec.tracing))
        {
            if (auto ato = aliasthisOf())
            {
                att = cast(AliasThisRec)(att | AliasThisRec.tracing);
                wm = ato.deduceWild(t, isRef);
                att = cast(AliasThisRec)(att & ~AliasThisRec.tracing);
            }
        }

        return wm;
    }

    override inout(Type) toHeadMutable() inout
    {
        return this;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeEnum : Type
{
    EnumDeclaration sym;

    extern (D) this(EnumDeclaration sym) @safe
    {
        super(Tenum);
        this.sym = sym;
    }

    override const(char)* kind() const
    {
        return "enum";
    }

    override TypeEnum syntaxCopy()
    {
        return this;
    }

    override uinteger_t size(const ref Loc loc)
    {
        return sym.getMemtype(loc).size(loc);
    }

    Type memType(const ref Loc loc = Loc.initial)
    {
        return sym.getMemtype(loc);
    }

    override uint alignsize()
    {
        Type t = memType();
        if (t.ty == Terror)
            return 4;
        return t.alignsize();
    }

    override Dsymbol toDsymbol(Scope* sc)
    {
        return sym;
    }

    override bool isintegral()
    {
        return memType().isintegral();
    }

    override bool isfloating()
    {
        return memType().isfloating();
    }

    override bool isreal()
    {
        return memType().isreal();
    }

    override bool isimaginary()
    {
        return memType().isimaginary();
    }

    override bool iscomplex()
    {
        return memType().iscomplex();
    }

    override bool isscalar()
    {
        return memType().isscalar();
    }

    override bool isunsigned()
    {
        return memType().isunsigned();
    }

    override bool isBoolean()
    {
        return memType().isBoolean();
    }

    override bool isString()
    {
        return memType().isString();
    }

    override bool isAssignable()
    {
        return memType().isAssignable();
    }

    override bool needsDestruction()
    {
        return memType().needsDestruction();
    }

    override bool needsCopyOrPostblit()
    {
        return memType().needsCopyOrPostblit();
    }

    override bool needsNested()
    {
        return memType().needsNested();
    }

    override MATCH implicitConvTo(Type to)
    {
        MATCH m;
        //printf("TypeEnum::implicitConvTo() %s to %s\n", toChars(), to.toChars());
        if (ty == to.ty && sym == (cast(TypeEnum)to).sym)
            m = (mod == to.mod) ? MATCH.exact : MATCH.constant;
        else if (sym.getMemtype(Loc.initial).implicitConvTo(to))
            m = MATCH.convert; // match with conversions
        else
            m = MATCH.nomatch; // no match
        return m;
    }

    override MATCH constConv(Type to)
    {
        if (equals(to))
            return MATCH.exact;
        if (ty == to.ty && sym == (cast(TypeEnum)to).sym && MODimplicitConv(mod, to.mod))
            return MATCH.constant;
        return MATCH.nomatch;
    }

    extern (D) Type toBasetype2()
    {
        if (!sym.members && !sym.memtype)
            return this;
        auto tb = sym.getMemtype(Loc.initial).toBasetype();
        return tb.castMod(mod);         // retain modifier bits from 'this'
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return sym.getDefaultValue(loc).toBool().hasValue(false);
    }

    override bool hasVoidInitPointers()
    {
        return memType().hasVoidInitPointers();
    }

    override bool hasSystemFields()
    {
        return memType().hasSystemFields();
    }

    override bool hasInvariant()
    {
        return memType().hasInvariant();
    }

    override Type nextOf()
    {
        return memType().nextOf();
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeClass : Type
{
    ClassDeclaration sym;
    AliasThisRec att = AliasThisRec.fwdref;
    CPPMANGLE cppmangle = CPPMANGLE.def;

    extern (D) this(ClassDeclaration sym) @safe
    {
        super(Tclass);
        this.sym = sym;
    }

    override const(char)* kind() const
    {
        return "class";
    }

    override uinteger_t size(const ref Loc loc)
    {
        return target.ptrsize;
    }

    override TypeClass syntaxCopy()
    {
        return this;
    }

    override Dsymbol toDsymbol(Scope* sc)
    {
        return sym;
    }

    override inout(ClassDeclaration) isClassHandle() inout
    {
        return sym;
    }

    override bool isBaseOf(Type t, int* poffset)
    {
        if (t && t.ty == Tclass)
        {
            ClassDeclaration cd = (cast(TypeClass)t).sym;
            if (cd.semanticRun < PASS.semanticdone && !cd.isBaseInfoComplete())
                cd.dsymbolSemantic(null);
            if (sym.semanticRun < PASS.semanticdone && !sym.isBaseInfoComplete())
                sym.dsymbolSemantic(null);

            if (sym.isBaseOf(cd, poffset))
                return true;
        }
        return false;
    }

    extern (D) MATCH implicitConvToWithoutAliasThis(Type to)
    {
        // Run semantic before checking whether class is convertible
        ClassDeclaration cdto = to.isClassHandle();
        if (cdto)
        {
            //printf("TypeClass::implicitConvTo(to = '%s') %s, isbase = %d %d\n", to.toChars(), toChars(), cdto.isBaseInfoComplete(), sym.isBaseInfoComplete());
            if (cdto.semanticRun < PASS.semanticdone && !cdto.isBaseInfoComplete())
                cdto.dsymbolSemantic(null);
            if (sym.semanticRun < PASS.semanticdone && !sym.isBaseInfoComplete())
                sym.dsymbolSemantic(null);
        }
        MATCH m = constConv(to);
        if (m > MATCH.nomatch)
            return m;

        if (cdto && cdto.isBaseOf(sym, null) && MODimplicitConv(mod, to.mod))
        {
            //printf("'to' is base\n");
            return MATCH.convert;
        }
        return MATCH.nomatch;
    }

    extern (D) MATCH implicitConvToThroughAliasThis(Type to)
    {
        MATCH m;
        if (sym.aliasthis && !(att & AliasThisRec.tracing))
        {
            if (auto ato = aliasthisOf())
            {
                att = cast(AliasThisRec)(att | AliasThisRec.tracing);
                m = ato.implicitConvTo(to);
                att = cast(AliasThisRec)(att & ~AliasThisRec.tracing);
            }
        }
        return m;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeClass::implicitConvTo(to = '%s') %s\n", to.toChars(), toChars());
        MATCH m = implicitConvToWithoutAliasThis(to);
        return m ? m : implicitConvToThroughAliasThis(to);
    }

    override MATCH constConv(Type to)
    {
        if (equals(to))
            return MATCH.exact;
        if (ty == to.ty && sym == (cast(TypeClass)to).sym && MODimplicitConv(mod, to.mod))
            return MATCH.constant;

        /* Conversion derived to const(base)
         */
        int offset = 0;
        if (to.isBaseOf(this, &offset) && offset == 0 && MODimplicitConv(mod, to.mod))
        {
            // Disallow:
            //  derived to base
            //  inout(derived) to inout(base)
            if (!to.isMutable() && !to.isWild())
                return MATCH.convert;
        }

        return MATCH.nomatch;
    }

    override MOD deduceWild(Type t, bool isRef)
    {
        ClassDeclaration cd = t.isClassHandle();
        if (cd && (sym == cd || cd.isBaseOf(sym, null)))
            return Type.deduceWild(t, isRef);

        ubyte wm = 0;

        if (t.hasWild() && sym.aliasthis && !(att & AliasThisRec.tracing))
        {
            if (auto ato = aliasthisOf())
            {
                att = cast(AliasThisRec)(att | AliasThisRec.tracing);
                wm = ato.deduceWild(t, isRef);
                att = cast(AliasThisRec)(att & ~AliasThisRec.tracing);
            }
        }

        return wm;
    }

    override inout(Type) toHeadMutable() inout
    {
        return this;
    }

    override bool isZeroInit(const ref Loc loc)
    {
        return true;
    }

    override bool isscope()
    {
        return sym.stack;
    }

    override bool isBoolean()
    {
        return true;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeTuple : Type
{
    // 'logically immutable' cached global - don't modify!
    __gshared TypeTuple empty = new TypeTuple();

    Parameters* arguments;  // types making up the tuple

    extern (D) this(Parameters* arguments) @safe
    {
        super(Ttuple);
        //printf("TypeTuple(this = %p)\n", this);
        this.arguments = arguments;
        //printf("TypeTuple() %p, %s\n", this, toChars());
        debug
        {
            if (arguments)
            {
                for (size_t i = 0; i < arguments.length; i++)
                {
                    Parameter arg = (*arguments)[i];
                    assert(arg && arg.type);
                }
            }
        }
    }

    /****************
     * Form TypeTuple from the types of the expressions.
     * Assume exps[] is already tuple expanded.
     */
    extern (D) this(Expressions* exps)
    {
        super(Ttuple);
        auto arguments = new Parameters(exps ? exps.length : 0);
        if (exps)
        {
            for (size_t i = 0; i < exps.length; i++)
            {
                Expression e = (*exps)[i];
                if (e.type.ty == Ttuple)
                    error(e.loc, "cannot form sequence of sequences");
                auto arg = new Parameter(e.loc, STC.undefined_, e.type, null, null, null, null);
                (*arguments)[i] = arg;
            }
        }
        this.arguments = arguments;
        //printf("TypeTuple() %p, %s\n", this, toChars());
    }

    static TypeTuple create(Parameters* arguments) @safe
    {
        return new TypeTuple(arguments);
    }

    /*******************************************
     * Type tuple with 0, 1 or 2 types in it.
     */
    extern (D) this() @safe
    {
        super(Ttuple);
        arguments = new Parameters();
    }

    extern (D) this(Type t1)
    {
        super(Ttuple);
        arguments = new Parameters();
        arguments.push(new Parameter(Loc.initial, 0, t1, null, null, null, null));
    }

    extern (D) this(Type t1, Type t2)
    {
        super(Ttuple);
        arguments = new Parameters();
        arguments.push(new Parameter(Loc.initial, 0, t1, null, null, null, null));
        arguments.push(new Parameter(Loc.initial, 0, t2, null, null, null, null));
    }

    static TypeTuple create() @safe
    {
        return new TypeTuple();
    }

    static TypeTuple create(Type t1)
    {
        return new TypeTuple(t1);
    }

    static TypeTuple create(Type t1, Type t2)
    {
        return new TypeTuple(t1, t2);
    }

    override const(char)* kind() const
    {
        return "sequence";
    }

    override TypeTuple syntaxCopy()
    {
        Parameters* args = Parameter.arraySyntaxCopy(arguments);
        auto t = new TypeTuple(args);
        t.mod = mod;
        return t;
    }

    override bool equals(const RootObject o) const
    {
        Type t = cast(Type)o;
        //printf("TypeTuple::equals(%s, %s)\n", toChars(), t.toChars());
        if (this == t)
            return true;
        if (auto tt = t.isTypeTuple())
        {
            if (arguments.length == tt.arguments.length)
            {
                for (size_t i = 0; i < tt.arguments.length; i++)
                {
                    const Parameter arg1 = (*arguments)[i];
                    Parameter arg2 = (*tt.arguments)[i];
                    if (!arg1.type.equals(arg2.type))
                        return false;
                }
                return true;
            }
        }
        return false;
    }

    override MATCH implicitConvTo(Type to)
    {
        if (this == to)
            return MATCH.exact;
        if (auto tt = to.isTypeTuple())
        {
            if (arguments.length == tt.arguments.length)
            {
                MATCH m = MATCH.exact;
                for (size_t i = 0; i < tt.arguments.length; i++)
                {
                    Parameter arg1 = (*arguments)[i];
                    Parameter arg2 = (*tt.arguments)[i];
                    MATCH mi = arg1.type.implicitConvTo(arg2.type);
                    if (mi < m)
                        m = mi;
                }
                return m;
            }
        }
        return MATCH.nomatch;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 * This is so we can slice a TypeTuple
 */
extern (C++) final class TypeSlice : TypeNext
{
    Expression lwr;
    Expression upr;

    extern (D) this(Type next, Expression lwr, Expression upr) @safe
    {
        super(Tslice, next);
        //printf("TypeSlice[%s .. %s]\n", lwr.toChars(), upr.toChars());
        this.lwr = lwr;
        this.upr = upr;
    }

    override const(char)* kind() const
    {
        return "slice";
    }

    override TypeSlice syntaxCopy()
    {
        auto t = new TypeSlice(next.syntaxCopy(), lwr.syntaxCopy(), upr.syntaxCopy());
        t.mod = mod;
        return t;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeNull : Type
{
    extern (D) this() @safe
    {
        //printf("TypeNull %p\n", this);
        super(Tnull);
    }

    override const(char)* kind() const
    {
        return "null";
    }

    override TypeNull syntaxCopy()
    {
        // No semantic analysis done, no need to copy
        return this;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeNull::implicitConvTo(this=%p, to=%p)\n", this, to);
        //printf("from: %s\n", toChars());
        //printf("to  : %s\n", to.toChars());
        MATCH m = Type.implicitConvTo(to);
        if (m != MATCH.nomatch)
            return m;

        // NULL implicitly converts to any pointer type or dynamic array
        //if (type.ty == Tpointer && type.nextOf().ty == Tvoid)
        {
            Type tb = to.toBasetype();
            if (tb.ty == Tnull || tb.ty == Tpointer || tb.ty == Tarray || tb.ty == Taarray || tb.ty == Tclass || tb.ty == Tdelegate)
                return MATCH.constant;
        }

        return MATCH.nomatch;
    }

    override bool isBoolean()
    {
        return true;
    }

    override uinteger_t size(const ref Loc loc)
    {
        return tvoidptr.size(loc);
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 */
extern (C++) final class TypeNoreturn : Type
{
    extern (D) this() @safe
    {
        //printf("TypeNoreturn %p\n", this);
        super(Tnoreturn);
    }

    override const(char)* kind() const
    {
        return "noreturn";
    }

    override TypeNoreturn syntaxCopy()
    {
        // No semantic analysis done, no need to copy
        return this;
    }

    override MATCH implicitConvTo(Type to)
    {
        //printf("TypeNoreturn::implicitConvTo(this=%p, to=%p)\n", this, to);
        //printf("from: %s\n", toChars());
        //printf("to  : %s\n", to.toChars());
        if (this.equals(to))
            return MATCH.exact;

        // Different qualifiers?
        if (to.ty == Tnoreturn)
            return MATCH.constant;

        // Implicitly convertible to any type
        return MATCH.convert;
    }

    override MATCH constConv(Type to)
    {
        // Either another noreturn or conversion to any type
        return this.implicitConvTo(to);
    }

    override bool isBoolean()
    {
        return true;  // bottom type can be implicitly converted to any other type
    }

    override uinteger_t size(const ref Loc loc)
    {
        return 0;
    }

    override uint alignsize()
    {
        return 0;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 * Unlike D, C can declare/define struct/union/enum tag names
 * inside Declarators, instead of separately as in D.
 * The order these appear in the symbol table must be in lexical
 * order. There isn't enough info at the parsing stage to determine if
 * it's a declaration or a reference to an existing name, so this Type
 * collects the necessary info and defers it to semantic().
 */
extern (C++) final class TypeTag : Type
{
    Loc loc;                /// location of declaration
    TOK tok;                /// TOK.struct_, TOK.union_, TOK.enum_
    structalign_t packalign; /// alignment of struct/union fields
    Identifier id;          /// tag name identifier
    Type base;              /// base type for enums otherwise null
    Dsymbols* members;      /// members of struct, null if none

    Type resolved;          /// type after semantic() in case there are more others
                            /// pointing to this instance, which can happen with
                            ///   struct S { int a; } s1, *s2;
    MOD mod;                /// modifiers to apply after type is resolved (only MODFlags.const_ at the moment)

    extern (D) this(const ref Loc loc, TOK tok, Identifier id, structalign_t packalign, Type base, Dsymbols* members) @safe
    {
        //printf("TypeTag ctor %s %p\n", id ? id.toChars() : "null".ptr, this);
        super(Ttag);
        this.loc = loc;
        this.tok = tok;
        this.id = id;
        this.packalign = packalign;
        this.base = base;
        this.members = members;
        this.mod = 0;
    }

    override const(char)* kind() const
    {
        return "tag";
    }

    override TypeTag syntaxCopy()
    {
        //printf("TypeTag syntaxCopy()\n");
        // No semantic analysis done, no need to copy
        return this;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 * Represents a function's formal parameters + variadics info.
 * Length, indexing and iteration are based on a depth-first tuple expansion.
 * https://dlang.org/spec/function.html#ParameterList
 */
extern (C++) struct ParameterList
{
    /// The raw (unexpanded) formal parameters, possibly containing tuples.
    Parameters* parameters;
    StorageClass stc;                   // storage class of ...
    VarArg varargs = VarArg.none;
    bool hasIdentifierList;             // true if C identifier-list style

    this(Parameters* parameters, VarArg varargs = VarArg.none, StorageClass stc = 0) @safe
    {
        this.parameters = parameters;
        this.varargs = varargs;
        this.stc = stc;
    }

    /// Returns the number of expanded parameters. Complexity: O(N).
    size_t length()
    {
        return Parameter.dim(parameters);
    }

    /// Returns the expanded parameter at the given index, or null if out of
    /// bounds. Complexity: O(i).
    Parameter opIndex(size_t i)
    {
        return Parameter.getNth(parameters, i);
    }

    /// Iterates over the expanded parameters. Complexity: O(N).
    /// Prefer this to avoid the O(N + N^2/2) complexity of calculating length
    /// and calling N times opIndex.
    extern (D) int opApply(scope Parameter.ForeachDg dg)
    {
        return Parameter._foreach(parameters, dg);
    }

    /// Iterates over the expanded parameters, matching them with the unexpanded
    /// ones, for semantic processing
    extern (D) int opApply(scope Parameter.SemanticForeachDg dg)
    {
        return Parameter._foreach(this.parameters, dg);
    }

    extern (D) ParameterList syntaxCopy()
    {
        return ParameterList(Parameter.arraySyntaxCopy(parameters), varargs);
    }

    /// Compares this to another ParameterList (and expands tuples if necessary)
    extern (D) bool opEquals(scope ref ParameterList other) const
    {
        if (stc != other.stc || varargs != other.varargs || (!parameters != !other.parameters))
            return false;

        if (this.parameters is other.parameters)
            return true;

        size_t idx;
        bool diff;

        // Pairwise compare each parameter
        // Can this avoid the O(n) indexing for the second list?
        foreach (_, p1; cast() this)
        {
            auto p2 = other[idx++];
            if (!p2 || p1 != p2) {
                diff = true;
                break;
            }
        }

        // Ensure no remaining parameters in `other`
        return !diff && other[idx] is null;
    }

    /// Returns: `true` if any parameter has a default argument
    extern(D) bool hasDefaultArgs()
    {
        foreach (oidx, oparam, eidx, eparam; this)
        {
            if (eparam.defaultArg)
                return true;
        }
        return false;
    }

    // Returns: `true` if any parameter doesn't have a default argument
    extern(D) bool hasArgsWithoutDefault()
    {
        foreach (oidx, oparam, eidx, eparam; this)
        {
            if (!eparam.defaultArg)
                return true;
        }
        return false;
    }
}


/***********************************************************
 */
extern (C++) final class Parameter : ASTNode
{
    import dmd.attrib : UserAttributeDeclaration;

    Loc loc;
    StorageClass storageClass;
    Type type;
    Identifier ident;
    Expression defaultArg;
    UserAttributeDeclaration userAttribDecl; // user defined attributes
    UnpackDeclaration unpack;

    extern (D) this(const ref Loc loc, StorageClass storageClass, Type type, Identifier ident, Expression defaultArg, UserAttributeDeclaration userAttribDecl, UnpackDeclaration unpack) @safe
    {
        this.loc = loc;
        this.type = type;
        this.ident = ident;
        this.storageClass = storageClass;
        this.defaultArg = defaultArg;
        this.userAttribDecl = userAttribDecl;
        this.unpack = unpack;
    }

    static Parameter create(const ref Loc loc, StorageClass storageClass, Type type, Identifier ident, Expression defaultArg, UserAttributeDeclaration userAttribDecl, UnpackDeclaration unpack) @safe
    {
        return new Parameter(loc, storageClass, type, ident, defaultArg, userAttribDecl, unpack);
    }

    Parameter syntaxCopy()
    {
        return new Parameter(loc, storageClass, type ? type.syntaxCopy() : null, ident, defaultArg ? defaultArg.syntaxCopy() : null, userAttribDecl ? userAttribDecl.syntaxCopy(null) : null, unpack ? unpack.syntaxCopy(null) : null);
    }

    /****************************************************
     * Determine if parameter is a lazy array of delegates.
     * If so, return the return type of those delegates.
     * If not, return NULL.
     *
     * Returns T if the type is one of the following forms:
     *      T delegate()[]
     *      T delegate()[dim]
     */
    Type isLazyArray()
    {
        Type tb = type.toBasetype();
        if (tb.ty == Tsarray || tb.ty == Tarray)
        {
            Type tel = (cast(TypeArray)tb).next.toBasetype();
            if (auto td = tel.isTypeDelegate())
            {
                TypeFunction tf = td.next.toTypeFunction();
                if (tf.parameterList.varargs == VarArg.none && tf.parameterList.length == 0)
                {
                    return tf.next; // return type of delegate
                }
            }
        }
        return null;
    }

    /// Returns: Whether the function parameter is lazy
    bool isLazy() const @safe pure nothrow @nogc
    {
        return (this.storageClass & (STC.lazy_)) != 0;
    }

    /// Returns: Whether the function parameter is a reference (out / ref)
    bool isReference() const @safe pure nothrow @nogc
    {
        return (this.storageClass & (STC.ref_ | STC.out_)) != 0;
    }

    // kludge for template.isType()
    override DYNCAST dyncast() const
    {
        return DYNCAST.parameter;
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }

    extern (D) static Parameters* arraySyntaxCopy(Parameters* parameters)
    {
        Parameters* params = null;
        if (parameters)
        {
            params = new Parameters(parameters.length);
            for (size_t i = 0; i < params.length; i++)
                (*params)[i] = (*parameters)[i].syntaxCopy();
        }
        return params;
    }

    /***************************************
     * Determine number of arguments, folding in tuples.
     */
    static size_t dim(Parameters* parameters)
    {
        size_t nargs = 0;

        int dimDg(size_t n, Parameter p)
        {
            ++nargs;
            return 0;
        }

        _foreach(parameters, &dimDg);
        return nargs;
    }

    /**
     * Get nth `Parameter`, folding in tuples.
     *
     * Since `parameters` can include tuples, which would increase its
     * length, this function allows to get the `nth` parameter as if
     * all tuples transitively contained in `parameters` were flattened.
     *
     * Params:
     *   parameters = Array of `Parameter` to iterate over
     *   nth = Index of the desired parameter.
     *
     * Returns:
     *   The parameter at index `nth` (taking tuples into account),
     *   or `null` if out of bound.
     */
    static Parameter getNth(Parameters* parameters, size_t nth)
    {
        Parameter param;

        int getNthParamDg(size_t n, Parameter p)
        {
            if (n == nth)
            {
                param = p;
                return 1;
            }
            return 0;
        }

        int res = _foreach(parameters, &getNthParamDg);
        return res ? param : null;
    }

    /// Type of delegate when iterating solely on the parameters
    alias ForeachDg = extern (D) int delegate(size_t paramidx, Parameter param);
    /// Type of delegate when iterating on both the original set of parameters,
    /// and the type tuple. Useful for semantic analysis.
    /// 'o' stands for 'original' and 'e' stands for 'expanded'.
    alias SemanticForeachDg = extern (D) int delegate(
        size_t oidx, Parameter oparam, size_t eidx, Parameter eparam);

    /***************************************
     * Expands tuples in args in depth first order. Calls
     * dg(void *ctx, size_t argidx, Parameter *arg) for each Parameter.
     * If dg returns !=0, stops and returns that value else returns 0.
     * Use this function to avoid the O(N + N^2/2) complexity of
     * calculating dim and calling N times getNth.
     */
    extern (D) static int _foreach(Parameters* parameters, scope ForeachDg dg)
    {
        assert(dg !is null);
        return _foreach(parameters, (_oidx, _oparam, idx, param) => dg(idx, param));
    }

    /// Ditto
    extern (D) static int _foreach(
        Parameters* parameters, scope SemanticForeachDg dg)
    {
        assert(dg !is null);
        if (parameters is null)
            return 0;

        size_t eidx;
        foreach (oidx; 0 .. parameters.length)
        {
            Parameter oparam = (*parameters)[oidx];
            if (auto r = _foreachImpl(dg, oidx, oparam, eidx, /* eparam */ oparam))
                return r;
        }
        return 0;
    }

    /// Implementation of the iteration process, which recurses in itself
    /// and just forwards `oidx` and `oparam`.
    extern (D) private static int _foreachImpl(scope SemanticForeachDg dg,
        size_t oidx, Parameter oparam, ref size_t eidx, Parameter eparam)
    {
        if (eparam is null)
            return 0;

        Type t = eparam.type.toBasetype();
        if (auto tu = t.isTypeTuple())
        {
            // Check for empty tuples
            if (tu.arguments is null)
                return 0;

            foreach (nidx; 0 .. tu.arguments.length)
            {
                Parameter nextep = (*tu.arguments)[nidx];
                if (auto r = _foreachImpl(dg, oidx, oparam, eidx, nextep))
                    return r;
            }
        }
        else
        {
            if (auto r = dg(oidx, oparam, eidx, eparam))
                return r;
            // The only place where we should increment eidx is here,
            // as a TypeTuple doesn't count as a parameter (for arity)
            // it it is empty.
            eidx++;
        }
        return 0;
    }

    override const(char)* toChars() const
    {
        return ident ? ident.toChars() : "__anonymous_param";
    }

    /*********************************
     * Compute covariance of parameters `this` and `p`
     * as determined by the storage classes of both.
     *
     * Params:
     *  returnByRef = true if the function returns by ref
     *  p = Parameter to compare with
     * Returns:
     *  true = `this` can be used in place of `p`
     *  false = nope
     */
    bool isCovariant(bool returnByRef, const Parameter p)
        const pure nothrow @nogc @safe
    {
        ulong thisSTC = this.storageClass;
        ulong otherSTC = p.storageClass;

        if (thisSTC & STC.constscoperef)
            thisSTC |= STC.scope_;
        if (otherSTC & STC.constscoperef)
            otherSTC |= STC.scope_;

        const mask = STC.ref_ | STC.out_ | STC.lazy_ | (((thisSTC | otherSTC) & STC.constscoperef) ? STC.in_ : 0);
        if ((thisSTC & mask) != (otherSTC & mask))
            return false;
        return isCovariantScope(returnByRef, thisSTC, otherSTC);
    }

    extern (D) static bool isCovariantScope(bool returnByRef, StorageClass from, StorageClass to) pure nothrow @nogc @safe
    {
        // Workaround for failing covariance when finding a common type of delegates,
        // some of which have parameters with inferred scope
        // https://issues.dlang.org/show_bug.cgi?id=21285
        // The root cause is that scopeinferred is not part of the mangle, and mangle
        // is used for type equality checks
        if (to & STC.returninferred)
            to &= ~STC.return_;
        // note: f(return int* x) currently 'infers' scope without inferring `return`, in that case keep STC.scope
        if (to & STC.scopeinferred && !(to & STC.return_))
            to &= ~STC.scope_;

        if (from == to)
            return true;

        /* result is true if the 'from' can be used as a 'to'
         */

        if ((from ^ to) & STC.ref_)               // differing in 'ref' means no covariance
            return false;

        /* workaround until we get STC.returnScope reliably set correctly
         */
        if (returnByRef)
        {
            from &= ~STC.returnScope;
            to   &= ~STC.returnScope;
        }
        else
        {
            from |= STC.returnScope;
            to   |= STC.returnScope;
        }
        return covariant[buildScopeRef(from)][buildScopeRef(to)];
    }

    extern (D) private static bool[ScopeRef.max + 1][ScopeRef.max + 1] covariantInit() pure nothrow @nogc @safe
    {
        /* Initialize covariant[][] with this:

             From\To           n   rs  s
             None              X
             ReturnScope       X   X
             Scope             X   X   X

             From\To           r   rr  rs  rr-s r-rs
             Ref               X   X
             ReturnRef             X
             RefScope          X   X   X   X    X
             ReturnRef-Scope       X       X
             Ref-ReturnScope   X   X            X
        */
        bool[ScopeRef.max + 1][ScopeRef.max + 1] covariant;

        foreach (i; 0 .. ScopeRef.max + 1)
        {
            covariant[i][i] = true;
            covariant[ScopeRef.RefScope][i] = true;
        }
        covariant[ScopeRef.ReturnScope][ScopeRef.None]        = true;
        covariant[ScopeRef.Scope      ][ScopeRef.None]        = true;
        covariant[ScopeRef.Scope      ][ScopeRef.ReturnScope] = true;

        covariant[ScopeRef.Ref            ][ScopeRef.ReturnRef] = true;
        covariant[ScopeRef.ReturnRef_Scope][ScopeRef.ReturnRef] = true;
        covariant[ScopeRef.Ref_ReturnScope][ScopeRef.Ref      ] = true;
        covariant[ScopeRef.Ref_ReturnScope][ScopeRef.ReturnRef] = true;

        return covariant;
    }

    extern (D) private static immutable bool[ScopeRef.max + 1][ScopeRef.max + 1] covariant = covariantInit();

    extern (D) bool opEquals(const Parameter other) const
    {
        return this.storageClass == other.storageClass
            && this.type == other.type;
    }
}

/*************************************************************
 * For printing two types with qualification when necessary.
 * Params:
 *    t1 = The first type to receive the type name for
 *    t2 = The second type to receive the type name for
 * Returns:
 *    The fully-qualified names of both types if the two type names are not the same,
 *    or the unqualified names of both types if the two type names are the same.
 */
const(char*)[2] toAutoQualChars(Type t1, Type t2)
{
    auto s1 = t1.toChars();
    auto s2 = t2.toChars();
    // show qualification only if it's different
    if (!t1.equals(t2) && strcmp(s1, s2) == 0)
    {
        s1 = t1.toPrettyChars(true);
        s2 = t2.toPrettyChars(true);
    }
    return [s1, s2];
}


/**
 * For each active modifier (MODFlags.const_, MODFlags.immutable_, etc) call `fp` with a
 * void* for the work param and a string representation of the attribute.
 */
void modifiersApply(const TypeFunction tf, void delegate(string) dg)
{
    immutable ubyte[4] modsArr = [MODFlags.const_, MODFlags.immutable_, MODFlags.wild, MODFlags.shared_];

    foreach (modsarr; modsArr)
    {
        if (tf.mod & modsarr)
        {
            dg(MODtoString(modsarr));
        }
    }
}

/**
 * For each active attribute (ref/const/nogc/etc) call `fp` with a void* for the
 * work param and a string representation of the attribute.
 */
void attributesApply(const TypeFunction tf, void delegate(string) dg, TRUSTformat trustFormat = TRUSTformatDefault)
{
    if (tf.purity)
        dg("pure");
    if (tf.isnothrow)
        dg("nothrow");
    if (tf.isnogc)
        dg("@nogc");
    if (tf.isproperty)
        dg("@property");
    if (tf.isref)
        dg("ref");
    if (tf.isreturn && !tf.isreturninferred)
        dg("return");
    if (tf.isScopeQual && !tf.isscopeinferred)
        dg("scope");
    if (tf.islive)
        dg("@live");

    TRUST trustAttrib = tf.trust;

    if (trustAttrib == TRUST.default_)
    {
        if (trustFormat != TRUSTformatSystem)
            return;
        trustAttrib = TRUST.system; // avoid calling with an empty string
    }

    dg(trustToString(trustAttrib));
}

/**
 * If the type is a class or struct, returns the symbol for it,
 * else null.
 */
extern (C++) AggregateDeclaration isAggregate(Type t)
{
    t = t.toBasetype();
    if (t.ty == Tclass)
        return (cast(TypeClass)t).sym;
    if (t.ty == Tstruct)
        return (cast(TypeStruct)t).sym;
    return null;
}

/***************************************************
 * Determine if type t can be indexed or sliced given that it is not an
 * aggregate with operator overloads.
 * Params:
 *      t = type to check
 * Returns:
 *      true if an expression of type t can be e1 in an array expression
 */
bool isIndexableNonAggregate(Type t)
{
    t = t.toBasetype();
    return (t.ty == Tpointer || t.ty == Tsarray || t.ty == Tarray || t.ty == Taarray ||
            t.ty == Ttuple || t.ty == Tvector);
}

/***************************************************
 * Determine if type t is copyable.
 * Params:
 *      t = type to check
 * Returns:
 *      true if we can copy it
 */
bool isCopyable(Type t)
{
    //printf("isCopyable() %s\n", t.toChars());
    if (auto ts = t.isTypeStruct())
    {
        if (ts.sym.postblit &&
            ts.sym.postblit.storage_class & STC.disable)
            return false;
        if (ts.sym.hasCopyCtor)
        {
            // check if there is a matching overload of the copy constructor and whether it is disabled or not
            // `assert(ctor)` fails on Win32 and Win_32_64. See: https://auto-tester.puremagic.com/pull-history.ghtml?projectid=1&repoid=1&pullid=10575
            Dsymbol ctor = search_function(ts.sym, Id.ctor);
            assert(ctor);
            scope el = new IdentifierExp(Loc.initial, Id.p); // dummy lvalue
            el.type = cast() ts;
            Expressions* args = new Expressions();
            args.push(el);
            FuncDeclaration f = resolveFuncCall(Loc.initial, null, ctor, null, cast()ts, ArgumentList(args), FuncResolveFlag.quiet);
            if (!f || f.storage_class & STC.disable)
                return false;
        }
    }
    return true;
}

/***************************************
 * Computes how a parameter may be returned.
 * Shrinking the representation is necessary because StorageClass is so wide
 * Params:
 *   stc = storage class of parameter
 * Returns:
 *   value from enum ScopeRef
 */
ScopeRef buildScopeRef(StorageClass stc) pure nothrow @nogc @safe
{
    if (stc & STC.out_)
        stc |= STC.ref_;        // treat `out` and `ref` the same

    ScopeRef result;
    final switch (stc & (STC.ref_ | STC.scope_ | STC.return_))
    {
        case 0:                        result = ScopeRef.None;        break;

        /* can occur in case test/compilable/testsctreturn.d
         * related to https://issues.dlang.org/show_bug.cgi?id=20149
         * where inout adds `return` without `scope` or `ref`
         */
        case STC.return_:              result = ScopeRef.Return;      break;

        case STC.ref_:                 result = ScopeRef.Ref;         break;
        case STC.scope_:               result = ScopeRef.Scope;       break;
        case STC.return_ | STC.ref_:   result = ScopeRef.ReturnRef;   break;
        case STC.return_ | STC.scope_: result = ScopeRef.ReturnScope; break;
        case STC.ref_    | STC.scope_: result = ScopeRef.RefScope;    break;

        case STC.return_ | STC.ref_ | STC.scope_:
            result = stc & STC.returnScope ? ScopeRef.Ref_ReturnScope
                                           : ScopeRef.ReturnRef_Scope;
            break;
    }
    return result;
}

/**
 * Classification of 'scope-return-ref' possibilities
 */
enum ScopeRef
{
    None,
    Scope,
    ReturnScope,
    Ref,
    ReturnRef,
    RefScope,
    ReturnRef_Scope,
    Ref_ReturnScope,
    Return,
}

/*********************************
 * Give us a nice string for debugging purposes.
 * Params:
 *      sr = value
 * Returns:
 *      corresponding string
 */
const(char)* ScopeRefToChars(ScopeRef sr) pure nothrow @nogc @safe
{
    with (ScopeRef)
    {
        static immutable char*[ScopeRef.max + 1] names =
        [
            None:            "None",
            Scope:           "Scope",
            ReturnScope:     "ReturnScope",
            Ref:             "Ref",
            ReturnRef:       "ReturnRef",
            RefScope:        "RefScope",
            ReturnRef_Scope: "ReturnRef_Scope",
            Ref_ReturnScope: "Ref_ReturnScope",
            Return:          "Return",
        ];
        return names[sr];
    }
}

/**
 * Creates an appropriate vector type for `tv` that will hold one boolean
 * result for each element of the vector type. The result of vector comparisons
 * is a single or doubleword mask of all 1s (comparison true) or all 0s
 * (comparison false). This SIMD mask type does not have an equivalent D type,
 * however its closest equivalent would be an integer vector of the same unit
 * size and length.
 *
 * Params:
 *   tv = The `TypeVector` to build a vector from.
 * Returns:
 *   A vector type suitable for the result of a vector comparison operation.
 */
TypeVector toBooleanVector(TypeVector tv)
{
    Type telem = tv.elementType();
    switch (telem.ty)
    {
        case Tvoid:
        case Tint8:
        case Tuns8:
        case Tint16:
        case Tuns16:
        case Tint32:
        case Tuns32:
        case Tint64:
        case Tuns64:
            // No need to build an equivalent mask type.
            return tv;

        case Tfloat32:
            telem = Type.tuns32;
            break;

        case Tfloat64:
            telem = Type.tuns64;
            break;

        default:
            assert(0);
    }

    TypeSArray tsa = tv.basetype.isTypeSArray();
    assert(tsa !is null);

    return new TypeVector(new TypeSArray(telem, tsa.dim));
}

/*************************************************
 * Dispatch to function based on static type of Type.
 */
mixin template VisitType(Result)
{
    Result VisitType(Type t)
    {
        final switch (t.ty)
        {
            case TY.Tvoid:
            case TY.Tint8:
            case TY.Tuns8:
            case TY.Tint16:
            case TY.Tuns16:
            case TY.Tint32:
            case TY.Tuns32:
            case TY.Tint64:
            case TY.Tuns64:
            case TY.Tfloat32:
            case TY.Tfloat64:
            case TY.Tfloat80:
            case TY.Timaginary32:
            case TY.Timaginary64:
            case TY.Timaginary80:
            case TY.Tcomplex32:
            case TY.Tcomplex64:
            case TY.Tcomplex80:
            case TY.Tbool:
            case TY.Tchar:
            case TY.Twchar:
            case TY.Tdchar:
            case TY.Tint128:
            case TY.Tuns128:    mixin(visitTYCase("Basic"));
            case TY.Tarray:     mixin(visitTYCase("DArray"));
            case TY.Tsarray:    mixin(visitTYCase("SArray"));
            case TY.Taarray:    mixin(visitTYCase("AArray"));
            case TY.Tpointer:   mixin(visitTYCase("Pointer"));
            case TY.Treference: mixin(visitTYCase("Reference"));
            case TY.Tfunction:  mixin(visitTYCase("Function"));
            case TY.Tident:     mixin(visitTYCase("Identifier"));
            case TY.Tclass:     mixin(visitTYCase("Class"));
            case TY.Tstruct:    mixin(visitTYCase("Struct"));
            case TY.Tenum:      mixin(visitTYCase("Enum"));
            case TY.Tdelegate:  mixin(visitTYCase("Delegate"));
            case TY.Terror:     mixin(visitTYCase("Error"));
            case TY.Tinstance:  mixin(visitTYCase("Instance"));
            case TY.Ttypeof:    mixin(visitTYCase("Typeof"));
            case TY.Ttuple:     mixin(visitTYCase("Tuple"));
            case TY.Tslice:     mixin(visitTYCase("Slice"));
            case TY.Treturn:    mixin(visitTYCase("Return"));
            case TY.Tnull:      mixin(visitTYCase("Null"));
            case TY.Tvector:    mixin(visitTYCase("Vector"));
            case TY.Ttraits:    mixin(visitTYCase("Traits"));
            case TY.Tmixin:     mixin(visitTYCase("Mixin"));
            case TY.Tnoreturn:  mixin(visitTYCase("Noreturn"));
            case TY.Ttag:       mixin(visitTYCase("Tag"));
            case TY.Tnone:      assert(0);
        }
    }
}

/****************************************
 * CTFE-only helper function for VisitInitializer.
 * Params:
 *      handler = string for the name of the visit handler
 * Returns: boilerplate code for a case
 */
pure string visitTYCase(string handler) @safe
{
    if (__ctfe)
    {
        return
            "
            enum isVoid = is(Result == void);
            auto tx = t.isType"~handler~"();
            static if (__traits(compiles, visit"~handler~"(tx)))
            {
                static if (isVoid)
                {
                    visit"~handler~"(tx);
                    return;
                }
                else
                {
                    if (Result r = visit"~handler~"(tx))
                        return r;
                    return Result.init;
                }
            }
            else static if (__traits(compiles, visitDefaultCase(t)))
            {
                static if (isVoid)
                {
                    visitDefaultCase(tx);
                    return;
                }
                else
                {
                    if (Result r = visitDefaultCase(t))
                        return r;
                    return Result.init;
                }
            }
            else
                static assert(0, "~handler~");
            ";
    }
    assert(0);
}


/**
 * Returns:
 *     `TypeIdentifier` corresponding to `object.Throwable`
 */
TypeIdentifier getThrowable()
{
    auto tid = new TypeIdentifier(Loc.initial, Id.empty);
    tid.addIdent(Id.object);
    tid.addIdent(Id.Throwable);
    return tid;
}

/**
 * Returns:
 *      TypeIdentifier corresponding to `object.Exception`
 */
TypeIdentifier getException()
{
    auto tid = new TypeIdentifier(Loc.initial, Id.empty);
    tid.addIdent(Id.object);
    tid.addIdent(Id.Exception);
    return tid;
}

/**************************************
 * Check and set 'att' if 't' is a recursive 'alias this' type
 *
 * The goal is to prevent endless loops when there is a cycle in the alias this chain.
 * Since there is no multiple `alias this`, the chain either ends in a leaf,
 * or it loops back on itself as some point.
 *
 * Example: S0 -> (S1 -> S2 -> S3 -> S1)
 *
 * `S0` is not a recursive alias this, so this returns `false`, and a rewrite to `S1` can be tried.
 * `S1` is a recursive alias this type, but since `att` is initialized to `null`,
 * this still returns `false`, but `att1` is set to `S1`.
 * A rewrite to `S2` and `S3` can be tried, but when we want to try a rewrite to `S1` again,
 * we notice `att == t`, so we're back at the start of the loop, and this returns `true`.
 *
 * Params:
 *   att = type reference used to detect recursion. Should be initialized to `null`.
 *   t   = type of 'alias this' rewrite to attempt
 *
 * Returns:
 *   `false` if the rewrite is safe, `true` if it would loop back around
 */
bool isRecursiveAliasThis(ref Type att, Type t)
{
    //printf("+isRecursiveAliasThis(att = %s, t = %s)\n", att ? att.toChars() : "null", t.toChars());
    auto tb = t.toBasetype();
    if (att && tb.equivalent(att))
        return true;
    else if (!att && tb.checkAliasThisRec())
        att = tb;
    return false;
}
