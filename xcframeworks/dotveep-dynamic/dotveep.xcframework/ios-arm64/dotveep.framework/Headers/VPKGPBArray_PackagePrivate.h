// Protocol Buffers - Google's data interchange format
// Copyright 2015 Google Inc.  All rights reserved.
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

#import "VPKGPBArray.h"

@class VPKGPBMessage;

//%PDDM-DEFINE DECLARE_ARRAY_EXTRAS()
//%ARRAY_INTERFACE_EXTRAS(Int32, int32_t)
//%ARRAY_INTERFACE_EXTRAS(UInt32, uint32_t)
//%ARRAY_INTERFACE_EXTRAS(Int64, int64_t)
//%ARRAY_INTERFACE_EXTRAS(UInt64, uint64_t)
//%ARRAY_INTERFACE_EXTRAS(Float, float)
//%ARRAY_INTERFACE_EXTRAS(Double, double)
//%ARRAY_INTERFACE_EXTRAS(Bool, BOOL)
//%ARRAY_INTERFACE_EXTRAS(Enum, int32_t)

//%PDDM-DEFINE ARRAY_INTERFACE_EXTRAS(NAME, TYPE)
//%#pragma mark - NAME
//%
//%@interface VPKGPB##NAME##Array () {
//% @package
//%  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
//%}
//%@end
//%

//%PDDM-EXPAND DECLARE_ARRAY_EXTRAS()
// This block of code is generated, do not edit it directly.

#pragma mark - Int32

@interface VPKGPBInt32Array () {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

#pragma mark - UInt32

@interface VPKGPBUInt32Array () {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

#pragma mark - Int64

@interface VPKGPBInt64Array () {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

#pragma mark - UInt64

@interface VPKGPBUInt64Array () {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

#pragma mark - Float

@interface VPKGPBFloatArray () {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

#pragma mark - Double

@interface VPKGPBDoubleArray () {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

#pragma mark - Bool

@interface VPKGPBBoolArray () {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

#pragma mark - Enum

@interface VPKGPBEnumArray () {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end

//%PDDM-EXPAND-END DECLARE_ARRAY_EXTRAS()

#pragma mark - NSArray Subclass

@interface VPKGPBAutocreatedArray : NSMutableArray {
 @package
  VPKGPB_UNSAFE_UNRETAINED VPKGPBMessage *_autocreator;
}
@end
