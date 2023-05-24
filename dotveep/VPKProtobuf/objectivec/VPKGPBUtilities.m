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

#import "VPKGPBUtilities_PackagePrivate.h"

#import <objc/runtime.h>

#import "VPKGPBArray_PackagePrivate.h"
#import "VPKGPBDescriptor_PackagePrivate.h"
#import "VPKGPBDictionary_PackagePrivate.h"
#import "VPKGPBMessage_PackagePrivate.h"
#import "VPKGPBUnknownField.h"
#import "VPKGPBUnknownFieldSet.h"

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

static void AppendTextFormatForMessage(VPKGPBMessage *message, NSMutableString *toStr,
                                       NSString *lineIndent);

// Are two datatypes the same basic type representation (ex Int32 and SInt32).
// Marked unused because currently only called from asserts/debug.
static BOOL DataTypesEquivalent(VPKGPBDataType type1, VPKGPBDataType type2) __attribute__((unused));

// Basic type representation for a type (ex: for SInt32 it is Int32).
// Marked unused because currently only called from asserts/debug.
static VPKGPBDataType BaseDataType(VPKGPBDataType type) __attribute__((unused));

// String name for a data type.
// Marked unused because currently only called from asserts/debug.
static NSString *TypeToString(VPKGPBDataType dataType) __attribute__((unused));

// Helper for clearing oneofs.
static void VPKGPBMaybeClearOneofPrivate(VPKGPBMessage *self, VPKGPBOneofDescriptor *oneof,
                                      int32_t oneofHasIndex, uint32_t fieldNumberNotToClear);

NSData *VPKGPBEmptyNSData(void) {
  static dispatch_once_t onceToken;
  static NSData *defaultNSData = nil;
  dispatch_once(&onceToken, ^{
    defaultNSData = [[NSData alloc] init];
  });
  return defaultNSData;
}

void VPKGPBMessageDropUnknownFieldsRecursively(VPKGPBMessage *initialMessage) {
  if (!initialMessage) {
    return;
  }

  // Use an array as a list to process to avoid recursion.
  NSMutableArray *todo = [NSMutableArray arrayWithObject:initialMessage];

  while (todo.count) {
    VPKGPBMessage *msg = todo.lastObject;
    [todo removeLastObject];

    // Clear unknowns.
    msg.unknownFields = nil;

    // Handle the message fields.
    VPKGPBDescriptor *descriptor = [[msg class] descriptor];
    for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
      if (!VPKGPBFieldDataTypeIsMessage(field)) {
        continue;
      }
      switch (field.fieldType) {
        case VPKGPBFieldTypeSingle:
          if (VPKGPBGetHasIvarField(msg, field)) {
            VPKGPBMessage *fieldMessage = VPKGPBGetObjectIvarWithFieldNoAutocreate(msg, field);
            [todo addObject:fieldMessage];
          }
          break;

        case VPKGPBFieldTypeRepeated: {
          NSArray *fieldMessages = VPKGPBGetObjectIvarWithFieldNoAutocreate(msg, field);
          if (fieldMessages.count) {
            [todo addObjectsFromArray:fieldMessages];
          }
          break;
        }

        case VPKGPBFieldTypeMap: {
          id rawFieldMap = VPKGPBGetObjectIvarWithFieldNoAutocreate(msg, field);
          switch (field.mapKeyDataType) {
            case VPKGPBDataTypeBool:
              [(VPKGPBBoolObjectDictionary *)rawFieldMap
                  enumerateKeysAndObjectsUsingBlock:^(__unused BOOL key, id _Nonnull object,
                                                      __unused BOOL *_Nonnull stop) {
                    [todo addObject:object];
                  }];
              break;
            case VPKGPBDataTypeFixed32:
            case VPKGPBDataTypeUInt32:
              [(VPKGPBUInt32ObjectDictionary *)rawFieldMap
                  enumerateKeysAndObjectsUsingBlock:^(__unused uint32_t key, id _Nonnull object,
                                                      __unused BOOL *_Nonnull stop) {
                    [todo addObject:object];
                  }];
              break;
            case VPKGPBDataTypeInt32:
            case VPKGPBDataTypeSFixed32:
            case VPKGPBDataTypeSInt32:
              [(VPKGPBInt32ObjectDictionary *)rawFieldMap
                  enumerateKeysAndObjectsUsingBlock:^(__unused int32_t key, id _Nonnull object,
                                                      __unused BOOL *_Nonnull stop) {
                    [todo addObject:object];
                  }];
              break;
            case VPKGPBDataTypeFixed64:
            case VPKGPBDataTypeUInt64:
              [(VPKGPBUInt64ObjectDictionary *)rawFieldMap
                  enumerateKeysAndObjectsUsingBlock:^(__unused uint64_t key, id _Nonnull object,
                                                      __unused BOOL *_Nonnull stop) {
                    [todo addObject:object];
                  }];
              break;
            case VPKGPBDataTypeInt64:
            case VPKGPBDataTypeSFixed64:
            case VPKGPBDataTypeSInt64:
              [(VPKGPBInt64ObjectDictionary *)rawFieldMap
                  enumerateKeysAndObjectsUsingBlock:^(__unused int64_t key, id _Nonnull object,
                                                      __unused BOOL *_Nonnull stop) {
                    [todo addObject:object];
                  }];
              break;
            case VPKGPBDataTypeString:
              [(NSDictionary *)rawFieldMap
                  enumerateKeysAndObjectsUsingBlock:^(__unused NSString *_Nonnull key,
                                                      VPKGPBMessage *_Nonnull obj,
                                                      __unused BOOL *_Nonnull stop) {
                    [todo addObject:obj];
                  }];
              break;
            case VPKGPBDataTypeFloat:
            case VPKGPBDataTypeDouble:
            case VPKGPBDataTypeEnum:
            case VPKGPBDataTypeBytes:
            case VPKGPBDataTypeGroup:
            case VPKGPBDataTypeMessage:
              NSCAssert(NO, @"Aren't valid key types.");
          }
          break;
        }  // switch(field.mapKeyDataType)
      }    // switch(field.fieldType)
    }      // for(fields)

    // Handle any extensions holding messages.
    for (VPKGPBExtensionDescriptor *extension in [msg extensionsCurrentlySet]) {
      if (!VPKGPBDataTypeIsMessage(extension.dataType)) {
        continue;
      }
      if (extension.isRepeated) {
        NSArray *extMessages = [msg getExtension:extension];
        [todo addObjectsFromArray:extMessages];
      } else {
        VPKGPBMessage *extMessage = [msg getExtension:extension];
        [todo addObject:extMessage];
      }
    }  // for(extensionsCurrentlySet)

  }  // while(todo.count)
}

// -- About Version Checks --
// There's actually 3 places these checks all come into play:
// 1. When the generated source is compile into .o files, the header check
//    happens. This is checking the protoc used matches the library being used
//    when making the .o.
// 2. Every place a generated proto header is included in a developer's code,
//    the header check comes into play again. But this time it is checking that
//    the current library headers being used still support/match the ones for
//    the generated code.
// 3. At runtime the final check here (VPKGPBCheckRuntimeVersionsInternal), is
//    called from the generated code passing in values captured when the
//    generated code's .o was made. This checks that at runtime the generated
//    code and runtime library match.

void VPKGPBCheckRuntimeVersionSupport(int32_t objcRuntimeVersion) {
  // NOTE: This is passing the value captured in the compiled code to check
  // against the values captured when the runtime support was compiled. This
  // ensures the library code isn't in a different framework/library that
  // was generated with a non matching version.
  if (GOOGLE_PROTOBUF_OBJC_VERSION < objcRuntimeVersion) {
    // Library is too old for headers.
    [NSException raise:NSInternalInconsistencyException
                format:@"Linked to ProtocolBuffer runtime version %d,"
                       @" but code compiled needing at least %d!",
                       GOOGLE_PROTOBUF_OBJC_VERSION, objcRuntimeVersion];
  }
  if (objcRuntimeVersion < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION) {
    // Headers are too old for library.
    [NSException raise:NSInternalInconsistencyException
                format:@"Proto generation source compiled against runtime"
                       @" version %d, but this version of the runtime only"
                       @" supports back to %d!",
                       objcRuntimeVersion, GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION];
  }
}

void VPKGPBRuntimeMatchFailure(void) {
  [NSException raise:NSInternalInconsistencyException
              format:@"Proto generation source appears to have been from a"
                     @" version newer that this runtime (%d).",
                     GOOGLE_PROTOBUF_OBJC_VERSION];
}

// This api is no longer used for version checks. 30001 is the last version
// using this old versioning model. When that support is removed, this function
// can be removed (along with the declaration in VPKGPBUtilities_PackagePrivate.h).
void VPKGPBCheckRuntimeVersionInternal(int32_t version) {
  VPKGPBInternalCompileAssert(GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION <= 30001,
                           time_to_remove_this_old_version_shim);
  if (version != GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION) {
    [NSException raise:NSInternalInconsistencyException
                format:@"Linked to ProtocolBuffer runtime version %d,"
                       @" but code compiled with version %d!",
                       GOOGLE_PROTOBUF_OBJC_GEN_VERSION, version];
  }
}

BOOL VPKGPBMessageHasFieldNumberSet(VPKGPBMessage *self, uint32_t fieldNumber) {
  VPKGPBDescriptor *descriptor = [self descriptor];
  VPKGPBFieldDescriptor *field = [descriptor fieldWithNumber:fieldNumber];
  return VPKGPBMessageHasFieldSet(self, field);
}

BOOL VPKGPBMessageHasFieldSet(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  if (self == nil || field == nil) return NO;

  // Repeated/Map don't use the bit, they check the count.
  if (VPKGPBFieldIsMapOrArray(field)) {
    // Array/map type doesn't matter, since VPKGPB*Array/NSArray and
    // VPKGPB*Dictionary/NSDictionary all support -count;
    NSArray *arrayOrMap = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
    return (arrayOrMap.count > 0);
  } else {
    return VPKGPBGetHasIvarField(self, field);
  }
}

void VPKGPBClearMessageField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  // If not set, nothing to do.
  if (!VPKGPBGetHasIvarField(self, field)) {
    return;
  }

  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  if (VPKGPBFieldStoresObject(field)) {
    // Object types are handled slightly differently, they need to be released.
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    id *typePtr = (id *)&storage[fieldDesc->offset];
    [*typePtr release];
    *typePtr = nil;
  } else {
    // POD types just need to clear the has bit as the Get* method will
    // fetch the default when needed.
  }
  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, NO);
}

void VPKGPBClearOneof(VPKGPBMessage *self, VPKGPBOneofDescriptor *oneof) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] oneofWithName:oneof.name] == oneof,
            @"OneofDescriptor %@ doesn't appear to be for %@ messages.", oneof.name, [self class]);
#endif
  VPKGPBFieldDescriptor *firstField = oneof->fields_[0];
  VPKGPBMaybeClearOneofPrivate(self, oneof, firstField->description_->hasIndex, 0);
}

BOOL VPKGPBGetHasIvar(VPKGPBMessage *self, int32_t idx, uint32_t fieldNumber) {
  NSCAssert(self->messageStorage_ != NULL, @"%@: All messages should have storage (from init)",
            [self class]);
  if (idx < 0) {
    NSCAssert(fieldNumber != 0, @"Invalid field number.");
    BOOL hasIvar = (self->messageStorage_->_has_storage_[-idx] == fieldNumber);
    return hasIvar;
  } else {
    NSCAssert(idx != VPKGPBNoHasBit, @"Invalid has bit.");
    uint32_t byteIndex = idx / 32;
    uint32_t bitMask = (1U << (idx % 32));
    BOOL hasIvar = (self->messageStorage_->_has_storage_[byteIndex] & bitMask) ? YES : NO;
    return hasIvar;
  }
}

uint32_t VPKGPBGetHasOneof(VPKGPBMessage *self, int32_t idx) {
  NSCAssert(idx < 0, @"%@: invalid index (%d) for oneof.", [self class], idx);
  uint32_t result = self->messageStorage_->_has_storage_[-idx];
  return result;
}

void VPKGPBSetHasIvar(VPKGPBMessage *self, int32_t idx, uint32_t fieldNumber, BOOL value) {
  if (idx < 0) {
    NSCAssert(fieldNumber != 0, @"Invalid field number.");
    uint32_t *has_storage = self->messageStorage_->_has_storage_;
    has_storage[-idx] = (value ? fieldNumber : 0);
  } else {
    NSCAssert(idx != VPKGPBNoHasBit, @"Invalid has bit.");
    uint32_t *has_storage = self->messageStorage_->_has_storage_;
    uint32_t byte = idx / 32;
    uint32_t bitMask = (1U << (idx % 32));
    if (value) {
      has_storage[byte] |= bitMask;
    } else {
      has_storage[byte] &= ~bitMask;
    }
  }
}

static void VPKGPBMaybeClearOneofPrivate(VPKGPBMessage *self, VPKGPBOneofDescriptor *oneof,
                                      int32_t oneofHasIndex, uint32_t fieldNumberNotToClear) {
  uint32_t fieldNumberSet = VPKGPBGetHasOneof(self, oneofHasIndex);
  if ((fieldNumberSet == fieldNumberNotToClear) || (fieldNumberSet == 0)) {
    // Do nothing/nothing set in the oneof.
    return;
  }

  // Like VPKGPBClearMessageField(), free the memory if an objecttype is set,
  // pod types don't need to do anything.
  VPKGPBFieldDescriptor *fieldSet = [oneof fieldWithNumber:fieldNumberSet];
  NSCAssert(fieldSet, @"%@: oneof set to something (%u) not in the oneof?", [self class],
            fieldNumberSet);
  if (fieldSet && VPKGPBFieldStoresObject(fieldSet)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    id *typePtr = (id *)&storage[fieldSet->description_->offset];
    [*typePtr release];
    *typePtr = nil;
  }

  // Set to nothing stored in the oneof.
  // (field number doesn't matter since setting to nothing).
  VPKGPBSetHasIvar(self, oneofHasIndex, 1, NO);
}

#pragma mark - IVar accessors

// clang-format off

//%PDDM-DEFINE IVAR_POD_ACCESSORS_DEFN(NAME, TYPE)
//%TYPE VPKGPBGetMessage##NAME##Field(VPKGPBMessage *self,
//% TYPE$S            NAME$S       VPKGPBFieldDescriptor *field) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
//%            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
//%            field.name, [self class]);
//%  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
//%                                VPKGPBDataType##NAME),
//%            @"Attempting to get value of TYPE from field %@ "
//%            @"of %@ which is of type %@.",
//%            [self class], field.name,
//%            TypeToString(VPKGPBGetFieldDataType(field)));
//%#endif
//%  if (VPKGPBGetHasIvarField(self, field)) {
//%    uint8_t *storage = (uint8_t *)self->messageStorage_;
//%    TYPE *typePtr = (TYPE *)&storage[field->description_->offset];
//%    return *typePtr;
//%  } else {
//%    return field.defaultValue.value##NAME;
//%  }
//%}
//%
//%// Only exists for public api, no core code should use this.
//%void VPKGPBSetMessage##NAME##Field(VPKGPBMessage *self,
//%                   NAME$S     VPKGPBFieldDescriptor *field,
//%                   NAME$S     TYPE value) {
//%  if (self == nil || field == nil) return;
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
//%            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
//%            field.name, [self class]);
//%  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
//%                                VPKGPBDataType##NAME),
//%            @"Attempting to set field %@ of %@ which is of type %@ with "
//%            @"value of type TYPE.",
//%            [self class], field.name,
//%            TypeToString(VPKGPBGetFieldDataType(field)));
//%#endif
//%  VPKGPBSet##NAME##IvarWithFieldPrivate(self, field, value);
//%}
//%
//%void VPKGPBSet##NAME##IvarWithFieldPrivate(VPKGPBMessage *self,
//%            NAME$S                    VPKGPBFieldDescriptor *field,
//%            NAME$S                    TYPE value) {
//%  VPKGPBOneofDescriptor *oneof = field->containingOneof_;
//%  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
//%  if (oneof) {
//%    VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
//%  }
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(self->messageStorage_ != NULL,
//%            @"%@: All messages should have storage (from init)",
//%            [self class]);
//%#endif
//%#if defined(__clang_analyzer__)
//%  if (self->messageStorage_ == NULL) return;
//%#endif
//%  uint8_t *storage = (uint8_t *)self->messageStorage_;
//%  TYPE *typePtr = (TYPE *)&storage[fieldDesc->offset];
//%  *typePtr = value;
//%  // If the value is zero, then we only count the field as "set" if the field
//%  // shouldn't auto clear on zero.
//%  BOOL hasValue = ((value != (TYPE)0)
//%                   || ((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) == 0));
//%  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
//%  VPKGPBBecomeVisibleToAutocreator(self);
//%}
//%
//%PDDM-DEFINE IVAR_ALIAS_DEFN_OBJECT(NAME, TYPE)
//%// Only exists for public api, no core code should use this.
//%TYPE *VPKGPBGetMessage##NAME##Field(VPKGPBMessage *self,
//% TYPE$S             NAME$S       VPKGPBFieldDescriptor *field) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
//%                                VPKGPBDataType##NAME),
//%            @"Attempting to get value of TYPE from field %@ "
//%            @"of %@ which is of type %@.",
//%            [self class], field.name,
//%            TypeToString(VPKGPBGetFieldDataType(field)));
//%#endif
//%  return (TYPE *)VPKGPBGetObjectIvarWithField(self, field);
//%}
//%
//%// Only exists for public api, no core code should use this.
//%void VPKGPBSetMessage##NAME##Field(VPKGPBMessage *self,
//%                   NAME$S     VPKGPBFieldDescriptor *field,
//%                   NAME$S     TYPE *value) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
//%                                VPKGPBDataType##NAME),
//%            @"Attempting to set field %@ of %@ which is of type %@ with "
//%            @"value of type TYPE.",
//%            [self class], field.name,
//%            TypeToString(VPKGPBGetFieldDataType(field)));
//%#endif
//%  VPKGPBSetObjectIvarWithField(self, field, (id)value);
//%}
//%
//%PDDM-DEFINE IVAR_ALIAS_DEFN_COPY_OBJECT(NAME, TYPE)
//%// Only exists for public api, no core code should use this.
//%TYPE *VPKGPBGetMessage##NAME##Field(VPKGPBMessage *self,
//% TYPE$S             NAME$S       VPKGPBFieldDescriptor *field) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
//%                                VPKGPBDataType##NAME),
//%            @"Attempting to get value of TYPE from field %@ "
//%            @"of %@ which is of type %@.",
//%            [self class], field.name,
//%            TypeToString(VPKGPBGetFieldDataType(field)));
//%#endif
//%  return (TYPE *)VPKGPBGetObjectIvarWithField(self, field);
//%}
//%
//%// Only exists for public api, no core code should use this.
//%void VPKGPBSetMessage##NAME##Field(VPKGPBMessage *self,
//%                   NAME$S     VPKGPBFieldDescriptor *field,
//%                   NAME$S     TYPE *value) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
//%                                VPKGPBDataType##NAME),
//%            @"Attempting to set field %@ of %@ which is of type %@ with "
//%            @"value of type TYPE.",
//%            [self class], field.name,
//%            TypeToString(VPKGPBGetFieldDataType(field)));
//%#endif
//%  VPKGPBSetCopyObjectIvarWithField(self, field, (id)value);
//%}
//%

// clang-format on

// Object types are handled slightly differently, they need to be released
// and retained.

void VPKGPBClearAutocreatedMessageIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  if (VPKGPBGetHasIvarField(self, field)) {
    return;
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[field->description_->offset];
  VPKGPBMessage *oldValue = *typePtr;
  *typePtr = NULL;
  VPKGPBClearMessageAutocreator(oldValue);
  [oldValue release];
}

// This exists only for bridging some aliased types, nothing else should use it.
static void VPKGPBSetObjectIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, id value) {
  if (self == nil || field == nil) return;
  VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, [value retain]);
}

static void VPKGPBSetCopyObjectIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, id value);

// VPKGPBSetCopyObjectIvarWithField is blocked from the analyzer because it flags
// a leak for the -copy even though VPKGPBSetRetainedObjectIvarWithFieldPrivate
// is marked as consuming the value. Note: For some reason this doesn't happen
// with the -retain in VPKGPBSetObjectIvarWithField.
#if !defined(__clang_analyzer__)
// This exists only for bridging some aliased types, nothing else should use it.
static void VPKGPBSetCopyObjectIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, id value) {
  if (self == nil || field == nil) return;
  VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, [value copy]);
}
#endif  // !defined(__clang_analyzer__)

void VPKGPBSetObjectIvarWithFieldPrivate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, id value) {
  VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, [value retain]);
}

void VPKGPBSetRetainedObjectIvarWithFieldPrivate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field,
                                              id value) {
  NSCAssert(self->messageStorage_ != NULL, @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  VPKGPBDataType fieldType = VPKGPBGetFieldDataType(field);
  BOOL isMapOrArray = VPKGPBFieldIsMapOrArray(field);
  BOOL fieldIsMessage = VPKGPBDataTypeIsMessage(fieldType);
#if defined(DEBUG) && DEBUG
  if (value == nil && !isMapOrArray && !fieldIsMessage && field.hasDefaultValue) {
    // Setting a message to nil is an obvious way to "clear" the value
    // as there is no way to set a non-empty default value for messages.
    //
    // For Strings and Bytes that have default values set it is not clear what
    // should be done when their value is set to nil. Is the intention just to
    // clear the set value and reset to default, or is the intention to set the
    // value to the empty string/data? Arguments can be made for both cases.
    // 'nil' has been abused as a replacement for an empty string/data in ObjC.
    // We decided to be consistent with all "object" types and clear the has
    // field, and fall back on the default value. The warning below will only
    // appear in debug, but the could should be changed so the intention is
    // clear.
    NSString *hasSel = NSStringFromSelector(field->hasOrCountSel_);
    NSString *propName = field.name;
    NSString *className = self.descriptor.name;
    NSLog(@"warning: '%@.%@ = nil;' is not clearly defined for fields with "
          @"default values. Please use '%@.%@ = %@' if you want to set it to "
          @"empty, or call '%@.%@ = NO' to reset it to it's default value of "
          @"'%@'. Defaulting to resetting default value.",
          className, propName, className, propName,
          (fieldType == VPKGPBDataTypeString) ? @"@\"\"" : @"VPKGPBEmptyNSData()", className, hasSel,
          field.defaultValue.valueString);
    // Note: valueString, depending on the type, it could easily be
    // valueData/valueMessage.
  }
#endif  // DEBUG
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  if (!isMapOrArray) {
    // Non repeated/map can be in an oneof, clear any existing value from the
    // oneof.
    VPKGPBOneofDescriptor *oneof = field->containingOneof_;
    if (oneof) {
      VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
    }
    // Clear "has" if they are being set to nil.
    BOOL setHasValue = (value != nil);
    // If the field should clear on a "zero" value, then check if the string/data
    // was zero length, and clear instead.
    if (((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) != 0) && ([value length] == 0)) {
      setHasValue = NO;
      // The value passed in was retained, it must be released since we
      // aren't saving anything in the field.
      [value release];
      value = nil;
    }
    VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, setHasValue);
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[fieldDesc->offset];

  id oldValue = *typePtr;

  *typePtr = value;

  if (oldValue) {
    if (isMapOrArray) {
      if (field.fieldType == VPKGPBFieldTypeRepeated) {
        // If the old array was autocreated by us, then clear it.
        if (VPKGPBDataTypeIsObject(fieldType)) {
          if ([oldValue isKindOfClass:[VPKGPBAutocreatedArray class]]) {
            VPKGPBAutocreatedArray *autoArray = oldValue;
            if (autoArray->_autocreator == self) {
              autoArray->_autocreator = nil;
            }
          }
        } else {
          // Type doesn't matter, it is a VPKGPB*Array.
          VPKGPBInt32Array *VPKGPBArray = oldValue;
          if (VPKGPBArray->_autocreator == self) {
            VPKGPBArray->_autocreator = nil;
          }
        }
      } else {  // VPKGPBFieldTypeMap
        // If the old map was autocreated by us, then clear it.
        if ((field.mapKeyDataType == VPKGPBDataTypeString) && VPKGPBDataTypeIsObject(fieldType)) {
          if ([oldValue isKindOfClass:[VPKGPBAutocreatedDictionary class]]) {
            VPKGPBAutocreatedDictionary *autoDict = oldValue;
            if (autoDict->_autocreator == self) {
              autoDict->_autocreator = nil;
            }
          }
        } else {
          // Type doesn't matter, it is a VPKGPB*Dictionary.
          VPKGPBInt32Int32Dictionary *VPKGPBDict = oldValue;
          if (VPKGPBDict->_autocreator == self) {
            VPKGPBDict->_autocreator = nil;
          }
        }
      }
    } else if (fieldIsMessage) {
      // If the old message value was autocreated by us, then clear it.
      VPKGPBMessage *oldMessageValue = oldValue;
      if (VPKGPBWasMessageAutocreatedBy(oldMessageValue, self)) {
        VPKGPBClearMessageAutocreator(oldMessageValue);
      }
    }
    [oldValue release];
  }

  VPKGPBBecomeVisibleToAutocreator(self);
}

id VPKGPBGetObjectIvarWithFieldNoAutocreate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  if (self->messageStorage_ == nil) {
    return nil;
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[field->description_->offset];
  return *typePtr;
}

// Only exists for public api, no core code should use this.
int32_t VPKGPBGetMessageEnumField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.", field.name, [self class]);
  NSCAssert(VPKGPBGetFieldDataType(field) == VPKGPBDataTypeEnum,
            @"Attempting to get value of type Enum from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name, TypeToString(VPKGPBGetFieldDataType(field)));
#endif

  int32_t result = VPKGPBGetMessageInt32Field(self, field);
  // If this is presevering unknown enums, make sure the value is valid before
  // returning it.

  if (!VPKGPBFieldIsClosedEnum(field) && ![field isValidEnumValue:result]) {
    result = kVPKGPBUnrecognizedEnumeratorValue;
  }
  return result;
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageEnumField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, int32_t value) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.", field.name, [self class]);
  NSCAssert(VPKGPBGetFieldDataType(field) == VPKGPBDataTypeEnum,
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type Enum.",
            [self class], field.name, TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetEnumIvarWithFieldPrivate(self, field, value);
}

void VPKGPBSetEnumIvarWithFieldPrivate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, int32_t value) {
  // Don't allow in unknown values.  Proto3 can use the Raw method.
  if (![field isValidEnumValue:value]) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@: Attempt to set an unknown enum value (%d)", [self class],
                       field.name, value];
  }
  VPKGPBSetInt32IvarWithFieldPrivate(self, field, value);
}

// Only exists for public api, no core code should use this.
int32_t VPKGPBGetMessageRawEnumField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  int32_t result = VPKGPBGetMessageInt32Field(self, field);
  return result;
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageRawEnumField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, int32_t value) {
  VPKGPBSetInt32IvarWithFieldPrivate(self, field, value);
}

BOOL VPKGPBGetMessageBoolField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.", field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field), VPKGPBDataTypeBool),
            @"Attempting to get value of type bool from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name, TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  if (VPKGPBGetHasIvarField(self, field)) {
    // Bools are stored in the has bits to avoid needing explicit space in the
    // storage structure.
    // (the field number passed to the HasIvar helper doesn't really matter
    // since the offset is never negative)
    VPKGPBMessageFieldDescription *fieldDesc = field->description_;
    return VPKGPBGetHasIvar(self, (int32_t)(fieldDesc->offset), fieldDesc->number);
  } else {
    return field.defaultValue.valueBool;
  }
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageBoolField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, BOOL value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.", field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field), VPKGPBDataTypeBool),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type bool.",
            [self class], field.name, TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetBoolIvarWithFieldPrivate(self, field, value);
}

void VPKGPBSetBoolIvarWithFieldPrivate(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, BOOL value) {
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  VPKGPBOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }

  // Bools are stored in the has bits to avoid needing explicit space in the
  // storage structure.
  // (the field number passed to the HasIvar helper doesn't really matter since
  // the offset is never negative)
  VPKGPBSetHasIvar(self, (int32_t)(fieldDesc->offset), fieldDesc->number, value);

  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (BOOL)0) || ((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) == 0));
  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  VPKGPBBecomeVisibleToAutocreator(self);
}

// clang-format off

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Int32, int32_t)
// This block of code is generated, do not edit it directly.

int32_t VPKGPBGetMessageInt32Field(VPKGPBMessage *self,
                                VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeInt32),
            @"Attempting to get value of int32_t from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  if (VPKGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    int32_t *typePtr = (int32_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueInt32;
  }
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageInt32Field(VPKGPBMessage *self,
                             VPKGPBFieldDescriptor *field,
                             int32_t value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeInt32),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type int32_t.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetInt32IvarWithFieldPrivate(self, field, value);
}

void VPKGPBSetInt32IvarWithFieldPrivate(VPKGPBMessage *self,
                                     VPKGPBFieldDescriptor *field,
                                     int32_t value) {
  VPKGPBOneofDescriptor *oneof = field->containingOneof_;
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  int32_t *typePtr = (int32_t *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (int32_t)0)
                   || ((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) == 0));
  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  VPKGPBBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.

uint32_t VPKGPBGetMessageUInt32Field(VPKGPBMessage *self,
                                  VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeUInt32),
            @"Attempting to get value of uint32_t from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  if (VPKGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    uint32_t *typePtr = (uint32_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueUInt32;
  }
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageUInt32Field(VPKGPBMessage *self,
                              VPKGPBFieldDescriptor *field,
                              uint32_t value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeUInt32),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type uint32_t.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetUInt32IvarWithFieldPrivate(self, field, value);
}

void VPKGPBSetUInt32IvarWithFieldPrivate(VPKGPBMessage *self,
                                      VPKGPBFieldDescriptor *field,
                                      uint32_t value) {
  VPKGPBOneofDescriptor *oneof = field->containingOneof_;
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  uint32_t *typePtr = (uint32_t *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (uint32_t)0)
                   || ((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) == 0));
  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  VPKGPBBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Int64, int64_t)
// This block of code is generated, do not edit it directly.

int64_t VPKGPBGetMessageInt64Field(VPKGPBMessage *self,
                                VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeInt64),
            @"Attempting to get value of int64_t from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  if (VPKGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    int64_t *typePtr = (int64_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueInt64;
  }
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageInt64Field(VPKGPBMessage *self,
                             VPKGPBFieldDescriptor *field,
                             int64_t value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeInt64),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type int64_t.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetInt64IvarWithFieldPrivate(self, field, value);
}

void VPKGPBSetInt64IvarWithFieldPrivate(VPKGPBMessage *self,
                                     VPKGPBFieldDescriptor *field,
                                     int64_t value) {
  VPKGPBOneofDescriptor *oneof = field->containingOneof_;
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  int64_t *typePtr = (int64_t *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (int64_t)0)
                   || ((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) == 0));
  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  VPKGPBBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.

uint64_t VPKGPBGetMessageUInt64Field(VPKGPBMessage *self,
                                  VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeUInt64),
            @"Attempting to get value of uint64_t from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  if (VPKGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    uint64_t *typePtr = (uint64_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueUInt64;
  }
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageUInt64Field(VPKGPBMessage *self,
                              VPKGPBFieldDescriptor *field,
                              uint64_t value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeUInt64),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type uint64_t.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetUInt64IvarWithFieldPrivate(self, field, value);
}

void VPKGPBSetUInt64IvarWithFieldPrivate(VPKGPBMessage *self,
                                      VPKGPBFieldDescriptor *field,
                                      uint64_t value) {
  VPKGPBOneofDescriptor *oneof = field->containingOneof_;
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  uint64_t *typePtr = (uint64_t *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (uint64_t)0)
                   || ((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) == 0));
  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  VPKGPBBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Float, float)
// This block of code is generated, do not edit it directly.

float VPKGPBGetMessageFloatField(VPKGPBMessage *self,
                              VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeFloat),
            @"Attempting to get value of float from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  if (VPKGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    float *typePtr = (float *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueFloat;
  }
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageFloatField(VPKGPBMessage *self,
                             VPKGPBFieldDescriptor *field,
                             float value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeFloat),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type float.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetFloatIvarWithFieldPrivate(self, field, value);
}

void VPKGPBSetFloatIvarWithFieldPrivate(VPKGPBMessage *self,
                                     VPKGPBFieldDescriptor *field,
                                     float value) {
  VPKGPBOneofDescriptor *oneof = field->containingOneof_;
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  float *typePtr = (float *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (float)0)
                   || ((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) == 0));
  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  VPKGPBBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Double, double)
// This block of code is generated, do not edit it directly.

double VPKGPBGetMessageDoubleField(VPKGPBMessage *self,
                                VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeDouble),
            @"Attempting to get value of double from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  if (VPKGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    double *typePtr = (double *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueDouble;
  }
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageDoubleField(VPKGPBMessage *self,
                              VPKGPBFieldDescriptor *field,
                              double value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeDouble),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type double.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetDoubleIvarWithFieldPrivate(self, field, value);
}

void VPKGPBSetDoubleIvarWithFieldPrivate(VPKGPBMessage *self,
                                      VPKGPBFieldDescriptor *field,
                                      double value) {
  VPKGPBOneofDescriptor *oneof = field->containingOneof_;
  VPKGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    VPKGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  double *typePtr = (double *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (double)0)
                   || ((fieldDesc->flags & VPKGPBFieldClearHasIvarOnZero) == 0));
  VPKGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  VPKGPBBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND-END (6 expansions)

// Aliases are function calls that are virtually the same.

//%PDDM-EXPAND IVAR_ALIAS_DEFN_COPY_OBJECT(String, NSString)
// This block of code is generated, do not edit it directly.

// Only exists for public api, no core code should use this.
NSString *VPKGPBGetMessageStringField(VPKGPBMessage *self,
                                   VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeString),
            @"Attempting to get value of NSString from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  return (NSString *)VPKGPBGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageStringField(VPKGPBMessage *self,
                              VPKGPBFieldDescriptor *field,
                              NSString *value) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeString),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type NSString.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetCopyObjectIvarWithField(self, field, (id)value);
}

//%PDDM-EXPAND IVAR_ALIAS_DEFN_COPY_OBJECT(Bytes, NSData)
// This block of code is generated, do not edit it directly.

// Only exists for public api, no core code should use this.
NSData *VPKGPBGetMessageBytesField(VPKGPBMessage *self,
                                VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeBytes),
            @"Attempting to get value of NSData from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  return (NSData *)VPKGPBGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageBytesField(VPKGPBMessage *self,
                             VPKGPBFieldDescriptor *field,
                             NSData *value) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeBytes),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type NSData.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetCopyObjectIvarWithField(self, field, (id)value);
}

//%PDDM-EXPAND IVAR_ALIAS_DEFN_OBJECT(Message, VPKGPBMessage)
// This block of code is generated, do not edit it directly.

// Only exists for public api, no core code should use this.
VPKGPBMessage *VPKGPBGetMessageMessageField(VPKGPBMessage *self,
                                      VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeMessage),
            @"Attempting to get value of VPKGPBMessage from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  return (VPKGPBMessage *)VPKGPBGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageMessageField(VPKGPBMessage *self,
                               VPKGPBFieldDescriptor *field,
                               VPKGPBMessage *value) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeMessage),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type VPKGPBMessage.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetObjectIvarWithField(self, field, (id)value);
}

//%PDDM-EXPAND IVAR_ALIAS_DEFN_OBJECT(Group, VPKGPBMessage)
// This block of code is generated, do not edit it directly.

// Only exists for public api, no core code should use this.
VPKGPBMessage *VPKGPBGetMessageGroupField(VPKGPBMessage *self,
                                    VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeGroup),
            @"Attempting to get value of VPKGPBMessage from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  return (VPKGPBMessage *)VPKGPBGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageGroupField(VPKGPBMessage *self,
                             VPKGPBFieldDescriptor *field,
                             VPKGPBMessage *value) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(VPKGPBGetFieldDataType(field),
                                VPKGPBDataTypeGroup),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type VPKGPBMessage.",
            [self class], field.name,
            TypeToString(VPKGPBGetFieldDataType(field)));
#endif
  VPKGPBSetObjectIvarWithField(self, field, (id)value);
}

//%PDDM-EXPAND-END (4 expansions)

// clang-format on

// VPKGPBGetMessageRepeatedField is defined in VPKGPBMessage.m

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageRepeatedField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, id array) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != VPKGPBFieldTypeRepeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a repeated field.", [self class], field.name];
  }
  Class expectedClass = Nil;
  switch (VPKGPBGetFieldDataType(field)) {
    case VPKGPBDataTypeBool:
      expectedClass = [VPKGPBBoolArray class];
      break;
    case VPKGPBDataTypeSFixed32:
    case VPKGPBDataTypeInt32:
    case VPKGPBDataTypeSInt32:
      expectedClass = [VPKGPBInt32Array class];
      break;
    case VPKGPBDataTypeFixed32:
    case VPKGPBDataTypeUInt32:
      expectedClass = [VPKGPBUInt32Array class];
      break;
    case VPKGPBDataTypeSFixed64:
    case VPKGPBDataTypeInt64:
    case VPKGPBDataTypeSInt64:
      expectedClass = [VPKGPBInt64Array class];
      break;
    case VPKGPBDataTypeFixed64:
    case VPKGPBDataTypeUInt64:
      expectedClass = [VPKGPBUInt64Array class];
      break;
    case VPKGPBDataTypeFloat:
      expectedClass = [VPKGPBFloatArray class];
      break;
    case VPKGPBDataTypeDouble:
      expectedClass = [VPKGPBDoubleArray class];
      break;
    case VPKGPBDataTypeBytes:
    case VPKGPBDataTypeString:
    case VPKGPBDataTypeMessage:
    case VPKGPBDataTypeGroup:
      expectedClass = [NSMutableArray class];
      break;
    case VPKGPBDataTypeEnum:
      expectedClass = [VPKGPBEnumArray class];
      break;
  }
  if (array && ![array isKindOfClass:expectedClass]) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@: Expected %@ object, got %@.", [self class], field.name,
                       expectedClass, [array class]];
  }
#endif
  VPKGPBSetObjectIvarWithField(self, field, array);
}

static VPKGPBDataType BaseDataType(VPKGPBDataType type) {
  switch (type) {
    case VPKGPBDataTypeSFixed32:
    case VPKGPBDataTypeInt32:
    case VPKGPBDataTypeSInt32:
    case VPKGPBDataTypeEnum:
      return VPKGPBDataTypeInt32;
    case VPKGPBDataTypeFixed32:
    case VPKGPBDataTypeUInt32:
      return VPKGPBDataTypeUInt32;
    case VPKGPBDataTypeSFixed64:
    case VPKGPBDataTypeInt64:
    case VPKGPBDataTypeSInt64:
      return VPKGPBDataTypeInt64;
    case VPKGPBDataTypeFixed64:
    case VPKGPBDataTypeUInt64:
      return VPKGPBDataTypeUInt64;
    case VPKGPBDataTypeMessage:
    case VPKGPBDataTypeGroup:
      return VPKGPBDataTypeMessage;
    case VPKGPBDataTypeBool:
    case VPKGPBDataTypeFloat:
    case VPKGPBDataTypeDouble:
    case VPKGPBDataTypeBytes:
    case VPKGPBDataTypeString:
      return type;
  }
}

static BOOL DataTypesEquivalent(VPKGPBDataType type1, VPKGPBDataType type2) {
  return BaseDataType(type1) == BaseDataType(type2);
}

static NSString *TypeToString(VPKGPBDataType dataType) {
  switch (dataType) {
    case VPKGPBDataTypeBool:
      return @"Bool";
    case VPKGPBDataTypeSFixed32:
    case VPKGPBDataTypeInt32:
    case VPKGPBDataTypeSInt32:
      return @"Int32";
    case VPKGPBDataTypeFixed32:
    case VPKGPBDataTypeUInt32:
      return @"UInt32";
    case VPKGPBDataTypeSFixed64:
    case VPKGPBDataTypeInt64:
    case VPKGPBDataTypeSInt64:
      return @"Int64";
    case VPKGPBDataTypeFixed64:
    case VPKGPBDataTypeUInt64:
      return @"UInt64";
    case VPKGPBDataTypeFloat:
      return @"Float";
    case VPKGPBDataTypeDouble:
      return @"Double";
    case VPKGPBDataTypeBytes:
    case VPKGPBDataTypeString:
    case VPKGPBDataTypeMessage:
    case VPKGPBDataTypeGroup:
      return @"Object";
    case VPKGPBDataTypeEnum:
      return @"Enum";
  }
}

// VPKGPBGetMessageMapField is defined in VPKGPBMessage.m

// Only exists for public api, no core code should use this.
void VPKGPBSetMessageMapField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, id dictionary) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != VPKGPBFieldTypeMap) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a map<> field.", [self class], field.name];
  }
  if (dictionary) {
    VPKGPBDataType keyDataType = field.mapKeyDataType;
    VPKGPBDataType valueDataType = VPKGPBGetFieldDataType(field);
    NSString *keyStr = TypeToString(keyDataType);
    NSString *valueStr = TypeToString(valueDataType);
    if (keyDataType == VPKGPBDataTypeString) {
      keyStr = @"String";
    }
    Class expectedClass = Nil;
    if ((keyDataType == VPKGPBDataTypeString) && VPKGPBDataTypeIsObject(valueDataType)) {
      expectedClass = [NSMutableDictionary class];
    } else {
      NSString *className = [NSString stringWithFormat:@"VPKGPB%@%@Dictionary", keyStr, valueStr];
      expectedClass = NSClassFromString(className);
      NSCAssert(expectedClass, @"Missing a class (%@)?", expectedClass);
    }
    if (![dictionary isKindOfClass:expectedClass]) {
      [NSException raise:NSInvalidArgumentException
                  format:@"%@.%@: Expected %@ object, got %@.", [self class], field.name,
                         expectedClass, [dictionary class]];
    }
  }
#endif
  VPKGPBSetObjectIvarWithField(self, field, dictionary);
}

#pragma mark - Misc Dynamic Runtime Utils

const char *VPKGPBMessageEncodingForSelector(SEL selector, BOOL instanceSel) {
  Protocol *protocol = objc_getProtocol(VPKGPBStringifySymbol(VPKGPBMessageSignatureProtocol));
  NSCAssert(protocol, @"Missing VPKGPBMessageSignatureProtocol");
  struct objc_method_description description =
      protocol_getMethodDescription(protocol, selector, NO, instanceSel);
  NSCAssert(description.name != Nil && description.types != nil, @"Missing method for selector %@",
            NSStringFromSelector(selector));
  return description.types;
}

#pragma mark - Text Format Support

static void AppendStringEscaped(NSString *toPrint, NSMutableString *destStr) {
  [destStr appendString:@"\""];
  NSUInteger len = [toPrint length];
  for (NSUInteger i = 0; i < len; ++i) {
    unichar aChar = [toPrint characterAtIndex:i];
    switch (aChar) {
      case '\n':
        [destStr appendString:@"\\n"];
        break;
      case '\r':
        [destStr appendString:@"\\r"];
        break;
      case '\t':
        [destStr appendString:@"\\t"];
        break;
      case '\"':
        [destStr appendString:@"\\\""];
        break;
      case '\'':
        [destStr appendString:@"\\\'"];
        break;
      case '\\':
        [destStr appendString:@"\\\\"];
        break;
      default:
        // This differs slightly from the C++ code in that the C++ doesn't
        // generate UTF8; it looks at the string in UTF8, but escapes every
        // byte > 0x7E.
        if (aChar < 0x20) {
          [destStr appendFormat:@"\\%d%d%d", (aChar / 64), ((aChar % 64) / 8), (aChar % 8)];
        } else {
          [destStr appendFormat:@"%C", aChar];
        }
        break;
    }
  }
  [destStr appendString:@"\""];
}

static void AppendBufferAsString(NSData *buffer, NSMutableString *destStr) {
  const char *src = (const char *)[buffer bytes];
  size_t srcLen = [buffer length];
  [destStr appendString:@"\""];
  for (const char *srcEnd = src + srcLen; src < srcEnd; src++) {
    switch (*src) {
      case '\n':
        [destStr appendString:@"\\n"];
        break;
      case '\r':
        [destStr appendString:@"\\r"];
        break;
      case '\t':
        [destStr appendString:@"\\t"];
        break;
      case '\"':
        [destStr appendString:@"\\\""];
        break;
      case '\'':
        [destStr appendString:@"\\\'"];
        break;
      case '\\':
        [destStr appendString:@"\\\\"];
        break;
      default:
        if (isprint(*src)) {
          [destStr appendFormat:@"%c", *src];
        } else {
          // NOTE: doing hex means you have to worry about the letter after
          // the hex being another hex char and forcing that to be escaped, so
          // use octal to keep it simple.
          [destStr appendFormat:@"\\%03o", (uint8_t)(*src)];
        }
        break;
    }
  }
  [destStr appendString:@"\""];
}

static void AppendTextFormatForMapMessageField(id map, VPKGPBFieldDescriptor *field,
                                               NSMutableString *toStr, NSString *lineIndent,
                                               NSString *fieldName, NSString *lineEnding) {
  VPKGPBDataType keyDataType = field.mapKeyDataType;
  VPKGPBDataType valueDataType = VPKGPBGetFieldDataType(field);
  BOOL isMessageValue = VPKGPBDataTypeIsMessage(valueDataType);

  NSString *msgStartFirst =
      [NSString stringWithFormat:@"%@%@ {%@\n", lineIndent, fieldName, lineEnding];
  NSString *msgStart = [NSString stringWithFormat:@"%@%@ {\n", lineIndent, fieldName];
  NSString *msgEnd = [NSString stringWithFormat:@"%@}\n", lineIndent];

  NSString *keyLine = [NSString stringWithFormat:@"%@  key: ", lineIndent];
  NSString *valueLine =
      [NSString stringWithFormat:@"%@  value%s ", lineIndent, (isMessageValue ? "" : ":")];

  __block BOOL isFirst = YES;

  if ((keyDataType == VPKGPBDataTypeString) && VPKGPBDataTypeIsObject(valueDataType)) {
    // map is an NSDictionary.
    NSDictionary *dict = map;
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, __unused BOOL *stop) {
      [toStr appendString:(isFirst ? msgStartFirst : msgStart)];
      isFirst = NO;

      [toStr appendString:keyLine];
      AppendStringEscaped(key, toStr);
      [toStr appendString:@"\n"];

      [toStr appendString:valueLine];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
      switch (valueDataType) {
        case VPKGPBDataTypeString:
          AppendStringEscaped(value, toStr);
          break;

        case VPKGPBDataTypeBytes:
          AppendBufferAsString(value, toStr);
          break;

        case VPKGPBDataTypeMessage:
          [toStr appendString:@"{\n"];
          NSString *subIndent = [lineIndent stringByAppendingString:@"    "];
          AppendTextFormatForMessage(value, toStr, subIndent);
          [toStr appendFormat:@"%@  }", lineIndent];
          break;

        default:
          NSCAssert(NO, @"Can't happen");
          break;
      }
#pragma clang diagnostic pop
      [toStr appendString:@"\n"];

      [toStr appendString:msgEnd];
    }];
  } else {
    // map is one of the VPKGPB*Dictionary classes, type doesn't matter.
    VPKGPBInt32Int32Dictionary *dict = map;
    [dict enumerateForTextFormat:^(id keyObj, id valueObj) {
      [toStr appendString:(isFirst ? msgStartFirst : msgStart)];
      isFirst = NO;

      // Key always is a NSString.
      if (keyDataType == VPKGPBDataTypeString) {
        [toStr appendString:keyLine];
        AppendStringEscaped(keyObj, toStr);
        [toStr appendString:@"\n"];
      } else {
        [toStr appendFormat:@"%@%@\n", keyLine, keyObj];
      }

      [toStr appendString:valueLine];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
      switch (valueDataType) {
        case VPKGPBDataTypeString:
          AppendStringEscaped(valueObj, toStr);
          break;

        case VPKGPBDataTypeBytes:
          AppendBufferAsString(valueObj, toStr);
          break;

        case VPKGPBDataTypeMessage:
          [toStr appendString:@"{\n"];
          NSString *subIndent = [lineIndent stringByAppendingString:@"    "];
          AppendTextFormatForMessage(valueObj, toStr, subIndent);
          [toStr appendFormat:@"%@  }", lineIndent];
          break;

        case VPKGPBDataTypeEnum: {
          int32_t enumValue = [valueObj intValue];
          NSString *valueStr = nil;
          VPKGPBEnumDescriptor *descriptor = field.enumDescriptor;
          if (descriptor) {
            valueStr = [descriptor textFormatNameForValue:enumValue];
          }
          if (valueStr) {
            [toStr appendString:valueStr];
          } else {
            [toStr appendFormat:@"%d", enumValue];
          }
          break;
        }

        default:
          NSCAssert(valueDataType != VPKGPBDataTypeGroup, @"Can't happen");
          // Everything else is a NSString.
          [toStr appendString:valueObj];
          break;
      }
#pragma clang diagnostic pop
      [toStr appendString:@"\n"];

      [toStr appendString:msgEnd];
    }];
  }
}

static void AppendTextFormatForMessageField(VPKGPBMessage *message, VPKGPBFieldDescriptor *field,
                                            NSMutableString *toStr, NSString *lineIndent) {
  id arrayOrMap;
  NSUInteger count;
  VPKGPBFieldType fieldType = field.fieldType;
  switch (fieldType) {
    case VPKGPBFieldTypeSingle:
      arrayOrMap = nil;
      count = (VPKGPBGetHasIvarField(message, field) ? 1 : 0);
      break;

    case VPKGPBFieldTypeRepeated:
      // Will be NSArray or VPKGPB*Array, type doesn't matter, they both
      // implement count.
      arrayOrMap = VPKGPBGetObjectIvarWithFieldNoAutocreate(message, field);
      count = [(NSArray *)arrayOrMap count];
      break;

    case VPKGPBFieldTypeMap: {
      // Will be VPKGPB*Dictionary or NSMutableDictionary, type doesn't matter,
      // they both implement count.
      arrayOrMap = VPKGPBGetObjectIvarWithFieldNoAutocreate(message, field);
      count = [(NSDictionary *)arrayOrMap count];
      break;
    }
  }

  if (count == 0) {
    // Nothing to print, out of here.
    return;
  }

  NSString *lineEnding = @"";

  // If the name can't be reversed or support for extra info was turned off,
  // this can return nil.
  NSString *fieldName = [field textFormatName];
  if ([fieldName length] == 0) {
    fieldName = [NSString stringWithFormat:@"%u", VPKGPBFieldNumber(field)];
    // If there is only one entry, put the objc name as a comment, other wise
    // add it before the repeated values.
    if (count > 1) {
      [toStr appendFormat:@"%@# %@\n", lineIndent, field.name];
    } else {
      lineEnding = [NSString stringWithFormat:@"  # %@", field.name];
    }
  }

  if (fieldType == VPKGPBFieldTypeMap) {
    AppendTextFormatForMapMessageField(arrayOrMap, field, toStr, lineIndent, fieldName, lineEnding);
    return;
  }

  id array = arrayOrMap;
  const BOOL isRepeated = (array != nil);

  VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
  BOOL isMessageField = VPKGPBDataTypeIsMessage(fieldDataType);
  for (NSUInteger j = 0; j < count; ++j) {
    // Start the line.
    [toStr appendFormat:@"%@%@%s ", lineIndent, fieldName, (isMessageField ? "" : ":")];

    // The value.
    switch (fieldDataType) {
#define FIELD_CASE(VPKGPBDATATYPE, CTYPE, REAL_TYPE, ...)                        \
  case VPKGPBDataType##VPKGPBDATATYPE: {                                            \
    CTYPE v = (isRepeated ? [(VPKGPB##REAL_TYPE##Array *)array valueAtIndex:j]   \
                          : VPKGPBGetMessage##REAL_TYPE##Field(message, field)); \
    [toStr appendFormat:__VA_ARGS__, v];                                      \
    break;                                                                    \
  }

      FIELD_CASE(Int32, int32_t, Int32, @"%d")
      FIELD_CASE(SInt32, int32_t, Int32, @"%d")
      FIELD_CASE(SFixed32, int32_t, Int32, @"%d")
      FIELD_CASE(UInt32, uint32_t, UInt32, @"%u")
      FIELD_CASE(Fixed32, uint32_t, UInt32, @"%u")
      FIELD_CASE(Int64, int64_t, Int64, @"%lld")
      FIELD_CASE(SInt64, int64_t, Int64, @"%lld")
      FIELD_CASE(SFixed64, int64_t, Int64, @"%lld")
      FIELD_CASE(UInt64, uint64_t, UInt64, @"%llu")
      FIELD_CASE(Fixed64, uint64_t, UInt64, @"%llu")
      FIELD_CASE(Float, float, Float, @"%.*g", FLT_DIG)
      FIELD_CASE(Double, double, Double, @"%.*lg", DBL_DIG)

#undef FIELD_CASE

      case VPKGPBDataTypeEnum: {
        int32_t v = (isRepeated ? [(VPKGPBEnumArray *)array rawValueAtIndex:j]
                                : VPKGPBGetMessageInt32Field(message, field));
        NSString *valueStr = nil;
        VPKGPBEnumDescriptor *descriptor = field.enumDescriptor;
        if (descriptor) {
          valueStr = [descriptor textFormatNameForValue:v];
        }
        if (valueStr) {
          [toStr appendString:valueStr];
        } else {
          [toStr appendFormat:@"%d", v];
        }
        break;
      }

      case VPKGPBDataTypeBool: {
        BOOL v = (isRepeated ? [(VPKGPBBoolArray *)array valueAtIndex:j]
                             : VPKGPBGetMessageBoolField(message, field));
        [toStr appendString:(v ? @"true" : @"false")];
        break;
      }

      case VPKGPBDataTypeString: {
        NSString *v = (isRepeated ? [(NSArray *)array objectAtIndex:j]
                                  : VPKGPBGetMessageStringField(message, field));
        AppendStringEscaped(v, toStr);
        break;
      }

      case VPKGPBDataTypeBytes: {
        NSData *v = (isRepeated ? [(NSArray *)array objectAtIndex:j]
                                : VPKGPBGetMessageBytesField(message, field));
        AppendBufferAsString(v, toStr);
        break;
      }

      case VPKGPBDataTypeGroup:
      case VPKGPBDataTypeMessage: {
        VPKGPBMessage *v = (isRepeated ? [(NSArray *)array objectAtIndex:j]
                                    : VPKGPBGetObjectIvarWithField(message, field));
        [toStr appendFormat:@"{%@\n", lineEnding];
        NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
        AppendTextFormatForMessage(v, toStr, subIndent);
        [toStr appendFormat:@"%@}", lineIndent];
        lineEnding = @"";
        break;
      }

    }  // switch(fieldDataType)

    // End the line.
    [toStr appendFormat:@"%@\n", lineEnding];

  }  // for(count)
}

static void AppendTextFormatForMessageExtensionRange(VPKGPBMessage *message, NSArray *activeExtensions,
                                                     VPKGPBExtensionRange range,
                                                     NSMutableString *toStr, NSString *lineIndent) {
  uint32_t start = range.start;
  uint32_t end = range.end;
  for (VPKGPBExtensionDescriptor *extension in activeExtensions) {
    uint32_t fieldNumber = extension.fieldNumber;
    if (fieldNumber < start) {
      // Not there yet.
      continue;
    }
    if (fieldNumber >= end) {
      // Done.
      break;
    }

    id rawExtValue = [message getExtension:extension];
    BOOL isRepeated = extension.isRepeated;

    NSUInteger numValues = 1;
    NSString *lineEnding = @"";
    if (isRepeated) {
      numValues = [(NSArray *)rawExtValue count];
    }

    NSString *singletonName = extension.singletonName;
    if (numValues == 1) {
      lineEnding = [NSString stringWithFormat:@"  # [%@]", singletonName];
    } else {
      [toStr appendFormat:@"%@# [%@]\n", lineIndent, singletonName];
    }

    VPKGPBDataType extDataType = extension.dataType;
    for (NSUInteger j = 0; j < numValues; ++j) {
      id curValue = (isRepeated ? [rawExtValue objectAtIndex:j] : rawExtValue);

      // Start the line.
      [toStr appendFormat:@"%@%u%s ", lineIndent, fieldNumber,
                          (VPKGPBDataTypeIsMessage(extDataType) ? "" : ":")];

      // The value.
      switch (extDataType) {
#define FIELD_CASE(VPKGPBDATATYPE, CTYPE, NUMSELECTOR, ...) \
  case VPKGPBDataType##VPKGPBDATATYPE: {                       \
    CTYPE v = [(NSNumber *)curValue NUMSELECTOR];        \
    [toStr appendFormat:__VA_ARGS__, v];                 \
    break;                                               \
  }

        FIELD_CASE(Int32, int32_t, intValue, @"%d")
        FIELD_CASE(SInt32, int32_t, intValue, @"%d")
        FIELD_CASE(SFixed32, int32_t, unsignedIntValue, @"%d")
        FIELD_CASE(UInt32, uint32_t, unsignedIntValue, @"%u")
        FIELD_CASE(Fixed32, uint32_t, unsignedIntValue, @"%u")
        FIELD_CASE(Int64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(SInt64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(SFixed64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(UInt64, uint64_t, unsignedLongLongValue, @"%llu")
        FIELD_CASE(Fixed64, uint64_t, unsignedLongLongValue, @"%llu")
        FIELD_CASE(Float, float, floatValue, @"%.*g", FLT_DIG)
        FIELD_CASE(Double, double, doubleValue, @"%.*lg", DBL_DIG)
        // TODO: Add a comment with the enum name from enum descriptors
        // (might not be real value, so leave it as a comment, ObjC compiler
        // name mangles differently).  Doesn't look like we actually generate
        // an enum descriptor reference like we do for normal fields, so this
        // will take a compiler change.
        FIELD_CASE(Enum, int32_t, intValue, @"%d")

#undef FIELD_CASE

        case VPKGPBDataTypeBool:
          [toStr appendString:([(NSNumber *)curValue boolValue] ? @"true" : @"false")];
          break;

        case VPKGPBDataTypeString:
          AppendStringEscaped(curValue, toStr);
          break;

        case VPKGPBDataTypeBytes:
          AppendBufferAsString((NSData *)curValue, toStr);
          break;

        case VPKGPBDataTypeGroup:
        case VPKGPBDataTypeMessage: {
          [toStr appendFormat:@"{%@\n", lineEnding];
          NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
          AppendTextFormatForMessage(curValue, toStr, subIndent);
          [toStr appendFormat:@"%@}", lineIndent];
          lineEnding = @"";
          break;
        }

      }  // switch(extDataType)

      // End the line.
      [toStr appendFormat:@"%@\n", lineEnding];

    }  //  for(numValues)

  }  // for..in(activeExtensions)
}

static void AppendTextFormatForMessage(VPKGPBMessage *message, NSMutableString *toStr,
                                       NSString *lineIndent) {
  VPKGPBDescriptor *descriptor = [message descriptor];
  NSArray *fieldsArray = descriptor->fields_;
  NSUInteger fieldCount = fieldsArray.count;
  const VPKGPBExtensionRange *extensionRanges = descriptor.extensionRanges;
  NSUInteger extensionRangesCount = descriptor.extensionRangesCount;
  NSArray *activeExtensions =
      [[message extensionsCurrentlySet] sortedArrayUsingSelector:@selector(compareByFieldNumber:)];
  for (NSUInteger i = 0, j = 0; i < fieldCount || j < extensionRangesCount;) {
    if (i == fieldCount) {
      AppendTextFormatForMessageExtensionRange(message, activeExtensions, extensionRanges[j++],
                                               toStr, lineIndent);
    } else if (j == extensionRangesCount ||
               VPKGPBFieldNumber(fieldsArray[i]) < extensionRanges[j].start) {
      AppendTextFormatForMessageField(message, fieldsArray[i++], toStr, lineIndent);
    } else {
      AppendTextFormatForMessageExtensionRange(message, activeExtensions, extensionRanges[j++],
                                               toStr, lineIndent);
    }
  }

  NSString *unknownFieldsStr = VPKGPBTextFormatForUnknownFieldSet(message.unknownFields, lineIndent);
  if ([unknownFieldsStr length] > 0) {
    [toStr appendFormat:@"%@# --- Unknown fields ---\n", lineIndent];
    [toStr appendString:unknownFieldsStr];
  }
}

NSString *VPKGPBTextFormatForMessage(VPKGPBMessage *message, NSString *lineIndent) {
  if (message == nil) return @"";
  if (lineIndent == nil) lineIndent = @"";

  NSMutableString *buildString = [NSMutableString string];
  AppendTextFormatForMessage(message, buildString, lineIndent);
  return buildString;
}

NSString *VPKGPBTextFormatForUnknownFieldSet(VPKGPBUnknownFieldSet *unknownSet, NSString *lineIndent) {
  if (unknownSet == nil) return @"";
  if (lineIndent == nil) lineIndent = @"";

  NSMutableString *result = [NSMutableString string];
  for (VPKGPBUnknownField *field in [unknownSet sortedFields]) {
    int32_t fieldNumber = [field number];

#define PRINT_LOOP(PROPNAME, CTYPE, FORMAT)                                                    \
  [field.PROPNAME                                                                              \
      enumerateValuesWithBlock:^(CTYPE value, __unused NSUInteger idx, __unused BOOL * stop) { \
        [result appendFormat:@"%@%d: " FORMAT "\n", lineIndent, fieldNumber, value];           \
      }];

    PRINT_LOOP(varintList, uint64_t, "%llu");
    PRINT_LOOP(fixed32List, uint32_t, "0x%X");
    PRINT_LOOP(fixed64List, uint64_t, "0x%llX");

#undef PRINT_LOOP

    // NOTE: C++ version of TextFormat tries to parse this as a message
    // and print that if it succeeds.
    for (NSData *data in field.lengthDelimitedList) {
      [result appendFormat:@"%@%d: ", lineIndent, fieldNumber];
      AppendBufferAsString(data, result);
      [result appendString:@"\n"];
    }

    for (VPKGPBUnknownFieldSet *subUnknownSet in field.groupList) {
      [result appendFormat:@"%@%d: {\n", lineIndent, fieldNumber];
      NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
      NSString *subUnknownSetStr = VPKGPBTextFormatForUnknownFieldSet(subUnknownSet, subIndent);
      [result appendString:subUnknownSetStr];
      [result appendFormat:@"%@}\n", lineIndent];
    }
  }
  return result;
}

// Helpers to decode a varint. Not using VPKGPBCodedInputStream version because
// that needs a state object, and we don't want to create an input stream out
// of the data.
VPKGPB_INLINE int8_t ReadRawByteFromData(const uint8_t **data) {
  int8_t result = *((int8_t *)(*data));
  ++(*data);
  return result;
}

static int32_t ReadRawVarint32FromData(const uint8_t **data) {
  int8_t tmp = ReadRawByteFromData(data);
  if (tmp >= 0) {
    return tmp;
  }
  int32_t result = tmp & 0x7f;
  if ((tmp = ReadRawByteFromData(data)) >= 0) {
    result |= tmp << 7;
  } else {
    result |= (tmp & 0x7f) << 7;
    if ((tmp = ReadRawByteFromData(data)) >= 0) {
      result |= tmp << 14;
    } else {
      result |= (tmp & 0x7f) << 14;
      if ((tmp = ReadRawByteFromData(data)) >= 0) {
        result |= tmp << 21;
      } else {
        result |= (tmp & 0x7f) << 21;
        result |= (tmp = ReadRawByteFromData(data)) << 28;
        if (tmp < 0) {
          // Discard upper 32 bits.
          for (int i = 0; i < 5; i++) {
            if (ReadRawByteFromData(data) >= 0) {
              return result;
            }
          }
          [NSException raise:NSParseErrorException format:@"Unable to read varint32"];
        }
      }
    }
  }
  return result;
}

NSString *VPKGPBDecodeTextFormatName(const uint8_t *decodeData, int32_t key, NSString *inputStr) {
  // decodData form:
  //  varint32: num entries
  //  for each entry:
  //    varint32: key
  //    bytes*: decode data
  //
  // decode data one of two forms:
  //  1: a \0 followed by the string followed by an \0
  //  2: bytecodes to transform an input into the right thing, ending with \0
  //
  // the bytes codes are of the form:
  //  0xabbccccc
  //  0x0 (all zeros), end.
  //  a - if set, add an underscore
  //  bb - 00 ccccc bytes as is
  //  bb - 10 ccccc upper first, as is on rest, ccccc byte total
  //  bb - 01 ccccc lower first, as is on rest, ccccc byte total
  //  bb - 11 ccccc all upper, ccccc byte total

  if (!decodeData || !inputStr) {
    return nil;
  }

  // Find key
  const uint8_t *scan = decodeData;
  int32_t numEntries = ReadRawVarint32FromData(&scan);
  BOOL foundKey = NO;
  while (!foundKey && (numEntries > 0)) {
    --numEntries;
    int32_t dataKey = ReadRawVarint32FromData(&scan);
    if (dataKey == key) {
      foundKey = YES;
    } else {
      // If it is a inlined string, it will start with \0; if it is bytecode it
      // will start with a code. So advance one (skipping the inline string
      // marker), and then loop until reaching the end marker (\0).
      ++scan;
      while (*scan != 0) ++scan;
      // Now move past the end marker.
      ++scan;
    }
  }

  if (!foundKey) {
    return nil;
  }

  // Decode

  if (*scan == 0) {
    // Inline string. Move over the marker, and NSString can take it as
    // UTF8.
    ++scan;
    NSString *result = [NSString stringWithUTF8String:(const char *)scan];
    return result;
  }

  NSMutableString *result = [NSMutableString stringWithCapacity:[inputStr length]];

  const uint8_t kAddUnderscore = 0b10000000;
  const uint8_t kOpMask = 0b01100000;
  // const uint8_t kOpAsIs        = 0b00000000;
  const uint8_t kOpFirstUpper = 0b01000000;
  const uint8_t kOpFirstLower = 0b00100000;
  const uint8_t kOpAllUpper = 0b01100000;
  const uint8_t kSegmentLenMask = 0b00011111;

  NSInteger i = 0;
  for (; *scan != 0; ++scan) {
    if (*scan & kAddUnderscore) {
      [result appendString:@"_"];
    }
    int segmentLen = *scan & kSegmentLenMask;
    uint8_t decodeOp = *scan & kOpMask;

    // Do op specific handling of the first character.
    if (decodeOp == kOpFirstUpper) {
      unichar c = [inputStr characterAtIndex:i];
      [result appendFormat:@"%c", toupper((char)c)];
      ++i;
      --segmentLen;
    } else if (decodeOp == kOpFirstLower) {
      unichar c = [inputStr characterAtIndex:i];
      [result appendFormat:@"%c", tolower((char)c)];
      ++i;
      --segmentLen;
    }
    // else op == kOpAsIs || op == kOpAllUpper

    // Now pull over the rest of the length for this segment.
    for (int x = 0; x < segmentLen; ++x) {
      unichar c = [inputStr characterAtIndex:(i + x)];
      if (decodeOp == kOpAllUpper) {
        [result appendFormat:@"%c", toupper((char)c)];
      } else {
        [result appendFormat:@"%C", c];
      }
    }
    i += segmentLen;
  }

  return result;
}

#pragma mark Legacy methods old generated code calls

// Shim from the older generated code into the runtime.
void VPKGPBSetInt32IvarWithFieldInternal(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, int32_t value,
                                      __unused VPKGPBFileSyntax syntax) {
  VPKGPBSetMessageInt32Field(self, field, value);
}

void VPKGPBMaybeClearOneof(VPKGPBMessage *self, VPKGPBOneofDescriptor *oneof, int32_t oneofHasIndex,
                        __unused uint32_t fieldNumberNotToClear) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] oneofWithName:oneof.name] == oneof,
            @"OneofDescriptor %@ doesn't appear to be for %@ messages.", oneof.name, [self class]);
  VPKGPBFieldDescriptor *firstField __unused = oneof->fields_[0];
  NSCAssert(firstField->description_->hasIndex == oneofHasIndex,
            @"Internal error, oneofHasIndex (%d) doesn't match (%d).",
            firstField->description_->hasIndex, oneofHasIndex);
#endif
  VPKGPBMaybeClearOneofPrivate(self, oneof, oneofHasIndex, 0);
}

#pragma clang diagnostic pop

#pragma mark Misc Helpers

BOOL VPKGPBClassHasSel(Class aClass, SEL sel) {
  // NOTE: We have to use class_copyMethodList, all other runtime method
  // lookups actually also resolve the method implementation and this
  // is called from within those methods.

  BOOL result = NO;
  unsigned int methodCount = 0;
  Method *methodList = class_copyMethodList(aClass, &methodCount);
  for (unsigned int i = 0; i < methodCount; ++i) {
    SEL methodSelector = method_getName(methodList[i]);
    if (methodSelector == sel) {
      result = YES;
      break;
    }
  }
  free(methodList);
  return result;
}
