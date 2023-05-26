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

#import "VPKGPBMessage_PackagePrivate.h"

#import <objc/message.h>
#import <objc/runtime.h>
#import <os/lock.h>
#import <stdatomic.h>

#import "VPKGPBArray_PackagePrivate.h"
#import "VPKGPBCodedInputStream_PackagePrivate.h"
#import "VPKGPBCodedOutputStream_PackagePrivate.h"
#import "VPKGPBDescriptor_PackagePrivate.h"
#import "VPKGPBDictionary_PackagePrivate.h"
#import "VPKGPBExtensionInternals.h"
#import "VPKGPBExtensionRegistry.h"
#import "VPKGPBRootObject_PackagePrivate.h"
#import "VPKGPBUnknownFieldSet_PackagePrivate.h"
#import "VPKGPBUtilities_PackagePrivate.h"

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

NSString *const VPKGPBMessageErrorDomain = VPKGPBNSStringifySymbol(VPKGPBMessageErrorDomain);

NSString *const VPKGPBErrorReasonKey = @"Reason";

static NSString *const kVPKGPBDataCoderKey = @"VPKGPBData";

//
// PLEASE REMEMBER:
//
// This is the base class for *all* messages generated, so any selector defined,
// *public* or *private* could end up colliding with a proto message field. So
// avoid using selectors that could match a property, use C functions to hide
// them, etc.
//

@interface VPKGPBMessage () {
 @package
  VPKGPBUnknownFieldSet *unknownFields_;
  NSMutableDictionary *extensionMap_;
  // Readonly access to autocreatedExtensionMap_ is protected via readOnlyLock_.
  NSMutableDictionary *autocreatedExtensionMap_;

  // If the object was autocreated, we remember the creator so that if we get
  // mutated, we can inform the creator to make our field visible.
  VPKGPBMessage *autocreator_;
  VPKGPBFieldDescriptor *autocreatorField_;
  VPKGPBExtensionDescriptor *autocreatorExtension_;

  // Messages can only be mutated from one thread. But some *readonly* operations modify internal
  // state because they autocreate things. The autocreatedExtensionMap_ is one such structure.
  // Access during readonly operations is protected via this lock.
  //
  // Long ago, this was an OSSpinLock, but then it came to light that there were issues for that on
  // iOS:
  //   http://mjtsai.com/blog/2015/12/16/osspinlock-is-unsafe/
  //   https://lists.swift.org/pipermail/swift-dev/Week-of-Mon-20151214/000372.html
  // It was changed to a dispatch_semaphore_t, but that has potential for priority inversion issues.
  // The minOS versions are now high enough that os_unfair_lock can be used, and should provide
  // all the support we need. For more information in the concurrency/locking space see:
  //   https://gist.github.com/tclementdev/6af616354912b0347cdf6db159c37057
  //   https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html
  //   https://developer.apple.com/videos/play/wwdc2017/706/
  os_unfair_lock readOnlyLock_;
}
@end

static id CreateArrayForField(VPKGPBFieldDescriptor *field, VPKGPBMessage *autocreator)
    __attribute__((ns_returns_retained));
static id GetOrCreateArrayIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
static id GetArrayIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
static id CreateMapForField(VPKGPBFieldDescriptor *field, VPKGPBMessage *autocreator)
    __attribute__((ns_returns_retained));
static id GetOrCreateMapIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
static id GetMapIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
static NSMutableDictionary *CloneExtensionMap(NSDictionary *extensionMap, NSZone *zone)
    __attribute__((ns_returns_retained));
static VPKGPBUnknownFieldSet *GetOrMakeUnknownFields(VPKGPBMessage *self);

#ifdef DEBUG
static NSError *MessageError(NSInteger code, NSDictionary *userInfo) {
  return [NSError errorWithDomain:VPKGPBMessageErrorDomain code:code userInfo:userInfo];
}
#endif

static NSError *ErrorFromException(NSException *exception) {
  NSError *error = nil;

  if ([exception.name isEqual:VPKGPBCodedInputStreamException]) {
    NSDictionary *exceptionInfo = exception.userInfo;
    error = exceptionInfo[VPKGPBCodedInputStreamUnderlyingErrorKey];
  }

  if (!error) {
    NSString *reason = exception.reason;
    NSDictionary *userInfo = nil;
    if ([reason length]) {
      userInfo = @{VPKGPBErrorReasonKey : reason};
    }

    error = [NSError errorWithDomain:VPKGPBMessageErrorDomain
                                code:VPKGPBMessageErrorCodeOther
                            userInfo:userInfo];
  }
  return error;
}

static void CheckExtension(VPKGPBMessage *self, VPKGPBExtensionDescriptor *extension) {
  if (![self isKindOfClass:extension.containingMessageClass]) {
    [NSException raise:NSInvalidArgumentException
                format:@"Extension %@ used on wrong class (%@ instead of %@)",
                       extension.singletonName, [self class], extension.containingMessageClass];
  }
}

static NSMutableDictionary *CloneExtensionMap(NSDictionary *extensionMap, NSZone *zone) {
  if (extensionMap.count == 0) {
    return nil;
  }
  NSMutableDictionary *result =
      [[NSMutableDictionary allocWithZone:zone] initWithCapacity:extensionMap.count];

  for (VPKGPBExtensionDescriptor *extension in extensionMap) {
    id value = [extensionMap objectForKey:extension];
    BOOL isMessageExtension = VPKGPBExtensionIsMessage(extension);

    if (extension.repeated) {
      if (isMessageExtension) {
        NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[value count]];
        for (VPKGPBMessage *listValue in value) {
          VPKGPBMessage *copiedValue = [listValue copyWithZone:zone];
          [list addObject:copiedValue];
          [copiedValue release];
        }
        [result setObject:list forKey:extension];
        [list release];
      } else {
        NSMutableArray *copiedValue = [value mutableCopyWithZone:zone];
        [result setObject:copiedValue forKey:extension];
        [copiedValue release];
      }
    } else {
      if (isMessageExtension) {
        VPKGPBMessage *copiedValue = [value copyWithZone:zone];
        [result setObject:copiedValue forKey:extension];
        [copiedValue release];
      } else {
        [result setObject:value forKey:extension];
      }
    }
  }

  return result;
}

static id CreateArrayForField(VPKGPBFieldDescriptor *field, VPKGPBMessage *autocreator) {
  id result;
  VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
  switch (fieldDataType) {
    case VPKGPBDataTypeBool:
      result = [[VPKGPBBoolArray alloc] init];
      break;
    case VPKGPBDataTypeFixed32:
    case VPKGPBDataTypeUInt32:
      result = [[VPKGPBUInt32Array alloc] init];
      break;
    case VPKGPBDataTypeInt32:
    case VPKGPBDataTypeSFixed32:
    case VPKGPBDataTypeSInt32:
      result = [[VPKGPBInt32Array alloc] init];
      break;
    case VPKGPBDataTypeFixed64:
    case VPKGPBDataTypeUInt64:
      result = [[VPKGPBUInt64Array alloc] init];
      break;
    case VPKGPBDataTypeInt64:
    case VPKGPBDataTypeSFixed64:
    case VPKGPBDataTypeSInt64:
      result = [[VPKGPBInt64Array alloc] init];
      break;
    case VPKGPBDataTypeFloat:
      result = [[VPKGPBFloatArray alloc] init];
      break;
    case VPKGPBDataTypeDouble:
      result = [[VPKGPBDoubleArray alloc] init];
      break;

    case VPKGPBDataTypeEnum:
      result = [[VPKGPBEnumArray alloc] initWithValidationFunction:field.enumDescriptor.enumVerifier];
      break;

    case VPKGPBDataTypeBytes:
    case VPKGPBDataTypeGroup:
    case VPKGPBDataTypeMessage:
    case VPKGPBDataTypeString:
      if (autocreator) {
        result = [[VPKGPBAutocreatedArray alloc] init];
      } else {
        result = [[NSMutableArray alloc] init];
      }
      break;
  }

  if (autocreator) {
    if (VPKGPBDataTypeIsObject(fieldDataType)) {
      VPKGPBAutocreatedArray *autoArray = result;
      autoArray->_autocreator = autocreator;
    } else {
      VPKGPBInt32Array *VPKGPBArray = result;
      VPKGPBArray->_autocreator = autocreator;
    }
  }

  return result;
}

static id CreateMapForField(VPKGPBFieldDescriptor *field, VPKGPBMessage *autocreator) {
  id result;
  VPKGPBDataType keyDataType = field.mapKeyDataType;
  VPKGPBDataType valueDataType = VPKGPBGetFieldDataType(field);
  switch (keyDataType) {
    case VPKGPBDataTypeBool:
      switch (valueDataType) {
        case VPKGPBDataTypeBool:
          result = [[VPKGPBBoolBoolDictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
          result = [[VPKGPBBoolUInt32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeSInt32:
          result = [[VPKGPBBoolInt32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
          result = [[VPKGPBBoolUInt64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeSInt64:
          result = [[VPKGPBBoolInt64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFloat:
          result = [[VPKGPBBoolFloatDictionary alloc] init];
          break;
        case VPKGPBDataTypeDouble:
          result = [[VPKGPBBoolDoubleDictionary alloc] init];
          break;
        case VPKGPBDataTypeEnum:
          result = [[VPKGPBBoolEnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeString:
          result = [[VPKGPBBoolObjectDictionary alloc] init];
          break;
        case VPKGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case VPKGPBDataTypeFixed32:
    case VPKGPBDataTypeUInt32:
      switch (valueDataType) {
        case VPKGPBDataTypeBool:
          result = [[VPKGPBUInt32BoolDictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
          result = [[VPKGPBUInt32UInt32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeSInt32:
          result = [[VPKGPBUInt32Int32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
          result = [[VPKGPBUInt32UInt64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeSInt64:
          result = [[VPKGPBUInt32Int64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFloat:
          result = [[VPKGPBUInt32FloatDictionary alloc] init];
          break;
        case VPKGPBDataTypeDouble:
          result = [[VPKGPBUInt32DoubleDictionary alloc] init];
          break;
        case VPKGPBDataTypeEnum:
          result = [[VPKGPBUInt32EnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeString:
          result = [[VPKGPBUInt32ObjectDictionary alloc] init];
          break;
        case VPKGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case VPKGPBDataTypeInt32:
    case VPKGPBDataTypeSFixed32:
    case VPKGPBDataTypeSInt32:
      switch (valueDataType) {
        case VPKGPBDataTypeBool:
          result = [[VPKGPBInt32BoolDictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
          result = [[VPKGPBInt32UInt32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeSInt32:
          result = [[VPKGPBInt32Int32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
          result = [[VPKGPBInt32UInt64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeSInt64:
          result = [[VPKGPBInt32Int64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFloat:
          result = [[VPKGPBInt32FloatDictionary alloc] init];
          break;
        case VPKGPBDataTypeDouble:
          result = [[VPKGPBInt32DoubleDictionary alloc] init];
          break;
        case VPKGPBDataTypeEnum:
          result = [[VPKGPBInt32EnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeString:
          result = [[VPKGPBInt32ObjectDictionary alloc] init];
          break;
        case VPKGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case VPKGPBDataTypeFixed64:
    case VPKGPBDataTypeUInt64:
      switch (valueDataType) {
        case VPKGPBDataTypeBool:
          result = [[VPKGPBUInt64BoolDictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
          result = [[VPKGPBUInt64UInt32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeSInt32:
          result = [[VPKGPBUInt64Int32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
          result = [[VPKGPBUInt64UInt64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeSInt64:
          result = [[VPKGPBUInt64Int64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFloat:
          result = [[VPKGPBUInt64FloatDictionary alloc] init];
          break;
        case VPKGPBDataTypeDouble:
          result = [[VPKGPBUInt64DoubleDictionary alloc] init];
          break;
        case VPKGPBDataTypeEnum:
          result = [[VPKGPBUInt64EnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeString:
          result = [[VPKGPBUInt64ObjectDictionary alloc] init];
          break;
        case VPKGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case VPKGPBDataTypeInt64:
    case VPKGPBDataTypeSFixed64:
    case VPKGPBDataTypeSInt64:
      switch (valueDataType) {
        case VPKGPBDataTypeBool:
          result = [[VPKGPBInt64BoolDictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
          result = [[VPKGPBInt64UInt32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeSInt32:
          result = [[VPKGPBInt64Int32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
          result = [[VPKGPBInt64UInt64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeSInt64:
          result = [[VPKGPBInt64Int64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFloat:
          result = [[VPKGPBInt64FloatDictionary alloc] init];
          break;
        case VPKGPBDataTypeDouble:
          result = [[VPKGPBInt64DoubleDictionary alloc] init];
          break;
        case VPKGPBDataTypeEnum:
          result = [[VPKGPBInt64EnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeString:
          result = [[VPKGPBInt64ObjectDictionary alloc] init];
          break;
        case VPKGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case VPKGPBDataTypeString:
      switch (valueDataType) {
        case VPKGPBDataTypeBool:
          result = [[VPKGPBStringBoolDictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
          result = [[VPKGPBStringUInt32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeSInt32:
          result = [[VPKGPBStringInt32Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
          result = [[VPKGPBStringUInt64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeSInt64:
          result = [[VPKGPBStringInt64Dictionary alloc] init];
          break;
        case VPKGPBDataTypeFloat:
          result = [[VPKGPBStringFloatDictionary alloc] init];
          break;
        case VPKGPBDataTypeDouble:
          result = [[VPKGPBStringDoubleDictionary alloc] init];
          break;
        case VPKGPBDataTypeEnum:
          result = [[VPKGPBStringEnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeString:
          if (autocreator) {
            result = [[VPKGPBAutocreatedDictionary alloc] init];
          } else {
            result = [[NSMutableDictionary alloc] init];
          }
          break;
        case VPKGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;

    case VPKGPBDataTypeFloat:
    case VPKGPBDataTypeDouble:
    case VPKGPBDataTypeEnum:
    case VPKGPBDataTypeBytes:
    case VPKGPBDataTypeGroup:
    case VPKGPBDataTypeMessage:
      NSCAssert(NO, @"shouldn't happen");
      return nil;
  }

  if (autocreator) {
    if ((keyDataType == VPKGPBDataTypeString) && VPKGPBDataTypeIsObject(valueDataType)) {
      VPKGPBAutocreatedDictionary *autoDict = result;
      autoDict->_autocreator = autocreator;
    } else {
      VPKGPBInt32Int32Dictionary *VPKGPBDict = result;
      VPKGPBDict->_autocreator = autocreator;
    }
  }

  return result;
}

#if !defined(__clang_analyzer__)
// These functions are blocked from the analyzer because the analyzer sees the
// VPKGPBSetRetainedObjectIvarWithFieldPrivate() call as consuming the array/map,
// so use of the array/map after the call returns is flagged as a use after
// free.
// But VPKGPBSetRetainedObjectIvarWithFieldPrivate() is "consuming" the retain
// count be holding onto the object (it is transferring it), the object is
// still valid after returning from the call.  The other way to avoid this
// would be to add a -retain/-autorelease, but that would force every
// repeated/map field parsed into the autorelease pool which is both a memory
// and performance hit.

static id GetOrCreateArrayIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  id array = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
  if (!array) {
    // No lock needed, this is called from places expecting to mutate
    // so no threading protection is needed.
    array = CreateArrayForField(field, nil);
    VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, array);
  }
  return array;
}

// This is like VPKGPBGetObjectIvarWithField(), but for arrays, it should
// only be used to wire the method into the class.
static id GetArrayIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  _Atomic(id) *typePtr = (_Atomic(id) *)&storage[field->description_->offset];
  id array = atomic_load(typePtr);
  if (array) {
    return array;
  }

  id expected = nil;
  id autocreated = CreateArrayForField(field, self);
  if (atomic_compare_exchange_strong(typePtr, &expected, autocreated)) {
    // Value was set, return it.
    return autocreated;
  }

  // Some other thread set it, release the one created and return what got set.
  if (VPKGPBFieldDataTypeIsObject(field)) {
    VPKGPBAutocreatedArray *autoArray = autocreated;
    autoArray->_autocreator = nil;
  } else {
    VPKGPBInt32Array *VPKGPBArray = autocreated;
    VPKGPBArray->_autocreator = nil;
  }
  [autocreated release];
  return expected;
}

static id GetOrCreateMapIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  id dict = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
  if (!dict) {
    // No lock needed, this is called from places expecting to mutate
    // so no threading protection is needed.
    dict = CreateMapForField(field, nil);
    VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, dict);
  }
  return dict;
}

// This is like VPKGPBGetObjectIvarWithField(), but for maps, it should
// only be used to wire the method into the class.
static id GetMapIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  _Atomic(id) *typePtr = (_Atomic(id) *)&storage[field->description_->offset];
  id dict = atomic_load(typePtr);
  if (dict) {
    return dict;
  }

  id expected = nil;
  id autocreated = CreateMapForField(field, self);
  if (atomic_compare_exchange_strong(typePtr, &expected, autocreated)) {
    // Value was set, return it.
    return autocreated;
  }

  // Some other thread set it, release the one created and return what got set.
  if ((field.mapKeyDataType == VPKGPBDataTypeString) && VPKGPBFieldDataTypeIsObject(field)) {
    VPKGPBAutocreatedDictionary *autoDict = autocreated;
    autoDict->_autocreator = nil;
  } else {
    VPKGPBInt32Int32Dictionary *VPKGPBDict = autocreated;
    VPKGPBDict->_autocreator = nil;
  }
  [autocreated release];
  return expected;
}

#endif  // !defined(__clang_analyzer__)

static id NewSingleValueFromInputStream(VPKGPBExtensionDescriptor *extension,
                                        VPKGPBMessage *messageToGetExtension,
                                        VPKGPBCodedInputStream *input,
                                        id<VPKGPBExtensionRegistry> extensionRegistry,
                                        VPKGPBMessage *existingValue)
    __attribute__((ns_returns_retained));

// Note that this returns a retained value intentionally.
static id NewSingleValueFromInputStream(VPKGPBExtensionDescriptor *extension,
                                        VPKGPBMessage *messageToGetExtension,
                                        VPKGPBCodedInputStream *input,
                                        id<VPKGPBExtensionRegistry> extensionRegistry,
                                        VPKGPBMessage *existingValue) {
  VPKGPBExtensionDescription *description = extension->description_;
  VPKGPBCodedInputStreamState *state = &input->state_;
  switch (description->dataType) {
    case VPKGPBDataTypeBool:
      return [[NSNumber alloc] initWithBool:VPKGPBCodedInputStreamReadBool(state)];
    case VPKGPBDataTypeFixed32:
      return [[NSNumber alloc] initWithUnsignedInt:VPKGPBCodedInputStreamReadFixed32(state)];
    case VPKGPBDataTypeSFixed32:
      return [[NSNumber alloc] initWithInt:VPKGPBCodedInputStreamReadSFixed32(state)];
    case VPKGPBDataTypeFloat:
      return [[NSNumber alloc] initWithFloat:VPKGPBCodedInputStreamReadFloat(state)];
    case VPKGPBDataTypeFixed64:
      return [[NSNumber alloc] initWithUnsignedLongLong:VPKGPBCodedInputStreamReadFixed64(state)];
    case VPKGPBDataTypeSFixed64:
      return [[NSNumber alloc] initWithLongLong:VPKGPBCodedInputStreamReadSFixed64(state)];
    case VPKGPBDataTypeDouble:
      return [[NSNumber alloc] initWithDouble:VPKGPBCodedInputStreamReadDouble(state)];
    case VPKGPBDataTypeInt32:
      return [[NSNumber alloc] initWithInt:VPKGPBCodedInputStreamReadInt32(state)];
    case VPKGPBDataTypeInt64:
      return [[NSNumber alloc] initWithLongLong:VPKGPBCodedInputStreamReadInt64(state)];
    case VPKGPBDataTypeSInt32:
      return [[NSNumber alloc] initWithInt:VPKGPBCodedInputStreamReadSInt32(state)];
    case VPKGPBDataTypeSInt64:
      return [[NSNumber alloc] initWithLongLong:VPKGPBCodedInputStreamReadSInt64(state)];
    case VPKGPBDataTypeUInt32:
      return [[NSNumber alloc] initWithUnsignedInt:VPKGPBCodedInputStreamReadUInt32(state)];
    case VPKGPBDataTypeUInt64:
      return [[NSNumber alloc] initWithUnsignedLongLong:VPKGPBCodedInputStreamReadUInt64(state)];
    case VPKGPBDataTypeBytes:
      return VPKGPBCodedInputStreamReadRetainedBytes(state);
    case VPKGPBDataTypeString:
      return VPKGPBCodedInputStreamReadRetainedString(state);
    case VPKGPBDataTypeEnum: {
      int32_t val = VPKGPBCodedInputStreamReadEnum(&input->state_);
      VPKGPBEnumDescriptor *enumDescriptor = extension.enumDescriptor;
      // If run with source generated before the closed enum support, all enums
      // will be considers not closed, so casing to the enum type for a switch
      // could cause things to fall off the end of a switch.
      if (!enumDescriptor.isClosed || enumDescriptor.enumVerifier(val)) {
        return [[NSNumber alloc] initWithInt:val];
      } else {
        VPKGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(messageToGetExtension);
        [unknownFields mergeVarintField:extension->description_->fieldNumber value:val];
        return nil;
      }
    }
    case VPKGPBDataTypeGroup:
    case VPKGPBDataTypeMessage: {
      VPKGPBMessage *message;
      if (existingValue) {
        message = [existingValue retain];
      } else {
        VPKGPBDescriptor *descriptor = [extension.msgClass descriptor];
        message = [[descriptor.messageClass alloc] init];
      }

      if (description->dataType == VPKGPBDataTypeGroup) {
        [input readGroup:description->fieldNumber
                      message:message
            extensionRegistry:extensionRegistry];
      } else {
        // description->dataType == VPKGPBDataTypeMessage
        if (VPKGPBExtensionIsWireFormat(description)) {
          // For MessageSet fields the message length will have already been
          // read.
          [message mergeFromCodedInputStream:input extensionRegistry:extensionRegistry];
        } else {
          [input readMessage:message extensionRegistry:extensionRegistry];
        }
      }

      return message;
    }
  }

  return nil;
}

static void ExtensionMergeFromInputStream(VPKGPBExtensionDescriptor *extension, BOOL isPackedOnStream,
                                          VPKGPBCodedInputStream *input,
                                          id<VPKGPBExtensionRegistry> extensionRegistry,
                                          VPKGPBMessage *message) {
  VPKGPBExtensionDescription *description = extension->description_;
  VPKGPBCodedInputStreamState *state = &input->state_;
  if (isPackedOnStream) {
    NSCAssert(VPKGPBExtensionIsRepeated(description), @"How was it packed if it isn't repeated?");
    int32_t length = VPKGPBCodedInputStreamReadInt32(state);
    size_t limit = VPKGPBCodedInputStreamPushLimit(state, length);
    while (VPKGPBCodedInputStreamBytesUntilLimit(state) > 0) {
      id value = NewSingleValueFromInputStream(extension, message, input, extensionRegistry, nil);
      if (value) {
        [message addExtension:extension value:value];
        [value release];
      }
    }
    VPKGPBCodedInputStreamPopLimit(state, limit);
  } else {
    id existingValue = nil;
    BOOL isRepeated = VPKGPBExtensionIsRepeated(description);
    if (!isRepeated && VPKGPBDataTypeIsMessage(description->dataType)) {
      existingValue = [message getExistingExtension:extension];
    }
    id value =
        NewSingleValueFromInputStream(extension, message, input, extensionRegistry, existingValue);
    if (value) {
      if (isRepeated) {
        [message addExtension:extension value:value];
      } else {
        [message setExtension:extension value:value];
      }
      [value release];
    }
  }
}

VPKGPBMessage *VPKGPBCreateMessageWithAutocreator(Class msgClass, VPKGPBMessage *autocreator,
                                            VPKGPBFieldDescriptor *field) {
  VPKGPBMessage *message = [[msgClass alloc] init];
  message->autocreator_ = autocreator;
  message->autocreatorField_ = [field retain];
  return message;
}

static VPKGPBMessage *CreateMessageWithAutocreatorForExtension(Class msgClass, VPKGPBMessage *autocreator,
                                                            VPKGPBExtensionDescriptor *extension)
    __attribute__((ns_returns_retained));

static VPKGPBMessage *CreateMessageWithAutocreatorForExtension(Class msgClass, VPKGPBMessage *autocreator,
                                                            VPKGPBExtensionDescriptor *extension) {
  VPKGPBMessage *message = [[msgClass alloc] init];
  message->autocreator_ = autocreator;
  message->autocreatorExtension_ = [extension retain];
  return message;
}

BOOL VPKGPBWasMessageAutocreatedBy(VPKGPBMessage *message, VPKGPBMessage *parent) {
  return (message->autocreator_ == parent);
}

void VPKGPBBecomeVisibleToAutocreator(VPKGPBMessage *self) {
  // Message objects that are implicitly created by accessing a message field
  // are initially not visible via the hasX selector. This method makes them
  // visible.
  if (self->autocreator_) {
    // This will recursively make all parent messages visible until it reaches a
    // super-creator that's visible.
    if (self->autocreatorField_) {
      VPKGPBSetObjectIvarWithFieldPrivate(self->autocreator_, self->autocreatorField_, self);
    } else {
      [self->autocreator_ setExtension:self->autocreatorExtension_ value:self];
    }
  }
}

void VPKGPBAutocreatedArrayModified(VPKGPBMessage *self, id array) {
  // When one of our autocreated arrays adds elements, make it visible.
  VPKGPBDescriptor *descriptor = [[self class] descriptor];
  for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
    if (field.fieldType == VPKGPBFieldTypeRepeated) {
      id curArray = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      if (curArray == array) {
        if (VPKGPBFieldDataTypeIsObject(field)) {
          VPKGPBAutocreatedArray *autoArray = array;
          autoArray->_autocreator = nil;
        } else {
          VPKGPBInt32Array *VPKGPBArray = array;
          VPKGPBArray->_autocreator = nil;
        }
        VPKGPBBecomeVisibleToAutocreator(self);
        return;
      }
    }
  }
  NSCAssert(NO, @"Unknown autocreated %@ for %@.", [array class], self);
}

void VPKGPBAutocreatedDictionaryModified(VPKGPBMessage *self, id dictionary) {
  // When one of our autocreated dicts adds elements, make it visible.
  VPKGPBDescriptor *descriptor = [[self class] descriptor];
  for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
    if (field.fieldType == VPKGPBFieldTypeMap) {
      id curDict = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      if (curDict == dictionary) {
        if ((field.mapKeyDataType == VPKGPBDataTypeString) && VPKGPBFieldDataTypeIsObject(field)) {
          VPKGPBAutocreatedDictionary *autoDict = dictionary;
          autoDict->_autocreator = nil;
        } else {
          VPKGPBInt32Int32Dictionary *VPKGPBDict = dictionary;
          VPKGPBDict->_autocreator = nil;
        }
        VPKGPBBecomeVisibleToAutocreator(self);
        return;
      }
    }
  }
  NSCAssert(NO, @"Unknown autocreated %@ for %@.", [dictionary class], self);
}

void VPKGPBClearMessageAutocreator(VPKGPBMessage *self) {
  if ((self == nil) || !self->autocreator_) {
    return;
  }

#if defined(DEBUG) && DEBUG && !defined(NS_BLOCK_ASSERTIONS)
  // Either the autocreator must have its "has" flag set to YES, or it must be
  // NO and not equal to ourselves.
  BOOL autocreatorHas =
      (self->autocreatorField_ ? VPKGPBGetHasIvarField(self->autocreator_, self->autocreatorField_)
                               : [self->autocreator_ hasExtension:self->autocreatorExtension_]);
  VPKGPBMessage *autocreatorFieldValue =
      (self->autocreatorField_
           ? VPKGPBGetObjectIvarWithFieldNoAutocreate(self->autocreator_, self->autocreatorField_)
           : [self->autocreator_->autocreatedExtensionMap_
                 objectForKey:self->autocreatorExtension_]);
  NSCAssert(autocreatorHas || autocreatorFieldValue != self,
            @"Cannot clear autocreator because it still refers to self, self: %@.", self);

#endif  // DEBUG && !defined(NS_BLOCK_ASSERTIONS)

  self->autocreator_ = nil;
  [self->autocreatorField_ release];
  self->autocreatorField_ = nil;
  [self->autocreatorExtension_ release];
  self->autocreatorExtension_ = nil;
}

static VPKGPBUnknownFieldSet *GetOrMakeUnknownFields(VPKGPBMessage *self) {
  if (!self->unknownFields_) {
    self->unknownFields_ = [[VPKGPBUnknownFieldSet alloc] init];
    VPKGPBBecomeVisibleToAutocreator(self);
  }
  return self->unknownFields_;
}

@implementation VPKGPBMessage

+ (void)initialize {
  Class pbMessageClass = [VPKGPBMessage class];
  if ([self class] == pbMessageClass) {
    // This is here to start up the "base" class descriptor.
    [self descriptor];
    // Message shares extension method resolving with VPKGPBRootObject so insure
    // it is started up at the same time.
    (void)[VPKGPBRootObject class];
  } else if ([self superclass] == pbMessageClass) {
    // This is here to start up all the "message" subclasses. Just needs to be
    // done for the messages, not any of the subclasses.
    // This must be done in initialize to enforce thread safety of start up of
    // the protocol buffer library.
    // Note: The generated code for -descriptor calls
    // +[VPKGPBDescriptor allocDescriptorForClass:...], passing the VPKGPBRootObject
    // subclass for the file.  That call chain is what ensures that *Root class
    // is started up to support extension resolution off the message class
    // (+resolveClassMethod: below) in a thread safe manner.
    [self descriptor];
  }
}

+ (instancetype)allocWithZone:(NSZone *)zone {
  // Override alloc to allocate our classes with the additional storage
  // required for the instance variables.
  VPKGPBDescriptor *descriptor = [self descriptor];
  return NSAllocateObject(self, descriptor->storageSize_, zone);
}

+ (instancetype)alloc {
  return [self allocWithZone:nil];
}

+ (VPKGPBDescriptor *)descriptor {
  // This is thread safe because it is called from +initialize.
  static VPKGPBDescriptor *descriptor = NULL;
  static VPKGPBFileDescriptor *fileDescriptor = NULL;
  if (!descriptor) {
    // Use a dummy file that marks it as proto2 syntax so when used generically
    // it supports unknowns/etc.
    fileDescriptor = [[VPKGPBFileDescriptor alloc] initWithPackage:@"internal"
                                                         syntax:VPKGPBFileSyntaxProto2];

    descriptor = [VPKGPBDescriptor allocDescriptorForClass:[VPKGPBMessage class]
                                              rootClass:Nil
                                                   file:fileDescriptor
                                                 fields:NULL
                                             fieldCount:0
                                            storageSize:0
                                                  flags:0];
  }
  return descriptor;
}

+ (instancetype)message {
  return [[[self alloc] init] autorelease];
}

- (instancetype)init {
  if ((self = [super init])) {
    messageStorage_ =
        (VPKGPBMessage_StoragePtr)(((uint8_t *)self) + class_getInstanceSize([self class]));
    readOnlyLock_ = OS_UNFAIR_LOCK_INIT;
  }

  return self;
}

- (instancetype)initWithData:(NSData *)data error:(NSError **)errorPtr {
  return [self initWithData:data extensionRegistry:nil error:errorPtr];
}

- (instancetype)initWithData:(NSData *)data
           extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry
                       error:(NSError **)errorPtr {
  if ((self = [self init])) {
    @try {
      [self mergeFromData:data extensionRegistry:extensionRegistry];
      if (errorPtr) {
        *errorPtr = nil;
      }
    } @catch (NSException *exception) {
      [self release];
      self = nil;
      if (errorPtr) {
        *errorPtr = ErrorFromException(exception);
      }
    }
#ifdef DEBUG
    if (self && !self.initialized) {
      [self release];
      self = nil;
      if (errorPtr) {
        *errorPtr = MessageError(VPKGPBMessageErrorCodeMissingRequiredField, nil);
      }
    }
#endif
  }
  return self;
}

- (instancetype)initWithCodedInputStream:(VPKGPBCodedInputStream *)input
                       extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry
                                   error:(NSError **)errorPtr {
  if ((self = [self init])) {
    @try {
      [self mergeFromCodedInputStream:input extensionRegistry:extensionRegistry];
      if (errorPtr) {
        *errorPtr = nil;
      }
    } @catch (NSException *exception) {
      [self release];
      self = nil;
      if (errorPtr) {
        *errorPtr = ErrorFromException(exception);
      }
    }
#ifdef DEBUG
    if (self && !self.initialized) {
      [self release];
      self = nil;
      if (errorPtr) {
        *errorPtr = MessageError(VPKGPBMessageErrorCodeMissingRequiredField, nil);
      }
    }
#endif
  }
  return self;
}

- (void)dealloc {
  [self internalClear:NO];
  NSCAssert(!autocreator_, @"Autocreator was not cleared before dealloc.");
  [super dealloc];
}

- (void)copyFieldsInto:(VPKGPBMessage *)message
                  zone:(NSZone *)zone
            descriptor:(VPKGPBDescriptor *)descriptor {
  // Copy all the storage...
  memcpy(message->messageStorage_, messageStorage_, descriptor->storageSize_);

  // Loop over the fields doing fixup...
  for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
    if (VPKGPBFieldIsMapOrArray(field)) {
      id value = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      if (value) {
        // We need to copy the array/map, but the catch is for message fields,
        // we also need to ensure all the messages as those need copying also.
        id newValue;
        if (VPKGPBFieldDataTypeIsMessage(field)) {
          if (field.fieldType == VPKGPBFieldTypeRepeated) {
            NSArray *existingArray = (NSArray *)value;
            NSMutableArray *newArray =
                [[NSMutableArray alloc] initWithCapacity:existingArray.count];
            newValue = newArray;
            for (VPKGPBMessage *msg in existingArray) {
              VPKGPBMessage *copiedMsg = [msg copyWithZone:zone];
              [newArray addObject:copiedMsg];
              [copiedMsg release];
            }
          } else {
            if (field.mapKeyDataType == VPKGPBDataTypeString) {
              // Map is an NSDictionary.
              NSDictionary *existingDict = value;
              NSMutableDictionary *newDict =
                  [[NSMutableDictionary alloc] initWithCapacity:existingDict.count];
              newValue = newDict;
              [existingDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, VPKGPBMessage *msg,
                                                                __unused BOOL *stop) {
                VPKGPBMessage *copiedMsg = [msg copyWithZone:zone];
                [newDict setObject:copiedMsg forKey:key];
                [copiedMsg release];
              }];
            } else {
              // Is one of the VPKGPB*ObjectDictionary classes.  Type doesn't
              // matter, just need one to invoke the selector.
              VPKGPBInt32ObjectDictionary *existingDict = value;
              newValue = [existingDict deepCopyWithZone:zone];
            }
          }
        } else {
          // Not messages (but is a map/array)...
          if (field.fieldType == VPKGPBFieldTypeRepeated) {
            if (VPKGPBFieldDataTypeIsObject(field)) {
              // NSArray
              newValue = [value mutableCopyWithZone:zone];
            } else {
              // VPKGPB*Array
              newValue = [value copyWithZone:zone];
            }
          } else {
            if ((field.mapKeyDataType == VPKGPBDataTypeString) && VPKGPBFieldDataTypeIsObject(field)) {
              // NSDictionary
              newValue = [value mutableCopyWithZone:zone];
            } else {
              // Is one of the VPKGPB*Dictionary classes.  Type doesn't matter,
              // just need one to invoke the selector.
              VPKGPBInt32Int32Dictionary *existingDict = value;
              newValue = [existingDict copyWithZone:zone];
            }
          }
        }
        // We retain here because the memcpy picked up the pointer value and
        // the next call to SetRetainedObject... will release the current value.
        [value retain];
        VPKGPBSetRetainedObjectIvarWithFieldPrivate(message, field, newValue);
      }
    } else if (VPKGPBFieldDataTypeIsMessage(field)) {
      // For object types, if we have a value, copy it.  If we don't,
      // zero it to remove the pointer to something that was autocreated
      // (and the ptr just got memcpyed).
      if (VPKGPBGetHasIvarField(self, field)) {
        VPKGPBMessage *value = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        VPKGPBMessage *newValue = [value copyWithZone:zone];
        // We retain here because the memcpy picked up the pointer value and
        // the next call to SetRetainedObject... will release the current value.
        [value retain];
        VPKGPBSetRetainedObjectIvarWithFieldPrivate(message, field, newValue);
      } else {
        uint8_t *storage = (uint8_t *)message->messageStorage_;
        id *typePtr = (id *)&storage[field->description_->offset];
        *typePtr = NULL;
      }
    } else if (VPKGPBFieldDataTypeIsObject(field) && VPKGPBGetHasIvarField(self, field)) {
      // A set string/data value (message picked off above), copy it.
      id value = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      id newValue = [value copyWithZone:zone];
      // We retain here because the memcpy picked up the pointer value and
      // the next call to SetRetainedObject... will release the current value.
      [value retain];
      VPKGPBSetRetainedObjectIvarWithFieldPrivate(message, field, newValue);
    } else {
      // memcpy took care of the rest of the primitive fields if they were set.
    }
  }  // for (field in descriptor->fields_)
}

- (id)copyWithZone:(NSZone *)zone {
  VPKGPBDescriptor *descriptor = [self descriptor];
  VPKGPBMessage *result = [[descriptor.messageClass allocWithZone:zone] init];

  [self copyFieldsInto:result zone:zone descriptor:descriptor];
  // Make immutable copies of the extra bits.
  result->unknownFields_ = [unknownFields_ copyWithZone:zone];
  result->extensionMap_ = CloneExtensionMap(extensionMap_, zone);
  return result;
}

- (void)clear {
  [self internalClear:YES];
}

- (void)internalClear:(BOOL)zeroStorage {
  VPKGPBDescriptor *descriptor = [self descriptor];
  for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
    if (VPKGPBFieldIsMapOrArray(field)) {
      id arrayOrMap = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      if (arrayOrMap) {
        if (field.fieldType == VPKGPBFieldTypeRepeated) {
          if (VPKGPBFieldDataTypeIsObject(field)) {
            if ([arrayOrMap isKindOfClass:[VPKGPBAutocreatedArray class]]) {
              VPKGPBAutocreatedArray *autoArray = arrayOrMap;
              if (autoArray->_autocreator == self) {
                autoArray->_autocreator = nil;
              }
            }
          } else {
            // Type doesn't matter, it is a VPKGPB*Array.
            VPKGPBInt32Array *VPKGPBArray = arrayOrMap;
            if (VPKGPBArray->_autocreator == self) {
              VPKGPBArray->_autocreator = nil;
            }
          }
        } else {
          if ((field.mapKeyDataType == VPKGPBDataTypeString) && VPKGPBFieldDataTypeIsObject(field)) {
            if ([arrayOrMap isKindOfClass:[VPKGPBAutocreatedDictionary class]]) {
              VPKGPBAutocreatedDictionary *autoDict = arrayOrMap;
              if (autoDict->_autocreator == self) {
                autoDict->_autocreator = nil;
              }
            }
          } else {
            // Type doesn't matter, it is a VPKGPB*Dictionary.
            VPKGPBInt32Int32Dictionary *VPKGPBDict = arrayOrMap;
            if (VPKGPBDict->_autocreator == self) {
              VPKGPBDict->_autocreator = nil;
            }
          }
        }
        [arrayOrMap release];
      }
    } else if (VPKGPBFieldDataTypeIsMessage(field)) {
      VPKGPBClearAutocreatedMessageIvarWithField(self, field);
      VPKGPBMessage *value = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      [value release];
    } else if (VPKGPBFieldDataTypeIsObject(field) && VPKGPBGetHasIvarField(self, field)) {
      id value = VPKGPBGetObjectIvarWithField(self, field);
      [value release];
    }
  }

  // VPKGPBClearMessageAutocreator() expects that its caller has already been
  // removed from autocreatedExtensionMap_ so we set to nil first.
  NSArray *autocreatedValues = [autocreatedExtensionMap_ allValues];
  [autocreatedExtensionMap_ release];
  autocreatedExtensionMap_ = nil;

  // Since we're clearing all of our extensions, make sure that we clear the
  // autocreator on any that we've created so they no longer refer to us.
  for (VPKGPBMessage *value in autocreatedValues) {
    NSCAssert(VPKGPBWasMessageAutocreatedBy(value, self),
              @"Autocreated extension does not refer back to self.");
    VPKGPBClearMessageAutocreator(value);
  }

  [extensionMap_ release];
  extensionMap_ = nil;
  [unknownFields_ release];
  unknownFields_ = nil;

  // Note that clearing does not affect autocreator_. If we are being cleared
  // because of a dealloc, then autocreator_ should be nil anyway. If we are
  // being cleared because someone explicitly clears us, we don't want to
  // sever our relationship with our autocreator.

  if (zeroStorage) {
    memset(messageStorage_, 0, descriptor->storageSize_);
  }
}

- (BOOL)isInitialized {
  VPKGPBDescriptor *descriptor = [self descriptor];
  for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
    if (field.isRequired) {
      if (!VPKGPBGetHasIvarField(self, field)) {
        return NO;
      }
    }
    if (VPKGPBFieldDataTypeIsMessage(field)) {
      VPKGPBFieldType fieldType = field.fieldType;
      if (fieldType == VPKGPBFieldTypeSingle) {
        if (field.isRequired) {
          VPKGPBMessage *message = VPKGPBGetMessageMessageField(self, field);
          if (!message.initialized) {
            return NO;
          }
        } else {
          NSAssert(field.isOptional, @"%@: Single message field %@ not required or optional?",
                   [self class], field.name);
          if (VPKGPBGetHasIvarField(self, field)) {
            VPKGPBMessage *message = VPKGPBGetMessageMessageField(self, field);
            if (!message.initialized) {
              return NO;
            }
          }
        }
      } else if (fieldType == VPKGPBFieldTypeRepeated) {
        NSArray *array = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        for (VPKGPBMessage *message in array) {
          if (!message.initialized) {
            return NO;
          }
        }
      } else {  // fieldType == VPKGPBFieldTypeMap
        if (field.mapKeyDataType == VPKGPBDataTypeString) {
          NSDictionary *map = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
          if (map && !VPKGPBDictionaryIsInitializedInternalHelper(map, field)) {
            return NO;
          }
        } else {
          // Real type is VPKGPB*ObjectDictionary, exact type doesn't matter.
          VPKGPBInt32ObjectDictionary *map = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
          if (map && ![map isInitialized]) {
            return NO;
          }
        }
      }
    }
  }

  __block BOOL result = YES;
  [extensionMap_
      enumerateKeysAndObjectsUsingBlock:^(VPKGPBExtensionDescriptor *extension, id obj, BOOL *stop) {
        if (VPKGPBExtensionIsMessage(extension)) {
          if (extension.isRepeated) {
            for (VPKGPBMessage *msg in obj) {
              if (!msg.initialized) {
                result = NO;
                *stop = YES;
                break;
              }
            }
          } else {
            VPKGPBMessage *asMsg = obj;
            if (!asMsg.initialized) {
              result = NO;
              *stop = YES;
            }
          }
        }
      }];
  return result;
}

- (VPKGPBDescriptor *)descriptor {
  return [[self class] descriptor];
}

- (NSData *)data {
#ifdef DEBUG
  if (!self.initialized) {
    return nil;
  }
#endif
  NSMutableData *data = [NSMutableData dataWithLength:[self serializedSize]];
  VPKGPBCodedOutputStream *stream = [[VPKGPBCodedOutputStream alloc] initWithData:data];
  @try {
    [self writeToCodedOutputStream:stream];
  } @catch (NSException *exception) {
    // This really shouldn't happen. The only way writeToCodedOutputStream:
    // could throw is if something in the library has a bug and the
    // serializedSize was wrong.
#ifdef DEBUG
    NSLog(@"%@: Internal exception while building message data: %@", [self class], exception);
#endif
    data = nil;
  }
  [stream release];
  return data;
}

- (NSData *)delimitedData {
  size_t serializedSize = [self serializedSize];
  size_t varintSize = VPKGPBComputeRawVarint32SizeForInteger(serializedSize);
  NSMutableData *data = [NSMutableData dataWithLength:(serializedSize + varintSize)];
  VPKGPBCodedOutputStream *stream = [[VPKGPBCodedOutputStream alloc] initWithData:data];
  @try {
    [self writeDelimitedToCodedOutputStream:stream];
  } @catch (NSException *exception) {
    // This really shouldn't happen.  The only way writeToCodedOutputStream:
    // could throw is if something in the library has a bug and the
    // serializedSize was wrong.
#ifdef DEBUG
    NSLog(@"%@: Internal exception while building message delimitedData: %@", [self class],
          exception);
#endif
    // If it happens, truncate.
    data.length = 0;
  }
  [stream release];
  return data;
}

- (void)writeToOutputStream:(NSOutputStream *)output {
  VPKGPBCodedOutputStream *stream = [[VPKGPBCodedOutputStream alloc] initWithOutputStream:output];
  [self writeToCodedOutputStream:stream];
  [stream release];
}

- (void)writeToCodedOutputStream:(VPKGPBCodedOutputStream *)output {
  VPKGPBDescriptor *descriptor = [self descriptor];
  NSArray *fieldsArray = descriptor->fields_;
  NSUInteger fieldCount = fieldsArray.count;
  const VPKGPBExtensionRange *extensionRanges = descriptor.extensionRanges;
  NSUInteger extensionRangesCount = descriptor.extensionRangesCount;
  NSArray *sortedExtensions =
      [[extensionMap_ allKeys] sortedArrayUsingSelector:@selector(compareByFieldNumber:)];
  for (NSUInteger i = 0, j = 0; i < fieldCount || j < extensionRangesCount;) {
    if (i == fieldCount) {
      [self writeExtensionsToCodedOutputStream:output
                                         range:extensionRanges[j++]
                              sortedExtensions:sortedExtensions];
    } else if (j == extensionRangesCount ||
               VPKGPBFieldNumber(fieldsArray[i]) < extensionRanges[j].start) {
      [self writeField:fieldsArray[i++] toCodedOutputStream:output];
    } else {
      [self writeExtensionsToCodedOutputStream:output
                                         range:extensionRanges[j++]
                              sortedExtensions:sortedExtensions];
    }
  }
  if (descriptor.isWireFormat) {
    [unknownFields_ writeAsMessageSetTo:output];
  } else {
    [unknownFields_ writeToCodedOutputStream:output];
  }
}

- (void)writeDelimitedToOutputStream:(NSOutputStream *)output {
  VPKGPBCodedOutputStream *codedOutput = [[VPKGPBCodedOutputStream alloc] initWithOutputStream:output];
  [self writeDelimitedToCodedOutputStream:codedOutput];
  [codedOutput release];
}

- (void)writeDelimitedToCodedOutputStream:(VPKGPBCodedOutputStream *)output {
  [output writeRawVarintSizeTAs32:[self serializedSize]];
  [self writeToCodedOutputStream:output];
}

- (void)writeField:(VPKGPBFieldDescriptor *)field toCodedOutputStream:(VPKGPBCodedOutputStream *)output {
  VPKGPBFieldType fieldType = field.fieldType;
  if (fieldType == VPKGPBFieldTypeSingle) {
    BOOL has = VPKGPBGetHasIvarField(self, field);
    if (!has) {
      return;
    }
  }
  uint32_t fieldNumber = VPKGPBFieldNumber(field);

  switch (VPKGPBGetFieldDataType(field)) {
      // clang-format off

//%PDDM-DEFINE FIELD_CASE(TYPE, REAL_TYPE)
//%FIELD_CASE_FULL(TYPE, REAL_TYPE, REAL_TYPE)
//%PDDM-DEFINE FIELD_CASE_FULL(TYPE, REAL_TYPE, ARRAY_TYPE)
//%    case VPKGPBDataType##TYPE:
//%      if (fieldType == VPKGPBFieldTypeRepeated) {
//%        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
//%        VPKGPB##ARRAY_TYPE##Array *array =
//%            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
//%        [output write##TYPE##Array:fieldNumber values:array tag:tag];
//%      } else if (fieldType == VPKGPBFieldTypeSingle) {
//%        [output write##TYPE:fieldNumber
//%              TYPE$S  value:VPKGPBGetMessage##REAL_TYPE##Field(self, field)];
//%      } else {  // fieldType == VPKGPBFieldTypeMap
//%        // Exact type here doesn't matter.
//%        VPKGPBInt32##ARRAY_TYPE##Dictionary *dict =
//%            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
//%        [dict writeToCodedOutputStream:output asField:field];
//%      }
//%      break;
//%
//%PDDM-DEFINE FIELD_CASE2(TYPE)
//%    case VPKGPBDataType##TYPE:
//%      if (fieldType == VPKGPBFieldTypeRepeated) {
//%        NSArray *array = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
//%        [output write##TYPE##Array:fieldNumber values:array];
//%      } else if (fieldType == VPKGPBFieldTypeSingle) {
//%        // VPKGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
//%        // again.
//%        [output write##TYPE:fieldNumber
//%              TYPE$S  value:VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
//%      } else {  // fieldType == VPKGPBFieldTypeMap
//%        // Exact type here doesn't matter.
//%        id dict = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
//%        VPKGPBDataType mapKeyDataType = field.mapKeyDataType;
//%        if (mapKeyDataType == VPKGPBDataTypeString) {
//%          VPKGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
//%        } else {
//%          [dict writeToCodedOutputStream:output asField:field];
//%        }
//%      }
//%      break;
//%
//%PDDM-EXPAND FIELD_CASE(Bool, Bool)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeBool:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBBoolArray *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeBoolArray:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeBool:fieldNumber
                    value:VPKGPBGetMessageBoolField(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32BoolDictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(Fixed32, UInt32)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeFixed32:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBUInt32Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeFixed32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeFixed32:fieldNumber
                       value:VPKGPBGetMessageUInt32Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32UInt32Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(SFixed32, Int32)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeSFixed32:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBInt32Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeSFixed32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeSFixed32:fieldNumber
                        value:VPKGPBGetMessageInt32Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32Int32Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(Float, Float)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeFloat:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBFloatArray *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeFloatArray:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeFloat:fieldNumber
                     value:VPKGPBGetMessageFloatField(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32FloatDictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(Fixed64, UInt64)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeFixed64:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBUInt64Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeFixed64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeFixed64:fieldNumber
                       value:VPKGPBGetMessageUInt64Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32UInt64Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(SFixed64, Int64)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeSFixed64:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBInt64Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeSFixed64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeSFixed64:fieldNumber
                        value:VPKGPBGetMessageInt64Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32Int64Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(Double, Double)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeDouble:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBDoubleArray *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeDoubleArray:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeDouble:fieldNumber
                      value:VPKGPBGetMessageDoubleField(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32DoubleDictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(Int32, Int32)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeInt32:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBInt32Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeInt32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeInt32:fieldNumber
                     value:VPKGPBGetMessageInt32Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32Int32Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(Int64, Int64)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeInt64:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBInt64Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeInt64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeInt64:fieldNumber
                     value:VPKGPBGetMessageInt64Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32Int64Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(SInt32, Int32)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeSInt32:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBInt32Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeSInt32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeSInt32:fieldNumber
                      value:VPKGPBGetMessageInt32Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32Int32Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(SInt64, Int64)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeSInt64:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBInt64Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeSInt64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeSInt64:fieldNumber
                      value:VPKGPBGetMessageInt64Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32Int64Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(UInt32, UInt32)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeUInt32:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBUInt32Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeUInt32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeUInt32:fieldNumber
                      value:VPKGPBGetMessageUInt32Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32UInt32Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE(UInt64, UInt64)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeUInt64:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBUInt64Array *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeUInt64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeUInt64:fieldNumber
                      value:VPKGPBGetMessageUInt64Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32UInt64Dictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE_FULL(Enum, Int32, Enum)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeEnum:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? VPKGPBFieldTag(field) : 0;
        VPKGPBEnumArray *array =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeEnumArray:fieldNumber values:array tag:tag];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        [output writeEnum:fieldNumber
                    value:VPKGPBGetMessageInt32Field(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        VPKGPBInt32EnumDictionary *dict =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

//%PDDM-EXPAND FIELD_CASE2(Bytes)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeBytes:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        NSArray *array = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeBytesArray:fieldNumber values:array];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        // VPKGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
        // again.
        [output writeBytes:fieldNumber
                     value:VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        id dict = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        VPKGPBDataType mapKeyDataType = field.mapKeyDataType;
        if (mapKeyDataType == VPKGPBDataTypeString) {
          VPKGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
        } else {
          [dict writeToCodedOutputStream:output asField:field];
        }
      }
      break;

//%PDDM-EXPAND FIELD_CASE2(String)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeString:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        NSArray *array = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeStringArray:fieldNumber values:array];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        // VPKGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
        // again.
        [output writeString:fieldNumber
                      value:VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        id dict = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        VPKGPBDataType mapKeyDataType = field.mapKeyDataType;
        if (mapKeyDataType == VPKGPBDataTypeString) {
          VPKGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
        } else {
          [dict writeToCodedOutputStream:output asField:field];
        }
      }
      break;

//%PDDM-EXPAND FIELD_CASE2(Message)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeMessage:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        NSArray *array = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeMessageArray:fieldNumber values:array];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        // VPKGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
        // again.
        [output writeMessage:fieldNumber
                       value:VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        id dict = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        VPKGPBDataType mapKeyDataType = field.mapKeyDataType;
        if (mapKeyDataType == VPKGPBDataTypeString) {
          VPKGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
        } else {
          [dict writeToCodedOutputStream:output asField:field];
        }
      }
      break;

//%PDDM-EXPAND FIELD_CASE2(Group)
// This block of code is generated, do not edit it directly.

    case VPKGPBDataTypeGroup:
      if (fieldType == VPKGPBFieldTypeRepeated) {
        NSArray *array = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeGroupArray:fieldNumber values:array];
      } else if (fieldType == VPKGPBFieldTypeSingle) {
        // VPKGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
        // again.
        [output writeGroup:fieldNumber
                     value:VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
      } else {  // fieldType == VPKGPBFieldTypeMap
        // Exact type here doesn't matter.
        id dict = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        VPKGPBDataType mapKeyDataType = field.mapKeyDataType;
        if (mapKeyDataType == VPKGPBDataTypeString) {
          VPKGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
        } else {
          [dict writeToCodedOutputStream:output asField:field];
        }
      }
      break;

//%PDDM-EXPAND-END (18 expansions)

// clang-format off
  }
}

#pragma mark - Extensions

- (id)getExtension:(VPKGPBExtensionDescriptor *)extension {
  CheckExtension(self, extension);
  id value = [extensionMap_ objectForKey:extension];
  if (value != nil) {
    return value;
  }

  // No default for repeated.
  if (extension.isRepeated) {
    return nil;
  }
  // Non messages get their default.
  if (!VPKGPBExtensionIsMessage(extension)) {
    return extension.defaultValue;
  }

  // Check for an autocreated value.
  os_unfair_lock_lock(&readOnlyLock_);
  value = [autocreatedExtensionMap_ objectForKey:extension];
  if (!value) {
    // Auto create the message extensions to match normal fields.
    value = CreateMessageWithAutocreatorForExtension(extension.msgClass, self,
                                                     extension);

    if (autocreatedExtensionMap_ == nil) {
      autocreatedExtensionMap_ = [[NSMutableDictionary alloc] init];
    }

    // We can't simply call setExtension here because that would clear the new
    // value's autocreator.
    [autocreatedExtensionMap_ setObject:value forKey:extension];
    [value release];
  }

  os_unfair_lock_unlock(&readOnlyLock_);
  return value;
}

- (id)getExistingExtension:(VPKGPBExtensionDescriptor *)extension {
  // This is an internal method so we don't need to call CheckExtension().
  return [extensionMap_ objectForKey:extension];
}

- (BOOL)hasExtension:(VPKGPBExtensionDescriptor *)extension {
#if defined(DEBUG) && DEBUG
  CheckExtension(self, extension);
#endif  // DEBUG
  return nil != [extensionMap_ objectForKey:extension];
}

- (NSArray *)extensionsCurrentlySet {
  return [extensionMap_ allKeys];
}

- (void)writeExtensionsToCodedOutputStream:(VPKGPBCodedOutputStream *)output
                                     range:(VPKGPBExtensionRange)range
                          sortedExtensions:(NSArray *)sortedExtensions {
  uint32_t start = range.start;
  uint32_t end = range.end;
  for (VPKGPBExtensionDescriptor *extension in sortedExtensions) {
    uint32_t fieldNumber = extension.fieldNumber;
    if (fieldNumber < start) {
      continue;
    }
    if (fieldNumber >= end) {
      break;
    }
    id value = [extensionMap_ objectForKey:extension];
    VPKGPBWriteExtensionValueToOutputStream(extension, value, output);
  }
}

- (void)setExtension:(VPKGPBExtensionDescriptor *)extension value:(id)value {
  if (!value) {
    [self clearExtension:extension];
    return;
  }

  CheckExtension(self, extension);

  if (extension.repeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"Must call addExtension() for repeated types."];
  }

  if (extensionMap_ == nil) {
    extensionMap_ = [[NSMutableDictionary alloc] init];
  }

  // This pointless cast is for CLANG_WARN_NULLABLE_TO_NONNULL_CONVERSION.
  // Without it, the compiler complains we're passing an id nullable when
  // setObject:forKey: requires a id nonnull for the value. The check for
  // !value at the start of the method ensures it isn't nil, but the check
  // isn't smart enough to realize that.
  [extensionMap_ setObject:(id)value forKey:extension];

  VPKGPBExtensionDescriptor *descriptor = extension;

  if (VPKGPBExtensionIsMessage(descriptor) && !descriptor.isRepeated) {
    VPKGPBMessage *autocreatedValue =
        [[autocreatedExtensionMap_ objectForKey:extension] retain];
    // Must remove from the map before calling VPKGPBClearMessageAutocreator() so
    // that VPKGPBClearMessageAutocreator() knows its safe to clear.
    [autocreatedExtensionMap_ removeObjectForKey:extension];
    VPKGPBClearMessageAutocreator(autocreatedValue);
    [autocreatedValue release];
  }

  VPKGPBBecomeVisibleToAutocreator(self);
}

- (void)addExtension:(VPKGPBExtensionDescriptor *)extension value:(id)value {
  CheckExtension(self, extension);

  if (!extension.repeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"Must call setExtension() for singular types."];
  }

  if (extensionMap_ == nil) {
    extensionMap_ = [[NSMutableDictionary alloc] init];
  }
  NSMutableArray *list = [extensionMap_ objectForKey:extension];
  if (list == nil) {
    list = [NSMutableArray array];
    [extensionMap_ setObject:list forKey:extension];
  }

  [list addObject:value];
  VPKGPBBecomeVisibleToAutocreator(self);
}

- (void)setExtension:(VPKGPBExtensionDescriptor *)extension
               index:(NSUInteger)idx
               value:(id)value {
  CheckExtension(self, extension);

  if (!extension.repeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"Must call setExtension() for singular types."];
  }

  if (extensionMap_ == nil) {
    extensionMap_ = [[NSMutableDictionary alloc] init];
  }

  NSMutableArray *list = [extensionMap_ objectForKey:extension];

  [list replaceObjectAtIndex:idx withObject:value];
  VPKGPBBecomeVisibleToAutocreator(self);
}

- (void)clearExtension:(VPKGPBExtensionDescriptor *)extension {
  CheckExtension(self, extension);

  // Only become visible if there was actually a value to clear.
  if ([extensionMap_ objectForKey:extension]) {
    [extensionMap_ removeObjectForKey:extension];
    VPKGPBBecomeVisibleToAutocreator(self);
  }
}

#pragma mark - mergeFrom

- (void)mergeFromData:(NSData *)data
    extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry {
  VPKGPBCodedInputStream *input = [[VPKGPBCodedInputStream alloc] initWithData:data];
  [self mergeFromCodedInputStream:input extensionRegistry:extensionRegistry];
  [input checkLastTagWas:0];
  [input release];
}

#pragma mark - mergeDelimitedFrom

- (void)mergeDelimitedFromCodedInputStream:(VPKGPBCodedInputStream *)input
                         extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry {
  VPKGPBCodedInputStreamState *state = &input->state_;
  if (VPKGPBCodedInputStreamIsAtEnd(state)) {
    return;
  }
  NSData *data = VPKGPBCodedInputStreamReadRetainedBytesNoCopy(state);
  if (data == nil) {
    return;
  }
  [self mergeFromData:data extensionRegistry:extensionRegistry];
  [data release];
}

#pragma mark - Parse From Data Support

+ (instancetype)parseFromData:(NSData *)data error:(NSError **)errorPtr {
  return [self parseFromData:data extensionRegistry:nil error:errorPtr];
}

+ (instancetype)parseFromData:(NSData *)data
            extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry
                        error:(NSError **)errorPtr {
  return [[[self alloc] initWithData:data
                   extensionRegistry:extensionRegistry
                               error:errorPtr] autorelease];
}

+ (instancetype)parseFromCodedInputStream:(VPKGPBCodedInputStream *)input
                        extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry
                                    error:(NSError **)errorPtr {
  return
      [[[self alloc] initWithCodedInputStream:input
                            extensionRegistry:extensionRegistry
                                        error:errorPtr] autorelease];
}

#pragma mark - Parse Delimited From Data Support

+ (instancetype)parseDelimitedFromCodedInputStream:(VPKGPBCodedInputStream *)input
                                 extensionRegistry:
                                     (id<VPKGPBExtensionRegistry>)extensionRegistry
                                             error:(NSError **)errorPtr {
  VPKGPBMessage *message = [[[self alloc] init] autorelease];
  @try {
    [message mergeDelimitedFromCodedInputStream:input
                              extensionRegistry:extensionRegistry];
    if (errorPtr) {
      *errorPtr = nil;
    }
  }
  @catch (NSException *exception) {
    message = nil;
    if (errorPtr) {
      *errorPtr = ErrorFromException(exception);
    }
  }
#ifdef DEBUG
  if (message && !message.initialized) {
    message = nil;
    if (errorPtr) {
      *errorPtr = MessageError(VPKGPBMessageErrorCodeMissingRequiredField, nil);
    }
  }
#endif
  return message;
}

#pragma mark - Unknown Field Support

- (VPKGPBUnknownFieldSet *)unknownFields {
  return unknownFields_;
}

- (void)setUnknownFields:(VPKGPBUnknownFieldSet *)unknownFields {
  if (unknownFields != unknownFields_) {
    [unknownFields_ release];
    unknownFields_ = [unknownFields copy];
    VPKGPBBecomeVisibleToAutocreator(self);
  }
}

- (void)parseMessageSet:(VPKGPBCodedInputStream *)input
      extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry {
  uint32_t typeId = 0;
  NSData *rawBytes = nil;
  VPKGPBExtensionDescriptor *extension = nil;
  VPKGPBCodedInputStreamState *state = &input->state_;
  while (true) {
    uint32_t tag = VPKGPBCodedInputStreamReadTag(state);
    if (tag == 0) {
      break;
    }

    if (tag == VPKGPBWireFormatMessageSetTypeIdTag) {
      typeId = VPKGPBCodedInputStreamReadUInt32(state);
      if (typeId != 0) {
        extension = [extensionRegistry extensionForDescriptor:[self descriptor]
                                                  fieldNumber:typeId];
      }
    } else if (tag == VPKGPBWireFormatMessageSetMessageTag) {
      rawBytes =
          [VPKGPBCodedInputStreamReadRetainedBytesNoCopy(state) autorelease];
    } else {
      if (![input skipField:tag]) {
        break;
      }
    }
  }

  [input checkLastTagWas:VPKGPBWireFormatMessageSetItemEndTag];

  if (rawBytes != nil && typeId != 0) {
    if (extension != nil) {
      VPKGPBCodedInputStream *newInput =
          [[VPKGPBCodedInputStream alloc] initWithData:rawBytes];
      ExtensionMergeFromInputStream(extension,
                                    extension.packable,
                                    newInput,
                                    extensionRegistry,
                                    self);
      [newInput release];
    } else {
      VPKGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
      // rawBytes was created via a NoCopy, so it can be reusing a
      // subrange of another NSData that might go out of scope as things
      // unwind, so a copy is needed to ensure what is saved in the
      // unknown fields stays valid.
      NSData *cloned = [NSData dataWithData:rawBytes];
      [unknownFields mergeMessageSetMessage:typeId data:cloned];
    }
  }
}

- (BOOL)parseUnknownField:(VPKGPBCodedInputStream *)input
        extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry
                      tag:(uint32_t)tag {
  VPKGPBWireFormat wireType = VPKGPBWireFormatGetTagWireType(tag);
  int32_t fieldNumber = VPKGPBWireFormatGetTagFieldNumber(tag);

  VPKGPBDescriptor *descriptor = [self descriptor];
  VPKGPBExtensionDescriptor *extension =
      [extensionRegistry extensionForDescriptor:descriptor
                                    fieldNumber:fieldNumber];
  if (extension == nil) {
    if (descriptor.wireFormat && VPKGPBWireFormatMessageSetItemTag == tag) {
      [self parseMessageSet:input extensionRegistry:extensionRegistry];
      return YES;
    }
  } else {
    if (extension.wireType == wireType) {
      ExtensionMergeFromInputStream(extension,
                                    extension.packable,
                                    input,
                                    extensionRegistry,
                                    self);
      return YES;
    }
    // Primitive, repeated types can be packed on unpacked on the wire, and are
    // parsed either way.
    if ([extension isRepeated] &&
        !VPKGPBDataTypeIsObject(extension->description_->dataType) &&
        (extension.alternateWireType == wireType)) {
      ExtensionMergeFromInputStream(extension,
                                    !extension.packable,
                                    input,
                                    extensionRegistry,
                                    self);
      return YES;
    }
  }
  if ([VPKGPBUnknownFieldSet isFieldTag:tag]) {
    VPKGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
    return [unknownFields mergeFieldFrom:tag input:input];
  } else {
    return NO;
  }
}

- (void)addUnknownMapEntry:(int32_t)fieldNum value:(NSData *)data {
  VPKGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
  [unknownFields addUnknownMapEntry:fieldNum value:data];
}

#pragma mark - MergeFromCodedInputStream Support

static void MergeSingleFieldFromCodedInputStream(
    VPKGPBMessage *self, VPKGPBFieldDescriptor *field,
    VPKGPBCodedInputStream *input, id<VPKGPBExtensionRegistry>extensionRegistry) {
  VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
  switch (fieldDataType) {
#define CASE_SINGLE_POD(NAME, TYPE, FUNC_TYPE)                             \
    case VPKGPBDataType##NAME: {                                              \
      TYPE val = VPKGPBCodedInputStreamRead##NAME(&input->state_);            \
      VPKGPBSet##FUNC_TYPE##IvarWithFieldPrivate(self, field, val);           \
      break;                                                               \
            }
#define CASE_SINGLE_OBJECT(NAME)                                           \
    case VPKGPBDataType##NAME: {                                              \
      id val = VPKGPBCodedInputStreamReadRetained##NAME(&input->state_);      \
      VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, val);          \
      break;                                                               \
    }
      CASE_SINGLE_POD(Bool, BOOL, Bool)
      CASE_SINGLE_POD(Fixed32, uint32_t, UInt32)
      CASE_SINGLE_POD(SFixed32, int32_t, Int32)
      CASE_SINGLE_POD(Float, float, Float)
      CASE_SINGLE_POD(Fixed64, uint64_t, UInt64)
      CASE_SINGLE_POD(SFixed64, int64_t, Int64)
      CASE_SINGLE_POD(Double, double, Double)
      CASE_SINGLE_POD(Int32, int32_t, Int32)
      CASE_SINGLE_POD(Int64, int64_t, Int64)
      CASE_SINGLE_POD(SInt32, int32_t, Int32)
      CASE_SINGLE_POD(SInt64, int64_t, Int64)
      CASE_SINGLE_POD(UInt32, uint32_t, UInt32)
      CASE_SINGLE_POD(UInt64, uint64_t, UInt64)
      CASE_SINGLE_OBJECT(Bytes)
      CASE_SINGLE_OBJECT(String)
#undef CASE_SINGLE_POD
#undef CASE_SINGLE_OBJECT

    case VPKGPBDataTypeMessage: {
      if (VPKGPBGetHasIvarField(self, field)) {
        // VPKGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has
        // check again.
        VPKGPBMessage *message =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [input readMessage:message extensionRegistry:extensionRegistry];
      } else {
        VPKGPBMessage *message = [[field.msgClass alloc] init];
        [input readMessage:message extensionRegistry:extensionRegistry];
        VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, message);
      }
      break;
    }

    case VPKGPBDataTypeGroup: {
      if (VPKGPBGetHasIvarField(self, field)) {
        // VPKGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has
        // check again.
        VPKGPBMessage *message =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [input readGroup:VPKGPBFieldNumber(field)
                      message:message
            extensionRegistry:extensionRegistry];
      } else {
        VPKGPBMessage *message = [[field.msgClass alloc] init];
        [input readGroup:VPKGPBFieldNumber(field)
                      message:message
            extensionRegistry:extensionRegistry];
        VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, message);
      }
      break;
    }

    case VPKGPBDataTypeEnum: {
      int32_t val = VPKGPBCodedInputStreamReadEnum(&input->state_);
      if (!VPKGPBFieldIsClosedEnum(field) || [field isValidEnumValue:val]) {
        VPKGPBSetInt32IvarWithFieldPrivate(self, field, val);
      } else {
        VPKGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
        [unknownFields mergeVarintField:VPKGPBFieldNumber(field) value:val];
      }
    }
  }  // switch
}

static void MergeRepeatedPackedFieldFromCodedInputStream(
    VPKGPBMessage *self, VPKGPBFieldDescriptor *field,
    VPKGPBCodedInputStream *input) {
  VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
  VPKGPBCodedInputStreamState *state = &input->state_;
  id genericArray = GetOrCreateArrayIvarWithField(self, field);
  int32_t length = VPKGPBCodedInputStreamReadInt32(state);
  size_t limit = VPKGPBCodedInputStreamPushLimit(state, length);
  while (VPKGPBCodedInputStreamBytesUntilLimit(state) > 0) {
    switch (fieldDataType) {
#define CASE_REPEATED_PACKED_POD(NAME, TYPE, ARRAY_TYPE)      \
     case VPKGPBDataType##NAME: {                                \
       TYPE val = VPKGPBCodedInputStreamRead##NAME(state);       \
       [(VPKGPB##ARRAY_TYPE##Array *)genericArray addValue:val]; \
       break;                                                 \
     }
        CASE_REPEATED_PACKED_POD(Bool, BOOL, Bool)
        CASE_REPEATED_PACKED_POD(Fixed32, uint32_t, UInt32)
        CASE_REPEATED_PACKED_POD(SFixed32, int32_t, Int32)
        CASE_REPEATED_PACKED_POD(Float, float, Float)
        CASE_REPEATED_PACKED_POD(Fixed64, uint64_t, UInt64)
        CASE_REPEATED_PACKED_POD(SFixed64, int64_t, Int64)
        CASE_REPEATED_PACKED_POD(Double, double, Double)
        CASE_REPEATED_PACKED_POD(Int32, int32_t, Int32)
        CASE_REPEATED_PACKED_POD(Int64, int64_t, Int64)
        CASE_REPEATED_PACKED_POD(SInt32, int32_t, Int32)
        CASE_REPEATED_PACKED_POD(SInt64, int64_t, Int64)
        CASE_REPEATED_PACKED_POD(UInt32, uint32_t, UInt32)
        CASE_REPEATED_PACKED_POD(UInt64, uint64_t, UInt64)
#undef CASE_REPEATED_PACKED_POD

      case VPKGPBDataTypeBytes:
      case VPKGPBDataTypeString:
      case VPKGPBDataTypeMessage:
      case VPKGPBDataTypeGroup:
        NSCAssert(NO, @"Non primitive types can't be packed");
        break;

      case VPKGPBDataTypeEnum: {
        int32_t val = VPKGPBCodedInputStreamReadEnum(state);
        if (!VPKGPBFieldIsClosedEnum(field) || [field isValidEnumValue:val]) {
          [(VPKGPBEnumArray*)genericArray addRawValue:val];
        } else {
          VPKGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
          [unknownFields mergeVarintField:VPKGPBFieldNumber(field) value:val];
        }
        break;
      }
    }  // switch
  }  // while(BytesUntilLimit() > 0)
  VPKGPBCodedInputStreamPopLimit(state, limit);
}

static void MergeRepeatedNotPackedFieldFromCodedInputStream(
    VPKGPBMessage *self, VPKGPBFieldDescriptor *field,
    VPKGPBCodedInputStream *input, id<VPKGPBExtensionRegistry>extensionRegistry) {
  VPKGPBCodedInputStreamState *state = &input->state_;
  id genericArray = GetOrCreateArrayIvarWithField(self, field);
  switch (VPKGPBGetFieldDataType(field)) {
#define CASE_REPEATED_NOT_PACKED_POD(NAME, TYPE, ARRAY_TYPE) \
   case VPKGPBDataType##NAME: {                                 \
     TYPE val = VPKGPBCodedInputStreamRead##NAME(state);        \
     [(VPKGPB##ARRAY_TYPE##Array *)genericArray addValue:val];  \
     break;                                                  \
   }
#define CASE_REPEATED_NOT_PACKED_OBJECT(NAME)                \
   case VPKGPBDataType##NAME: {                                 \
     id val = VPKGPBCodedInputStreamReadRetained##NAME(state);  \
     [(NSMutableArray*)genericArray addObject:val];          \
     [val release];                                          \
     break;                                                  \
   }
      CASE_REPEATED_NOT_PACKED_POD(Bool, BOOL, Bool)
      CASE_REPEATED_NOT_PACKED_POD(Fixed32, uint32_t, UInt32)
      CASE_REPEATED_NOT_PACKED_POD(SFixed32, int32_t, Int32)
      CASE_REPEATED_NOT_PACKED_POD(Float, float, Float)
      CASE_REPEATED_NOT_PACKED_POD(Fixed64, uint64_t, UInt64)
      CASE_REPEATED_NOT_PACKED_POD(SFixed64, int64_t, Int64)
      CASE_REPEATED_NOT_PACKED_POD(Double, double, Double)
      CASE_REPEATED_NOT_PACKED_POD(Int32, int32_t, Int32)
      CASE_REPEATED_NOT_PACKED_POD(Int64, int64_t, Int64)
      CASE_REPEATED_NOT_PACKED_POD(SInt32, int32_t, Int32)
      CASE_REPEATED_NOT_PACKED_POD(SInt64, int64_t, Int64)
      CASE_REPEATED_NOT_PACKED_POD(UInt32, uint32_t, UInt32)
      CASE_REPEATED_NOT_PACKED_POD(UInt64, uint64_t, UInt64)
      CASE_REPEATED_NOT_PACKED_OBJECT(Bytes)
      CASE_REPEATED_NOT_PACKED_OBJECT(String)
#undef CASE_REPEATED_NOT_PACKED_POD
#undef CASE_NOT_PACKED_OBJECT
    case VPKGPBDataTypeMessage: {
      VPKGPBMessage *message = [[field.msgClass alloc] init];
      [input readMessage:message extensionRegistry:extensionRegistry];
      [(NSMutableArray*)genericArray addObject:message];
      [message release];
      break;
    }
    case VPKGPBDataTypeGroup: {
      VPKGPBMessage *message = [[field.msgClass alloc] init];
      [input readGroup:VPKGPBFieldNumber(field)
                    message:message
          extensionRegistry:extensionRegistry];
      [(NSMutableArray*)genericArray addObject:message];
      [message release];
      break;
    }
    case VPKGPBDataTypeEnum: {
      int32_t val = VPKGPBCodedInputStreamReadEnum(state);
      if (!VPKGPBFieldIsClosedEnum(field) || [field isValidEnumValue:val]) {
        [(VPKGPBEnumArray*)genericArray addRawValue:val];
      } else {
        VPKGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
        [unknownFields mergeVarintField:VPKGPBFieldNumber(field) value:val];
      }
      break;
    }
  }  // switch
}

- (void)mergeFromCodedInputStream:(VPKGPBCodedInputStream *)input
                extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry {
  VPKGPBDescriptor *descriptor = [self descriptor];
  VPKGPBCodedInputStreamState *state = &input->state_;
  uint32_t tag = 0;
  NSUInteger startingIndex = 0;
  NSArray *fields = descriptor->fields_;
  NSUInteger numFields = fields.count;
  while (YES) {
    BOOL merged = NO;
    tag = VPKGPBCodedInputStreamReadTag(state);
    if (tag == 0) {
      break;  // Reached end.
    }
    for (NSUInteger i = 0; i < numFields; ++i) {
      if (startingIndex >= numFields) startingIndex = 0;
      VPKGPBFieldDescriptor *fieldDescriptor = fields[startingIndex];
      if (VPKGPBFieldTag(fieldDescriptor) == tag) {
        VPKGPBFieldType fieldType = fieldDescriptor.fieldType;
        if (fieldType == VPKGPBFieldTypeSingle) {
          MergeSingleFieldFromCodedInputStream(self, fieldDescriptor,
                                               input, extensionRegistry);
          // Well formed protos will only have a single field once, advance
          // the starting index to the next field.
          startingIndex += 1;
        } else if (fieldType == VPKGPBFieldTypeRepeated) {
          if (fieldDescriptor.isPackable) {
            MergeRepeatedPackedFieldFromCodedInputStream(
                self, fieldDescriptor, input);
            // Well formed protos will only have a repeated field that is
            // packed once, advance the starting index to the next field.
            startingIndex += 1;
          } else {
            MergeRepeatedNotPackedFieldFromCodedInputStream(
                self, fieldDescriptor, input, extensionRegistry);
          }
        } else {  // fieldType == VPKGPBFieldTypeMap
          // VPKGPB*Dictionary or NSDictionary, exact type doesn't matter at this
          // point.
          id map = GetOrCreateMapIvarWithField(self, fieldDescriptor);
          [input readMapEntry:map
            extensionRegistry:extensionRegistry
                        field:fieldDescriptor
                parentMessage:self];
        }
        merged = YES;
        break;
      } else {
        startingIndex += 1;
      }
    }  // for(i < numFields)

    if (!merged && (tag != 0)) {
      // Primitive, repeated types can be packed on unpacked on the wire, and
      // are parsed either way.  The above loop covered tag in the preferred
      // for, so this need to check the alternate form.
      for (NSUInteger i = 0; i < numFields; ++i) {
        if (startingIndex >= numFields) startingIndex = 0;
        VPKGPBFieldDescriptor *fieldDescriptor = fields[startingIndex];
        if ((fieldDescriptor.fieldType == VPKGPBFieldTypeRepeated) &&
            !VPKGPBFieldDataTypeIsObject(fieldDescriptor) &&
            (VPKGPBFieldAlternateTag(fieldDescriptor) == tag)) {
          BOOL alternateIsPacked = !fieldDescriptor.isPackable;
          if (alternateIsPacked) {
            MergeRepeatedPackedFieldFromCodedInputStream(
                self, fieldDescriptor, input);
            // Well formed protos will only have a repeated field that is
            // packed once, advance the starting index to the next field.
            startingIndex += 1;
          } else {
            MergeRepeatedNotPackedFieldFromCodedInputStream(
                self, fieldDescriptor, input, extensionRegistry);
          }
          merged = YES;
          break;
        } else {
          startingIndex += 1;
        }
      }
    }

    if (!merged) {
      if (tag == 0) {
        // zero signals EOF / limit reached
        return;
      } else {
        if (![self parseUnknownField:input
                   extensionRegistry:extensionRegistry
                                 tag:tag]) {
          // it's an endgroup tag
          return;
        }
      }
    }  // if(!merged)

  }  // while(YES)
}

#pragma mark - MergeFrom Support

- (void)mergeFrom:(VPKGPBMessage *)other {
  Class selfClass = [self class];
  Class otherClass = [other class];
  if (!([selfClass isSubclassOfClass:otherClass] ||
        [otherClass isSubclassOfClass:selfClass])) {
    [NSException raise:NSInvalidArgumentException
                format:@"Classes must match %@ != %@", selfClass, otherClass];
  }

  // We assume something will be done and become visible.
  VPKGPBBecomeVisibleToAutocreator(self);

  VPKGPBDescriptor *descriptor = [[self class] descriptor];

  for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
    VPKGPBFieldType fieldType = field.fieldType;
    if (fieldType == VPKGPBFieldTypeSingle) {
      int32_t hasIndex = VPKGPBFieldHasIndex(field);
      uint32_t fieldNumber = VPKGPBFieldNumber(field);
      if (!VPKGPBGetHasIvar(other, hasIndex, fieldNumber)) {
        // Other doesn't have the field set, on to the next.
        continue;
      }
      VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
      switch (fieldDataType) {
        case VPKGPBDataTypeBool:
          VPKGPBSetBoolIvarWithFieldPrivate(
              self, field, VPKGPBGetMessageBoolField(other, field));
          break;
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeEnum:
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSInt32:
          VPKGPBSetInt32IvarWithFieldPrivate(
              self, field, VPKGPBGetMessageInt32Field(other, field));
          break;
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
          VPKGPBSetUInt32IvarWithFieldPrivate(
              self, field, VPKGPBGetMessageUInt32Field(other, field));
          break;
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSInt64:
          VPKGPBSetInt64IvarWithFieldPrivate(
              self, field, VPKGPBGetMessageInt64Field(other, field));
          break;
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
          VPKGPBSetUInt64IvarWithFieldPrivate(
              self, field, VPKGPBGetMessageUInt64Field(other, field));
          break;
        case VPKGPBDataTypeFloat:
          VPKGPBSetFloatIvarWithFieldPrivate(
              self, field, VPKGPBGetMessageFloatField(other, field));
          break;
        case VPKGPBDataTypeDouble:
          VPKGPBSetDoubleIvarWithFieldPrivate(
              self, field, VPKGPBGetMessageDoubleField(other, field));
          break;
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeString: {
          id otherVal = VPKGPBGetObjectIvarWithFieldNoAutocreate(other, field);
          VPKGPBSetObjectIvarWithFieldPrivate(self, field, otherVal);
          break;
        }
        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeGroup: {
          id otherVal = VPKGPBGetObjectIvarWithFieldNoAutocreate(other, field);
          if (VPKGPBGetHasIvar(self, hasIndex, fieldNumber)) {
            VPKGPBMessage *message =
                VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
            [message mergeFrom:otherVal];
          } else {
            VPKGPBMessage *message = [otherVal copy];
            VPKGPBSetRetainedObjectIvarWithFieldPrivate(self, field, message);
          }
          break;
        }
      } // switch()
    } else if (fieldType == VPKGPBFieldTypeRepeated) {
      // In the case of a list, they need to be appended, and there is no
      // _hasIvar to worry about setting.
      id otherArray =
          VPKGPBGetObjectIvarWithFieldNoAutocreate(other, field);
      if (otherArray) {
        VPKGPBDataType fieldDataType = field->description_->dataType;
        if (VPKGPBDataTypeIsObject(fieldDataType)) {
          NSMutableArray *resultArray =
              GetOrCreateArrayIvarWithField(self, field);
          [resultArray addObjectsFromArray:otherArray];
        } else if (fieldDataType == VPKGPBDataTypeEnum) {
          VPKGPBEnumArray *resultArray =
              GetOrCreateArrayIvarWithField(self, field);
          [resultArray addRawValuesFromArray:otherArray];
        } else {
          // The array type doesn't matter, that all implement
          // -addValuesFromArray:.
          VPKGPBInt32Array *resultArray =
              GetOrCreateArrayIvarWithField(self, field);
          [resultArray addValuesFromArray:otherArray];
        }
      }
    } else {  // fieldType = VPKGPBFieldTypeMap
      // In the case of a map, they need to be merged, and there is no
      // _hasIvar to worry about setting.
      id otherDict = VPKGPBGetObjectIvarWithFieldNoAutocreate(other, field);
      if (otherDict) {
        VPKGPBDataType keyDataType = field.mapKeyDataType;
        VPKGPBDataType valueDataType = field->description_->dataType;
        if (VPKGPBDataTypeIsObject(keyDataType) &&
            VPKGPBDataTypeIsObject(valueDataType)) {
          NSMutableDictionary *resultDict =
              GetOrCreateMapIvarWithField(self, field);
          [resultDict addEntriesFromDictionary:otherDict];
        } else if (valueDataType == VPKGPBDataTypeEnum) {
          // The exact type doesn't matter, just need to know it is a
          // VPKGPB*EnumDictionary.
          VPKGPBInt32EnumDictionary *resultDict =
              GetOrCreateMapIvarWithField(self, field);
          [resultDict addRawEntriesFromDictionary:otherDict];
        } else {
          // The exact type doesn't matter, they all implement
          // -addEntriesFromDictionary:.
          VPKGPBInt32Int32Dictionary *resultDict =
              GetOrCreateMapIvarWithField(self, field);
          [resultDict addEntriesFromDictionary:otherDict];
        }
      }
    }  // if (fieldType)..else if...else
  }  // for(fields)

  // Unknown fields.
  if (!unknownFields_) {
    [self setUnknownFields:other.unknownFields];
  } else {
    [unknownFields_ mergeUnknownFields:other.unknownFields];
  }

  // Extensions

  if (other->extensionMap_.count == 0) {
    return;
  }

  if (extensionMap_ == nil) {
    extensionMap_ =
        CloneExtensionMap(other->extensionMap_, NSZoneFromPointer(self));
  } else {
    for (VPKGPBExtensionDescriptor *extension in other->extensionMap_) {
      id otherValue = [other->extensionMap_ objectForKey:extension];
      id value = [extensionMap_ objectForKey:extension];
      BOOL isMessageExtension = VPKGPBExtensionIsMessage(extension);

      if (extension.repeated) {
        NSMutableArray *list = value;
        if (list == nil) {
          list = [[NSMutableArray alloc] init];
          [extensionMap_ setObject:list forKey:extension];
          [list release];
        }
        if (isMessageExtension) {
          for (VPKGPBMessage *otherListValue in otherValue) {
            VPKGPBMessage *copiedValue = [otherListValue copy];
            [list addObject:copiedValue];
            [copiedValue release];
          }
        } else {
          [list addObjectsFromArray:otherValue];
        }
      } else {
        if (isMessageExtension) {
          if (value) {
            [(VPKGPBMessage *)value mergeFrom:(VPKGPBMessage *)otherValue];
          } else {
            VPKGPBMessage *copiedValue = [otherValue copy];
            [extensionMap_ setObject:copiedValue forKey:extension];
            [copiedValue release];
          }
        } else {
          [extensionMap_ setObject:otherValue forKey:extension];
        }
      }

      if (isMessageExtension && !extension.isRepeated) {
        VPKGPBMessage *autocreatedValue =
            [[autocreatedExtensionMap_ objectForKey:extension] retain];
        // Must remove from the map before calling VPKGPBClearMessageAutocreator()
        // so that VPKGPBClearMessageAutocreator() knows its safe to clear.
        [autocreatedExtensionMap_ removeObjectForKey:extension];
        VPKGPBClearMessageAutocreator(autocreatedValue);
        [autocreatedValue release];
      }
    }
  }
}

#pragma mark - isEqual: & hash Support

- (BOOL)isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[VPKGPBMessage class]]) {
    return NO;
  }
  VPKGPBMessage *otherMsg = other;
  VPKGPBDescriptor *descriptor = [[self class] descriptor];
  if ([[otherMsg class] descriptor] != descriptor) {
    return NO;
  }
  uint8_t *selfStorage = (uint8_t *)messageStorage_;
  uint8_t *otherStorage = (uint8_t *)otherMsg->messageStorage_;

  for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
    if (VPKGPBFieldIsMapOrArray(field)) {
      // In the case of a list or map, there is no _hasIvar to worry about.
      // NOTE: These are NSArray/VPKGPB*Array or NSDictionary/VPKGPB*Dictionary, but
      // the type doesn't really matter as the objects all support -count and
      // -isEqual:.
      NSArray *resultMapOrArray =
          VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      NSArray *otherMapOrArray =
          VPKGPBGetObjectIvarWithFieldNoAutocreate(other, field);
      // nil and empty are equal
      if (resultMapOrArray.count != 0 || otherMapOrArray.count != 0) {
        if (![resultMapOrArray isEqual:otherMapOrArray]) {
          return NO;
        }
      }
    } else {  // Single field
      int32_t hasIndex = VPKGPBFieldHasIndex(field);
      uint32_t fieldNum = VPKGPBFieldNumber(field);
      BOOL selfHas = VPKGPBGetHasIvar(self, hasIndex, fieldNum);
      BOOL otherHas = VPKGPBGetHasIvar(other, hasIndex, fieldNum);
      if (selfHas != otherHas) {
        return NO;  // Differing has values, not equal.
      }
      if (!selfHas) {
        // Same has values, was no, nothing else to check for this field.
        continue;
      }
      // Now compare the values.
      VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
      size_t fieldOffset = field->description_->offset;
      switch (fieldDataType) {
        case VPKGPBDataTypeBool: {
          // Bools are stored in has_bits to avoid needing explicit space in
          // the storage structure.
          // (the field number passed to the HasIvar helper doesn't really
          // matter since the offset is never negative)
          BOOL selfValue = VPKGPBGetHasIvar(self, (int32_t)(fieldOffset), 0);
          BOOL otherValue = VPKGPBGetHasIvar(other, (int32_t)(fieldOffset), 0);
          if (selfValue != otherValue) {
            return NO;
          }
          break;
        }
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSInt32:
        case VPKGPBDataTypeEnum:
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
        case VPKGPBDataTypeFloat: {
          VPKGPBInternalCompileAssert(sizeof(float) == sizeof(uint32_t), float_not_32_bits);
          // These are all 32bit, signed/unsigned doesn't matter for equality.
          uint32_t *selfValPtr = (uint32_t *)&selfStorage[fieldOffset];
          uint32_t *otherValPtr = (uint32_t *)&otherStorage[fieldOffset];
          if (*selfValPtr != *otherValPtr) {
            return NO;
          }
          break;
        }
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSInt64:
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
        case VPKGPBDataTypeDouble: {
          VPKGPBInternalCompileAssert(sizeof(double) == sizeof(uint64_t), double_not_64_bits);
          // These are all 64bit, signed/unsigned doesn't matter for equality.
          uint64_t *selfValPtr = (uint64_t *)&selfStorage[fieldOffset];
          uint64_t *otherValPtr = (uint64_t *)&otherStorage[fieldOffset];
          if (*selfValPtr != *otherValPtr) {
            return NO;
          }
          break;
        }
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeString:
        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeGroup: {
          // Type doesn't matter here, they all implement -isEqual:.
          id *selfValPtr = (id *)&selfStorage[fieldOffset];
          id *otherValPtr = (id *)&otherStorage[fieldOffset];
          if (![*selfValPtr isEqual:*otherValPtr]) {
            return NO;
          }
          break;
        }
      } // switch()
    }   // if(mapOrArray)...else
  }  // for(fields)

  // nil and empty are equal
  if (extensionMap_.count != 0 || otherMsg->extensionMap_.count != 0) {
    if (![extensionMap_ isEqual:otherMsg->extensionMap_]) {
      return NO;
    }
  }

  // nil and empty are equal
  VPKGPBUnknownFieldSet *otherUnknowns = otherMsg->unknownFields_;
  if ([unknownFields_ countOfFields] != 0 ||
      [otherUnknowns countOfFields] != 0) {
    if (![unknownFields_ isEqual:otherUnknowns]) {
      return NO;
    }
  }

  return YES;
}

// It is very difficult to implement a generic hash for ProtoBuf messages that
// will perform well. If you need hashing on your ProtoBufs (eg you are using
// them as dictionary keys) you will probably want to implement a ProtoBuf
// message specific hash as a category on your protobuf class. Do not make it a
// category on VPKGPBMessage as you will conflict with this hash, and will possibly
// override hash for all generated protobufs. A good implementation of hash will
// be really fast, so we would recommend only hashing protobufs that have an
// identifier field of some kind that you can easily hash. If you implement
// hash, we would strongly recommend overriding isEqual: in your category as
// well, as the default implementation of isEqual: is extremely slow, and may
// drastically affect performance in large sets.
- (NSUInteger)hash {
  VPKGPBDescriptor *descriptor = [[self class] descriptor];
  const NSUInteger prime = 19;
  uint8_t *storage = (uint8_t *)messageStorage_;

  // Start with the descriptor and then mix it with some instance info.
  // Hopefully that will give a spread based on classes and what fields are set.
  NSUInteger result = (NSUInteger)descriptor;

  for (VPKGPBFieldDescriptor *field in descriptor->fields_) {
    if (VPKGPBFieldIsMapOrArray(field)) {
      // Exact type doesn't matter, just check if there are any elements.
      NSArray *mapOrArray = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      NSUInteger count = mapOrArray.count;
      if (count) {
        // NSArray/NSDictionary use count, use the field number and the count.
        result = prime * result + VPKGPBFieldNumber(field);
        result = prime * result + count;
      }
    } else if (VPKGPBGetHasIvarField(self, field)) {
      // Just using the field number seemed simple/fast, but then a small
      // message class where all the same fields are always set (to different
      // things would end up all with the same hash, so pull in some data).
      VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
      size_t fieldOffset = field->description_->offset;
      switch (fieldDataType) {
        case VPKGPBDataTypeBool: {
          // Bools are stored in has_bits to avoid needing explicit space in
          // the storage structure.
          // (the field number passed to the HasIvar helper doesn't really
          // matter since the offset is never negative)
          BOOL value = VPKGPBGetHasIvar(self, (int32_t)(fieldOffset), 0);
          result = prime * result + value;
          break;
        }
        case VPKGPBDataTypeSFixed32:
        case VPKGPBDataTypeInt32:
        case VPKGPBDataTypeSInt32:
        case VPKGPBDataTypeEnum:
        case VPKGPBDataTypeFixed32:
        case VPKGPBDataTypeUInt32:
        case VPKGPBDataTypeFloat: {
          VPKGPBInternalCompileAssert(sizeof(float) == sizeof(uint32_t), float_not_32_bits);
          // These are all 32bit, just mix it in.
          uint32_t *valPtr = (uint32_t *)&storage[fieldOffset];
          result = prime * result + *valPtr;
          break;
        }
        case VPKGPBDataTypeSFixed64:
        case VPKGPBDataTypeInt64:
        case VPKGPBDataTypeSInt64:
        case VPKGPBDataTypeFixed64:
        case VPKGPBDataTypeUInt64:
        case VPKGPBDataTypeDouble: {
          VPKGPBInternalCompileAssert(sizeof(double) == sizeof(uint64_t), double_not_64_bits);
          // These are all 64bit, just mix what fits into an NSUInteger in.
          uint64_t *valPtr = (uint64_t *)&storage[fieldOffset];
          result = prime * result + (NSUInteger)(*valPtr);
          break;
        }
        case VPKGPBDataTypeBytes:
        case VPKGPBDataTypeString: {
          // Type doesn't matter here, they both implement -hash:.
          id *valPtr = (id *)&storage[fieldOffset];
          result = prime * result + [*valPtr hash];
          break;
        }

        case VPKGPBDataTypeMessage:
        case VPKGPBDataTypeGroup: {
          VPKGPBMessage **valPtr = (VPKGPBMessage **)&storage[fieldOffset];
          // Could call -hash on the sub message, but that could recurse pretty
          // deep; follow the lead of NSArray/NSDictionary and don't really
          // recurse for hash, instead use the field number and the descriptor
          // of the sub message.  Yes, this could suck for a bunch of messages
          // where they all only differ in the sub messages, but if you are
          // using a message with sub messages for something that needs -hash,
          // odds are you are also copying them as keys, and that deep copy
          // will also suck.
          result = prime * result + VPKGPBFieldNumber(field);
          result = prime * result + (NSUInteger)[[*valPtr class] descriptor];
          break;
        }
      } // switch()
    }
  }

  // Unknowns and extensions are not included.

  return result;
}

#pragma mark - Description Support

- (NSString *)description {
  NSString *textFormat = VPKGPBTextFormatForMessage(self, @"    ");
  NSString *description = [NSString
      stringWithFormat:@"<%@ %p>: {\n%@}", [self class], self, textFormat];
  return description;
}

#if defined(DEBUG) && DEBUG

// Xcode 5.1 added support for custom quick look info.
// https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/CustomClassDisplay_in_QuickLook/CH01-quick_look_for_custom_objects/CH01-quick_look_for_custom_objects.html#//apple_ref/doc/uid/TP40014001-CH2-SW1
- (id)debugQuickLookObject {
  return VPKGPBTextFormatForMessage(self, nil);
}

#endif  // DEBUG

#pragma mark - SerializedSize

- (size_t)serializedSize {
  VPKGPBDescriptor *descriptor = [[self class] descriptor];
  size_t result = 0;

  // Has check is done explicitly, so VPKGPBGetObjectIvarWithFieldNoAutocreate()
  // avoids doing the has check again.

  // Fields.
  for (VPKGPBFieldDescriptor *fieldDescriptor in descriptor->fields_) {
    VPKGPBFieldType fieldType = fieldDescriptor.fieldType;
    VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(fieldDescriptor);

    // Single Fields
    if (fieldType == VPKGPBFieldTypeSingle) {
      BOOL selfHas = VPKGPBGetHasIvarField(self, fieldDescriptor);
      if (!selfHas) {
        continue;  // Nothing to do.
      }

      uint32_t fieldNumber = VPKGPBFieldNumber(fieldDescriptor);

      switch (fieldDataType) {
#define CASE_SINGLE_POD(NAME, TYPE, FUNC_TYPE)                                \
        case VPKGPBDataType##NAME: {                                             \
          TYPE fieldVal = VPKGPBGetMessage##FUNC_TYPE##Field(self, fieldDescriptor); \
          result += VPKGPBCompute##NAME##Size(fieldNumber, fieldVal);            \
          break;                                                              \
        }
#define CASE_SINGLE_OBJECT(NAME)                                              \
        case VPKGPBDataType##NAME: {                                             \
          id fieldVal = VPKGPBGetObjectIvarWithFieldNoAutocreate(self, fieldDescriptor); \
          result += VPKGPBCompute##NAME##Size(fieldNumber, fieldVal);            \
          break;                                                              \
        }
          CASE_SINGLE_POD(Bool, BOOL, Bool)
          CASE_SINGLE_POD(Fixed32, uint32_t, UInt32)
          CASE_SINGLE_POD(SFixed32, int32_t, Int32)
          CASE_SINGLE_POD(Float, float, Float)
          CASE_SINGLE_POD(Fixed64, uint64_t, UInt64)
          CASE_SINGLE_POD(SFixed64, int64_t, Int64)
          CASE_SINGLE_POD(Double, double, Double)
          CASE_SINGLE_POD(Int32, int32_t, Int32)
          CASE_SINGLE_POD(Int64, int64_t, Int64)
          CASE_SINGLE_POD(SInt32, int32_t, Int32)
          CASE_SINGLE_POD(SInt64, int64_t, Int64)
          CASE_SINGLE_POD(UInt32, uint32_t, UInt32)
          CASE_SINGLE_POD(UInt64, uint64_t, UInt64)
          CASE_SINGLE_OBJECT(Bytes)
          CASE_SINGLE_OBJECT(String)
          CASE_SINGLE_OBJECT(Message)
          CASE_SINGLE_OBJECT(Group)
          CASE_SINGLE_POD(Enum, int32_t, Int32)
#undef CASE_SINGLE_POD
#undef CASE_SINGLE_OBJECT
      }

    // Repeated Fields
    } else if (fieldType == VPKGPBFieldTypeRepeated) {
      id genericArray =
          VPKGPBGetObjectIvarWithFieldNoAutocreate(self, fieldDescriptor);
      NSUInteger count = [genericArray count];
      if (count == 0) {
        continue;  // Nothing to add.
      }
      __block size_t dataSize = 0;

      switch (fieldDataType) {
#define CASE_REPEATED_POD(NAME, TYPE, ARRAY_TYPE)                             \
    CASE_REPEATED_POD_EXTRA(NAME, TYPE, ARRAY_TYPE, )
#define CASE_REPEATED_POD_EXTRA(NAME, TYPE, ARRAY_TYPE, ARRAY_ACCESSOR_NAME)  \
        case VPKGPBDataType##NAME: {                                             \
          VPKGPB##ARRAY_TYPE##Array *array = genericArray;                       \
          [array enumerate##ARRAY_ACCESSOR_NAME##ValuesWithBlock:^(TYPE value, __unused NSUInteger idx, __unused BOOL *stop) { \
            dataSize += VPKGPBCompute##NAME##SizeNoTag(value);                   \
          }];                                                                 \
          break;                                                              \
        }
#define CASE_REPEATED_OBJECT(NAME)                                            \
        case VPKGPBDataType##NAME: {                                             \
          for (id value in genericArray) {                                    \
            dataSize += VPKGPBCompute##NAME##SizeNoTag(value);                   \
          }                                                                   \
          break;                                                              \
        }
          CASE_REPEATED_POD(Bool, BOOL, Bool)
          CASE_REPEATED_POD(Fixed32, uint32_t, UInt32)
          CASE_REPEATED_POD(SFixed32, int32_t, Int32)
          CASE_REPEATED_POD(Float, float, Float)
          CASE_REPEATED_POD(Fixed64, uint64_t, UInt64)
          CASE_REPEATED_POD(SFixed64, int64_t, Int64)
          CASE_REPEATED_POD(Double, double, Double)
          CASE_REPEATED_POD(Int32, int32_t, Int32)
          CASE_REPEATED_POD(Int64, int64_t, Int64)
          CASE_REPEATED_POD(SInt32, int32_t, Int32)
          CASE_REPEATED_POD(SInt64, int64_t, Int64)
          CASE_REPEATED_POD(UInt32, uint32_t, UInt32)
          CASE_REPEATED_POD(UInt64, uint64_t, UInt64)
          CASE_REPEATED_OBJECT(Bytes)
          CASE_REPEATED_OBJECT(String)
          CASE_REPEATED_OBJECT(Message)
          CASE_REPEATED_OBJECT(Group)
          CASE_REPEATED_POD_EXTRA(Enum, int32_t, Enum, Raw)
#undef CASE_REPEATED_POD
#undef CASE_REPEATED_POD_EXTRA
#undef CASE_REPEATED_OBJECT
      }  // switch
      result += dataSize;
      size_t tagSize = VPKGPBComputeTagSize(VPKGPBFieldNumber(fieldDescriptor));
      if (fieldDataType == VPKGPBDataTypeGroup) {
        // Groups have both a start and an end tag.
        tagSize *= 2;
      }
      if (fieldDescriptor.isPackable) {
        result += tagSize;
        result += VPKGPBComputeSizeTSizeAsInt32NoTag(dataSize);
      } else {
        result += count * tagSize;
      }

    // Map<> Fields
    } else {  // fieldType == VPKGPBFieldTypeMap
      if (VPKGPBDataTypeIsObject(fieldDataType) &&
          (fieldDescriptor.mapKeyDataType == VPKGPBDataTypeString)) {
        // If key type was string, then the map is an NSDictionary.
        NSDictionary *map =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, fieldDescriptor);
        if (map) {
          result += VPKGPBDictionaryComputeSizeInternalHelper(map, fieldDescriptor);
        }
      } else {
        // Type will be VPKGPB*GroupDictionary, exact type doesn't matter.
        VPKGPBInt32Int32Dictionary *map =
            VPKGPBGetObjectIvarWithFieldNoAutocreate(self, fieldDescriptor);
        result += [map computeSerializedSizeAsField:fieldDescriptor];
      }
    }
  }  // for(fields)

  // Add any unknown fields.
  if (descriptor.wireFormat) {
    result += [unknownFields_ serializedSizeAsMessageSet];
  } else {
    result += [unknownFields_ serializedSize];
  }

  // Add any extensions.
  for (VPKGPBExtensionDescriptor *extension in extensionMap_) {
    id value = [extensionMap_ objectForKey:extension];
    result += VPKGPBComputeExtensionSerializedSizeIncludingTag(extension, value);
  }

  return result;
}

#pragma mark - Resolve Methods Support

typedef struct ResolveIvarAccessorMethodResult {
  IMP impToAdd;
  SEL encodingSelector;
} ResolveIvarAccessorMethodResult;

// |field| can be __unsafe_unretained because they are created at startup
// and are essentially global. No need to pay for retain/release when
// they are captured in blocks.
static void ResolveIvarGet(__unsafe_unretained VPKGPBFieldDescriptor *field,
                           ResolveIvarAccessorMethodResult *result) {
  VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
  switch (fieldDataType) {
#define CASE_GET(NAME, TYPE, TRUE_NAME)                          \
    case VPKGPBDataType##NAME: {                                    \
      result->impToAdd = imp_implementationWithBlock(^(id obj) { \
        return VPKGPBGetMessage##TRUE_NAME##Field(obj, field);      \
       });                                                       \
      result->encodingSelector = @selector(get##NAME);           \
      break;                                                     \
    }
#define CASE_GET_OBJECT(NAME, TYPE, TRUE_NAME)                   \
    case VPKGPBDataType##NAME: {                                    \
      result->impToAdd = imp_implementationWithBlock(^(id obj) { \
        return VPKGPBGetObjectIvarWithField(obj, field);            \
       });                                                       \
      result->encodingSelector = @selector(get##NAME);           \
      break;                                                     \
    }
      CASE_GET(Bool, BOOL, Bool)
      CASE_GET(Fixed32, uint32_t, UInt32)
      CASE_GET(SFixed32, int32_t, Int32)
      CASE_GET(Float, float, Float)
      CASE_GET(Fixed64, uint64_t, UInt64)
      CASE_GET(SFixed64, int64_t, Int64)
      CASE_GET(Double, double, Double)
      CASE_GET(Int32, int32_t, Int32)
      CASE_GET(Int64, int64_t, Int64)
      CASE_GET(SInt32, int32_t, Int32)
      CASE_GET(SInt64, int64_t, Int64)
      CASE_GET(UInt32, uint32_t, UInt32)
      CASE_GET(UInt64, uint64_t, UInt64)
      CASE_GET_OBJECT(Bytes, id, Object)
      CASE_GET_OBJECT(String, id, Object)
      CASE_GET_OBJECT(Message, id, Object)
      CASE_GET_OBJECT(Group, id, Object)
      CASE_GET(Enum, int32_t, Enum)
#undef CASE_GET
  }
}

// See comment about __unsafe_unretained on ResolveIvarGet.
static void ResolveIvarSet(__unsafe_unretained VPKGPBFieldDescriptor *field,
                           ResolveIvarAccessorMethodResult *result) {
  VPKGPBDataType fieldDataType = VPKGPBGetFieldDataType(field);
  switch (fieldDataType) {
#define CASE_SET(NAME, TYPE, TRUE_NAME)                                       \
    case VPKGPBDataType##NAME: {                                                 \
      result->impToAdd = imp_implementationWithBlock(^(id obj, TYPE value) {  \
        return VPKGPBSet##TRUE_NAME##IvarWithFieldPrivate(obj, field, value);    \
      });                                                                     \
      result->encodingSelector = @selector(set##NAME:);                       \
      break;                                                                  \
    }
#define CASE_SET_COPY(NAME)                                                   \
    case VPKGPBDataType##NAME: {                                                 \
      result->impToAdd = imp_implementationWithBlock(^(id obj, id value) {    \
        return VPKGPBSetRetainedObjectIvarWithFieldPrivate(obj, field, [value copy]); \
      });                                                                     \
      result->encodingSelector = @selector(set##NAME:);                       \
      break;                                                                  \
    }
      CASE_SET(Bool, BOOL, Bool)
      CASE_SET(Fixed32, uint32_t, UInt32)
      CASE_SET(SFixed32, int32_t, Int32)
      CASE_SET(Float, float, Float)
      CASE_SET(Fixed64, uint64_t, UInt64)
      CASE_SET(SFixed64, int64_t, Int64)
      CASE_SET(Double, double, Double)
      CASE_SET(Int32, int32_t, Int32)
      CASE_SET(Int64, int64_t, Int64)
      CASE_SET(SInt32, int32_t, Int32)
      CASE_SET(SInt64, int64_t, Int64)
      CASE_SET(UInt32, uint32_t, UInt32)
      CASE_SET(UInt64, uint64_t, UInt64)
      CASE_SET_COPY(Bytes)
      CASE_SET_COPY(String)
      CASE_SET(Message, id, Object)
      CASE_SET(Group, id, Object)
      CASE_SET(Enum, int32_t, Enum)
#undef CASE_SET
  }
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
  const VPKGPBDescriptor *descriptor = [self descriptor];
  if (!descriptor) {
    return [super resolveInstanceMethod:sel];
  }

  // NOTE: hasOrCountSel_/setHasSel_ will be NULL if the field for the given
  // message should not have has support (done in VPKGPBDescriptor.m), so there is
  // no need for checks here to see if has*/setHas* are allowed.
  ResolveIvarAccessorMethodResult result = {NULL, NULL};

  // See comment about __unsafe_unretained on ResolveIvarGet.
  for (__unsafe_unretained VPKGPBFieldDescriptor *field in descriptor->fields_) {
    BOOL isMapOrArray = VPKGPBFieldIsMapOrArray(field);
    if (!isMapOrArray) {
      // Single fields.
      if (sel == field->getSel_) {
        ResolveIvarGet(field, &result);
        break;
      } else if (sel == field->setSel_) {
        ResolveIvarSet(field, &result);
        break;
      } else if (sel == field->hasOrCountSel_) {
        int32_t index = VPKGPBFieldHasIndex(field);
        uint32_t fieldNum = VPKGPBFieldNumber(field);
        result.impToAdd = imp_implementationWithBlock(^(id obj) {
          return VPKGPBGetHasIvar(obj, index, fieldNum);
        });
        result.encodingSelector = @selector(getBool);
        break;
      } else if (sel == field->setHasSel_) {
        result.impToAdd = imp_implementationWithBlock(^(id obj, BOOL value) {
          if (value) {
            [NSException raise:NSInvalidArgumentException
                        format:@"%@: %@ can only be set to NO (to clear field).",
                               [obj class],
                               NSStringFromSelector(field->setHasSel_)];
          }
          VPKGPBClearMessageField(obj, field);
        });
        result.encodingSelector = @selector(setBool:);
        break;
      } else {
        VPKGPBOneofDescriptor *oneof = field->containingOneof_;
        if (oneof && (sel == oneof->caseSel_)) {
          int32_t index = VPKGPBFieldHasIndex(field);
          result.impToAdd = imp_implementationWithBlock(^(id obj) {
            return VPKGPBGetHasOneof(obj, index);
          });
          result.encodingSelector = @selector(getEnum);
          break;
        }
      }
    } else {
      // map<>/repeated fields.
      if (sel == field->getSel_) {
        if (field.fieldType == VPKGPBFieldTypeRepeated) {
          result.impToAdd = imp_implementationWithBlock(^(id obj) {
            return GetArrayIvarWithField(obj, field);
          });
        } else {
          result.impToAdd = imp_implementationWithBlock(^(id obj) {
            return GetMapIvarWithField(obj, field);
          });
        }
        result.encodingSelector = @selector(getArray);
        break;
      } else if (sel == field->setSel_) {
        // Local for syntax so the block can directly capture it and not the
        // full lookup.
        result.impToAdd = imp_implementationWithBlock(^(id obj, id value) {
          VPKGPBSetObjectIvarWithFieldPrivate(obj, field, value);
        });
        result.encodingSelector = @selector(setArray:);
        break;
      } else if (sel == field->hasOrCountSel_) {
        result.impToAdd = imp_implementationWithBlock(^(id obj) {
          // Type doesn't matter, all *Array and *Dictionary types support
          // -count.
          NSArray *arrayOrMap =
              VPKGPBGetObjectIvarWithFieldNoAutocreate(obj, field);
          return [arrayOrMap count];
        });
        result.encodingSelector = @selector(getArrayCount);
        break;
      }
    }
  }
  if (result.impToAdd) {
    const char *encoding =
        VPKGPBMessageEncodingForSelector(result.encodingSelector, YES);
    Class msgClass = descriptor.messageClass;
    BOOL methodAdded = class_addMethod(msgClass, sel, result.impToAdd, encoding);
    // class_addMethod() is documented as also failing if the method was already
    // added; so we check if the method is already there and return success so
    // the method dispatch will still happen.  Why would it already be added?
    // Two threads could cause the same method to be bound at the same time,
    // but only one will actually bind it; the other still needs to return true
    // so things will dispatch.
    if (!methodAdded) {
      methodAdded = VPKGPBClassHasSel(msgClass, sel);
    }
    return methodAdded;
  }
  return [super resolveInstanceMethod:sel];
}

+ (BOOL)resolveClassMethod:(SEL)sel {
  // Extensions scoped to a Message and looked up via class methods.
  if (VPKGPBResolveExtensionClassMethod(self, sel)) {
    return YES;
  }
  return [super resolveClassMethod:sel];
}

#pragma mark - NSCoding Support

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if (self) {
    NSData *data =
        [aDecoder decodeObjectOfClass:[NSData class] forKey:kVPKGPBDataCoderKey];
    if (data.length) {
      [self mergeFromData:data extensionRegistry:nil];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
#if defined(DEBUG) && DEBUG
  if (extensionMap_.count) {
    // Hint to go along with the docs on VPKGPBMessage about this.
    //
    // Note: This is incomplete, in that it only checked the "root" message,
    // if a sub message in a field has extensions, the issue still exists. A
    // recursive check could be done here (like the work in
    // VPKGPBMessageDropUnknownFieldsRecursively()), but that has the potential to
    // be expensive and could slow down serialization in DEBUG enough to cause
    // developers other problems.
    NSLog(@"Warning: writing out a VPKGPBMessage (%@) via NSCoding and it"
          @" has %ld extensions; when read back in, those fields will be"
          @" in the unknownFields property instead.",
          [self class], (long)extensionMap_.count);
  }
#endif
  NSData *data = [self data];
  if (data.length) {
    [aCoder encodeObject:data forKey:kVPKGPBDataCoderKey];
  }
}

#pragma mark - KVC Support

+ (BOOL)accessInstanceVariablesDirectly {
  // Make sure KVC doesn't use instance variables.
  return NO;
}

@end

#pragma mark - Messages from VPKGPBUtilities.h but defined here for access to helpers.

// Only exists for public api, no core code should use this.
id VPKGPBGetMessageRepeatedField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != VPKGPBFieldTypeRepeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a repeated field.",
     [self class], field.name];
  }
#endif
  return GetOrCreateArrayIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
id VPKGPBGetMessageMapField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != VPKGPBFieldTypeMap) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a map<> field.",
     [self class], field.name];
  }
#endif
  return GetOrCreateMapIvarWithField(self, field);
}

id VPKGPBGetObjectIvarWithField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field) {
  NSCAssert(!VPKGPBFieldIsMapOrArray(field), @"Shouldn't get here");
  if (!VPKGPBFieldDataTypeIsMessage(field)) {
    if (VPKGPBGetHasIvarField(self, field)) {
      uint8_t *storage = (uint8_t *)self->messageStorage_;
      id *typePtr = (id *)&storage[field->description_->offset];
      return *typePtr;
    }
    // Not set...non messages (string/data), get their default.
    return field.defaultValue.valueMessage;
  }

  uint8_t *storage = (uint8_t *)self->messageStorage_;
  _Atomic(id) *typePtr = (_Atomic(id) *)&storage[field->description_->offset];
  id msg = atomic_load(typePtr);
  if (msg) {
    return msg;
  }

  id expected = nil;
  id autocreated = VPKGPBCreateMessageWithAutocreator(field.msgClass, self, field);
  if (atomic_compare_exchange_strong(typePtr, &expected, autocreated)) {
    // Value was set, return it.
    return autocreated;
  }

  // Some other thread set it, release the one created and return what got set.
  VPKGPBClearMessageAutocreator(autocreated);
  [autocreated release];
  return expected;
}

#pragma clang diagnostic pop
