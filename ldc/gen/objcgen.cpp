//===-- objcgen.cpp -------------------------------------------------------===//
//
//                         LDC – the LLVM D compiler
//
// This file is distributed under the BSD-style LDC license. See the LICENSE
// file for details.
//
// Support limited to Objective-C on Darwin (OS X, iOS, tvOS, watchOS)
//
//===----------------------------------------------------------------------===//

// FIXME: the guts of ProtocolDeclaration from dmd's objc_glue.d is not implemented yet

#include "gen/objcgen.h"

#include "dmd/mtype.h"
#include "dmd/objc.h"
#include "dmd/expression.h"
#include "dmd/declaration.h"
#include "dmd/identifier.h"
#include "gen/irstate.h"

bool objc_isSupported(const llvm::Triple &triple) {
  if (triple.isOSDarwin()) {
    // Objective-C only supported on Darwin at this time
    switch (triple.getArch()) {
    case llvm::Triple::aarch64: // arm64 iOS, tvOS
    case llvm::Triple::arm:     // armv6 iOS
    case llvm::Triple::thumb:   // thumbv7 iOS, watchOS
    case llvm::Triple::x86_64:  // OSX, iOS, tvOS sim
      return true;
    case llvm::Triple::x86: // OSX, iOS, watchOS sim
      return false;
    default:
      break;
    }
  }
  return false;
}

// cache the result
llvm::GlobalVariable *getGlobal(
	llvm::Module& module,
	llvm::StringRef name,
	llvm::Type* type = nullptr
) {
	if(type == nullptr)
		type = llvm::PointerType::get(llvm::Type::getVoidTy(module.getContext()), 0);
	auto var = new LLGlobalVariable(
		module,
		type,
		false, // prevent const elimination optimization
		LLGlobalValue::ExternalLinkage,
		nullptr, // initializer
		name,
		nullptr, // insert before
		LLGlobalVariable::NotThreadLocal,
		0, // address space
		true); // externally initialized

	return var;
}

// cache the result!
llvm::GlobalVariable *getGlobalWithBytes(
	llvm::Module& module,
	llvm::StringRef name,
	std::vector<llvm::Constant*> packedContents
) {
	auto init = llvm::ConstantStruct::getAnon(
		packedContents,
		true // packed
	);
	/*
	llvm::StringRef(bytes, len), len, llvm::Type::getInt8Ty(module.getContext()));
	*/

	auto var = new LLGlobalVariable(
		module,
		init->getType(),
		false, // prevent const elimination optimization
		LLGlobalValue::ExternalLinkage,
		init,
		name,
		nullptr, // insert before
		LLGlobalVariable::NotThreadLocal,
		0, // address space
		false); // externally initialized
	var->setSection("__DATA,__objc_data,regular");

	return var;

	// see llvm::ConstantStruct::getAnon
	// // for what will probably actually be necessary
}

llvm::Constant* size_tV(llvm::Module& module, size_t v) {
	return llvm::ConstantInt::get(
		llvm::Type::getInt64Ty(module.getContext()),
		v
	);
}

llvm::Constant* dwordV(llvm::Module& module, unsigned int v) {
	return llvm::ConstantInt::get(
		llvm::Type::getInt32Ty(module.getContext()),
		v
	);
}

llvm::Constant* xoffOrNull(llvm::Module& module, llvm::GlobalVariable* g) {
	if(g == nullptr)
		return size_tV(module, 0);
	else
		return g;
}


llvm::GlobalVariable *ObjCState::getIVarOffset(const ClassDeclaration& cd, const VarDeclaration& vd, bool outputSymbol) {
	char buffer[256];
	snprintf(buffer, sizeof(buffer), "OBJC_IVAR_$_%s.%s", cd.ident->toChars(), vd.ident->toChars());

	auto name = llvm::StringRef(buffer);

	auto it = ivarOffsetTable.find(name);
	if (it != ivarOffsetTable.end()) {
		return it->second;
	}

	if(cd.objc.isExtern) {
		auto var = getGlobal(module, name);

		ivarOffsetTable[name] = var;
		retain(var);
		return var;
	} else {
		// FIXME: needs its actual offset in here
		std::vector<llvm::Constant*> members;
		members.push_back(size_tV(module, vd.offset));

		auto var = getGlobalWithBytes(module, name, members);

		ivarOffsetTable[name] = var;
		retain(var);
		return var;
	}
}

llvm::GlobalVariable* getEmptyCache(llvm::Module& module) {
	static llvm::GlobalVariable* g;
	if(g == nullptr)
		g = getGlobal(module, "_objc_empty_cache");
	return g;
}
llvm::GlobalVariable* getEmptyVtable(llvm::Module& module) {
	static llvm::GlobalVariable* g;
	if(g == nullptr)
		g = getGlobal(module, "_objc_empty_vtable");
	return g;
}

llvm::GlobalVariable *ObjCState::getMethVarType(const llvm::StringRef& ty) {
	auto it = methVarTypeTable.find(ty);
	if (it != methVarTypeTable.end()) {
		return it->second;
	}

  	auto var = getCStringVar("OBJC_METH_VAR_TYPE", ty, "__TEXT,__objc_methtype,cstring_literals");

	methVarTypeTable[ty] = var;
	retain(var);
	return var;
}

const char* dTypeToObjcType(Type* t) {
	// FIXME: this is copy/paste from getTypeEncoding in dmd's obc_glue.d
	// and it should just be shared

        switch (t->ty)
        {
            case TY::Tvoid: return "v";
            case TY::Tbool: return "B";
            case TY::Tint8: return "c";
            case TY::Tuns8: return "C";
            case TY::Tchar: return "C";
            case TY::Tint16: return "s";
            case TY::Tuns16: return "S";
            case TY::Twchar: return "S";
            case TY::Tint32: return "i";
            case TY::Tuns32: return "I";
            case TY::Tdchar: return "I";
            case TY::Tint64: return "q";
            case TY::Tuns64: return "Q";
            case TY::Tfloat32: return "f";
            case TY::Tcomplex32: return "jf";
            case TY::Tfloat64: return "d";
            case TY::Tcomplex64: return "jd";
            case TY::Tfloat80: return "D";
            case TY::Tcomplex80: return "jD";
            default: return "?"; // unknown
        }
}

llvm::GlobalVariable *ObjCState::getMethVarType(const FuncDeclaration& fd) {
	std::string result;

	result.append(dTypeToObjcType(fd.type->nextOf()));

        if (fd.parameters)
        {
		for(size_t idx; idx < fd.parameters->length; idx++)
			result.append(dTypeToObjcType((*fd.parameters)[idx]->type));
        }

        return getMethVarType(result);
}

llvm::GlobalVariable *ObjCState::getClassNameRo(const llvm::StringRef& name) {
	auto it = classNameRoTable.find(name);
	if (it != classNameRoTable.end()) {
		return it->second;
	}

  	auto var = getCStringVar("OBJC_CLASS_NAME", name, "__TEXT,__objc_classname,cstring_literals");

	classNameRoTable[name] = var;
	retain(var);
	return var;
}

#include "ir/irfunction.h"

llvm::GlobalVariable* getMethodList(ObjCState& state, llvm::Module& module, ClassDeclaration& cd, bool isMeta) {
	auto methods = isMeta ? cd.objc.metaclass->objc.methodList : cd.objc.methodList;

	int methodCount = 0;
	for(d_size_t idx = 0; idx < methods.length; idx++) {
		if(methods.ptr[idx]->fbody)
			methodCount++;
	}

	if(methodCount == 0)
		return nullptr;

	std::vector<llvm::Constant*> members;
	members.push_back(dwordV(module, 24)); // _objc_method.sizeof
	members.push_back(dwordV(module, methodCount));

	for(d_size_t idx = 0; idx < methods.length; idx++) {
		if(methods.ptr[idx]->fbody) {
			auto func = methods.ptr[idx];

			auto sel = func->objc.selector;
  			llvm::StringRef s(sel->stringvalue, sel->stringlen);
			members.push_back(state.getMethVarName(s));
			members.push_back(state.getMethVarType(*func));
			members.push_back(DtoCallee(func));
		}
	}

	char buffer[256];
	auto prefix = isMeta ? "OBJC_$_CLASS_METHODS_" : "OBJC_$_INSTANCE_METHODS_";
	snprintf(buffer, sizeof(buffer), "%s%s", prefix, cd.objc.identifier->toChars());

	return getGlobalWithBytes(module, buffer, members);
}
llvm::GlobalVariable* getProtocolList(llvm::Module& module, ClassDeclaration& cd) {
	return nullptr; // FIXME
}

llvm::GlobalVariable* ObjCState::getProtocolSymbol(const InterfaceDeclaration& id) {
    /*
	llvm::StringRef name = id.objc.identifier->toChars();

	auto it = protocolTable.find(name);
	if (it != protocolTable.end()) {
		return it->second;
	}

    // see line 1300 of the D file

	std::vector<llvm::Constant*> members;


  	auto var = getGlobalWithBytes(module, name, members);

	protocolTable[name] = var;
	retain(var);

	return var;
    */
    return nullptr; // FIXME;
}

int instanceStart(ClassDeclaration& classDeclaration, bool isMeta) {
        if (isMeta)
            return 40;

        int start = classDeclaration.size(classDeclaration.loc);

        if (!classDeclaration.members || classDeclaration.members->length == 0)
            return start;

        for(d_size_t idx = 0; idx < classDeclaration.members->length; idx++)
        {
            auto var = ((*classDeclaration.members)[idx])->isVarDeclaration();

            if (var && var->isField())
                return var->offset;
        }

        return start;
}

// this should be cached because it is only called from getClassName, which is cached
llvm::GlobalVariable* getClassRo(ObjCState& state, llvm::Module& module, ClassDeclaration& cd, bool isMeta) {
	std::vector<llvm::Constant*> members;

	unsigned int flags = isMeta ? 1 : 0; 
	if(cd.objc.isRootClass())
		flags |= 2;
	members.push_back(dwordV(module, flags));
	members.push_back(dwordV(module, instanceStart(cd, isMeta)));
	members.push_back(dwordV(module, isMeta ? 40 : cd.size(cd.loc))); // instanceSize

	members.push_back(dwordV(module, 0)); // reserved

	members.push_back(size_tV(module, 0)); // ivar layout
	members.push_back(state.getClassNameRo(cd.ident->toChars())); // name of the class

	members.push_back(xoffOrNull(module, getMethodList(state, module, cd, isMeta)));
	members.push_back(xoffOrNull(module, getProtocolList(module, cd)));

	if(isMeta) {
		members.push_back(size_tV(module, 0)); // instance variable list
		members.push_back(size_tV(module, 0)); // weak ivar layout
		members.push_back(size_tV(module, 0)); // properties
	} else {
		llvm::GlobalVariable* getIVarList = nullptr;
		if(cd.fields.length > 0) {
			std::vector<llvm::Constant*> ivars;
			ivars.push_back(dwordV(module, 32)); // entsize
			ivars.push_back(dwordV(module, cd.fields.length)); // ivar count

			for(size_t idx = 0; idx < cd.fields.size(); idx++) {
				// must not be null, must not be static,
				// but those are already set by frontend
				auto vd = cd.fields[idx]->isVarDeclaration();

				ivars.push_back(state.getIVarOffset(cd, *vd, true)); // pointer to ivar offset
				ivars.push_back(state.getMethVarName(llvm::StringRef(vd->ident->toChars())));
				ivars.push_back(state.getMethVarType(dTypeToObjcType(vd->type)));
				ivars.push_back(dwordV(module, vd->alignment.isDefault() ? -1 : vd->alignment.get()));
				ivars.push_back(dwordV(module, vd->size(vd->loc)));
			}

			char buffer[256];
			snprintf(buffer, sizeof(buffer), "OBJC_$_INSTANCE_VARIABLES_%s", cd.objc.identifier->toChars());

			getIVarList = getGlobalWithBytes(module, buffer, ivars);
			getIVarList->setSection("__DATA,__objc_const,regular");
		}

		members.push_back(xoffOrNull(module, getIVarList));
		members.push_back(size_tV(module, 0)); // weak ivar layout
		members.push_back(xoffOrNull(module, nullptr /* getPropertyList() but properties are not supported yet in dmd either */));
	}

	char buffer[256];
	auto prefix = isMeta ? "OBJC_METACLASS_RO_$_" : "OBJC_CLASS_RO_$_";
	snprintf(buffer, sizeof(buffer), "%s%s", prefix, cd.ident->toChars());

	auto name = llvm::StringRef(buffer);

	auto var = getGlobalWithBytes(module, name, members);
	var->setSection("__DATA,__objc_const,regular");
	return var;
}

llvm::GlobalVariable *ObjCState::getClassName(const ClassDeclaration& cd, bool isMeta) {
	auto prefix = isMeta ? "OBJC_METACLASS_$_" : "OBJC_CLASS_$_";

	char buffer[256];
	snprintf(buffer, sizeof(buffer), "%s%s", prefix, cd.ident->toChars());

	auto name = llvm::StringRef(buffer);

	auto it = classNameTable.find(name);
	if (it != classNameTable.end()) {
		return it->second;
	}

	if(cd.objc.isExtern) {
		auto var = getGlobal(module, name);

		classNameTable[name] = var;
		retain(var);
		return var;
	} else {
		// if it is not extern, we need to initialize it with the class definition

		std::vector<llvm::Constant*> members;

		if(isMeta) {
			const ClassDeclaration* metaclassDeclaration = &cd;
			while(metaclassDeclaration->baseClass)
				metaclassDeclaration = metaclassDeclaration->baseClass;

			members.push_back(getClassName(*metaclassDeclaration, true));
		} else {
			members.push_back(getClassName(cd, true));

			// not extern, not meta, we need to add it to the module list
			classes.push_back(const_cast<ClassDeclaration*>(&cd));
		}

		// base class symbol
		members.push_back(xoffOrNull(
			module,
			cd.baseClass ? getClassName(*cd.baseClass, isMeta) : nullptr
		));

		members.push_back(getEmptyCache(module));
		members.push_back(getEmptyVtable(module));
		members.push_back(xoffOrNull(module, getClassRo(*this, module, const_cast<ClassDeclaration&>(cd), isMeta)));

		auto var = getGlobalWithBytes(module, name, members);

		classNameTable[name] = var;
		retain(var);
		return var;
	}
}

llvm::GlobalVariable *ObjCState::getClassReference(const ClassDeclaration& cd) {
        hasSymbols_ = true;

        auto name = llvm::StringRef(cd.objc.identifier->toChars());

	auto it = classReferenceTable.find(name);
	if (it != classReferenceTable.end()) {
		return it->second;
	}

	auto gvar = getClassName(cd, false);

	auto var = new LLGlobalVariable(
		module, gvar->getType(),
		false, // prevent const elimination optimization
		LLGlobalValue::PrivateLinkage, gvar, "OBJC_CLASSLIST_REFERENCES_$_", nullptr,
		LLGlobalVariable::NotThreadLocal, 0,
		true); // externally initialized
	var->setSection("__DATA,__objc_classrefs,regular,no_dead_strip");

	classReferenceTable[name] = var;
	retain(var);
	return var;
}

LLGlobalVariable *ObjCState::getCStringVar(const char *symbol,
                                           const llvm::StringRef &str,
                                           const char *section) {
  auto init = llvm::ConstantDataArray::getString(module.getContext(), str);
  auto var = new LLGlobalVariable(module, init->getType(), false,
                                  LLGlobalValue::PrivateLinkage, init, symbol);
  var->setSection(section);
  return var;
}

LLGlobalVariable *ObjCState::getMethVarName(const llvm::StringRef &name) {
  auto it = methVarNameTable.find(name);
  if (it != methVarNameTable.end()) {
    return it->second;
  }

  auto var = getCStringVar("OBJC_METH_VAR_NAME_", name, "__TEXT,__objc_methname,cstring_literals");
  methVarNameTable[name] = var;
  retain(var);
  return var;
}

LLGlobalVariable *ObjCState::getMethVarRef(const ObjcSelector &sel) {
  llvm::StringRef s(sel.stringvalue, sel.stringlen);
  auto it = methVarRefTable.find(s);
  if (it != methVarRefTable.end()) {
    return it->second;
  }

  auto gvar = getMethVarName(s);
  auto selref = new LLGlobalVariable(
      module, gvar->getType(),
      false, // prevent const elimination optimization
      LLGlobalValue::PrivateLinkage, gvar, "OBJC_SELECTOR_REFERENCES_", nullptr,
      LLGlobalVariable::NotThreadLocal, 0,
      true); // externally initialized
  selref->setSection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip");

  // Save for later lookup and prevent optimizer elimination
  methVarRefTable[s] = selref;
  retain(selref);

  return selref;
}

void ObjCState::retain(LLConstant *sym) {
  retainedSymbols.push_back(DtoBitCast(sym, getVoidPtrType()));
}

void ObjCState::finalize() {
  if (!retainedSymbols.empty()) {
    std::vector<llvm::Constant*> members;
    for (auto cls = classes.begin(); cls != classes.end(); ++cls) {
    	auto c = *cls;
        if (c->classKind == ClassKind::objc && !c->objc.isExtern && !c->objc.isMeta) {
            // this is the only kind of class that should be in the list but still
            // put it out

            members.push_back(getClassName(*c, false));
        }
    }
    // categories? idk what that even is

    auto sym = getGlobalWithBytes(module, "L_OBJC_LABEL_CLASS_$", members);
    sym->setSection("__DATA,__objc_classlist,regular,no_dead_strip");
    retainedSymbols.push_back(sym);

    genImageInfo();

    // add in references so optimizer won't remove symbols.
    retainSymbols();
  }
}

void ObjCState::genImageInfo() {
  // Use LLVM to generate image info
  const char *section = "__DATA,__objc_imageinfo,regular,no_dead_strip";
  module.addModuleFlag(llvm::Module::Error, "Objective-C Version", 2 /* non fragile abi */); //  unused?
  module.addModuleFlag(llvm::Module::Error, "Objective-C Image Info Version", 0u); // version
  module.addModuleFlag(llvm::Module::Error, "Objective-C Image Info Section", llvm::MDString::get(module.getContext(), section));
  module.addModuleFlag(llvm::Module::Override, "Objective-C Garbage Collection", 0u); // flags
}

void ObjCState::retainSymbols() {
  // put all objc symbols in the llvm.compiler.used array so optimizer won't
  // remove.
  auto arrayType = LLArrayType::get(retainedSymbols.front()->getType(),
                                    retainedSymbols.size());
  auto usedArray = LLConstantArray::get(arrayType, retainedSymbols);
  auto var = new LLGlobalVariable(module, arrayType, false,
                                  LLGlobalValue::AppendingLinkage, usedArray,
                                  "llvm.compiler.used");
  var->setSection("llvm.metadata");
}
