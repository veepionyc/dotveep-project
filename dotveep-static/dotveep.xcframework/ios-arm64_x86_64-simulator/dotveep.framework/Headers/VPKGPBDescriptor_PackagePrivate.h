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

// This header is private to the ProtobolBuffers library and must NOT be
// included by any sources outside this library. The contents of this file are
// subject to change at any time without notice.

#import "VPKGPBDescriptor.h"
#import "VPKGPBWireFormat.h"

// Describes attributes of the field.
typedef NS_OPTIONS(uint16_t, VPKGPBFieldFlags) {
  VPKGPBFieldNone = 0,
  // These map to standard protobuf concepts.
  VPKGPBFieldRequired = 1 << 0,
  VPKGPBFieldRepeated = 1 << 1,
  VPKGPBFieldPacked = 1 << 2,
  VPKGPBFieldOptional = 1 << 3,
  VPKGPBFieldHasDefaultValue = 1 << 4,

  // Indicate that the field should "clear" when set to zero value. This is the
  // proto3 non optional behavior for singular data (ints, data, string, enum)
  // fields.
  VPKGPBFieldClearHasIvarOnZero = 1 << 5,
  // Indicates the field needs custom handling for the TextFormat name, if not
  // set, the name can be derived from the ObjC name.
  VPKGPBFieldTextFormatNameCustom = 1 << 6,
  // This flag has never had any meaning, it was set on all enum fields.
  VPKGPBFieldHasEnumDescriptor = 1 << 7,

  // These are not standard protobuf concepts, they are specific to the
  // Objective C runtime.

  // These bits are used to mark the field as a map and what the key
  // type is.
  VPKGPBFieldMapKeyMask = 0xF << 8,
  VPKGPBFieldMapKeyInt32 = 1 << 8,
  VPKGPBFieldMapKeyInt64 = 2 << 8,
  VPKGPBFieldMapKeyUInt32 = 3 << 8,
  VPKGPBFieldMapKeyUInt64 = 4 << 8,
  VPKGPBFieldMapKeySInt32 = 5 << 8,
  VPKGPBFieldMapKeySInt64 = 6 << 8,
  VPKGPBFieldMapKeyFixed32 = 7 << 8,
  VPKGPBFieldMapKeyFixed64 = 8 << 8,
  VPKGPBFieldMapKeySFixed32 = 9 << 8,
  VPKGPBFieldMapKeySFixed64 = 10 << 8,
  VPKGPBFieldMapKeyBool = 11 << 8,
  VPKGPBFieldMapKeyString = 12 << 8,

  // If the enum for this field is "closed", meaning that it:
  // - Has a fixed set of named values.
  // - Encountering values not in this set causes them to be treated as unknown
  //   fields.
  // - The first value (i.e., the default) may be nonzero.
  // NOTE: This could be tracked just on the VPKGPBEnumDescriptor, but to support
  // previously generated code, there would be not data to get the behavior
  // correct, so instead it is tracked on the field. If old source compatibility
  // is removed, this could be removed and the VPKGPBEnumDescription fetched from
  // the VPKGPBFieldDescriptor instead.
  VPKGPBFieldClosedEnum = 1 << 12,
};

// NOTE: The structures defined here have their members ordered to minimize
// their size. This directly impacts the size of apps since these exist per
// field/extension.

typedef struct VPKGPBFileDescription {
  // The proto package for the file.
  const char *package;
  // The objc_class_prefix option if present.
  const char *prefix;
  // The file's proto syntax.
  VPKGPBFileSyntax syntax;
} VPKGPBFileDescription;

// Describes a single field in a protobuf as it is represented as an ivar.
typedef struct VPKGPBMessageFieldDescription {
  // Name of ivar.
  const char *name;
  union {
    // className is deprecated and will be removed in favor of clazz.
    // kept around right now for backwards compatibility.
    // clazz is used iff VPKGPBDescriptorInitializationFlag_UsesClassRefs is set.
    char *className;  // Name of the class of the message.
    Class clazz;      // Class of the message.
    // For enums only.
    VPKGPBEnumDescriptorFunc enumDescFunc;
  } dataTypeSpecific;
  // The field number for the ivar.
  uint32_t number;
  // The index (in bits) into _has_storage_.
  //   >= 0: the bit to use for a value being set.
  //   = VPKGPBNoHasBit(INT32_MAX): no storage used.
  //   < 0: in a oneOf, use a full int32 to record the field active.
  int32_t hasIndex;
  // Offset of the variable into it's structure struct.
  uint32_t offset;
  // Field flags. Use accessor functions below.
  VPKGPBFieldFlags flags;
  // Data type of the ivar.
  VPKGPBDataType dataType;
} VPKGPBMessageFieldDescription;

// Fields in messages defined in a 'proto2' syntax file can provide a default
// value. This struct provides the default along with the field info.
typedef struct VPKGPBMessageFieldDescriptionWithDefault {
  // Default value for the ivar.
  VPKGPBGenericValue defaultValue;

  VPKGPBMessageFieldDescription core;
} VPKGPBMessageFieldDescriptionWithDefault;

// Describes attributes of the extension.
typedef NS_OPTIONS(uint8_t, VPKGPBExtensionOptions) {
  VPKGPBExtensionNone = 0,
  // These map to standard protobuf concepts.
  VPKGPBExtensionRepeated = 1 << 0,
  VPKGPBExtensionPacked = 1 << 1,
  VPKGPBExtensionSetWireFormat = 1 << 2,
};

// An extension
typedef struct VPKGPBExtensionDescription {
  VPKGPBGenericValue defaultValue;
  const char *singletonName;
  // Before 3.12, `extendedClass` was just a `const char *`. Thanks to nested
  // initialization
  // (https://en.cppreference.com/w/c/language/struct_initialization#Nested_initialization) old
  // generated code with `.extendedClass = VPKGPBStringifySymbol(Something)` still works; and the
  // current generator can use `extendedClass.clazz`, to pass a Class reference.
  union {
    const char *name;
    Class clazz;
  } extendedClass;
  // Before 3.12, this was `const char *messageOrGroupClassName`. In the
  // initial 3.12 release, we moved the `union messageOrGroupClass`, and failed
  // to realize that would break existing source code for extensions. So to
  // keep existing source code working, we added an unnamed union (C11) to
  // provide both the old field name and the new union. This keeps both older
  // and newer code working.
  // Background: https://github.com/protocolbuffers/protobuf/issues/7555
  union {
    const char *messageOrGroupClassName;
    union {
      const char *name;
      Class clazz;
    } messageOrGroupClass;
  };
  VPKGPBEnumDescriptorFunc enumDescriptorFunc;
  int32_t fieldNumber;
  VPKGPBDataType dataType;
  VPKGPBExtensionOptions options;
} VPKGPBExtensionDescription;

typedef NS_OPTIONS(uint32_t, VPKGPBDescriptorInitializationFlags) {
  VPKGPBDescriptorInitializationFlag_None = 0,
  VPKGPBDescriptorInitializationFlag_FieldsWithDefault = 1 << 0,
  VPKGPBDescriptorInitializationFlag_WireFormat = 1 << 1,

  // This is used as a stopgap as we move from using class names to class
  // references. The runtime needs to support both until we allow a
  // breaking change in the runtime.
  VPKGPBDescriptorInitializationFlag_UsesClassRefs = 1 << 2,

  // This flag is used to indicate that the generated sources already contain
  // the `VPKGPBFieldClearHasIvarOnZero` flag and it doesn't have to be computed
  // at startup. This allows older generated code to still work with the
  // current runtime library.
  VPKGPBDescriptorInitializationFlag_Proto3OptionalKnown = 1 << 3,

  // This flag is used to indicate that the generated sources already contain
  // the `VPKGPBFieldCloseEnum` flag and it doesn't have to be computed at startup.
  // This allows the older generated code to still work with the current runtime
  // library.
  VPKGPBDescriptorInitializationFlag_ClosedEnumSupportKnown = 1 << 4,
};

@interface VPKGPBDescriptor () {
 @package
  NSArray *fields_;
  NSArray *oneofs_;
  uint32_t storageSize_;
}

// fieldDescriptions and fileDescription have to be long lived, they are held as raw pointers.
+ (instancetype)allocDescriptorForClass:(Class)messageClass
                            messageName:(NSString *)messageName
                        fileDescription:(VPKGPBFileDescription *)fileDescription
                                 fields:(void *)fieldDescriptions
                             fieldCount:(uint32_t)fieldCount
                            storageSize:(uint32_t)storageSize
                                  flags:(VPKGPBDescriptorInitializationFlags)flags;

// Called right after init to provide extra information to avoid init having
// an explosion of args. These pointers are recorded, so they are expected
// to live for the lifetime of the app.
- (void)setupOneofs:(const char **)oneofNames
              count:(uint32_t)count
      firstHasIndex:(int32_t)firstHasIndex;
- (void)setupExtraTextInfo:(const char *)extraTextFormatInfo;
- (void)setupExtensionRanges:(const VPKGPBExtensionRange *)ranges count:(int32_t)count;
- (void)setupContainingMessageClass:(Class)msgClass;

// Deprecated, these remain to support older versions of source generation.
+ (instancetype)allocDescriptorForClass:(Class)messageClass
                                   file:(VPKGPBFileDescriptor *)file
                                 fields:(void *)fieldDescriptions
                             fieldCount:(uint32_t)fieldCount
                            storageSize:(uint32_t)storageSize
                                  flags:(VPKGPBDescriptorInitializationFlags)flags;
+ (instancetype)allocDescriptorForClass:(Class)messageClass
                              rootClass:(Class)rootClass
                                   file:(VPKGPBFileDescriptor *)file
                                 fields:(void *)fieldDescriptions
                             fieldCount:(uint32_t)fieldCount
                            storageSize:(uint32_t)storageSize
                                  flags:(VPKGPBDescriptorInitializationFlags)flags;
- (void)setupContainingMessageClassName:(const char *)msgClassName;
- (void)setupMessageClassNameSuffix:(NSString *)suffix;

@end

@interface VPKGPBFileDescriptor ()
- (instancetype)initWithPackage:(NSString *)package
                     objcPrefix:(NSString *)objcPrefix
                         syntax:(VPKGPBFileSyntax)syntax;
- (instancetype)initWithPackage:(NSString *)package syntax:(VPKGPBFileSyntax)syntax;
@end

@interface VPKGPBOneofDescriptor () {
 @package
  const char *name_;
  NSArray *fields_;
  SEL caseSel_;
}
// name must be long lived.
- (instancetype)initWithName:(const char *)name fields:(NSArray *)fields;
@end

@interface VPKGPBFieldDescriptor () {
 @package
  VPKGPBMessageFieldDescription *description_;
  VPKGPB_UNSAFE_UNRETAINED VPKGPBOneofDescriptor *containingOneof_;

  SEL getSel_;
  SEL setSel_;
  SEL hasOrCountSel_;  // *Count for map<>/repeated fields, has* otherwise.
  SEL setHasSel_;
}
@end

typedef NS_OPTIONS(uint32_t, VPKGPBEnumDescriptorInitializationFlags) {
  VPKGPBEnumDescriptorInitializationFlag_None = 0,

  // Available: 1 << 0

  // Marks this enum as a closed enum.
  VPKGPBEnumDescriptorInitializationFlag_IsClosed = 1 << 1,
};

@interface VPKGPBEnumDescriptor ()
// valueNames, values and extraTextFormatInfo have to be long lived, they are
// held as raw pointers.
+ (instancetype)allocDescriptorForName:(NSString *)name
                            valueNames:(const char *)valueNames
                                values:(const int32_t *)values
                                 count:(uint32_t)valueCount
                          enumVerifier:(VPKGPBEnumValidationFunc)enumVerifier
                                 flags:(VPKGPBEnumDescriptorInitializationFlags)flags;
+ (instancetype)allocDescriptorForName:(NSString *)name
                            valueNames:(const char *)valueNames
                                values:(const int32_t *)values
                                 count:(uint32_t)valueCount
                          enumVerifier:(VPKGPBEnumValidationFunc)enumVerifier
                                 flags:(VPKGPBEnumDescriptorInitializationFlags)flags
                   extraTextFormatInfo:(const char *)extraTextFormatInfo;

// Deprecated, these remain to support older versions of source generation.
+ (instancetype)allocDescriptorForName:(NSString *)name
                            valueNames:(const char *)valueNames
                                values:(const int32_t *)values
                                 count:(uint32_t)valueCount
                          enumVerifier:(VPKGPBEnumValidationFunc)enumVerifier;
+ (instancetype)allocDescriptorForName:(NSString *)name
                            valueNames:(const char *)valueNames
                                values:(const int32_t *)values
                                 count:(uint32_t)valueCount
                          enumVerifier:(VPKGPBEnumValidationFunc)enumVerifier
                   extraTextFormatInfo:(const char *)extraTextFormatInfo;
@end

@interface VPKGPBExtensionDescriptor () {
 @package
  VPKGPBExtensionDescription *description_;
}
@property(nonatomic, readonly) VPKGPBWireFormat wireType;

// For repeated extensions, alternateWireType is the wireType with the opposite
// value for the packable property.  i.e. - if the extension was marked packed
// it would be the wire type for unpacked; if the extension was marked unpacked,
// it would be the wire type for packed.
@property(nonatomic, readonly) VPKGPBWireFormat alternateWireType;

// description has to be long lived, it is held as a raw pointer.
- (instancetype)initWithExtensionDescription:(VPKGPBExtensionDescription *)desc
                               usesClassRefs:(BOOL)usesClassRefs;
// Deprecated. Calls above with `usesClassRefs = NO`
- (instancetype)initWithExtensionDescription:(VPKGPBExtensionDescription *)desc;

- (NSComparisonResult)compareByFieldNumber:(VPKGPBExtensionDescriptor *)other;
@end

CF_EXTERN_C_BEGIN

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

VPKGPB_INLINE BOOL VPKGPBFieldIsMapOrArray(VPKGPBFieldDescriptor *field) {
  return (field->description_->flags & (VPKGPBFieldRepeated | VPKGPBFieldMapKeyMask)) != 0;
}

VPKGPB_INLINE VPKGPBDataType VPKGPBGetFieldDataType(VPKGPBFieldDescriptor *field) {
  return field->description_->dataType;
}

VPKGPB_INLINE int32_t VPKGPBFieldHasIndex(VPKGPBFieldDescriptor *field) {
  return field->description_->hasIndex;
}

VPKGPB_INLINE uint32_t VPKGPBFieldNumber(VPKGPBFieldDescriptor *field) {
  return field->description_->number;
}

VPKGPB_INLINE BOOL VPKGPBFieldIsClosedEnum(VPKGPBFieldDescriptor *field) {
  return (field->description_->flags & VPKGPBFieldClosedEnum) != 0;
}

#pragma clang diagnostic pop

uint32_t VPKGPBFieldTag(VPKGPBFieldDescriptor *self);

// For repeated fields, alternateWireType is the wireType with the opposite
// value for the packable property.  i.e. - if the field was marked packed it
// would be the wire type for unpacked; if the field was marked unpacked, it
// would be the wire type for packed.
uint32_t VPKGPBFieldAlternateTag(VPKGPBFieldDescriptor *self);

VPKGPB_INLINE BOOL VPKGPBExtensionIsRepeated(VPKGPBExtensionDescription *description) {
  return (description->options & VPKGPBExtensionRepeated) != 0;
}

VPKGPB_INLINE BOOL VPKGPBExtensionIsPacked(VPKGPBExtensionDescription *description) {
  return (description->options & VPKGPBExtensionPacked) != 0;
}

VPKGPB_INLINE BOOL VPKGPBExtensionIsWireFormat(VPKGPBExtensionDescription *description) {
  return (description->options & VPKGPBExtensionSetWireFormat) != 0;
}

// Helper for compile time assets.
#ifndef VPKGPBInternalCompileAssert
#define VPKGPBInternalCompileAssert(test, msg) _Static_assert((test), #msg)
#endif  // VPKGPBInternalCompileAssert

// Sanity check that there isn't padding between the field description
// structures with and without a default.
VPKGPBInternalCompileAssert(sizeof(VPKGPBMessageFieldDescriptionWithDefault) ==
                             (sizeof(VPKGPBGenericValue) + sizeof(VPKGPBMessageFieldDescription)),
                         DescriptionsWithDefault_different_size_than_expected);

CF_EXTERN_C_END
