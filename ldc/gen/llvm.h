//===-- gen/llvm.h - Common LLVM includes and aliases -----------*- C++ -*-===//
//
//                         LDC – the LLVM D compiler
//
// This file is distributed under the BSD-style LDC license. See the LICENSE
// file for details.
//
//===----------------------------------------------------------------------===//
//
// Pulls in commonly used LLVM headers and provides shorthands for some LLVM
// types.
//
// TODO: Consider removing this file; the aliases mostly make code more
// cumbersome to read for people familiar with LLVM anyway.
//
//===----------------------------------------------------------------------===//

#pragma once

#include "llvm/IR/Type.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/DebugInfo.h"

using llvm::APFloat;
using llvm::APInt;
using llvm::IRBuilder;

#if LDC_LLVM_VER >= 1900
#define GET_INTRINSIC_DECL(_X, _TY)                                              \
  (llvm::Intrinsic::getDeclaration(&gIR->module, llvm::Intrinsic::_X, _TY))
#else
#define GET_INTRINSIC_DECL(_X, _TY)                                              \
  (llvm::Intrinsic::getDeclaration(&gIR->module, llvm::Intrinsic::_X))
#endif

// shortcuts for the common llvm types

#define LLType llvm::Type
#define LLFunctionType llvm::FunctionType
#define LLPointerType llvm::PointerType
#define LLStructType llvm::StructType
#define LLArrayType llvm::ArrayType
#define LLIntegerType llvm::IntegerType
#define LLOpaqueType llvm::OpaqueType

#define LLValue llvm::Value
#define LLGlobalValue llvm::GlobalValue
#define LLGlobalVariable llvm::GlobalVariable
#define LLFunction llvm::Function

#define LLConstant llvm::Constant
#define LLConstantStruct llvm::ConstantStruct
#define LLConstantArray llvm::ConstantArray
#define LLConstantInt llvm::ConstantInt
#define LLConstantFP llvm::ConstantFP

#define LLSmallVector llvm::SmallVector

#define LLConstantList std::vector<LLConstant *>
#define LLStringRef llvm::StringRef