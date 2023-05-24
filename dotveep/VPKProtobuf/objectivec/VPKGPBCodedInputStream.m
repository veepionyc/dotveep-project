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

#import "VPKGPBCodedInputStream_PackagePrivate.h"

#import "VPKGPBDictionary_PackagePrivate.h"
#import "VPKGPBMessage_PackagePrivate.h"
#import "VPKGPBUnknownFieldSet_PackagePrivate.h"
#import "VPKGPBUtilities_PackagePrivate.h"
#import "VPKGPBWireFormat.h"

NSString *const VPKGPBCodedInputStreamException = VPKGPBNSStringifySymbol(VPKGPBCodedInputStreamException);

NSString *const VPKGPBCodedInputStreamUnderlyingErrorKey =
    VPKGPBNSStringifySymbol(VPKGPBCodedInputStreamUnderlyingErrorKey);

NSString *const VPKGPBCodedInputStreamErrorDomain =
    VPKGPBNSStringifySymbol(VPKGPBCodedInputStreamErrorDomain);

// Matching:
// https://github.com/protocolbuffers/protobuf/blob/main/java/core/src/main/java/com/google/protobuf/CodedInputStream.java#L62
//  private static final int DEFAULT_RECURSION_LIMIT = 100;
// https://github.com/protocolbuffers/protobuf/blob/main/src/google/protobuf/io/coded_stream.cc#L86
//  int CodedInputStream::default_recursion_limit_ = 100;
static const NSUInteger kDefaultRecursionLimit = 100;

static void RaiseException(NSInteger code, NSString *reason) {
  NSDictionary *errorInfo = nil;
  if ([reason length]) {
    errorInfo = @{VPKGPBErrorReasonKey : reason};
  }
  NSError *error = [NSError errorWithDomain:VPKGPBCodedInputStreamErrorDomain
                                       code:code
                                   userInfo:errorInfo];

  NSDictionary *exceptionInfo = @{VPKGPBCodedInputStreamUnderlyingErrorKey : error};
  [[NSException exceptionWithName:VPKGPBCodedInputStreamException reason:reason
                         userInfo:exceptionInfo] raise];
}

static void CheckRecursionLimit(VPKGPBCodedInputStreamState *state) {
  if (state->recursionDepth >= kDefaultRecursionLimit) {
    RaiseException(VPKGPBCodedInputStreamErrorRecursionDepthExceeded, nil);
  }
}

static void CheckSize(VPKGPBCodedInputStreamState *state, size_t size) {
  size_t newSize = state->bufferPos + size;
  if (newSize > state->bufferSize) {
    RaiseException(VPKGPBCodedInputStreamErrorInvalidSize, nil);
  }
  if (newSize > state->currentLimit) {
    // Fast forward to end of currentLimit;
    state->bufferPos = state->currentLimit;
    RaiseException(VPKGPBCodedInputStreamErrorSubsectionLimitReached, nil);
  }
}

static int8_t ReadRawByte(VPKGPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int8_t));
  return ((int8_t *)state->bytes)[state->bufferPos++];
}

static int32_t ReadRawLittleEndian32(VPKGPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int32_t));
  // Not using OSReadLittleInt32 because it has undocumented dependency
  // on reads being aligned.
  int32_t value;
  memcpy(&value, state->bytes + state->bufferPos, sizeof(int32_t));
  value = OSSwapLittleToHostInt32(value);
  state->bufferPos += sizeof(int32_t);
  return value;
}

static int64_t ReadRawLittleEndian64(VPKGPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int64_t));
  // Not using OSReadLittleInt64 because it has undocumented dependency
  // on reads being aligned.
  int64_t value;
  memcpy(&value, state->bytes + state->bufferPos, sizeof(int64_t));
  value = OSSwapLittleToHostInt64(value);
  state->bufferPos += sizeof(int64_t);
  return value;
}

static int64_t ReadRawVarint64(VPKGPBCodedInputStreamState *state) {
  int32_t shift = 0;
  int64_t result = 0;
  while (shift < 64) {
    int8_t b = ReadRawByte(state);
    result |= (int64_t)((uint64_t)(b & 0x7F) << shift);
    if ((b & 0x80) == 0) {
      return result;
    }
    shift += 7;
  }
  RaiseException(VPKGPBCodedInputStreamErrorInvalidVarInt, @"Invalid VarInt64");
  return 0;
}

static int32_t ReadRawVarint32(VPKGPBCodedInputStreamState *state) {
  return (int32_t)ReadRawVarint64(state);
}

static void SkipRawData(VPKGPBCodedInputStreamState *state, size_t size) {
  CheckSize(state, size);
  state->bufferPos += size;
}

double VPKGPBCodedInputStreamReadDouble(VPKGPBCodedInputStreamState *state) {
  int64_t value = ReadRawLittleEndian64(state);
  return VPKGPBConvertInt64ToDouble(value);
}

float VPKGPBCodedInputStreamReadFloat(VPKGPBCodedInputStreamState *state) {
  int32_t value = ReadRawLittleEndian32(state);
  return VPKGPBConvertInt32ToFloat(value);
}

uint64_t VPKGPBCodedInputStreamReadUInt64(VPKGPBCodedInputStreamState *state) {
  uint64_t value = ReadRawVarint64(state);
  return value;
}

uint32_t VPKGPBCodedInputStreamReadUInt32(VPKGPBCodedInputStreamState *state) {
  uint32_t value = ReadRawVarint32(state);
  return value;
}

int64_t VPKGPBCodedInputStreamReadInt64(VPKGPBCodedInputStreamState *state) {
  int64_t value = ReadRawVarint64(state);
  return value;
}

int32_t VPKGPBCodedInputStreamReadInt32(VPKGPBCodedInputStreamState *state) {
  int32_t value = ReadRawVarint32(state);
  return value;
}

uint64_t VPKGPBCodedInputStreamReadFixed64(VPKGPBCodedInputStreamState *state) {
  uint64_t value = ReadRawLittleEndian64(state);
  return value;
}

uint32_t VPKGPBCodedInputStreamReadFixed32(VPKGPBCodedInputStreamState *state) {
  uint32_t value = ReadRawLittleEndian32(state);
  return value;
}

int32_t VPKGPBCodedInputStreamReadEnum(VPKGPBCodedInputStreamState *state) {
  int32_t value = ReadRawVarint32(state);
  return value;
}

int32_t VPKGPBCodedInputStreamReadSFixed32(VPKGPBCodedInputStreamState *state) {
  int32_t value = ReadRawLittleEndian32(state);
  return value;
}

int64_t VPKGPBCodedInputStreamReadSFixed64(VPKGPBCodedInputStreamState *state) {
  int64_t value = ReadRawLittleEndian64(state);
  return value;
}

int32_t VPKGPBCodedInputStreamReadSInt32(VPKGPBCodedInputStreamState *state) {
  int32_t value = VPKGPBDecodeZigZag32(ReadRawVarint32(state));
  return value;
}

int64_t VPKGPBCodedInputStreamReadSInt64(VPKGPBCodedInputStreamState *state) {
  int64_t value = VPKGPBDecodeZigZag64(ReadRawVarint64(state));
  return value;
}

BOOL VPKGPBCodedInputStreamReadBool(VPKGPBCodedInputStreamState *state) {
  return ReadRawVarint64(state) != 0;
}

int32_t VPKGPBCodedInputStreamReadTag(VPKGPBCodedInputStreamState *state) {
  if (VPKGPBCodedInputStreamIsAtEnd(state)) {
    state->lastTag = 0;
    return 0;
  }

  state->lastTag = ReadRawVarint32(state);
  // Tags have to include a valid wireformat.
  if (!VPKGPBWireFormatIsValidTag(state->lastTag)) {
    RaiseException(VPKGPBCodedInputStreamErrorInvalidTag, @"Invalid wireformat in tag.");
  }
  // Zero is not a valid field number.
  if (VPKGPBWireFormatGetTagFieldNumber(state->lastTag) == 0) {
    RaiseException(VPKGPBCodedInputStreamErrorInvalidTag,
                   @"A zero field number on the wire is invalid.");
  }
  return state->lastTag;
}

NSString *VPKGPBCodedInputStreamReadRetainedString(VPKGPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  NSString *result;
  if (size == 0) {
    result = @"";
  } else {
    CheckSize(state, size);
    result = [[NSString alloc] initWithBytes:&state->bytes[state->bufferPos]
                                      length:size
                                    encoding:NSUTF8StringEncoding];
    state->bufferPos += size;
    if (!result) {
#ifdef DEBUG
      // https://developers.google.com/protocol-buffers/docs/proto#scalar
      NSLog(@"UTF-8 failure, is some field type 'string' when it should be "
            @"'bytes'?");
#endif
      RaiseException(VPKGPBCodedInputStreamErrorInvalidUTF8, nil);
    }
  }
  return result;
}

NSData *VPKGPBCodedInputStreamReadRetainedBytes(VPKGPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  if (size < 0) return nil;
  CheckSize(state, size);
  NSData *result = [[NSData alloc] initWithBytes:state->bytes + state->bufferPos length:size];
  state->bufferPos += size;
  return result;
}

NSData *VPKGPBCodedInputStreamReadRetainedBytesNoCopy(VPKGPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  if (size < 0) return nil;
  CheckSize(state, size);
  // Cast is safe because freeWhenDone is NO.
  NSData *result = [[NSData alloc] initWithBytesNoCopy:(void *)(state->bytes + state->bufferPos)
                                                length:size
                                          freeWhenDone:NO];
  state->bufferPos += size;
  return result;
}

size_t VPKGPBCodedInputStreamPushLimit(VPKGPBCodedInputStreamState *state, size_t byteLimit) {
  byteLimit += state->bufferPos;
  size_t oldLimit = state->currentLimit;
  if (byteLimit > oldLimit) {
    RaiseException(VPKGPBCodedInputStreamErrorInvalidSubsectionLimit, nil);
  }
  state->currentLimit = byteLimit;
  return oldLimit;
}

void VPKGPBCodedInputStreamPopLimit(VPKGPBCodedInputStreamState *state, size_t oldLimit) {
  state->currentLimit = oldLimit;
}

size_t VPKGPBCodedInputStreamBytesUntilLimit(VPKGPBCodedInputStreamState *state) {
  return state->currentLimit - state->bufferPos;
}

BOOL VPKGPBCodedInputStreamIsAtEnd(VPKGPBCodedInputStreamState *state) {
  return (state->bufferPos == state->bufferSize) || (state->bufferPos == state->currentLimit);
}

void VPKGPBCodedInputStreamCheckLastTagWas(VPKGPBCodedInputStreamState *state, int32_t value) {
  if (state->lastTag != value) {
    RaiseException(VPKGPBCodedInputStreamErrorInvalidTag, @"Unexpected tag read");
  }
}

@implementation VPKGPBCodedInputStream

+ (instancetype)streamWithData:(NSData *)data {
  return [[[self alloc] initWithData:data] autorelease];
}

- (instancetype)initWithData:(NSData *)data {
  if ((self = [super init])) {
#ifdef DEBUG
    NSCAssert([self class] == [VPKGPBCodedInputStream class],
              @"Subclassing of VPKGPBCodedInputStream is not allowed.");
#endif
    buffer_ = [data retain];
    state_.bytes = (const uint8_t *)[data bytes];
    state_.bufferSize = [data length];
    state_.currentLimit = state_.bufferSize;
  }
  return self;
}

- (void)dealloc {
  [buffer_ release];
  [super dealloc];
}

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (int32_t)readTag {
  return VPKGPBCodedInputStreamReadTag(&state_);
}

- (void)checkLastTagWas:(int32_t)value {
  VPKGPBCodedInputStreamCheckLastTagWas(&state_, value);
}

- (BOOL)skipField:(int32_t)tag {
  NSAssert(VPKGPBWireFormatIsValidTag(tag), @"Invalid tag");
  switch (VPKGPBWireFormatGetTagWireType(tag)) {
    case VPKGPBWireFormatVarint:
      VPKGPBCodedInputStreamReadInt32(&state_);
      return YES;
    case VPKGPBWireFormatFixed64:
      SkipRawData(&state_, sizeof(int64_t));
      return YES;
    case VPKGPBWireFormatLengthDelimited:
      SkipRawData(&state_, ReadRawVarint32(&state_));
      return YES;
    case VPKGPBWireFormatStartGroup:
      [self skipMessage];
      VPKGPBCodedInputStreamCheckLastTagWas(
          &state_,
          VPKGPBWireFormatMakeTag(VPKGPBWireFormatGetTagFieldNumber(tag), VPKGPBWireFormatEndGroup));
      return YES;
    case VPKGPBWireFormatEndGroup:
      return NO;
    case VPKGPBWireFormatFixed32:
      SkipRawData(&state_, sizeof(int32_t));
      return YES;
  }
}

- (void)skipMessage {
  while (YES) {
    int32_t tag = VPKGPBCodedInputStreamReadTag(&state_);
    if (tag == 0 || ![self skipField:tag]) {
      return;
    }
  }
}

- (BOOL)isAtEnd {
  return VPKGPBCodedInputStreamIsAtEnd(&state_);
}

- (size_t)position {
  return state_.bufferPos;
}

- (size_t)pushLimit:(size_t)byteLimit {
  return VPKGPBCodedInputStreamPushLimit(&state_, byteLimit);
}

- (void)popLimit:(size_t)oldLimit {
  VPKGPBCodedInputStreamPopLimit(&state_, oldLimit);
}

- (double)readDouble {
  return VPKGPBCodedInputStreamReadDouble(&state_);
}

- (float)readFloat {
  return VPKGPBCodedInputStreamReadFloat(&state_);
}

- (uint64_t)readUInt64 {
  return VPKGPBCodedInputStreamReadUInt64(&state_);
}

- (int64_t)readInt64 {
  return VPKGPBCodedInputStreamReadInt64(&state_);
}

- (int32_t)readInt32 {
  return VPKGPBCodedInputStreamReadInt32(&state_);
}

- (uint64_t)readFixed64 {
  return VPKGPBCodedInputStreamReadFixed64(&state_);
}

- (uint32_t)readFixed32 {
  return VPKGPBCodedInputStreamReadFixed32(&state_);
}

- (BOOL)readBool {
  return VPKGPBCodedInputStreamReadBool(&state_);
}

- (NSString *)readString {
  return [VPKGPBCodedInputStreamReadRetainedString(&state_) autorelease];
}

- (void)readGroup:(int32_t)fieldNumber
              message:(VPKGPBMessage *)message
    extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry {
  CheckRecursionLimit(&state_);
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self extensionRegistry:extensionRegistry];
  VPKGPBCodedInputStreamCheckLastTagWas(&state_,
                                     VPKGPBWireFormatMakeTag(fieldNumber, VPKGPBWireFormatEndGroup));
  --state_.recursionDepth;
}

- (void)readUnknownGroup:(int32_t)fieldNumber message:(VPKGPBUnknownFieldSet *)message {
  CheckRecursionLimit(&state_);
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self];
  VPKGPBCodedInputStreamCheckLastTagWas(&state_,
                                     VPKGPBWireFormatMakeTag(fieldNumber, VPKGPBWireFormatEndGroup));
  --state_.recursionDepth;
}

- (void)readMessage:(VPKGPBMessage *)message
    extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry {
  CheckRecursionLimit(&state_);
  int32_t length = ReadRawVarint32(&state_);
  size_t oldLimit = VPKGPBCodedInputStreamPushLimit(&state_, length);
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self extensionRegistry:extensionRegistry];
  VPKGPBCodedInputStreamCheckLastTagWas(&state_, 0);
  --state_.recursionDepth;
  VPKGPBCodedInputStreamPopLimit(&state_, oldLimit);
}

- (void)readMapEntry:(id)mapDictionary
    extensionRegistry:(id<VPKGPBExtensionRegistry>)extensionRegistry
                field:(VPKGPBFieldDescriptor *)field
        parentMessage:(VPKGPBMessage *)parentMessage {
  CheckRecursionLimit(&state_);
  int32_t length = ReadRawVarint32(&state_);
  size_t oldLimit = VPKGPBCodedInputStreamPushLimit(&state_, length);
  ++state_.recursionDepth;
  VPKGPBDictionaryReadEntry(mapDictionary, self, extensionRegistry, field, parentMessage);
  VPKGPBCodedInputStreamCheckLastTagWas(&state_, 0);
  --state_.recursionDepth;
  VPKGPBCodedInputStreamPopLimit(&state_, oldLimit);
}

- (NSData *)readBytes {
  return [VPKGPBCodedInputStreamReadRetainedBytes(&state_) autorelease];
}

- (uint32_t)readUInt32 {
  return VPKGPBCodedInputStreamReadUInt32(&state_);
}

- (int32_t)readEnum {
  return VPKGPBCodedInputStreamReadEnum(&state_);
}

- (int32_t)readSFixed32 {
  return VPKGPBCodedInputStreamReadSFixed32(&state_);
}

- (int64_t)readSFixed64 {
  return VPKGPBCodedInputStreamReadSFixed64(&state_);
}

- (int32_t)readSInt32 {
  return VPKGPBCodedInputStreamReadSInt32(&state_);
}

- (int64_t)readSInt64 {
  return VPKGPBCodedInputStreamReadSInt64(&state_);
}

#pragma clang diagnostic pop

@end
