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

#import "VPKGPBWireFormat.h"

#import "VPKGPBUtilities_PackagePrivate.h"

enum {
  VPKGPBWireFormatTagTypeBits = 3,
  VPKGPBWireFormatTagTypeMask = 7 /* = (1 << VPKGPBWireFormatTagTypeBits) - 1 */,
};

uint32_t VPKGPBWireFormatMakeTag(uint32_t fieldNumber, VPKGPBWireFormat wireType) {
  return (fieldNumber << VPKGPBWireFormatTagTypeBits) | wireType;
}

VPKGPBWireFormat VPKGPBWireFormatGetTagWireType(uint32_t tag) {
  return (VPKGPBWireFormat)(tag & VPKGPBWireFormatTagTypeMask);
}

uint32_t VPKGPBWireFormatGetTagFieldNumber(uint32_t tag) {
  return VPKGPBLogicalRightShift32(tag, VPKGPBWireFormatTagTypeBits);
}

BOOL VPKGPBWireFormatIsValidTag(uint32_t tag) {
  uint32_t formatBits = (tag & VPKGPBWireFormatTagTypeMask);
  // The valid VPKGPBWireFormat* values are 0-5, anything else is not a valid tag.
  BOOL result = (formatBits <= 5);
  return result;
}

VPKGPBWireFormat VPKGPBWireFormatForType(VPKGPBDataType type, BOOL isPacked) {
  if (isPacked) {
    return VPKGPBWireFormatLengthDelimited;
  }

  static const VPKGPBWireFormat format[VPKGPBDataType_Count] = {
      VPKGPBWireFormatVarint,           // VPKGPBDataTypeBool
      VPKGPBWireFormatFixed32,          // VPKGPBDataTypeFixed32
      VPKGPBWireFormatFixed32,          // VPKGPBDataTypeSFixed32
      VPKGPBWireFormatFixed32,          // VPKGPBDataTypeFloat
      VPKGPBWireFormatFixed64,          // VPKGPBDataTypeFixed64
      VPKGPBWireFormatFixed64,          // VPKGPBDataTypeSFixed64
      VPKGPBWireFormatFixed64,          // VPKGPBDataTypeDouble
      VPKGPBWireFormatVarint,           // VPKGPBDataTypeInt32
      VPKGPBWireFormatVarint,           // VPKGPBDataTypeInt64
      VPKGPBWireFormatVarint,           // VPKGPBDataTypeSInt32
      VPKGPBWireFormatVarint,           // VPKGPBDataTypeSInt64
      VPKGPBWireFormatVarint,           // VPKGPBDataTypeUInt32
      VPKGPBWireFormatVarint,           // VPKGPBDataTypeUInt64
      VPKGPBWireFormatLengthDelimited,  // VPKGPBDataTypeBytes
      VPKGPBWireFormatLengthDelimited,  // VPKGPBDataTypeString
      VPKGPBWireFormatLengthDelimited,  // VPKGPBDataTypeMessage
      VPKGPBWireFormatStartGroup,       // VPKGPBDataTypeGroup
      VPKGPBWireFormatVarint            // VPKGPBDataTypeEnum
  };
  return format[type];
}
