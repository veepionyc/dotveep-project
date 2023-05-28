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

#import "VPKGPBDictionary.h"

@class VPKGPBCodedInputStream;
@class VPKGPBCodedOutputStream;
@protocol VPKGPBExtensionRegistry;
@class VPKGPBFieldDescriptor;

@protocol VPKGPBDictionaryInternalsProtocol
- (size_t)computeSerializedSizeAsField:(VPKGPBFieldDescriptor *)field;
- (void)writeToCodedOutputStream:(VPKGPBCodedOutputStream *)outputStream
                         asField:(VPKGPBFieldDescriptor *)field;
- (void)setVPKGPBGenericValue:(VPKGPBGenericValue *)value forVPKGPBGenericValueKey:(VPKGPBGenericValue *)key;
- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block;
@end

// Disable clang-format for the macros.
// clang-format off

//%PDDM-DEFINE DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(KEY_NAME)
//%DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(KEY_NAME)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Object, Object)
//%PDDM-DEFINE DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(KEY_NAME)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, UInt32, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Int32, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, UInt64, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Int64, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Bool, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Float, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Double, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Enum, Enum)

//%PDDM-DEFINE DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, VALUE_NAME, HELPER)
//%@interface VPKGPB##KEY_NAME##VALUE_NAME##Dictionary () <VPKGPBDictionaryInternalsProtocol> {
//% @package
//%  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
//%}
//%EXTRA_DICTIONARY_PRIVATE_INTERFACES_##HELPER()@end
//%

//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Basic()
// Empty
//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Object()
//%- (BOOL)isInitialized;
//%- (instancetype)deepCopyWithZone:(NSZone *)zone
//%    __attribute__((ns_returns_retained));
//%
//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Enum()
//%- (NSData *)serializedDataForUnknownValue:(int32_t)value
//%                                   forKey:(VPKGPBGenericValue *)key
//%                              keyDataType:(VPKGPBDataType)keyDataType;
//%

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(UInt32)
// This block of code is generated, do not edit it directly.

@interface VPKGPBUInt32UInt32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt32Int32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt32UInt64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt32Int64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt32BoolDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt32FloatDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt32DoubleDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt32EnumDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(VPKGPBGenericValue *)key
                              keyDataType:(VPKGPBDataType)keyDataType;
@end

@interface VPKGPBUInt32ObjectDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Int32)
// This block of code is generated, do not edit it directly.

@interface VPKGPBInt32UInt32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt32Int32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt32UInt64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt32Int64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt32BoolDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt32FloatDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt32DoubleDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt32EnumDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(VPKGPBGenericValue *)key
                              keyDataType:(VPKGPBDataType)keyDataType;
@end

@interface VPKGPBInt32ObjectDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(UInt64)
// This block of code is generated, do not edit it directly.

@interface VPKGPBUInt64UInt32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt64Int32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt64UInt64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt64Int64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt64BoolDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt64FloatDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt64DoubleDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBUInt64EnumDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(VPKGPBGenericValue *)key
                              keyDataType:(VPKGPBDataType)keyDataType;
@end

@interface VPKGPBUInt64ObjectDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Int64)
// This block of code is generated, do not edit it directly.

@interface VPKGPBInt64UInt32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt64Int32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt64UInt64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt64Int64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt64BoolDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt64FloatDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt64DoubleDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBInt64EnumDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(VPKGPBGenericValue *)key
                              keyDataType:(VPKGPBDataType)keyDataType;
@end

@interface VPKGPBInt64ObjectDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Bool)
// This block of code is generated, do not edit it directly.

@interface VPKGPBBoolUInt32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBBoolInt32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBBoolUInt64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBBoolInt64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBBoolBoolDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBBoolFloatDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBBoolDoubleDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBBoolEnumDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(VPKGPBGenericValue *)key
                              keyDataType:(VPKGPBDataType)keyDataType;
@end

@interface VPKGPBBoolObjectDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

//%PDDM-EXPAND DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(String)
// This block of code is generated, do not edit it directly.

@interface VPKGPBStringUInt32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBStringInt32Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBStringUInt64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBStringInt64Dictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBStringBoolDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBStringFloatDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBStringDoubleDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

@interface VPKGPBStringEnumDictionary () <VPKGPBDictionaryInternalsProtocol> {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(VPKGPBGenericValue *)key
                              keyDataType:(VPKGPBDataType)keyDataType;
@end

//%PDDM-EXPAND-END (6 expansions)

// clang-format on

#pragma mark - NSDictionary Subclass

@interface VPKGPBAutocreatedDictionary : NSMutableDictionary {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

#pragma mark - Helpers

CF_EXTERN_C_BEGIN

// Helper to compute size when an NSDictionary is used for the map instead
// of a custom type.
size_t VPKGPBDictionaryComputeSizeInternalHelper(NSDictionary *dict, VPKGPBFieldDescriptor *field);

// Helper to write out when an NSDictionary is used for the map instead
// of a custom type.
void VPKGPBDictionaryWriteToStreamInternalHelper(VPKGPBCodedOutputStream *outputStream,
                                              NSDictionary *dict, VPKGPBFieldDescriptor *field);

// Helper to check message initialization when an NSDictionary is used for
// the map instead of a custom type.
BOOL VPKGPBDictionaryIsInitializedInternalHelper(NSDictionary *dict, VPKGPBFieldDescriptor *field);

// Helper to read a map instead.
void VPKGPBDictionaryReadEntry(id mapDictionary, VPKGPBCodedInputStream *stream,
                            id<VPKGPBExtensionRegistry> registry, VPKGPBFieldDescriptor *field,
                            VPKGPBMessage *parentMessage);

CF_EXTERN_C_END
