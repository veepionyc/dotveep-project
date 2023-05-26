// Protocol Buffers - Google's data interchange format
// Copyright 2016 Google Inc.  All rights reserved.
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

#import "VPKGPBCodedOutputStream.h"

NS_ASSUME_NONNULL_BEGIN

CF_EXTERN_C_BEGIN

size_t VPKGPBComputeDoubleSize(int32_t fieldNumber, double value) __attribute__((const));
size_t VPKGPBComputeFloatSize(int32_t fieldNumber, float value) __attribute__((const));
size_t VPKGPBComputeUInt64Size(int32_t fieldNumber, uint64_t value) __attribute__((const));
size_t VPKGPBComputeInt64Size(int32_t fieldNumber, int64_t value) __attribute__((const));
size_t VPKGPBComputeInt32Size(int32_t fieldNumber, int32_t value) __attribute__((const));
size_t VPKGPBComputeFixed64Size(int32_t fieldNumber, uint64_t value) __attribute__((const));
size_t VPKGPBComputeFixed32Size(int32_t fieldNumber, uint32_t value) __attribute__((const));
size_t VPKGPBComputeBoolSize(int32_t fieldNumber, BOOL value) __attribute__((const));
size_t VPKGPBComputeStringSize(int32_t fieldNumber, NSString *value) __attribute__((const));
size_t VPKGPBComputeGroupSize(int32_t fieldNumber, VPKGPBMessage *value) __attribute__((const));
size_t VPKGPBComputeUnknownGroupSize(int32_t fieldNumber, VPKGPBUnknownFieldSet *value)
    __attribute__((const));
size_t VPKGPBComputeMessageSize(int32_t fieldNumber, VPKGPBMessage *value) __attribute__((const));
size_t VPKGPBComputeBytesSize(int32_t fieldNumber, NSData *value) __attribute__((const));
size_t VPKGPBComputeUInt32Size(int32_t fieldNumber, uint32_t value) __attribute__((const));
size_t VPKGPBComputeSFixed32Size(int32_t fieldNumber, int32_t value) __attribute__((const));
size_t VPKGPBComputeSFixed64Size(int32_t fieldNumber, int64_t value) __attribute__((const));
size_t VPKGPBComputeSInt32Size(int32_t fieldNumber, int32_t value) __attribute__((const));
size_t VPKGPBComputeSInt64Size(int32_t fieldNumber, int64_t value) __attribute__((const));
size_t VPKGPBComputeTagSize(int32_t fieldNumber) __attribute__((const));
size_t VPKGPBComputeWireFormatTagSize(int field_number, VPKGPBDataType dataType) __attribute__((const));

size_t VPKGPBComputeDoubleSizeNoTag(double value) __attribute__((const));
size_t VPKGPBComputeFloatSizeNoTag(float value) __attribute__((const));
size_t VPKGPBComputeUInt64SizeNoTag(uint64_t value) __attribute__((const));
size_t VPKGPBComputeInt64SizeNoTag(int64_t value) __attribute__((const));
size_t VPKGPBComputeInt32SizeNoTag(int32_t value) __attribute__((const));
size_t VPKGPBComputeFixed64SizeNoTag(uint64_t value) __attribute__((const));
size_t VPKGPBComputeFixed32SizeNoTag(uint32_t value) __attribute__((const));
size_t VPKGPBComputeBoolSizeNoTag(BOOL value) __attribute__((const));
size_t VPKGPBComputeStringSizeNoTag(NSString *value) __attribute__((const));
size_t VPKGPBComputeGroupSizeNoTag(VPKGPBMessage *value) __attribute__((const));
size_t VPKGPBComputeUnknownGroupSizeNoTag(VPKGPBUnknownFieldSet *value) __attribute__((const));
size_t VPKGPBComputeMessageSizeNoTag(VPKGPBMessage *value) __attribute__((const));
size_t VPKGPBComputeBytesSizeNoTag(NSData *value) __attribute__((const));
size_t VPKGPBComputeUInt32SizeNoTag(int32_t value) __attribute__((const));
size_t VPKGPBComputeEnumSizeNoTag(int32_t value) __attribute__((const));
size_t VPKGPBComputeSFixed32SizeNoTag(int32_t value) __attribute__((const));
size_t VPKGPBComputeSFixed64SizeNoTag(int64_t value) __attribute__((const));
size_t VPKGPBComputeSInt32SizeNoTag(int32_t value) __attribute__((const));
size_t VPKGPBComputeSInt64SizeNoTag(int64_t value) __attribute__((const));

// Note that this will calculate the size of 64 bit values truncated to 32.
size_t VPKGPBComputeSizeTSizeAsInt32NoTag(size_t value) __attribute__((const));

size_t VPKGPBComputeRawVarint32Size(int32_t value) __attribute__((const));
size_t VPKGPBComputeRawVarint64Size(int64_t value) __attribute__((const));

// Note that this will calculate the size of 64 bit values truncated to 32.
size_t VPKGPBComputeRawVarint32SizeForInteger(NSInteger value) __attribute__((const));

// Compute the number of bytes that would be needed to encode a
// MessageSet extension to the stream.  For historical reasons,
// the wire format differs from normal fields.
size_t VPKGPBComputeMessageSetExtensionSize(int32_t fieldNumber, VPKGPBMessage *value)
    __attribute__((const));

// Compute the number of bytes that would be needed to encode an
// unparsed MessageSet extension field to the stream.  For
// historical reasons, the wire format differs from normal fields.
size_t VPKGPBComputeRawMessageSetExtensionSize(int32_t fieldNumber, NSData *value)
    __attribute__((const));

size_t VPKGPBComputeEnumSize(int32_t fieldNumber, int32_t value) __attribute__((const));

CF_EXTERN_C_END

NS_ASSUME_NONNULL_END
