// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// https://developers.google.com/protocol-buffers/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>

#import "VPKGPBUtilities.h"

#import "VPKGPBDescriptor_PackagePrivate.h"

// Macros for stringifying library symbols. These are used in the generated
// VPKGPB descriptor classes wherever a library symbol name is represented as a
// string.
#define VPKGPBStringify(S) #S
#define VPKGPBStringifySymbol(S) VPKGPBStringify(S)

#define VPKGPBNSStringify(S) @ #S
#define VPKGPBNSStringifySymbol(S) VPKGPBNSStringify(S)

// Macros for generating a Class from a class name. These are used in
// the generated VPKGPB descriptor classes wherever an Objective C class
// reference is needed for a generated class.
#define VPKGPBObjCClassSymbol(name) OBJC_CLASS_$_##name
#define VPKGPBObjCClass(name) ((__bridge Class) & (VPKGPBObjCClassSymbol(name)))
#define VPKGPBObjCClassDeclaration(name) extern const VPKGPBObjcClass_t VPKGPBObjCClassSymbol(name)

// Constant to internally mark when there is no has bit.
#define VPKGPBNoHasBit INT32_MAX

CF_EXTERN_C_BEGIN

// These two are used to inject a runtime check for version mismatch into the
// generated sources to make sure they are linked with a supporting runtime.
void VPKGPBCheckRuntimeVersionSupport(int32_t objcRuntimeVersion);
VPKGPB_INLINE void VPKGPB_DEBUG_CHECK_RUNTIME_VERSIONS(void) {
  // NOTE: By being inline here, this captures the value from the library's
  // headers at the time the generated code was compiled.
#if defined(DEBUG) && DEBUG
  VPKGPBCheckRuntimeVersionSupport(GOOGLE_PROTOBUF_OBJC_VERSION);
#endif
}

// Helper called within the library when the runtime detects something that
// indicates a older runtime is being used with newer generated code. Normally
// VPKGPB_DEBUG_CHECK_RUNTIME_VERSIONS() gates this with a better message; this
// is just a final safety net to prevent otherwise hard to diagnose errors.
void VPKGPBRuntimeMatchFailure(void);

// Legacy version of the checks, remove when GOOGLE_PROTOBUF_OBJC_GEN_VERSION
// goes away (see more info in VPKGPBBootstrap.h).
void VPKGPBCheckRuntimeVersionInternal(int32_t version);
VPKGPB_INLINE void VPKGPBDebugCheckRuntimeVersion(void) {
#if defined(DEBUG) && DEBUG
  VPKGPBCheckRuntimeVersionInternal(GOOGLE_PROTOBUF_OBJC_GEN_VERSION);
#endif
}

// Conversion functions for de/serializing floating point types.

VPKGPB_INLINE int64_t VPKGPBConvertDoubleToInt64(double v) {
  VPKGPBInternalCompileAssert(sizeof(double) == sizeof(int64_t), double_not_64_bits);
  int64_t result;
  memcpy(&result, &v, sizeof(result));
  return result;
}

VPKGPB_INLINE int32_t VPKGPBConvertFloatToInt32(float v) {
  VPKGPBInternalCompileAssert(sizeof(float) == sizeof(int32_t), float_not_32_bits);
  int32_t result;
  memcpy(&result, &v, sizeof(result));
  return result;
}

VPKGPB_INLINE double VPKGPBConvertInt64ToDouble(int64_t v) {
  VPKGPBInternalCompileAssert(sizeof(double) == sizeof(int64_t), double_not_64_bits);
  double result;
  memcpy(&result, &v, sizeof(result));
  return result;
}

VPKGPB_INLINE float VPKGPBConvertInt32ToFloat(int32_t v) {
  VPKGPBInternalCompileAssert(sizeof(float) == sizeof(int32_t), float_not_32_bits);
  float result;
  memcpy(&result, &v, sizeof(result));
  return result;
}

VPKGPB_INLINE int32_t VPKGPBLogicalRightShift32(int32_t value, int32_t spaces) {
  return (int32_t)((uint32_t)(value) >> spaces);
}

VPKGPB_INLINE int64_t VPKGPBLogicalRightShift64(int64_t value, int32_t spaces) {
  return (int64_t)((uint64_t)(value) >> spaces);
}

// Decode a ZigZag-encoded 32-bit value.  ZigZag encodes signed integers
// into values that can be efficiently encoded with varint.  (Otherwise,
// negative values must be sign-extended to 64 bits to be varint encoded,
// thus always taking 10 bytes on the wire.)
VPKGPB_INLINE int32_t VPKGPBDecodeZigZag32(uint32_t n) {
  return (int32_t)(VPKGPBLogicalRightShift32((int32_t)n, 1) ^ -((int32_t)(n)&1));
}

// Decode a ZigZag-encoded 64-bit value.  ZigZag encodes signed integers
// into values that can be efficiently encoded with varint.  (Otherwise,
// negative values must be sign-extended to 64 bits to be varint encoded,
// thus always taking 10 bytes on the wire.)
VPKGPB_INLINE int64_t VPKGPBDecodeZigZag64(uint64_t n) {
  return (int64_t)(VPKGPBLogicalRightShift64((int64_t)n, 1) ^ -((int64_t)(n)&1));
}

// Encode a ZigZag-encoded 32-bit value.  ZigZag encodes signed integers
// into values that can be efficiently encoded with varint.  (Otherwise,
// negative values must be sign-extended to 64 bits to be varint encoded,
// thus always taking 10 bytes on the wire.)
VPKGPB_INLINE uint32_t VPKGPBEncodeZigZag32(int32_t n) {
  // Note:  the right-shift must be arithmetic
  return ((uint32_t)n << 1) ^ (uint32_t)(n >> 31);
}

// Encode a ZigZag-encoded 64-bit value.  ZigZag encodes signed integers
// into values that can be efficiently encoded with varint.  (Otherwise,
// negative values must be sign-extended to 64 bits to be varint encoded,
// thus always taking 10 bytes on the wire.)
VPKGPB_INLINE uint64_t VPKGPBEncodeZigZag64(int64_t n) {
  // Note:  the right-shift must be arithmetic
  return ((uint64_t)n << 1) ^ (uint64_t)(n >> 63);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

VPKGPB_INLINE BOOL VPKGPBDataTypeIsObject(VPKGPBDataType type) {
  switch (type) {
    case VPKGPBDataTypeBytes:
    case VPKGPBDataTypeString:
    case VPKGPBDataTypeMessage:
    case VPKGPBDataTypeGroup:
      return YES;
    default:
      return NO;
  }
}

VPKGPB_INLINE BOOL VPKGPBDataTypeIsMessage(VPKGPBDataType type) {
  switch (type) {
    case VPKGPBDataTypeMessage:
    case VPKGPBDataTypeGroup:
      return YES;
    default:
      return NO;
  }
}

VPKGPB_INLINE BOOL VPKGPBFieldDataTypeIsMessage(VPKGPBFieldDescriptor *field) {
  return VPKGPBDataTypeIsMessage(field->description_->dataType);
}

VPKGPB_INLINE BOOL VPKGPBFieldDataTypeIsObject(VPKGPBFieldDescriptor *field) {
  return VPKGPBDataTypeIsObject(field->description_->dataType);
}

VPKGPB_INLINE BOOL VPKGPBExtensionIsMessage(VPKGPBExtensionDescriptor *ext) {
  return VPKGPBDataTypeIsMessage(ext->description_->dataType);
}

// The field is an array/map or it has an object value.
VPKGPB_INLINE BOOL VPKGPBFieldStoresObject(VPKGPBFieldDescriptor *field) {
  VPKGPBMessageFieldDescription *desc = field->description_;
  if ((desc->flags & (VPKGPBFieldRepeated | VPKGPBFieldMapKeyMask)) != 0) {
    return YES;
  }
  return VPKGPBDataTypeIsObject(desc->dataType);
}

BOOL VPKGPBGetHasIvar(VPKGPBMessage *self, int32_t index, uint32_t fieldNumber);
void VPKGPBSetHasIvar(VPKGPBMessage *self, int32_t idx, uint32_t fieldNumber, BOOL value);
uint32_t VPKGPBGetHasOneof(VPKGPBMessage *self, int32_t index);

VPKGPB_INLINE BOOL VPKGPBGetHasIvarField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  return VPKGPBGetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number);
}

#pragma clang diagnostic pop

// Disable clang-format for the macros.
// clang-format off

//%PDDM-DEFINE VPKGPB_IVAR_SET_DECL(NAME, TYPE)
//%void VPKGPBSet##NAME##IvarWithFieldPrivate(VPKGPBMessage *self,
//%            NAME$S                    VPKGPBFieldDescriptor *field,
//%            NAME$S                    TYPE value);
//%PDDM-EXPAND VPKGPB_IVAR_SET_DECL(Bool, BOOL)
// This block of code is generated, do not edit it directly.

void VPKGPBSetBoolIvarWithFieldPrivate(VPKGPBMessage *self,
                                    VPKGPBFieldDescriptor *field,
                                    BOOL value);
//%PDDM-EXPAND VPKGPB_IVAR_SET_DECL(Int32, int32_t)
// This block of code is generated, do not edit it directly.

void VPKGPBSetInt32IvarWithFieldPrivate(VPKGPBMessage *self,
                                     VPKGPBFieldDescriptor *field,
                                     int32_t value);
//%PDDM-EXPAND VPKGPB_IVAR_SET_DECL(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.

void VPKGPBSetUInt32IvarWithFieldPrivate(VPKGPBMessage *self,
                                      VPKGPBFieldDescriptor *field,
                                      uint32_t value);
//%PDDM-EXPAND VPKGPB_IVAR_SET_DECL(Int64, int64_t)
// This block of code is generated, do not edit it directly.

void VPKGPBSetInt64IvarWithFieldPrivate(VPKGPBMessage *self,
                                     VPKGPBFieldDescriptor *field,
                                     int64_t value);
//%PDDM-EXPAND VPKGPB_IVAR_SET_DECL(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.

void VPKGPBSetUInt64IvarWithFieldPrivate(VPKGPBMessage *self,
                                      VPKGPBFieldDescriptor *field,
                                      uint64_t value);
//%PDDM-EXPAND VPKGPB_IVAR_SET_DECL(Float, float)
// This block of code is generated, do not edit it directly.

void VPKGPBSetFloatIvarWithFieldPrivate(VPKGPBMessage *self,
                                     VPKGPBFieldDescriptor *field,
                                     float value);
//%PDDM-EXPAND VPKGPB_IVAR_SET_DECL(Double, double)
// This block of code is generated, do not edit it directly.

void VPKGPBSetDoubleIvarWithFieldPrivate(VPKGPBMessage *self,
                                      VPKGPBFieldDescriptor *field,
                                      double value);
//%PDDM-EXPAND-END (7 expansions)

// clang-format on

void VPKGPBSetEnumIvarWithFieldPrivate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, int32_t value);

id VPKGPBGetObjectIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

void VPKGPBSetObjectIvarWithFieldPrivate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, id value);
void VPKGPBSetRetainedObjectIvarWithFieldPrivate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field,
                                              id __attribute__((ns_consumed)) value);

// VPKGPBGetObjectIvarWithField will automatically create the field (message) if
// it doesn't exist. VPKGPBGetObjectIvarWithFieldNoAutocreate will return nil.
id VPKGPBGetObjectIvarWithFieldNoAutocreate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

// Clears and releases the autocreated message ivar, if it's autocreated. If
// it's not set as autocreated, this method does nothing.
void VPKGPBClearAutocreatedMessageIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

// Returns an Objective C encoding for |selector|. |instanceSel| should be
// YES if it's an instance selector (as opposed to a class selector).
// |selector| must be a selector from MessageSignatureProtocol.
const char *VPKGPBMessageEncodingForSelector(SEL selector, BOOL instanceSel);

// Helper for text format name encoding.
// decodeData is the data describing the special decodes.
// key and inputString are the input that needs decoding.
NSString *VPKGPBDecodeTextFormatName(const uint8_t *decodeData, int32_t key, NSString *inputString);

// Shims from the older generated code into the runtime.
void VPKGPBSetInt32IvarWithFieldInternal(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, int32_t value,
                                      VPKGPBFileSyntax syntax);
void VPKGPBMaybeClearOneof(VPKGPBMessage *self, VPKGPBOneofDescriptor *oneof, int32_t oneofHasIndex,
                        uint32_t fieldNumberNotToClear);

// A series of selectors that are used solely to get @encoding values
// for them by the dynamic protobuf runtime code. See
// VPKGPBMessageEncodingForSelector for details. VPKGPBRootObject conforms to
// the protocol so that it is encoded in the Objective C runtime.
@protocol VPKGPBMessageSignatureProtocol
@optional

#define VPKGPB_MESSAGE_SIGNATURE_ENTRY(TYPE, NAME) \
  -(TYPE)get##NAME;                             \
  -(void)set##NAME : (TYPE)value;               \
  -(TYPE)get##NAME##AtIndex : (NSUInteger)index;

VPKGPB_MESSAGE_SIGNATURE_ENTRY(BOOL, Bool)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(uint32_t, Fixed32)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(int32_t, SFixed32)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(float, Float)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(uint64_t, Fixed64)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(int64_t, SFixed64)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(double, Double)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(int32_t, Int32)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(int64_t, Int64)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(int32_t, SInt32)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(int64_t, SInt64)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(uint32_t, UInt32)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(uint64_t, UInt64)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(NSData *, Bytes)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(NSString *, String)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(VPKGPBMessage *, Message)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(VPKGPBMessage *, Group)
VPKGPB_MESSAGE_SIGNATURE_ENTRY(int32_t, Enum)

#undef VPKGPB_MESSAGE_SIGNATURE_ENTRY

- (id)getArray;
- (NSUInteger)getArrayCount;
- (void)setArray:(NSArray *)array;
+ (id)getClassValue;
@end

BOOL VPKGPBClassHasSel(Class aClass, SEL sel);

CF_EXTERN_C_END
