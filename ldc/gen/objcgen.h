//===-- gen/objcgen.cpp -----------------------------------------*- C++ -*-===//
//
//                         LDC – the LLVM D compiler
//
// This file is distributed under the BSD-style LDC license. See the LICENSE
// file for details.
//
//===----------------------------------------------------------------------===//
//
// Functions for generating Objective-C method calls.
//
//===----------------------------------------------------------------------===//

#pragma once

#include <vector>
#include "llvm/ADT/StringMap.h"

struct ObjcSelector;
namespace llvm {
class Constant;
class GlobalVariable;
class Module;
class Triple;
}

class ClassDeclaration;
class FuncDeclaration;
class InterfaceDeclaration;
class VarDeclaration;

bool objc_isSupported(const llvm::Triple &triple);

typedef llvm::StringMap<llvm::GlobalVariable *> SymbolCache;

// Objective-C state tied to an LLVM module (object file).
class ObjCState {
public:
  ObjCState(llvm::Module &module) : module(module) {}

  llvm::GlobalVariable *getMethVarRef(const ObjcSelector &sel);
  llvm::GlobalVariable *getClassReference(const ClassDeclaration& cd);
  llvm::GlobalVariable *getIVarOffset(const ClassDeclaration& cd, const VarDeclaration& var, bool outputSymbol);
  llvm::GlobalVariable *getMethVarName(const llvm::StringRef &name);
  llvm::GlobalVariable *getMethVarType(const llvm::StringRef& ty);
  llvm::GlobalVariable *getMethVarType(const FuncDeclaration& ty);
  llvm::GlobalVariable *getClassNameRo(const llvm::StringRef& name);

  llvm::GlobalVariable* getProtocolSymbol(const InterfaceDeclaration& id);

  void finalize();

private:
  llvm::Module &module;

  // symbols that shouldn't be optimized away
  std::vector<llvm::Constant *> retainedSymbols;

  // Cache for `_OBJC_METACLASS_$_`/`_OBJC_CLASS_$_` symbols.
  SymbolCache classNameTable;
  SymbolCache classNameRoTable;

  // Cache for `L_OBJC_CLASSLIST_REFERENCES_` symbols.
  SymbolCache classReferenceTable;

  // Cache for `__OBJC_PROTOCOL_$_` symbols.
  SymbolCache protocolTable;

  SymbolCache methVarNameTable;
  SymbolCache methVarRefTable;
  SymbolCache methVarTypeTable;

  // Cache for instance variable offsets
  SymbolCache ivarOffsetTable;

  std::vector<ClassDeclaration*> classes;

  llvm::GlobalVariable *getCStringVar(const char *symbol,
                                      const llvm::StringRef &str,
                                      const char *section);
  llvm::GlobalVariable *getClassName(const ClassDeclaration& cd, bool isMeta);
  void retain(llvm::Constant *sym);

  void genImageInfo();
  void retainSymbols();

  bool hasSymbols_ = false;
};
