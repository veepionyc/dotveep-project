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

#import "VPKGPBArray.h"
#import "VPKGPBMessage.h"
#import "VPKGPBRuntimeTypes.h"

@class VPKGPBOneofDescriptor;

CF_EXTERN_C_BEGIN

NS_ASSUME_NONNULL_BEGIN

/**
 * Generates a string that should be a valid "TextFormat" for the C++ version
 * of Protocol Buffers.
 *
 * @param message    The message to generate from.
 * @param lineIndent A string to use as the prefix for all lines generated. Can
 *                   be nil if no extra indent is needed.
 *
 * @return An NSString with the TextFormat of the message.
 **/
NSString *VPKGPBTextFormatForMessage(VPKGPBMessage *message, NSString *__nullable lineIndent);

/**
 * Generates a string that should be a valid "TextFormat" for the C++ version
 * of Protocol Buffers.
 *
 * @param unknownSet The unknown field set to generate from.
 * @param lineIndent A string to use as the prefix for all lines generated. Can
 *                   be nil if no extra indent is needed.
 *
 * @return An NSString with the TextFormat of the unknown field set.
 **/
NSString *VPKGPBTextFormatForUnknownFieldSet(VPKGPBUnknownFieldSet *__nullable unknownSet,
                                          NSString *__nullable lineIndent);

/**
 * Checks if the given field number is set on a message.
 *
 * @param self        The message to check.
 * @param fieldNumber The field number to check.
 *
 * @return YES if the field number is set on the given message.
 **/
BOOL VPKGPBMessageHasFieldNumberSet(VPKGPBMessage *self, uint32_t fieldNumber);

/**
 * Checks if the given field is set on a message.
 *
 * @param self  The message to check.
 * @param field The field to check.
 *
 * @return YES if the field is set on the given message.
 **/
BOOL VPKGPBMessageHasFieldSet(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Clears the given field for the given message.
 *
 * @param self  The message for which to clear the field.
 * @param field The field to clear.
 **/
void VPKGPBClearMessageField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Clears the given oneof field for the given message.
 *
 * @param self  The message for which to clear the field.
 * @param oneof The oneof to clear.
 **/
void VPKGPBClearOneof(VPKGPBMessage *self, VPKGPBOneofDescriptor *oneof);

// Disable clang-format for the macros.
// clang-format off

//%PDDM-EXPAND VPKGPB_ACCESSORS()
// This block of code is generated, do not edit it directly.


//
// Get/Set a given field from/to a message.
//

// Single Fields

/**
 * Gets the value of a bytes field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
NSData *VPKGPBGetMessageBytesField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a bytes field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageBytesField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, NSData *value);

/**
 * Gets the value of a string field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
NSString *VPKGPBGetMessageStringField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a string field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageStringField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, NSString *value);

/**
 * Gets the value of a message field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
VPKGPBMessage *VPKGPBGetMessageMessageField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a message field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageMessageField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, VPKGPBMessage *value);

/**
 * Gets the value of a group field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
VPKGPBMessage *VPKGPBGetMessageGroupField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a group field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageGroupField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, VPKGPBMessage *value);

/**
 * Gets the value of a bool field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
BOOL VPKGPBGetMessageBoolField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a bool field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageBoolField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, BOOL value);

/**
 * Gets the value of an int32 field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
int32_t VPKGPBGetMessageInt32Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of an int32 field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageInt32Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, int32_t value);

/**
 * Gets the value of an uint32 field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
uint32_t VPKGPBGetMessageUInt32Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of an uint32 field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageUInt32Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, uint32_t value);

/**
 * Gets the value of an int64 field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
int64_t VPKGPBGetMessageInt64Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of an int64 field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageInt64Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, int64_t value);

/**
 * Gets the value of an uint64 field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
uint64_t VPKGPBGetMessageUInt64Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of an uint64 field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageUInt64Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, uint64_t value);

/**
 * Gets the value of a float field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
float VPKGPBGetMessageFloatField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a float field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageFloatField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, float value);

/**
 * Gets the value of a double field.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 **/
double VPKGPBGetMessageDoubleField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a double field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The to set in the field.
 **/
void VPKGPBSetMessageDoubleField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, double value);

/**
 * Gets the given enum field of a message. For proto3, if the value isn't a
 * member of the enum, @c kVPKGPBUnrecognizedEnumeratorValue will be returned.
 * VPKGPBGetMessageRawEnumField will bypass the check and return whatever value
 * was set.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 *
 * @return The enum value for the given field.
 **/
int32_t VPKGPBGetMessageEnumField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Set the given enum field of a message. You can only set values that are
 * members of the enum.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The enum value to set in the field.
 **/
void VPKGPBSetMessageEnumField(VPKGPBMessage *self,
                            VPKGPBFieldDescriptor *field,
                            int32_t value);

/**
 * Get the given enum field of a message. No check is done to ensure the value
 * was defined in the enum.
 *
 * @param self  The message from which to get the field.
 * @param field The field to get.
 *
 * @return The raw enum value for the given field.
 **/
int32_t VPKGPBGetMessageRawEnumField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Set the given enum field of a message. You can set the value to anything,
 * even a value that is not a member of the enum.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param value The raw enum value to set in the field.
 **/
void VPKGPBSetMessageRawEnumField(VPKGPBMessage *self,
                               VPKGPBFieldDescriptor *field,
                               int32_t value);

// Repeated Fields

/**
 * Gets the value of a repeated field.
 *
 * @param self  The message from which to get the field.
 * @param field The repeated field to get.
 *
 * @return A VPKGPB*Array or an NSMutableArray based on the field's type.
 **/
id VPKGPBGetMessageRepeatedField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a repeated field.
 *
 * @param self  The message into which to set the field.
 * @param field The field to set.
 * @param array A VPKGPB*Array or NSMutableArray based on the field's type.
 **/
void VPKGPBSetMessageRepeatedField(VPKGPBMessage *self,
                                VPKGPBFieldDescriptor *field,
                                id array);

// Map Fields

/**
 * Gets the value of a map<> field.
 *
 * @param self  The message from which to get the field.
 * @param field The repeated field to get.
 *
 * @return A VPKGPB*Dictionary or NSMutableDictionary based on the field's type.
 **/
id VPKGPBGetMessageMapField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);

/**
 * Sets the value of a map<> field.
 *
 * @param self       The message into which to set the field.
 * @param field      The field to set.
 * @param dictionary A VPKGPB*Dictionary or NSMutableDictionary based on the
 *                   field's type.
 **/
void VPKGPBSetMessageMapField(VPKGPBMessage *self,
                           VPKGPBFieldDescriptor *field,
                           id dictionary);

//%PDDM-EXPAND-END VPKGPB_ACCESSORS()

// clang-format on

/**
 * Returns an empty NSData to assign to byte fields when you wish to assign them
 * to empty. Prevents allocating a lot of little [NSData data] objects.
 **/
NSData *VPKGPBEmptyNSData(void) __attribute__((pure));

/**
 * Drops the `unknownFields` from the given message and from all sub message.
 **/
void VPKGPBMessageDropUnknownFieldsRecursively(VPKGPBMessage *message);

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

// Disable clang-format for the macros.
// clang-format off

//%PDDM-DEFINE VPKGPB_ACCESSORS()
//%
//%//
//%// Get/Set a given field from/to a message.
//%//
//%
//%// Single Fields
//%
//%VPKGPB_ACCESSOR_SINGLE_FULL(Bytes, NSData, , *)
//%VPKGPB_ACCESSOR_SINGLE_FULL(String, NSString, , *)
//%VPKGPB_ACCESSOR_SINGLE_FULL(Message, VPKGPBMessage, , *)
//%VPKGPB_ACCESSOR_SINGLE_FULL(Group, VPKGPBMessage, , *)
//%VPKGPB_ACCESSOR_SINGLE(Bool, BOOL, )
//%VPKGPB_ACCESSOR_SINGLE(Int32, int32_t, n)
//%VPKGPB_ACCESSOR_SINGLE(UInt32, uint32_t, n)
//%VPKGPB_ACCESSOR_SINGLE(Int64, int64_t, n)
//%VPKGPB_ACCESSOR_SINGLE(UInt64, uint64_t, n)
//%VPKGPB_ACCESSOR_SINGLE(Float, float, )
//%VPKGPB_ACCESSOR_SINGLE(Double, double, )
//%/**
//% * Gets the given enum field of a message. For proto3, if the value isn't a
//% * member of the enum, @c kVPKGPBUnrecognizedEnumeratorValue will be returned.
//% * VPKGPBGetMessageRawEnumField will bypass the check and return whatever value
//% * was set.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The field to get.
//% *
//% * @return The enum value for the given field.
//% **/
//%int32_t VPKGPBGetMessageEnumField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
//%
//%/**
//% * Set the given enum field of a message. You can only set values that are
//% * members of the enum.
//% *
//% * @param self  The message into which to set the field.
//% * @param field The field to set.
//% * @param value The enum value to set in the field.
//% **/
//%void VPKGPBSetMessageEnumField(VPKGPBMessage *self,
//%                            VPKGPBFieldDescriptor *field,
//%                            int32_t value);
//%
//%/**
//% * Get the given enum field of a message. No check is done to ensure the value
//% * was defined in the enum.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The field to get.
//% *
//% * @return The raw enum value for the given field.
//% **/
//%int32_t VPKGPBGetMessageRawEnumField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
//%
//%/**
//% * Set the given enum field of a message. You can set the value to anything,
//% * even a value that is not a member of the enum.
//% *
//% * @param self  The message into which to set the field.
//% * @param field The field to set.
//% * @param value The raw enum value to set in the field.
//% **/
//%void VPKGPBSetMessageRawEnumField(VPKGPBMessage *self,
//%                               VPKGPBFieldDescriptor *field,
//%                               int32_t value);
//%
//%// Repeated Fields
//%
//%/**
//% * Gets the value of a repeated field.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The repeated field to get.
//% *
//% * @return A VPKGPB*Array or an NSMutableArray based on the field's type.
//% **/
//%id VPKGPBGetMessageRepeatedField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
//%
//%/**
//% * Sets the value of a repeated field.
//% *
//% * @param self  The message into which to set the field.
//% * @param field The field to set.
//% * @param array A VPKGPB*Array or NSMutableArray based on the field's type.
//% **/
//%void VPKGPBSetMessageRepeatedField(VPKGPBMessage *self,
//%                                VPKGPBFieldDescriptor *field,
//%                                id array);
//%
//%// Map Fields
//%
//%/**
//% * Gets the value of a map<> field.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The repeated field to get.
//% *
//% * @return A VPKGPB*Dictionary or NSMutableDictionary based on the field's type.
//% **/
//%id VPKGPBGetMessageMapField(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
//%
//%/**
//% * Sets the value of a map<> field.
//% *
//% * @param self       The message into which to set the field.
//% * @param field      The field to set.
//% * @param dictionary A VPKGPB*Dictionary or NSMutableDictionary based on the
//% *                   field's type.
//% **/
//%void VPKGPBSetMessageMapField(VPKGPBMessage *self,
//%                           VPKGPBFieldDescriptor *field,
//%                           id dictionary);
//%

//%PDDM-DEFINE VPKGPB_ACCESSOR_SINGLE(NAME, TYPE, AN)
//%VPKGPB_ACCESSOR_SINGLE_FULL(NAME, TYPE, AN, )
//%PDDM-DEFINE VPKGPB_ACCESSOR_SINGLE_FULL(NAME, TYPE, AN, TisP)
//%/**
//% * Gets the value of a##AN NAME$L field.
//% *
//% * @param self  The message from which to get the field.
//% * @param field The field to get.
//% **/
//%TYPE TisP##VPKGPBGetMessage##NAME##Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field);
//%
//%/**
//% * Sets the value of a##AN NAME$L field.
//% *
//% * @param self  The message into which to set the field.
//% * @param field The field to set.
//% * @param value The to set in the field.
//% **/
//%void VPKGPBSetMessage##NAME##Field(VPKGPBMessage *self, VPKGPBFieldDescriptor *field, TYPE TisP##value);
//%

// clang-format on
