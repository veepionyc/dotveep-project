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

#import "VPKGPBCodedOutputStream_PackagePrivate.h"

#import <mach/vm_param.h>

#import "VPKGPBArray.h"
#import "VPKGPBUnknownFieldSet_PackagePrivate.h"
#import "VPKGPBUtilities_PackagePrivate.h"

// These values are the existing values so as not to break any code that might
// have already been inspecting them when they weren't documented/exposed.
NSString *const VPKGPBCodedOutputStreamException_OutOfSpace = @"OutOfSpace";
NSString *const VPKGPBCodedOutputStreamException_WriteFailed = @"WriteFailed";

// Structure for containing state of a VPKGPBCodedInputStream. Brought out into
// a struct so that we can inline several common functions instead of dealing
// with overhead of ObjC dispatch.
typedef struct VPKGPBOutputBufferState {
  uint8_t *bytes;
  size_t size;
  size_t position;
  NSOutputStream *output;
} VPKGPBOutputBufferState;

@implementation VPKGPBCodedOutputStream {
  VPKGPBOutputBufferState state_;
  NSMutableData *buffer_;
}

static const int32_t LITTLE_ENDIAN_32_SIZE = sizeof(uint32_t);
static const int32_t LITTLE_ENDIAN_64_SIZE = sizeof(uint64_t);

// Internal helper that writes the current buffer to the output. The
// buffer position is reset to its initial value when this returns.
static void VPKGPBRefreshBuffer(VPKGPBOutputBufferState *state) {
  if (state->output == nil) {
    // We're writing to a single buffer.
    [NSException raise:VPKGPBCodedOutputStreamException_OutOfSpace format:@""];
  }
  if (state->position != 0) {
    NSInteger written = [state->output write:state->bytes maxLength:state->position];
    if (written != (NSInteger)state->position) {
      [NSException raise:VPKGPBCodedOutputStreamException_WriteFailed format:@""];
    }
    state->position = 0;
  }
}

static void VPKGPBWriteRawByte(VPKGPBOutputBufferState *state, uint8_t value) {
  if (state->position == state->size) {
    VPKGPBRefreshBuffer(state);
  }
  state->bytes[state->position++] = value;
}

static void VPKGPBWriteRawVarint32(VPKGPBOutputBufferState *state, int32_t value) {
  while (YES) {
    if ((value & ~0x7F) == 0) {
      uint8_t val = (uint8_t)value;
      VPKGPBWriteRawByte(state, val);
      return;
    } else {
      VPKGPBWriteRawByte(state, (value & 0x7F) | 0x80);
      value = VPKGPBLogicalRightShift32(value, 7);
    }
  }
}

static void VPKGPBWriteRawVarint64(VPKGPBOutputBufferState *state, int64_t value) {
  while (YES) {
    if ((value & ~0x7FL) == 0) {
      uint8_t val = (uint8_t)value;
      VPKGPBWriteRawByte(state, val);
      return;
    } else {
      VPKGPBWriteRawByte(state, ((int32_t)value & 0x7F) | 0x80);
      value = VPKGPBLogicalRightShift64(value, 7);
    }
  }
}

static void VPKGPBWriteInt32NoTag(VPKGPBOutputBufferState *state, int32_t value) {
  if (value >= 0) {
    VPKGPBWriteRawVarint32(state, value);
  } else {
    // Must sign-extend
    VPKGPBWriteRawVarint64(state, value);
  }
}

static void VPKGPBWriteUInt32(VPKGPBOutputBufferState *state, int32_t fieldNumber, uint32_t value) {
  VPKGPBWriteTagWithFormat(state, fieldNumber, VPKGPBWireFormatVarint);
  VPKGPBWriteRawVarint32(state, value);
}

static void VPKGPBWriteTagWithFormat(VPKGPBOutputBufferState *state, uint32_t fieldNumber,
                                  VPKGPBWireFormat format) {
  VPKGPBWriteRawVarint32(state, VPKGPBWireFormatMakeTag(fieldNumber, format));
}

static void VPKGPBWriteRawLittleEndian32(VPKGPBOutputBufferState *state, int32_t value) {
  VPKGPBWriteRawByte(state, (value)&0xFF);
  VPKGPBWriteRawByte(state, (value >> 8) & 0xFF);
  VPKGPBWriteRawByte(state, (value >> 16) & 0xFF);
  VPKGPBWriteRawByte(state, (value >> 24) & 0xFF);
}

static void VPKGPBWriteRawLittleEndian64(VPKGPBOutputBufferState *state, int64_t value) {
  VPKGPBWriteRawByte(state, (int32_t)(value)&0xFF);
  VPKGPBWriteRawByte(state, (int32_t)(value >> 8) & 0xFF);
  VPKGPBWriteRawByte(state, (int32_t)(value >> 16) & 0xFF);
  VPKGPBWriteRawByte(state, (int32_t)(value >> 24) & 0xFF);
  VPKGPBWriteRawByte(state, (int32_t)(value >> 32) & 0xFF);
  VPKGPBWriteRawByte(state, (int32_t)(value >> 40) & 0xFF);
  VPKGPBWriteRawByte(state, (int32_t)(value >> 48) & 0xFF);
  VPKGPBWriteRawByte(state, (int32_t)(value >> 56) & 0xFF);
}

- (void)dealloc {
  [self flush];
  [state_.output close];
  [state_.output release];
  [buffer_ release];

  [super dealloc];
}

- (instancetype)initWithOutputStream:(NSOutputStream *)output {
  NSMutableData *data = [NSMutableData dataWithLength:PAGE_SIZE];
  return [self initWithOutputStream:output data:data];
}

- (instancetype)initWithData:(NSMutableData *)data {
  return [self initWithOutputStream:nil data:data];
}

// This initializer isn't exposed, but it is the designated initializer.
// Setting OutputStream and NSData is to control the buffering behavior/size
// of the work, but that is more obvious via the bufferSize: version.
- (instancetype)initWithOutputStream:(NSOutputStream *)output data:(NSMutableData *)data {
  if ((self = [super init])) {
    buffer_ = [data retain];
    state_.bytes = [data mutableBytes];
    state_.size = [data length];
    state_.output = [output retain];
    [state_.output open];
  }
  return self;
}

+ (instancetype)streamWithOutputStream:(NSOutputStream *)output {
  NSMutableData *data = [NSMutableData dataWithLength:PAGE_SIZE];
  return [[[self alloc] initWithOutputStream:output data:data] autorelease];
}

+ (instancetype)streamWithData:(NSMutableData *)data {
  return [[[self alloc] initWithData:data] autorelease];
}

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (void)writeDoubleNoTag:(double)value {
  VPKGPBWriteRawLittleEndian64(&state_, VPKGPBConvertDoubleToInt64(value));
}

- (void)writeDouble:(int32_t)fieldNumber value:(double)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatFixed64);
  VPKGPBWriteRawLittleEndian64(&state_, VPKGPBConvertDoubleToInt64(value));
}

- (void)writeFloatNoTag:(float)value {
  VPKGPBWriteRawLittleEndian32(&state_, VPKGPBConvertFloatToInt32(value));
}

- (void)writeFloat:(int32_t)fieldNumber value:(float)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatFixed32);
  VPKGPBWriteRawLittleEndian32(&state_, VPKGPBConvertFloatToInt32(value));
}

- (void)writeUInt64NoTag:(uint64_t)value {
  VPKGPBWriteRawVarint64(&state_, value);
}

- (void)writeUInt64:(int32_t)fieldNumber value:(uint64_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatVarint);
  VPKGPBWriteRawVarint64(&state_, value);
}

- (void)writeInt64NoTag:(int64_t)value {
  VPKGPBWriteRawVarint64(&state_, value);
}

- (void)writeInt64:(int32_t)fieldNumber value:(int64_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatVarint);
  VPKGPBWriteRawVarint64(&state_, value);
}

- (void)writeInt32NoTag:(int32_t)value {
  VPKGPBWriteInt32NoTag(&state_, value);
}

- (void)writeInt32:(int32_t)fieldNumber value:(int32_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatVarint);
  VPKGPBWriteInt32NoTag(&state_, value);
}

- (void)writeFixed64NoTag:(uint64_t)value {
  VPKGPBWriteRawLittleEndian64(&state_, value);
}

- (void)writeFixed64:(int32_t)fieldNumber value:(uint64_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatFixed64);
  VPKGPBWriteRawLittleEndian64(&state_, value);
}

- (void)writeFixed32NoTag:(uint32_t)value {
  VPKGPBWriteRawLittleEndian32(&state_, value);
}

- (void)writeFixed32:(int32_t)fieldNumber value:(uint32_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatFixed32);
  VPKGPBWriteRawLittleEndian32(&state_, value);
}

- (void)writeBoolNoTag:(BOOL)value {
  VPKGPBWriteRawByte(&state_, (value ? 1 : 0));
}

- (void)writeBool:(int32_t)fieldNumber value:(BOOL)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatVarint);
  VPKGPBWriteRawByte(&state_, (value ? 1 : 0));
}

- (void)writeStringNoTag:(const NSString *)value {
  size_t length = [value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  VPKGPBWriteRawVarint32(&state_, (int32_t)length);
  if (length == 0) {
    return;
  }

  const char *quickString = CFStringGetCStringPtr((CFStringRef)value, kCFStringEncodingUTF8);

  // Fast path: Most strings are short, if the buffer already has space,
  // add to it directly.
  NSUInteger bufferBytesLeft = state_.size - state_.position;
  if (bufferBytesLeft >= length) {
    NSUInteger usedBufferLength = 0;
    BOOL result;
    if (quickString != NULL) {
      memcpy(state_.bytes + state_.position, quickString, length);
      usedBufferLength = length;
      result = YES;
    } else {
      result = [value getBytes:state_.bytes + state_.position
                     maxLength:bufferBytesLeft
                    usedLength:&usedBufferLength
                      encoding:NSUTF8StringEncoding
                       options:(NSStringEncodingConversionOptions)0
                         range:NSMakeRange(0, [value length])
                remainingRange:NULL];
    }
    if (result) {
      NSAssert2((usedBufferLength == length), @"Our UTF8 calc was wrong? %tu vs %zd",
                usedBufferLength, length);
      state_.position += usedBufferLength;
      return;
    }
  } else if (quickString != NULL) {
    [self writeRawPtr:quickString offset:0 length:length];
  } else {
    // Slow path: just get it as data and write it out.
    NSData *utf8Data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSAssert2(([utf8Data length] == length), @"Strings UTF8 length was wrong? %tu vs %zd",
              [utf8Data length], length);
    [self writeRawData:utf8Data];
  }
}

- (void)writeString:(int32_t)fieldNumber value:(NSString *)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatLengthDelimited);
  [self writeStringNoTag:value];
}

- (void)writeGroupNoTag:(int32_t)fieldNumber value:(VPKGPBMessage *)value {
  [value writeToCodedOutputStream:self];
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatEndGroup);
}

- (void)writeGroup:(int32_t)fieldNumber value:(VPKGPBMessage *)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatStartGroup);
  [self writeGroupNoTag:fieldNumber value:value];
}

- (void)writeUnknownGroupNoTag:(int32_t)fieldNumber value:(const VPKGPBUnknownFieldSet *)value {
  [value writeToCodedOutputStream:self];
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatEndGroup);
}

- (void)writeUnknownGroup:(int32_t)fieldNumber value:(VPKGPBUnknownFieldSet *)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatStartGroup);
  [self writeUnknownGroupNoTag:fieldNumber value:value];
}

- (void)writeMessageNoTag:(VPKGPBMessage *)value {
  VPKGPBWriteRawVarint32(&state_, (int32_t)[value serializedSize]);
  [value writeToCodedOutputStream:self];
}

- (void)writeMessage:(int32_t)fieldNumber value:(VPKGPBMessage *)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatLengthDelimited);
  [self writeMessageNoTag:value];
}

- (void)writeBytesNoTag:(NSData *)value {
  VPKGPBWriteRawVarint32(&state_, (int32_t)[value length]);
  [self writeRawData:value];
}

- (void)writeBytes:(int32_t)fieldNumber value:(NSData *)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatLengthDelimited);
  [self writeBytesNoTag:value];
}

- (void)writeUInt32NoTag:(uint32_t)value {
  VPKGPBWriteRawVarint32(&state_, value);
}

- (void)writeUInt32:(int32_t)fieldNumber value:(uint32_t)value {
  VPKGPBWriteUInt32(&state_, fieldNumber, value);
}

- (void)writeEnumNoTag:(int32_t)value {
  VPKGPBWriteInt32NoTag(&state_, value);
}

- (void)writeEnum:(int32_t)fieldNumber value:(int32_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatVarint);
  VPKGPBWriteInt32NoTag(&state_, value);
}

- (void)writeSFixed32NoTag:(int32_t)value {
  VPKGPBWriteRawLittleEndian32(&state_, value);
}

- (void)writeSFixed32:(int32_t)fieldNumber value:(int32_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatFixed32);
  VPKGPBWriteRawLittleEndian32(&state_, value);
}

- (void)writeSFixed64NoTag:(int64_t)value {
  VPKGPBWriteRawLittleEndian64(&state_, value);
}

- (void)writeSFixed64:(int32_t)fieldNumber value:(int64_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatFixed64);
  VPKGPBWriteRawLittleEndian64(&state_, value);
}

- (void)writeSInt32NoTag:(int32_t)value {
  VPKGPBWriteRawVarint32(&state_, VPKGPBEncodeZigZag32(value));
}

- (void)writeSInt32:(int32_t)fieldNumber value:(int32_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatVarint);
  VPKGPBWriteRawVarint32(&state_, VPKGPBEncodeZigZag32(value));
}

- (void)writeSInt64NoTag:(int64_t)value {
  VPKGPBWriteRawVarint64(&state_, VPKGPBEncodeZigZag64(value));
}

- (void)writeSInt64:(int32_t)fieldNumber value:(int64_t)value {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, VPKGPBWireFormatVarint);
  VPKGPBWriteRawVarint64(&state_, VPKGPBEncodeZigZag64(value));
}

// clang-format off

//%PDDM-DEFINE WRITE_PACKABLE_DEFNS(NAME, ARRAY_TYPE, TYPE, ACCESSOR_NAME)
//%- (void)write##NAME##Array:(int32_t)fieldNumber
//%       NAME$S     values:(VPKGPB##ARRAY_TYPE##Array *)values
//%       NAME$S        tag:(uint32_t)tag {
//%  if (tag != 0) {
//%    if (values.count == 0) return;
//%    __block size_t dataSize = 0;
//%    [values enumerate##ACCESSOR_NAME##ValuesWithBlock:^(TYPE value, __unused NSUInteger idx,__unused  BOOL *stop) {
//%      dataSize += VPKGPBCompute##NAME##SizeNoTag(value);
//%    }];
//%    VPKGPBWriteRawVarint32(&state_, tag);
//%    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
//%    [values enumerate##ACCESSOR_NAME##ValuesWithBlock:^(TYPE value, __unused NSUInteger idx, __unused BOOL *stop) {
//%      [self write##NAME##NoTag:value];
//%    }];
//%  } else {
//%    [values enumerate##ACCESSOR_NAME##ValuesWithBlock:^(TYPE value, __unused NSUInteger idx, __unused BOOL *stop) {
//%      [self write##NAME:fieldNumber value:value];
//%    }];
//%  }
//%}
//%
//%PDDM-DEFINE WRITE_UNPACKABLE_DEFNS(NAME, TYPE)
//%- (void)write##NAME##Array:(int32_t)fieldNumber values:(NSArray *)values {
//%  for (TYPE *value in values) {
//%    [self write##NAME:fieldNumber value:value];
//%  }
//%}
//%
//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(Double, Double, double, )
// This block of code is generated, do not edit it directly.

- (void)writeDoubleArray:(int32_t)fieldNumber
                  values:(VPKGPBDoubleArray *)values
                     tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(double value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeDoubleSizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(double value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeDoubleNoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(double value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeDouble:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(Float, Float, float, )
// This block of code is generated, do not edit it directly.

- (void)writeFloatArray:(int32_t)fieldNumber
                 values:(VPKGPBFloatArray *)values
                    tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(float value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeFloatSizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(float value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeFloatNoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(float value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeFloat:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(UInt64, UInt64, uint64_t, )
// This block of code is generated, do not edit it directly.

- (void)writeUInt64Array:(int32_t)fieldNumber
                  values:(VPKGPBUInt64Array *)values
                     tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(uint64_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeUInt64SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(uint64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeUInt64NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(uint64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeUInt64:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(Int64, Int64, int64_t, )
// This block of code is generated, do not edit it directly.

- (void)writeInt64Array:(int32_t)fieldNumber
                 values:(VPKGPBInt64Array *)values
                    tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeInt64SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeInt64NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeInt64:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(Int32, Int32, int32_t, )
// This block of code is generated, do not edit it directly.

- (void)writeInt32Array:(int32_t)fieldNumber
                 values:(VPKGPBInt32Array *)values
                    tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeInt32SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeInt32NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeInt32:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(UInt32, UInt32, uint32_t, )
// This block of code is generated, do not edit it directly.

- (void)writeUInt32Array:(int32_t)fieldNumber
                  values:(VPKGPBUInt32Array *)values
                     tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(uint32_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeUInt32SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(uint32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeUInt32NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(uint32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeUInt32:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(Fixed64, UInt64, uint64_t, )
// This block of code is generated, do not edit it directly.

- (void)writeFixed64Array:(int32_t)fieldNumber
                   values:(VPKGPBUInt64Array *)values
                      tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(uint64_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeFixed64SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(uint64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeFixed64NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(uint64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeFixed64:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(Fixed32, UInt32, uint32_t, )
// This block of code is generated, do not edit it directly.

- (void)writeFixed32Array:(int32_t)fieldNumber
                   values:(VPKGPBUInt32Array *)values
                      tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(uint32_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeFixed32SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(uint32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeFixed32NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(uint32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeFixed32:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(SInt32, Int32, int32_t, )
// This block of code is generated, do not edit it directly.

- (void)writeSInt32Array:(int32_t)fieldNumber
                  values:(VPKGPBInt32Array *)values
                     tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeSInt32SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeSInt32NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeSInt32:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(SInt64, Int64, int64_t, )
// This block of code is generated, do not edit it directly.

- (void)writeSInt64Array:(int32_t)fieldNumber
                  values:(VPKGPBInt64Array *)values
                     tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeSInt64SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeSInt64NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeSInt64:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(SFixed64, Int64, int64_t, )
// This block of code is generated, do not edit it directly.

- (void)writeSFixed64Array:(int32_t)fieldNumber
                    values:(VPKGPBInt64Array *)values
                       tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeSFixed64SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeSFixed64NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(int64_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeSFixed64:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(SFixed32, Int32, int32_t, )
// This block of code is generated, do not edit it directly.

- (void)writeSFixed32Array:(int32_t)fieldNumber
                    values:(VPKGPBInt32Array *)values
                       tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeSFixed32SizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeSFixed32NoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(int32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeSFixed32:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(Bool, Bool, BOOL, )
// This block of code is generated, do not edit it directly.

- (void)writeBoolArray:(int32_t)fieldNumber
                values:(VPKGPBBoolArray *)values
                   tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateValuesWithBlock:^(BOOL value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeBoolSizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateValuesWithBlock:^(BOOL value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeBoolNoTag:value];
    }];
  } else {
    [values enumerateValuesWithBlock:^(BOOL value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeBool:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_PACKABLE_DEFNS(Enum, Enum, int32_t, Raw)
// This block of code is generated, do not edit it directly.

- (void)writeEnumArray:(int32_t)fieldNumber
                values:(VPKGPBEnumArray *)values
                   tag:(uint32_t)tag {
  if (tag != 0) {
    if (values.count == 0) return;
    __block size_t dataSize = 0;
    [values enumerateRawValuesWithBlock:^(int32_t value, __unused NSUInteger idx,__unused  BOOL *stop) {
      dataSize += VPKGPBComputeEnumSizeNoTag(value);
    }];
    VPKGPBWriteRawVarint32(&state_, tag);
    VPKGPBWriteRawVarint32(&state_, (int32_t)dataSize);
    [values enumerateRawValuesWithBlock:^(int32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeEnumNoTag:value];
    }];
  } else {
    [values enumerateRawValuesWithBlock:^(int32_t value, __unused NSUInteger idx, __unused BOOL *stop) {
      [self writeEnum:fieldNumber value:value];
    }];
  }
}

//%PDDM-EXPAND WRITE_UNPACKABLE_DEFNS(String, NSString)
// This block of code is generated, do not edit it directly.

- (void)writeStringArray:(int32_t)fieldNumber values:(NSArray *)values {
  for (NSString *value in values) {
    [self writeString:fieldNumber value:value];
  }
}

//%PDDM-EXPAND WRITE_UNPACKABLE_DEFNS(Message, VPKGPBMessage)
// This block of code is generated, do not edit it directly.

- (void)writeMessageArray:(int32_t)fieldNumber values:(NSArray *)values {
  for (VPKGPBMessage *value in values) {
    [self writeMessage:fieldNumber value:value];
  }
}

//%PDDM-EXPAND WRITE_UNPACKABLE_DEFNS(Bytes, NSData)
// This block of code is generated, do not edit it directly.

- (void)writeBytesArray:(int32_t)fieldNumber values:(NSArray *)values {
  for (NSData *value in values) {
    [self writeBytes:fieldNumber value:value];
  }
}

//%PDDM-EXPAND WRITE_UNPACKABLE_DEFNS(Group, VPKGPBMessage)
// This block of code is generated, do not edit it directly.

- (void)writeGroupArray:(int32_t)fieldNumber values:(NSArray *)values {
  for (VPKGPBMessage *value in values) {
    [self writeGroup:fieldNumber value:value];
  }
}

//%PDDM-EXPAND WRITE_UNPACKABLE_DEFNS(UnknownGroup, VPKGPBUnknownFieldSet)
// This block of code is generated, do not edit it directly.

- (void)writeUnknownGroupArray:(int32_t)fieldNumber values:(NSArray *)values {
  for (VPKGPBUnknownFieldSet *value in values) {
    [self writeUnknownGroup:fieldNumber value:value];
  }
}

//%PDDM-EXPAND-END (19 expansions)

// clang-format on

- (void)writeMessageSetExtension:(int32_t)fieldNumber value:(VPKGPBMessage *)value {
  VPKGPBWriteTagWithFormat(&state_, VPKGPBWireFormatMessageSetItem, VPKGPBWireFormatStartGroup);
  VPKGPBWriteUInt32(&state_, VPKGPBWireFormatMessageSetTypeId, fieldNumber);
  [self writeMessage:VPKGPBWireFormatMessageSetMessage value:value];
  VPKGPBWriteTagWithFormat(&state_, VPKGPBWireFormatMessageSetItem, VPKGPBWireFormatEndGroup);
}

- (void)writeRawMessageSetExtension:(int32_t)fieldNumber value:(NSData *)value {
  VPKGPBWriteTagWithFormat(&state_, VPKGPBWireFormatMessageSetItem, VPKGPBWireFormatStartGroup);
  VPKGPBWriteUInt32(&state_, VPKGPBWireFormatMessageSetTypeId, fieldNumber);
  [self writeBytes:VPKGPBWireFormatMessageSetMessage value:value];
  VPKGPBWriteTagWithFormat(&state_, VPKGPBWireFormatMessageSetItem, VPKGPBWireFormatEndGroup);
}

- (void)flush {
  if (state_.output != nil) {
    VPKGPBRefreshBuffer(&state_);
  }
}

- (void)writeRawByte:(uint8_t)value {
  VPKGPBWriteRawByte(&state_, value);
}

- (void)writeRawData:(const NSData *)data {
  [self writeRawPtr:[data bytes] offset:0 length:[data length]];
}

- (void)writeRawPtr:(const void *)value offset:(size_t)offset length:(size_t)length {
  if (value == nil || length == 0) {
    return;
  }

  NSUInteger bufferLength = state_.size;
  NSUInteger bufferBytesLeft = bufferLength - state_.position;
  if (bufferBytesLeft >= length) {
    // We have room in the current buffer.
    memcpy(state_.bytes + state_.position, ((uint8_t *)value) + offset, length);
    state_.position += length;
  } else {
    // Write extends past current buffer.  Fill the rest of this buffer and
    // flush.
    size_t bytesWritten = bufferBytesLeft;
    memcpy(state_.bytes + state_.position, ((uint8_t *)value) + offset, bytesWritten);
    offset += bytesWritten;
    length -= bytesWritten;
    state_.position = bufferLength;
    VPKGPBRefreshBuffer(&state_);
    bufferLength = state_.size;

    // Now deal with the rest.
    // Since we have an output stream, this is our buffer
    // and buffer offset == 0
    if (length <= bufferLength) {
      // Fits in new buffer.
      memcpy(state_.bytes, ((uint8_t *)value) + offset, length);
      state_.position = length;
    } else {
      // Write is very big.  Let's do it all at once.
      NSInteger written = [state_.output write:((uint8_t *)value) + offset maxLength:length];
      if (written != (NSInteger)length) {
        [NSException raise:VPKGPBCodedOutputStreamException_WriteFailed format:@""];
      }
    }
  }
}

- (void)writeTag:(uint32_t)fieldNumber format:(VPKGPBWireFormat)format {
  VPKGPBWriteTagWithFormat(&state_, fieldNumber, format);
}

- (void)writeRawVarint32:(int32_t)value {
  VPKGPBWriteRawVarint32(&state_, value);
}

- (void)writeRawVarintSizeTAs32:(size_t)value {
  // Note the truncation.
  VPKGPBWriteRawVarint32(&state_, (int32_t)value);
}

- (void)writeRawVarint64:(int64_t)value {
  VPKGPBWriteRawVarint64(&state_, value);
}

- (void)writeRawLittleEndian32:(int32_t)value {
  VPKGPBWriteRawLittleEndian32(&state_, value);
}

- (void)writeRawLittleEndian64:(int64_t)value {
  VPKGPBWriteRawLittleEndian64(&state_, value);
}

#pragma clang diagnostic pop

@end

size_t VPKGPBComputeDoubleSizeNoTag(__unused Float64 value) { return LITTLE_ENDIAN_64_SIZE; }

size_t VPKGPBComputeFloatSizeNoTag(__unused Float32 value) { return LITTLE_ENDIAN_32_SIZE; }

size_t VPKGPBComputeUInt64SizeNoTag(uint64_t value) { return VPKGPBComputeRawVarint64Size(value); }

size_t VPKGPBComputeInt64SizeNoTag(int64_t value) { return VPKGPBComputeRawVarint64Size(value); }

size_t VPKGPBComputeInt32SizeNoTag(int32_t value) {
  if (value >= 0) {
    return VPKGPBComputeRawVarint32Size(value);
  } else {
    // Must sign-extend.
    return 10;
  }
}

size_t VPKGPBComputeSizeTSizeAsInt32NoTag(size_t value) {
  return VPKGPBComputeInt32SizeNoTag((int32_t)value);
}

size_t VPKGPBComputeFixed64SizeNoTag(__unused uint64_t value) { return LITTLE_ENDIAN_64_SIZE; }

size_t VPKGPBComputeFixed32SizeNoTag(__unused uint32_t value) { return LITTLE_ENDIAN_32_SIZE; }

size_t VPKGPBComputeBoolSizeNoTag(__unused BOOL value) { return 1; }

size_t VPKGPBComputeStringSizeNoTag(NSString *value) {
  NSUInteger length = [value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  return VPKGPBComputeRawVarint32SizeForInteger(length) + length;
}

size_t VPKGPBComputeGroupSizeNoTag(VPKGPBMessage *value) { return [value serializedSize]; }

size_t VPKGPBComputeUnknownGroupSizeNoTag(VPKGPBUnknownFieldSet *value) { return value.serializedSize; }

size_t VPKGPBComputeMessageSizeNoTag(VPKGPBMessage *value) {
  size_t size = [value serializedSize];
  return VPKGPBComputeRawVarint32SizeForInteger(size) + size;
}

size_t VPKGPBComputeBytesSizeNoTag(NSData *value) {
  NSUInteger valueLength = [value length];
  return VPKGPBComputeRawVarint32SizeForInteger(valueLength) + valueLength;
}

size_t VPKGPBComputeUInt32SizeNoTag(int32_t value) { return VPKGPBComputeRawVarint32Size(value); }

size_t VPKGPBComputeEnumSizeNoTag(int32_t value) { return VPKGPBComputeInt32SizeNoTag(value); }

size_t VPKGPBComputeSFixed32SizeNoTag(__unused int32_t value) { return LITTLE_ENDIAN_32_SIZE; }

size_t VPKGPBComputeSFixed64SizeNoTag(__unused int64_t value) { return LITTLE_ENDIAN_64_SIZE; }

size_t VPKGPBComputeSInt32SizeNoTag(int32_t value) {
  return VPKGPBComputeRawVarint32Size(VPKGPBEncodeZigZag32(value));
}

size_t VPKGPBComputeSInt64SizeNoTag(int64_t value) {
  return VPKGPBComputeRawVarint64Size(VPKGPBEncodeZigZag64(value));
}

size_t VPKGPBComputeDoubleSize(int32_t fieldNumber, double value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeDoubleSizeNoTag(value);
}

size_t VPKGPBComputeFloatSize(int32_t fieldNumber, float value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeFloatSizeNoTag(value);
}

size_t VPKGPBComputeUInt64Size(int32_t fieldNumber, uint64_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeUInt64SizeNoTag(value);
}

size_t VPKGPBComputeInt64Size(int32_t fieldNumber, int64_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeInt64SizeNoTag(value);
}

size_t VPKGPBComputeInt32Size(int32_t fieldNumber, int32_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeInt32SizeNoTag(value);
}

size_t VPKGPBComputeFixed64Size(int32_t fieldNumber, uint64_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeFixed64SizeNoTag(value);
}

size_t VPKGPBComputeFixed32Size(int32_t fieldNumber, uint32_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeFixed32SizeNoTag(value);
}

size_t VPKGPBComputeBoolSize(int32_t fieldNumber, BOOL value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeBoolSizeNoTag(value);
}

size_t VPKGPBComputeStringSize(int32_t fieldNumber, NSString *value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeStringSizeNoTag(value);
}

size_t VPKGPBComputeGroupSize(int32_t fieldNumber, VPKGPBMessage *value) {
  return VPKGPBComputeTagSize(fieldNumber) * 2 + VPKGPBComputeGroupSizeNoTag(value);
}

size_t VPKGPBComputeUnknownGroupSize(int32_t fieldNumber, VPKGPBUnknownFieldSet *value) {
  return VPKGPBComputeTagSize(fieldNumber) * 2 + VPKGPBComputeUnknownGroupSizeNoTag(value);
}

size_t VPKGPBComputeMessageSize(int32_t fieldNumber, VPKGPBMessage *value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeMessageSizeNoTag(value);
}

size_t VPKGPBComputeBytesSize(int32_t fieldNumber, NSData *value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeBytesSizeNoTag(value);
}

size_t VPKGPBComputeUInt32Size(int32_t fieldNumber, uint32_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeUInt32SizeNoTag(value);
}

size_t VPKGPBComputeEnumSize(int32_t fieldNumber, int32_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeEnumSizeNoTag(value);
}

size_t VPKGPBComputeSFixed32Size(int32_t fieldNumber, int32_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeSFixed32SizeNoTag(value);
}

size_t VPKGPBComputeSFixed64Size(int32_t fieldNumber, int64_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeSFixed64SizeNoTag(value);
}

size_t VPKGPBComputeSInt32Size(int32_t fieldNumber, int32_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeSInt32SizeNoTag(value);
}

size_t VPKGPBComputeSInt64Size(int32_t fieldNumber, int64_t value) {
  return VPKGPBComputeTagSize(fieldNumber) + VPKGPBComputeRawVarint64Size(VPKGPBEncodeZigZag64(value));
}

size_t VPKGPBComputeMessageSetExtensionSize(int32_t fieldNumber, VPKGPBMessage *value) {
  return VPKGPBComputeTagSize(VPKGPBWireFormatMessageSetItem) * 2 +
         VPKGPBComputeUInt32Size(VPKGPBWireFormatMessageSetTypeId, fieldNumber) +
         VPKGPBComputeMessageSize(VPKGPBWireFormatMessageSetMessage, value);
}

size_t VPKGPBComputeRawMessageSetExtensionSize(int32_t fieldNumber, NSData *value) {
  return VPKGPBComputeTagSize(VPKGPBWireFormatMessageSetItem) * 2 +
         VPKGPBComputeUInt32Size(VPKGPBWireFormatMessageSetTypeId, fieldNumber) +
         VPKGPBComputeBytesSize(VPKGPBWireFormatMessageSetMessage, value);
}

size_t VPKGPBComputeTagSize(int32_t fieldNumber) {
  return VPKGPBComputeRawVarint32Size(VPKGPBWireFormatMakeTag(fieldNumber, VPKGPBWireFormatVarint));
}

size_t VPKGPBComputeWireFormatTagSize(int field_number, VPKGPBDataType dataType) {
  size_t result = VPKGPBComputeTagSize(field_number);
  if (dataType == VPKGPBDataTypeGroup) {
    // Groups have both a start and an end tag.
    return result * 2;
  } else {
    return result;
  }
}

size_t VPKGPBComputeRawVarint32Size(int32_t value) {
  // value is treated as unsigned, so it won't be sign-extended if negative.
  if ((value & (0xffffffff << 7)) == 0) return 1;
  if ((value & (0xffffffff << 14)) == 0) return 2;
  if ((value & (0xffffffff << 21)) == 0) return 3;
  if ((value & (0xffffffff << 28)) == 0) return 4;
  return 5;
}

size_t VPKGPBComputeRawVarint32SizeForInteger(NSInteger value) {
  // Note the truncation.
  return VPKGPBComputeRawVarint32Size((int32_t)value);
}

size_t VPKGPBComputeRawVarint64Size(int64_t value) {
  if ((value & (0xffffffffffffffffL << 7)) == 0) return 1;
  if ((value & (0xffffffffffffffffL << 14)) == 0) return 2;
  if ((value & (0xffffffffffffffffL << 21)) == 0) return 3;
  if ((value & (0xffffffffffffffffL << 28)) == 0) return 4;
  if ((value & (0xffffffffffffffffL << 35)) == 0) return 5;
  if ((value & (0xffffffffffffffffL << 42)) == 0) return 6;
  if ((value & (0xffffffffffffffffL << 49)) == 0) return 7;
  if ((value & (0xffffffffffffffffL << 56)) == 0) return 8;
  if ((value & (0xffffffffffffffffL << 63)) == 0) return 9;
  return 10;
}
