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

#import "VPKGPBExtensionInternals.h"

#import <objc/runtime.h>

#import "VPKGPBCodedInputStream_PackagePrivate.h"
#import "VPKGPBCodedOutputStream_PackagePrivate.h"
#import "VPKGPBDescriptor_PackagePrivate.h"
#import "VPKGPBMessage_PackagePrivate.h"
#import "VPKGPBUtilities_PackagePrivate.h"

VPKGPB_INLINE size_t DataTypeSize(VPKGPBDataType dataType) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
  switch (dataType) {
    case VPKGPBDataTypeBool:
      return 1;
    case VPKGPBDataTypeFixed32:
    case VPKGPBDataTypeSFixed32:
    case VPKGPBDataTypeFloat:
      return 4;
    case VPKGPBDataTypeFixed64:
    case VPKGPBDataTypeSFixed64:
    case VPKGPBDataTypeDouble:
      return 8;
    default:
      return 0;
  }
#pragma clang diagnostic pop
}

static size_t ComputePBSerializedSizeNoTagOfObject(VPKGPBDataType dataType, id object) {
#define FIELD_CASE(TYPE, ACCESSOR) \
  case VPKGPBDataType##TYPE:          \
    return VPKGPBCompute##TYPE##SizeNoTag([(NSNumber *)object ACCESSOR]);
#define FIELD_CASE2(TYPE) \
  case VPKGPBDataType##TYPE: \
    return VPKGPBCompute##TYPE##SizeNoTag(object);
  switch (dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Message)
    FIELD_CASE2(Group)
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static size_t ComputeSerializedSizeIncludingTagOfObject(VPKGPBExtensionDescription *description,
                                                        id object) {
#define FIELD_CASE(TYPE, ACCESSOR) \
  case VPKGPBDataType##TYPE:          \
    return VPKGPBCompute##TYPE##Size(description->fieldNumber, [(NSNumber *)object ACCESSOR]);
#define FIELD_CASE2(TYPE) \
  case VPKGPBDataType##TYPE: \
    return VPKGPBCompute##TYPE##Size(description->fieldNumber, object);
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Group)
    case VPKGPBDataTypeMessage:
      if (VPKGPBExtensionIsWireFormat(description)) {
        return VPKGPBComputeMessageSetExtensionSize(description->fieldNumber, object);
      } else {
        return VPKGPBComputeMessageSize(description->fieldNumber, object);
      }
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static size_t ComputeSerializedSizeIncludingTagOfArray(VPKGPBExtensionDescription *description,
                                                       NSArray *values) {
  if (VPKGPBExtensionIsPacked(description)) {
    size_t size = 0;
    size_t typeSize = DataTypeSize(description->dataType);
    if (typeSize != 0) {
      size = values.count * typeSize;
    } else {
      for (id value in values) {
        size += ComputePBSerializedSizeNoTagOfObject(description->dataType, value);
      }
    }
    return size + VPKGPBComputeTagSize(description->fieldNumber) +
           VPKGPBComputeRawVarint32SizeForInteger(size);
  } else {
    size_t size = 0;
    for (id value in values) {
      size += ComputeSerializedSizeIncludingTagOfObject(description, value);
    }
    return size;
  }
}

static void WriteObjectIncludingTagToCodedOutputStream(id object,
                                                       VPKGPBExtensionDescription *description,
                                                       VPKGPBCodedOutputStream *output) {
#define FIELD_CASE(TYPE, ACCESSOR)                                                     \
  case VPKGPBDataType##TYPE:                                                              \
    [output write##TYPE:description->fieldNumber value:[(NSNumber *)object ACCESSOR]]; \
    return;
#define FIELD_CASE2(TYPE)                                       \
  case VPKGPBDataType##TYPE:                                       \
    [output write##TYPE:description->fieldNumber value:object]; \
    return;
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Group)
    case VPKGPBDataTypeMessage:
      if (VPKGPBExtensionIsWireFormat(description)) {
        [output writeMessageSetExtension:description->fieldNumber value:object];
      } else {
        [output writeMessage:description->fieldNumber value:object];
      }
      return;
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static void WriteObjectNoTagToCodedOutputStream(id object, VPKGPBExtensionDescription *description,
                                                VPKGPBCodedOutputStream *output) {
#define FIELD_CASE(TYPE, ACCESSOR)                             \
  case VPKGPBDataType##TYPE:                                      \
    [output write##TYPE##NoTag:[(NSNumber *)object ACCESSOR]]; \
    return;
#define FIELD_CASE2(TYPE)               \
  case VPKGPBDataType##TYPE:               \
    [output write##TYPE##NoTag:object]; \
    return;
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Message)
    case VPKGPBDataTypeGroup:
      [output writeGroupNoTag:description->fieldNumber value:object];
      return;
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static void WriteArrayIncludingTagsToCodedOutputStream(NSArray *values,
                                                       VPKGPBExtensionDescription *description,
                                                       VPKGPBCodedOutputStream *output) {
  if (VPKGPBExtensionIsPacked(description)) {
    [output writeTag:description->fieldNumber format:VPKGPBWireFormatLengthDelimited];
    size_t dataSize = 0;
    size_t typeSize = DataTypeSize(description->dataType);
    if (typeSize != 0) {
      dataSize = values.count * typeSize;
    } else {
      for (id value in values) {
        dataSize += ComputePBSerializedSizeNoTagOfObject(description->dataType, value);
      }
    }
    [output writeRawVarintSizeTAs32:dataSize];
    for (id value in values) {
      WriteObjectNoTagToCodedOutputStream(value, description, output);
    }
  } else {
    for (id value in values) {
      WriteObjectIncludingTagToCodedOutputStream(value, description, output);
    }
  }
}

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

void VPKGPBWriteExtensionValueToOutputStream(VPKGPBExtensionDescriptor *extension, id value,
                                          VPKGPBCodedOutputStream *output) {
  VPKGPBExtensionDescription *description = extension->description_;
  if (VPKGPBExtensionIsRepeated(description)) {
    WriteArrayIncludingTagsToCodedOutputStream(value, description, output);
  } else {
    WriteObjectIncludingTagToCodedOutputStream(value, description, output);
  }
}

size_t VPKGPBComputeExtensionSerializedSizeIncludingTag(VPKGPBExtensionDescriptor *extension, id value) {
  VPKGPBExtensionDescription *description = extension->description_;
  if (VPKGPBExtensionIsRepeated(description)) {
    return ComputeSerializedSizeIncludingTagOfArray(description, value);
  } else {
    return ComputeSerializedSizeIncludingTagOfObject(description, value);
  }
}

#pragma clang diagnostic pop
