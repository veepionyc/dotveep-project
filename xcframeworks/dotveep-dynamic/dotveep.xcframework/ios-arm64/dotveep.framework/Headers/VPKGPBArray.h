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

#import <Foundation/Foundation.h>

#import "VPKGPBRuntimeTypes.h"

NS_ASSUME_NONNULL_BEGIN

// Disable clang-format for the macros.
// clang-format off

//%PDDM-EXPAND DECLARE_ARRAYS()
// This block of code is generated, do not edit it directly.

#pragma mark - Int32

/**
 * Class used for repeated fields of int32_t values. This performs better than
 * boxing into NSNumbers in NSArrays.
 *
 * @note This class is not meant to be subclassed.
 **/
__attribute__((objc_subclassing_restricted))
@interface VPKGPBInt32Array : NSObject <NSCopying>

/** The number of elements contained in the array. */
@property(nonatomic, readonly) NSUInteger count;

/**
 * @return A newly instanced and empty VPKGPBInt32Array.
 **/
+ (instancetype)array;

/**
 * Creates and initializes a VPKGPBInt32Array with the single element given.
 *
 * @param value The value to be placed in the array.
 *
 * @return A newly instanced VPKGPBInt32Array with value in it.
 **/
+ (instancetype)arrayWithValue:(int32_t)value;

/**
 * Creates and initializes a VPKGPBInt32Array with the contents of the given
 * array.
 *
 * @param array Array with the contents to be put into the new array.
 *
 * @return A newly instanced VPKGPBInt32Array with the contents of array.
 **/
+ (instancetype)arrayWithValueArray:(VPKGPBInt32Array *)array;

/**
 * Creates and initializes a VPKGPBInt32Array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly instanced VPKGPBInt32Array with a capacity of count.
 **/
+ (instancetype)arrayWithCapacity:(NSUInteger)count;

/**
 * @return A newly initialized and empty VPKGPBInt32Array.
 **/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the array, copying the given values.
 *
 * @param values An array with the values to put inside this array.
 * @param count  The number of elements to copy into the array.
 *
 * @return A newly initialized VPKGPBInt32Array with a copy of the values.
 **/
- (instancetype)initWithValues:(const int32_t [__nullable])values
                         count:(NSUInteger)count;

/**
 * Initializes the array, copying the given values.
 *
 * @param array An array with the values to put inside this array.
 *
 * @return A newly initialized VPKGPBInt32Array with a copy of the values.
 **/
- (instancetype)initWithValueArray:(VPKGPBInt32Array *)array;

/**
 * Initializes the array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly initialized VPKGPBInt32Array with a capacity of count.
 **/
- (instancetype)initWithCapacity:(NSUInteger)count;

/**
 * Gets the value at the given index.
 *
 * @param index The index of the value to get.
 *
 * @return The value at the given index.
 **/
- (int32_t)valueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(int32_t value, NSUInteger idx,
                                                       BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
                        usingBlock:(void (NS_NOESCAPE ^)(int32_t value, NSUInteger idx,
                                                         BOOL *stop))block;

/**
 * Adds a value to this array.
 *
 * @param value The value to add to this array.
 **/
- (void)addValue:(int32_t)value;

/**
 * Adds values to this array.
 *
 * @param values The values to add to this array.
 * @param count  The number of elements to add.
 **/
- (void)addValues:(const int32_t [__nullable])values count:(NSUInteger)count;

/**
 * Adds the values from the given array to this array.
 *
 * @param array The array containing the elements to add to this array.
 **/
- (void)addValuesFromArray:(VPKGPBInt32Array *)array;

/**
 * Inserts a value into the given position.
 *
 * @param value The value to add to this array.
 * @param index The index into which to insert the value.
 **/
- (void)insertValue:(int32_t)value atIndex:(NSUInteger)index;

/**
 * Replaces the value at the given index with the given value.
 *
 * @param index The index for which to replace the value.
 * @param value The value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withValue:(int32_t)value;

/**
 * Removes the value at the given index.
 *
 * @param index The index of the value to remove.
 **/
- (void)removeValueAtIndex:(NSUInteger)index;

/**
 * Removes all the values from this array.
 **/
- (void)removeAll;

/**
 * Exchanges the values between the given indexes.
 *
 * @param idx1 The index of the first element to exchange.
 * @param idx2 The index of the second element to exchange.
 **/
- (void)exchangeValueAtIndex:(NSUInteger)idx1
            withValueAtIndex:(NSUInteger)idx2;

@end

#pragma mark - UInt32

/**
 * Class used for repeated fields of uint32_t values. This performs better than
 * boxing into NSNumbers in NSArrays.
 *
 * @note This class is not meant to be subclassed.
 **/
__attribute__((objc_subclassing_restricted))
@interface VPKGPBUInt32Array : NSObject <NSCopying>

/** The number of elements contained in the array. */
@property(nonatomic, readonly) NSUInteger count;

/**
 * @return A newly instanced and empty VPKGPBUInt32Array.
 **/
+ (instancetype)array;

/**
 * Creates and initializes a VPKGPBUInt32Array with the single element given.
 *
 * @param value The value to be placed in the array.
 *
 * @return A newly instanced VPKGPBUInt32Array with value in it.
 **/
+ (instancetype)arrayWithValue:(uint32_t)value;

/**
 * Creates and initializes a VPKGPBUInt32Array with the contents of the given
 * array.
 *
 * @param array Array with the contents to be put into the new array.
 *
 * @return A newly instanced VPKGPBUInt32Array with the contents of array.
 **/
+ (instancetype)arrayWithValueArray:(VPKGPBUInt32Array *)array;

/**
 * Creates and initializes a VPKGPBUInt32Array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly instanced VPKGPBUInt32Array with a capacity of count.
 **/
+ (instancetype)arrayWithCapacity:(NSUInteger)count;

/**
 * @return A newly initialized and empty VPKGPBUInt32Array.
 **/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the array, copying the given values.
 *
 * @param values An array with the values to put inside this array.
 * @param count  The number of elements to copy into the array.
 *
 * @return A newly initialized VPKGPBUInt32Array with a copy of the values.
 **/
- (instancetype)initWithValues:(const uint32_t [__nullable])values
                         count:(NSUInteger)count;

/**
 * Initializes the array, copying the given values.
 *
 * @param array An array with the values to put inside this array.
 *
 * @return A newly initialized VPKGPBUInt32Array with a copy of the values.
 **/
- (instancetype)initWithValueArray:(VPKGPBUInt32Array *)array;

/**
 * Initializes the array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly initialized VPKGPBUInt32Array with a capacity of count.
 **/
- (instancetype)initWithCapacity:(NSUInteger)count;

/**
 * Gets the value at the given index.
 *
 * @param index The index of the value to get.
 *
 * @return The value at the given index.
 **/
- (uint32_t)valueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(uint32_t value, NSUInteger idx,
                                                       BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
                        usingBlock:(void (NS_NOESCAPE ^)(uint32_t value, NSUInteger idx,
                                                         BOOL *stop))block;

/**
 * Adds a value to this array.
 *
 * @param value The value to add to this array.
 **/
- (void)addValue:(uint32_t)value;

/**
 * Adds values to this array.
 *
 * @param values The values to add to this array.
 * @param count  The number of elements to add.
 **/
- (void)addValues:(const uint32_t [__nullable])values count:(NSUInteger)count;

/**
 * Adds the values from the given array to this array.
 *
 * @param array The array containing the elements to add to this array.
 **/
- (void)addValuesFromArray:(VPKGPBUInt32Array *)array;

/**
 * Inserts a value into the given position.
 *
 * @param value The value to add to this array.
 * @param index The index into which to insert the value.
 **/
- (void)insertValue:(uint32_t)value atIndex:(NSUInteger)index;

/**
 * Replaces the value at the given index with the given value.
 *
 * @param index The index for which to replace the value.
 * @param value The value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withValue:(uint32_t)value;

/**
 * Removes the value at the given index.
 *
 * @param index The index of the value to remove.
 **/
- (void)removeValueAtIndex:(NSUInteger)index;

/**
 * Removes all the values from this array.
 **/
- (void)removeAll;

/**
 * Exchanges the values between the given indexes.
 *
 * @param idx1 The index of the first element to exchange.
 * @param idx2 The index of the second element to exchange.
 **/
- (void)exchangeValueAtIndex:(NSUInteger)idx1
            withValueAtIndex:(NSUInteger)idx2;

@end

#pragma mark - Int64

/**
 * Class used for repeated fields of int64_t values. This performs better than
 * boxing into NSNumbers in NSArrays.
 *
 * @note This class is not meant to be subclassed.
 **/
__attribute__((objc_subclassing_restricted))
@interface VPKGPBInt64Array : NSObject <NSCopying>

/** The number of elements contained in the array. */
@property(nonatomic, readonly) NSUInteger count;

/**
 * @return A newly instanced and empty VPKGPBInt64Array.
 **/
+ (instancetype)array;

/**
 * Creates and initializes a VPKGPBInt64Array with the single element given.
 *
 * @param value The value to be placed in the array.
 *
 * @return A newly instanced VPKGPBInt64Array with value in it.
 **/
+ (instancetype)arrayWithValue:(int64_t)value;

/**
 * Creates and initializes a VPKGPBInt64Array with the contents of the given
 * array.
 *
 * @param array Array with the contents to be put into the new array.
 *
 * @return A newly instanced VPKGPBInt64Array with the contents of array.
 **/
+ (instancetype)arrayWithValueArray:(VPKGPBInt64Array *)array;

/**
 * Creates and initializes a VPKGPBInt64Array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly instanced VPKGPBInt64Array with a capacity of count.
 **/
+ (instancetype)arrayWithCapacity:(NSUInteger)count;

/**
 * @return A newly initialized and empty VPKGPBInt64Array.
 **/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the array, copying the given values.
 *
 * @param values An array with the values to put inside this array.
 * @param count  The number of elements to copy into the array.
 *
 * @return A newly initialized VPKGPBInt64Array with a copy of the values.
 **/
- (instancetype)initWithValues:(const int64_t [__nullable])values
                         count:(NSUInteger)count;

/**
 * Initializes the array, copying the given values.
 *
 * @param array An array with the values to put inside this array.
 *
 * @return A newly initialized VPKGPBInt64Array with a copy of the values.
 **/
- (instancetype)initWithValueArray:(VPKGPBInt64Array *)array;

/**
 * Initializes the array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly initialized VPKGPBInt64Array with a capacity of count.
 **/
- (instancetype)initWithCapacity:(NSUInteger)count;

/**
 * Gets the value at the given index.
 *
 * @param index The index of the value to get.
 *
 * @return The value at the given index.
 **/
- (int64_t)valueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(int64_t value, NSUInteger idx,
                                                       BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
                        usingBlock:(void (NS_NOESCAPE ^)(int64_t value, NSUInteger idx,
                                                         BOOL *stop))block;

/**
 * Adds a value to this array.
 *
 * @param value The value to add to this array.
 **/
- (void)addValue:(int64_t)value;

/**
 * Adds values to this array.
 *
 * @param values The values to add to this array.
 * @param count  The number of elements to add.
 **/
- (void)addValues:(const int64_t [__nullable])values count:(NSUInteger)count;

/**
 * Adds the values from the given array to this array.
 *
 * @param array The array containing the elements to add to this array.
 **/
- (void)addValuesFromArray:(VPKGPBInt64Array *)array;

/**
 * Inserts a value into the given position.
 *
 * @param value The value to add to this array.
 * @param index The index into which to insert the value.
 **/
- (void)insertValue:(int64_t)value atIndex:(NSUInteger)index;

/**
 * Replaces the value at the given index with the given value.
 *
 * @param index The index for which to replace the value.
 * @param value The value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withValue:(int64_t)value;

/**
 * Removes the value at the given index.
 *
 * @param index The index of the value to remove.
 **/
- (void)removeValueAtIndex:(NSUInteger)index;

/**
 * Removes all the values from this array.
 **/
- (void)removeAll;

/**
 * Exchanges the values between the given indexes.
 *
 * @param idx1 The index of the first element to exchange.
 * @param idx2 The index of the second element to exchange.
 **/
- (void)exchangeValueAtIndex:(NSUInteger)idx1
            withValueAtIndex:(NSUInteger)idx2;

@end

#pragma mark - UInt64

/**
 * Class used for repeated fields of uint64_t values. This performs better than
 * boxing into NSNumbers in NSArrays.
 *
 * @note This class is not meant to be subclassed.
 **/
__attribute__((objc_subclassing_restricted))
@interface VPKGPBUInt64Array : NSObject <NSCopying>

/** The number of elements contained in the array. */
@property(nonatomic, readonly) NSUInteger count;

/**
 * @return A newly instanced and empty VPKGPBUInt64Array.
 **/
+ (instancetype)array;

/**
 * Creates and initializes a VPKGPBUInt64Array with the single element given.
 *
 * @param value The value to be placed in the array.
 *
 * @return A newly instanced VPKGPBUInt64Array with value in it.
 **/
+ (instancetype)arrayWithValue:(uint64_t)value;

/**
 * Creates and initializes a VPKGPBUInt64Array with the contents of the given
 * array.
 *
 * @param array Array with the contents to be put into the new array.
 *
 * @return A newly instanced VPKGPBUInt64Array with the contents of array.
 **/
+ (instancetype)arrayWithValueArray:(VPKGPBUInt64Array *)array;

/**
 * Creates and initializes a VPKGPBUInt64Array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly instanced VPKGPBUInt64Array with a capacity of count.
 **/
+ (instancetype)arrayWithCapacity:(NSUInteger)count;

/**
 * @return A newly initialized and empty VPKGPBUInt64Array.
 **/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the array, copying the given values.
 *
 * @param values An array with the values to put inside this array.
 * @param count  The number of elements to copy into the array.
 *
 * @return A newly initialized VPKGPBUInt64Array with a copy of the values.
 **/
- (instancetype)initWithValues:(const uint64_t [__nullable])values
                         count:(NSUInteger)count;

/**
 * Initializes the array, copying the given values.
 *
 * @param array An array with the values to put inside this array.
 *
 * @return A newly initialized VPKGPBUInt64Array with a copy of the values.
 **/
- (instancetype)initWithValueArray:(VPKGPBUInt64Array *)array;

/**
 * Initializes the array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly initialized VPKGPBUInt64Array with a capacity of count.
 **/
- (instancetype)initWithCapacity:(NSUInteger)count;

/**
 * Gets the value at the given index.
 *
 * @param index The index of the value to get.
 *
 * @return The value at the given index.
 **/
- (uint64_t)valueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(uint64_t value, NSUInteger idx,
                                                       BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
                        usingBlock:(void (NS_NOESCAPE ^)(uint64_t value, NSUInteger idx,
                                                         BOOL *stop))block;

/**
 * Adds a value to this array.
 *
 * @param value The value to add to this array.
 **/
- (void)addValue:(uint64_t)value;

/**
 * Adds values to this array.
 *
 * @param values The values to add to this array.
 * @param count  The number of elements to add.
 **/
- (void)addValues:(const uint64_t [__nullable])values count:(NSUInteger)count;

/**
 * Adds the values from the given array to this array.
 *
 * @param array The array containing the elements to add to this array.
 **/
- (void)addValuesFromArray:(VPKGPBUInt64Array *)array;

/**
 * Inserts a value into the given position.
 *
 * @param value The value to add to this array.
 * @param index The index into which to insert the value.
 **/
- (void)insertValue:(uint64_t)value atIndex:(NSUInteger)index;

/**
 * Replaces the value at the given index with the given value.
 *
 * @param index The index for which to replace the value.
 * @param value The value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withValue:(uint64_t)value;

/**
 * Removes the value at the given index.
 *
 * @param index The index of the value to remove.
 **/
- (void)removeValueAtIndex:(NSUInteger)index;

/**
 * Removes all the values from this array.
 **/
- (void)removeAll;

/**
 * Exchanges the values between the given indexes.
 *
 * @param idx1 The index of the first element to exchange.
 * @param idx2 The index of the second element to exchange.
 **/
- (void)exchangeValueAtIndex:(NSUInteger)idx1
            withValueAtIndex:(NSUInteger)idx2;

@end

#pragma mark - Float

/**
 * Class used for repeated fields of float values. This performs better than
 * boxing into NSNumbers in NSArrays.
 *
 * @note This class is not meant to be subclassed.
 **/
__attribute__((objc_subclassing_restricted))
@interface VPKGPBFloatArray : NSObject <NSCopying>

/** The number of elements contained in the array. */
@property(nonatomic, readonly) NSUInteger count;

/**
 * @return A newly instanced and empty VPKGPBFloatArray.
 **/
+ (instancetype)array;

/**
 * Creates and initializes a VPKGPBFloatArray with the single element given.
 *
 * @param value The value to be placed in the array.
 *
 * @return A newly instanced VPKGPBFloatArray with value in it.
 **/
+ (instancetype)arrayWithValue:(float)value;

/**
 * Creates and initializes a VPKGPBFloatArray with the contents of the given
 * array.
 *
 * @param array Array with the contents to be put into the new array.
 *
 * @return A newly instanced VPKGPBFloatArray with the contents of array.
 **/
+ (instancetype)arrayWithValueArray:(VPKGPBFloatArray *)array;

/**
 * Creates and initializes a VPKGPBFloatArray with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly instanced VPKGPBFloatArray with a capacity of count.
 **/
+ (instancetype)arrayWithCapacity:(NSUInteger)count;

/**
 * @return A newly initialized and empty VPKGPBFloatArray.
 **/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the array, copying the given values.
 *
 * @param values An array with the values to put inside this array.
 * @param count  The number of elements to copy into the array.
 *
 * @return A newly initialized VPKGPBFloatArray with a copy of the values.
 **/
- (instancetype)initWithValues:(const float [__nullable])values
                         count:(NSUInteger)count;

/**
 * Initializes the array, copying the given values.
 *
 * @param array An array with the values to put inside this array.
 *
 * @return A newly initialized VPKGPBFloatArray with a copy of the values.
 **/
- (instancetype)initWithValueArray:(VPKGPBFloatArray *)array;

/**
 * Initializes the array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly initialized VPKGPBFloatArray with a capacity of count.
 **/
- (instancetype)initWithCapacity:(NSUInteger)count;

/**
 * Gets the value at the given index.
 *
 * @param index The index of the value to get.
 *
 * @return The value at the given index.
 **/
- (float)valueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(float value, NSUInteger idx,
                                                       BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
                        usingBlock:(void (NS_NOESCAPE ^)(float value, NSUInteger idx,
                                                         BOOL *stop))block;

/**
 * Adds a value to this array.
 *
 * @param value The value to add to this array.
 **/
- (void)addValue:(float)value;

/**
 * Adds values to this array.
 *
 * @param values The values to add to this array.
 * @param count  The number of elements to add.
 **/
- (void)addValues:(const float [__nullable])values count:(NSUInteger)count;

/**
 * Adds the values from the given array to this array.
 *
 * @param array The array containing the elements to add to this array.
 **/
- (void)addValuesFromArray:(VPKGPBFloatArray *)array;

/**
 * Inserts a value into the given position.
 *
 * @param value The value to add to this array.
 * @param index The index into which to insert the value.
 **/
- (void)insertValue:(float)value atIndex:(NSUInteger)index;

/**
 * Replaces the value at the given index with the given value.
 *
 * @param index The index for which to replace the value.
 * @param value The value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withValue:(float)value;

/**
 * Removes the value at the given index.
 *
 * @param index The index of the value to remove.
 **/
- (void)removeValueAtIndex:(NSUInteger)index;

/**
 * Removes all the values from this array.
 **/
- (void)removeAll;

/**
 * Exchanges the values between the given indexes.
 *
 * @param idx1 The index of the first element to exchange.
 * @param idx2 The index of the second element to exchange.
 **/
- (void)exchangeValueAtIndex:(NSUInteger)idx1
            withValueAtIndex:(NSUInteger)idx2;

@end

#pragma mark - Double

/**
 * Class used for repeated fields of double values. This performs better than
 * boxing into NSNumbers in NSArrays.
 *
 * @note This class is not meant to be subclassed.
 **/
__attribute__((objc_subclassing_restricted))
@interface VPKGPBDoubleArray : NSObject <NSCopying>

/** The number of elements contained in the array. */
@property(nonatomic, readonly) NSUInteger count;

/**
 * @return A newly instanced and empty VPKGPBDoubleArray.
 **/
+ (instancetype)array;

/**
 * Creates and initializes a VPKGPBDoubleArray with the single element given.
 *
 * @param value The value to be placed in the array.
 *
 * @return A newly instanced VPKGPBDoubleArray with value in it.
 **/
+ (instancetype)arrayWithValue:(double)value;

/**
 * Creates and initializes a VPKGPBDoubleArray with the contents of the given
 * array.
 *
 * @param array Array with the contents to be put into the new array.
 *
 * @return A newly instanced VPKGPBDoubleArray with the contents of array.
 **/
+ (instancetype)arrayWithValueArray:(VPKGPBDoubleArray *)array;

/**
 * Creates and initializes a VPKGPBDoubleArray with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly instanced VPKGPBDoubleArray with a capacity of count.
 **/
+ (instancetype)arrayWithCapacity:(NSUInteger)count;

/**
 * @return A newly initialized and empty VPKGPBDoubleArray.
 **/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the array, copying the given values.
 *
 * @param values An array with the values to put inside this array.
 * @param count  The number of elements to copy into the array.
 *
 * @return A newly initialized VPKGPBDoubleArray with a copy of the values.
 **/
- (instancetype)initWithValues:(const double [__nullable])values
                         count:(NSUInteger)count;

/**
 * Initializes the array, copying the given values.
 *
 * @param array An array with the values to put inside this array.
 *
 * @return A newly initialized VPKGPBDoubleArray with a copy of the values.
 **/
- (instancetype)initWithValueArray:(VPKGPBDoubleArray *)array;

/**
 * Initializes the array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly initialized VPKGPBDoubleArray with a capacity of count.
 **/
- (instancetype)initWithCapacity:(NSUInteger)count;

/**
 * Gets the value at the given index.
 *
 * @param index The index of the value to get.
 *
 * @return The value at the given index.
 **/
- (double)valueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(double value, NSUInteger idx,
                                                       BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
                        usingBlock:(void (NS_NOESCAPE ^)(double value, NSUInteger idx,
                                                         BOOL *stop))block;

/**
 * Adds a value to this array.
 *
 * @param value The value to add to this array.
 **/
- (void)addValue:(double)value;

/**
 * Adds values to this array.
 *
 * @param values The values to add to this array.
 * @param count  The number of elements to add.
 **/
- (void)addValues:(const double [__nullable])values count:(NSUInteger)count;

/**
 * Adds the values from the given array to this array.
 *
 * @param array The array containing the elements to add to this array.
 **/
- (void)addValuesFromArray:(VPKGPBDoubleArray *)array;

/**
 * Inserts a value into the given position.
 *
 * @param value The value to add to this array.
 * @param index The index into which to insert the value.
 **/
- (void)insertValue:(double)value atIndex:(NSUInteger)index;

/**
 * Replaces the value at the given index with the given value.
 *
 * @param index The index for which to replace the value.
 * @param value The value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withValue:(double)value;

/**
 * Removes the value at the given index.
 *
 * @param index The index of the value to remove.
 **/
- (void)removeValueAtIndex:(NSUInteger)index;

/**
 * Removes all the values from this array.
 **/
- (void)removeAll;

/**
 * Exchanges the values between the given indexes.
 *
 * @param idx1 The index of the first element to exchange.
 * @param idx2 The index of the second element to exchange.
 **/
- (void)exchangeValueAtIndex:(NSUInteger)idx1
            withValueAtIndex:(NSUInteger)idx2;

@end

#pragma mark - Bool

/**
 * Class used for repeated fields of BOOL values. This performs better than
 * boxing into NSNumbers in NSArrays.
 *
 * @note This class is not meant to be subclassed.
 **/
__attribute__((objc_subclassing_restricted))
@interface VPKGPBBoolArray : NSObject <NSCopying>

/** The number of elements contained in the array. */
@property(nonatomic, readonly) NSUInteger count;

/**
 * @return A newly instanced and empty VPKGPBBoolArray.
 **/
+ (instancetype)array;

/**
 * Creates and initializes a VPKGPBBoolArray with the single element given.
 *
 * @param value The value to be placed in the array.
 *
 * @return A newly instanced VPKGPBBoolArray with value in it.
 **/
+ (instancetype)arrayWithValue:(BOOL)value;

/**
 * Creates and initializes a VPKGPBBoolArray with the contents of the given
 * array.
 *
 * @param array Array with the contents to be put into the new array.
 *
 * @return A newly instanced VPKGPBBoolArray with the contents of array.
 **/
+ (instancetype)arrayWithValueArray:(VPKGPBBoolArray *)array;

/**
 * Creates and initializes a VPKGPBBoolArray with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly instanced VPKGPBBoolArray with a capacity of count.
 **/
+ (instancetype)arrayWithCapacity:(NSUInteger)count;

/**
 * @return A newly initialized and empty VPKGPBBoolArray.
 **/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the array, copying the given values.
 *
 * @param values An array with the values to put inside this array.
 * @param count  The number of elements to copy into the array.
 *
 * @return A newly initialized VPKGPBBoolArray with a copy of the values.
 **/
- (instancetype)initWithValues:(const BOOL [__nullable])values
                         count:(NSUInteger)count;

/**
 * Initializes the array, copying the given values.
 *
 * @param array An array with the values to put inside this array.
 *
 * @return A newly initialized VPKGPBBoolArray with a copy of the values.
 **/
- (instancetype)initWithValueArray:(VPKGPBBoolArray *)array;

/**
 * Initializes the array with the given capacity.
 *
 * @param count The capacity needed for the array.
 *
 * @return A newly initialized VPKGPBBoolArray with a capacity of count.
 **/
- (instancetype)initWithCapacity:(NSUInteger)count;

/**
 * Gets the value at the given index.
 *
 * @param index The index of the value to get.
 *
 * @return The value at the given index.
 **/
- (BOOL)valueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(BOOL value, NSUInteger idx,
                                                       BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
                        usingBlock:(void (NS_NOESCAPE ^)(BOOL value, NSUInteger idx,
                                                         BOOL *stop))block;

/**
 * Adds a value to this array.
 *
 * @param value The value to add to this array.
 **/
- (void)addValue:(BOOL)value;

/**
 * Adds values to this array.
 *
 * @param values The values to add to this array.
 * @param count  The number of elements to add.
 **/
- (void)addValues:(const BOOL [__nullable])values count:(NSUInteger)count;

/**
 * Adds the values from the given array to this array.
 *
 * @param array The array containing the elements to add to this array.
 **/
- (void)addValuesFromArray:(VPKGPBBoolArray *)array;

/**
 * Inserts a value into the given position.
 *
 * @param value The value to add to this array.
 * @param index The index into which to insert the value.
 **/
- (void)insertValue:(BOOL)value atIndex:(NSUInteger)index;

/**
 * Replaces the value at the given index with the given value.
 *
 * @param index The index for which to replace the value.
 * @param value The value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withValue:(BOOL)value;

/**
 * Removes the value at the given index.
 *
 * @param index The index of the value to remove.
 **/
- (void)removeValueAtIndex:(NSUInteger)index;

/**
 * Removes all the values from this array.
 **/
- (void)removeAll;

/**
 * Exchanges the values between the given indexes.
 *
 * @param idx1 The index of the first element to exchange.
 * @param idx2 The index of the second element to exchange.
 **/
- (void)exchangeValueAtIndex:(NSUInteger)idx1
            withValueAtIndex:(NSUInteger)idx2;

@end

#pragma mark - Enum

/**
 * This class is used for repeated fields of int32_t values. This performs
 * better than boxing into NSNumbers in NSArrays.
 *
 * @note This class is not meant to be subclassed.
 **/
__attribute__((objc_subclassing_restricted))
@interface VPKGPBEnumArray : NSObject <NSCopying>

/** The number of elements contained in the array. */
@property(nonatomic, readonly) NSUInteger count;
/** The validation function to check if the enums are valid. */
@property(nonatomic, readonly) VPKGPBEnumValidationFunc validationFunc;

/**
 * @return A newly instanced and empty VPKGPBEnumArray.
 **/
+ (instancetype)array;

/**
 * Creates and initializes a VPKGPBEnumArray with the enum validation function
 * given.
 *
 * @param func The enum validation function for the array.
 *
 * @return A newly instanced VPKGPBEnumArray.
 **/
+ (instancetype)arrayWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func;

/**
 * Creates and initializes a VPKGPBEnumArray with the enum validation function
 * given and the single raw value given.
 *
 * @param func  The enum validation function for the array.
 * @param value The raw value to add to this array.
 *
 * @return A newly instanced VPKGPBEnumArray.
 **/
+ (instancetype)arrayWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
                                   rawValue:(int32_t)value;

/**
 * Creates and initializes a VPKGPBEnumArray that adds the elements from the
 * given array.
 *
 * @param array Array containing the values to add to the new array.
 *
 * @return A newly instanced VPKGPBEnumArray.
 **/
+ (instancetype)arrayWithValueArray:(VPKGPBEnumArray *)array;

/**
 * Creates and initializes a VPKGPBEnumArray with the given enum validation
 * function and with the givencapacity.
 *
 * @param func  The enum validation function for the array.
 * @param count The capacity needed for the array.
 *
 * @return A newly instanced VPKGPBEnumArray with a capacity of count.
 **/
+ (instancetype)arrayWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
                                   capacity:(NSUInteger)count;

/**
 * Initializes the array with the given enum validation function.
 *
 * @param func The enum validation function for the array.
 *
 * @return A newly initialized VPKGPBEnumArray with a copy of the values.
 **/
- (instancetype)initWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
    NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the array, copying the given values.
 *
 * @param func   The enum validation function for the array.
 * @param values An array with the values to put inside this array.
 * @param count  The number of elements to copy into the array.
 *
 * @return A newly initialized VPKGPBEnumArray with a copy of the values.
 **/
- (instancetype)initWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
                                 rawValues:(const int32_t [__nullable])values
                                     count:(NSUInteger)count;

/**
 * Initializes the array, copying the given values.
 *
 * @param array An array with the values to put inside this array.
 *
 * @return A newly initialized VPKGPBEnumArray with a copy of the values.
 **/
- (instancetype)initWithValueArray:(VPKGPBEnumArray *)array;

/**
 * Initializes the array with the given capacity.
 *
 * @param func  The enum validation function for the array.
 * @param count The capacity needed for the array.
 *
 * @return A newly initialized VPKGPBEnumArray with a capacity of count.
 **/
- (instancetype)initWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
                                  capacity:(NSUInteger)count;

// These will return kVPKGPBUnrecognizedEnumeratorValue if the value at index is not a
// valid enumerator as defined by validationFunc. If the actual value is
// desired, use "raw" version of the method.

/**
 * Gets the value at the given index.
 *
 * @param index The index of the value to get.
 *
 * @return The value at the given index.
 **/
- (int32_t)valueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(int32_t value, NSUInteger idx,
                                                       BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
                        usingBlock:(void (NS_NOESCAPE ^)(int32_t value, NSUInteger idx,
                                                         BOOL *stop))block;

// These methods bypass the validationFunc to provide access to values that were not
// known at the time the binary was compiled.

/**
 * Gets the raw enum value at the given index.
 *
 * @param index The index of the raw enum value to get.
 *
 * @return The raw enum value at the given index.
 **/
- (int32_t)rawValueAtIndex:(NSUInteger)index;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateRawValuesWithBlock:(void (NS_NOESCAPE ^)(int32_t value, NSUInteger idx,
                                                          BOOL *stop))block;

/**
 * Enumerates the values on this array with the given block.
 *
 * @param opts  Options to control the enumeration.
 * @param block The block to enumerate with.
 *   **value**: The current value being enumerated.
 *   **idx**:   The index of the current value.
 *   **stop**:  A pointer to a boolean that when set stops the enumeration.
 **/
- (void)enumerateRawValuesWithOptions:(NSEnumerationOptions)opts
                           usingBlock:(void (NS_NOESCAPE ^)(int32_t value, NSUInteger idx,
                                                          BOOL *stop))block;

// If value is not a valid enumerator as defined by validationFunc, these
// methods will assert in debug, and will log in release and assign the value
// to the default value. Use the rawValue methods below to assign non enumerator
// values.

/**
 * Adds a value to this array.
 *
 * @param value The value to add to this array.
 **/
- (void)addValue:(int32_t)value;

/**
 * Adds values to this array.
 *
 * @param values The values to add to this array.
 * @param count  The number of elements to add.
 **/
- (void)addValues:(const int32_t [__nullable])values count:(NSUInteger)count;


/**
 * Inserts a value into the given position.
 *
 * @param value The value to add to this array.
 * @param index The index into which to insert the value.
 **/
- (void)insertValue:(int32_t)value atIndex:(NSUInteger)index;

/**
 * Replaces the value at the given index with the given value.
 *
 * @param index The index for which to replace the value.
 * @param value The value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withValue:(int32_t)value;

// These methods bypass the validationFunc to provide setting of values that were not
// known at the time the binary was compiled.

/**
 * Adds a raw enum value to this array.
 *
 * @note This method bypass the validationFunc to enable the setting of values that
 *       were not known at the time the binary was compiled.
 *
 * @param value The raw enum value to add to the array.
 **/
- (void)addRawValue:(int32_t)value;

/**
 * Adds raw enum values to this array.
 *
 * @note This method bypass the validationFunc to enable the setting of values that
 *       were not known at the time the binary was compiled.
 *
 * @param array Array containing the raw enum values to add to this array.
 **/
- (void)addRawValuesFromArray:(VPKGPBEnumArray *)array;

/**
 * Adds raw enum values to this array.
 *
 * @note This method bypass the validationFunc to enable the setting of values that
 *       were not known at the time the binary was compiled.
 *
 * @param values Array containing the raw enum values to add to this array.
 * @param count  The number of raw values to add.
 **/
- (void)addRawValues:(const int32_t [__nullable])values count:(NSUInteger)count;

/**
 * Inserts a raw enum value at the given index.
 *
 * @note This method bypass the validationFunc to enable the setting of values that
 *       were not known at the time the binary was compiled.
 *
 * @param value Raw enum value to add.
 * @param index The index into which to insert the value.
 **/
- (void)insertRawValue:(int32_t)value atIndex:(NSUInteger)index;

/**
 * Replaces the raw enum value at the given index with the given value.
 *
 * @note This method bypass the validationFunc to enable the setting of values that
 *       were not known at the time the binary was compiled.
 *
 * @param index The index for which to replace the value.
 * @param value The raw enum value to replace with.
 **/
- (void)replaceValueAtIndex:(NSUInteger)index withRawValue:(int32_t)value;

// No validation applies to these methods.

/**
 * Removes the value at the given index.
 *
 * @param index The index of the value to remove.
 **/
- (void)removeValueAtIndex:(NSUInteger)index;

/**
 * Removes all the values from this array.
 **/
- (void)removeAll;

/**
 * Exchanges the values between the given indexes.
 *
 * @param idx1 The index of the first element to exchange.
 * @param idx2 The index of the second element to exchange.
 **/
- (void)exchangeValueAtIndex:(NSUInteger)idx1
            withValueAtIndex:(NSUInteger)idx2;

@end

//%PDDM-EXPAND-END DECLARE_ARRAYS()

NS_ASSUME_NONNULL_END

//%PDDM-DEFINE DECLARE_ARRAYS()
//%ARRAY_INTERFACE_SIMPLE(Int32, int32_t)
//%ARRAY_INTERFACE_SIMPLE(UInt32, uint32_t)
//%ARRAY_INTERFACE_SIMPLE(Int64, int64_t)
//%ARRAY_INTERFACE_SIMPLE(UInt64, uint64_t)
//%ARRAY_INTERFACE_SIMPLE(Float, float)
//%ARRAY_INTERFACE_SIMPLE(Double, double)
//%ARRAY_INTERFACE_SIMPLE(Bool, BOOL)
//%ARRAY_INTERFACE_ENUM(Enum, int32_t)

//
// The common case (everything but Enum)
//

//%PDDM-DEFINE ARRAY_INTERFACE_SIMPLE(NAME, TYPE)
//%#pragma mark - NAME
//%
//%/**
//% * Class used for repeated fields of ##TYPE## values. This performs better than
//% * boxing into NSNumbers in NSArrays.
//% *
//% * @note This class is not meant to be subclassed.
//% **/
//%__attribute__((objc_subclassing_restricted))
//%@interface VPKGPB##NAME##Array : NSObject <NSCopying>
//%
//%/** The number of elements contained in the array. */
//%@property(nonatomic, readonly) NSUInteger count;
//%
//%/**
//% * @return A newly instanced and empty VPKGPB##NAME##Array.
//% **/
//%+ (instancetype)array;
//%
//%/**
//% * Creates and initializes a VPKGPB##NAME##Array with the single element given.
//% *
//% * @param value The value to be placed in the array.
//% *
//% * @return A newly instanced VPKGPB##NAME##Array with value in it.
//% **/
//%+ (instancetype)arrayWithValue:(TYPE)value;
//%
//%/**
//% * Creates and initializes a VPKGPB##NAME##Array with the contents of the given
//% * array.
//% *
//% * @param array Array with the contents to be put into the new array.
//% *
//% * @return A newly instanced VPKGPB##NAME##Array with the contents of array.
//% **/
//%+ (instancetype)arrayWithValueArray:(VPKGPB##NAME##Array *)array;
//%
//%/**
//% * Creates and initializes a VPKGPB##NAME##Array with the given capacity.
//% *
//% * @param count The capacity needed for the array.
//% *
//% * @return A newly instanced VPKGPB##NAME##Array with a capacity of count.
//% **/
//%+ (instancetype)arrayWithCapacity:(NSUInteger)count;
//%
//%/**
//% * @return A newly initialized and empty VPKGPB##NAME##Array.
//% **/
//%- (instancetype)init NS_DESIGNATED_INITIALIZER;
//%
//%/**
//% * Initializes the array, copying the given values.
//% *
//% * @param values An array with the values to put inside this array.
//% * @param count  The number of elements to copy into the array.
//% *
//% * @return A newly initialized VPKGPB##NAME##Array with a copy of the values.
//% **/
//%- (instancetype)initWithValues:(const TYPE [__nullable])values
//%                         count:(NSUInteger)count;
//%
//%/**
//% * Initializes the array, copying the given values.
//% *
//% * @param array An array with the values to put inside this array.
//% *
//% * @return A newly initialized VPKGPB##NAME##Array with a copy of the values.
//% **/
//%- (instancetype)initWithValueArray:(VPKGPB##NAME##Array *)array;
//%
//%/**
//% * Initializes the array with the given capacity.
//% *
//% * @param count The capacity needed for the array.
//% *
//% * @return A newly initialized VPKGPB##NAME##Array with a capacity of count.
//% **/
//%- (instancetype)initWithCapacity:(NSUInteger)count;
//%
//%ARRAY_IMMUTABLE_INTERFACE(NAME, TYPE, Basic)
//%
//%ARRAY_MUTABLE_INTERFACE(NAME, TYPE, Basic)
//%
//%@end
//%

//
// Macros specific to Enums (to tweak their interface).
//

//%PDDM-DEFINE ARRAY_INTERFACE_ENUM(NAME, TYPE)
//%#pragma mark - NAME
//%
//%/**
//% * This class is used for repeated fields of ##TYPE## values. This performs
//% * better than boxing into NSNumbers in NSArrays.
//% *
//% * @note This class is not meant to be subclassed.
//% **/
//%__attribute__((objc_subclassing_restricted))
//%@interface VPKGPB##NAME##Array : NSObject <NSCopying>
//%
//%/** The number of elements contained in the array. */
//%@property(nonatomic, readonly) NSUInteger count;
//%/** The validation function to check if the enums are valid. */
//%@property(nonatomic, readonly) VPKGPBEnumValidationFunc validationFunc;
//%
//%/**
//% * @return A newly instanced and empty VPKGPB##NAME##Array.
//% **/
//%+ (instancetype)array;
//%
//%/**
//% * Creates and initializes a VPKGPB##NAME##Array with the enum validation function
//% * given.
//% *
//% * @param func The enum validation function for the array.
//% *
//% * @return A newly instanced VPKGPB##NAME##Array.
//% **/
//%+ (instancetype)arrayWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func;
//%
//%/**
//% * Creates and initializes a VPKGPB##NAME##Array with the enum validation function
//% * given and the single raw value given.
//% *
//% * @param func  The enum validation function for the array.
//% * @param value The raw value to add to this array.
//% *
//% * @return A newly instanced VPKGPB##NAME##Array.
//% **/
//%+ (instancetype)arrayWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
//%                                   rawValue:(TYPE)value;
//%
//%/**
//% * Creates and initializes a VPKGPB##NAME##Array that adds the elements from the
//% * given array.
//% *
//% * @param array Array containing the values to add to the new array.
//% *
//% * @return A newly instanced VPKGPB##NAME##Array.
//% **/
//%+ (instancetype)arrayWithValueArray:(VPKGPB##NAME##Array *)array;
//%
//%/**
//% * Creates and initializes a VPKGPB##NAME##Array with the given enum validation
//% * function and with the givencapacity.
//% *
//% * @param func  The enum validation function for the array.
//% * @param count The capacity needed for the array.
//% *
//% * @return A newly instanced VPKGPB##NAME##Array with a capacity of count.
//% **/
//%+ (instancetype)arrayWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
//%                                   capacity:(NSUInteger)count;
//%
//%/**
//% * Initializes the array with the given enum validation function.
//% *
//% * @param func The enum validation function for the array.
//% *
//% * @return A newly initialized VPKGPB##NAME##Array with a copy of the values.
//% **/
//%- (instancetype)initWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
//%    NS_DESIGNATED_INITIALIZER;
//%
//%/**
//% * Initializes the array, copying the given values.
//% *
//% * @param func   The enum validation function for the array.
//% * @param values An array with the values to put inside this array.
//% * @param count  The number of elements to copy into the array.
//% *
//% * @return A newly initialized VPKGPB##NAME##Array with a copy of the values.
//% **/
//%- (instancetype)initWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
//%                                 rawValues:(const TYPE [__nullable])values
//%                                     count:(NSUInteger)count;
//%
//%/**
//% * Initializes the array, copying the given values.
//% *
//% * @param array An array with the values to put inside this array.
//% *
//% * @return A newly initialized VPKGPB##NAME##Array with a copy of the values.
//% **/
//%- (instancetype)initWithValueArray:(VPKGPB##NAME##Array *)array;
//%
//%/**
//% * Initializes the array with the given capacity.
//% *
//% * @param func  The enum validation function for the array.
//% * @param count The capacity needed for the array.
//% *
//% * @return A newly initialized VPKGPB##NAME##Array with a capacity of count.
//% **/
//%- (instancetype)initWithValidationFunction:(nullable VPKGPBEnumValidationFunc)func
//%                                  capacity:(NSUInteger)count;
//%
//%// These will return kVPKGPBUnrecognizedEnumeratorValue if the value at index is not a
//%// valid enumerator as defined by validationFunc. If the actual value is
//%// desired, use "raw" version of the method.
//%
//%ARRAY_IMMUTABLE_INTERFACE(NAME, TYPE, NAME)
//%
//%// These methods bypass the validationFunc to provide access to values that were not
//%// known at the time the binary was compiled.
//%
//%/**
//% * Gets the raw enum value at the given index.
//% *
//% * @param index The index of the raw enum value to get.
//% *
//% * @return The raw enum value at the given index.
//% **/
//%- (TYPE)rawValueAtIndex:(NSUInteger)index;
//%
//%/**
//% * Enumerates the values on this array with the given block.
//% *
//% * @param block The block to enumerate with.
//% *   **value**: The current value being enumerated.
//% *   **idx**:   The index of the current value.
//% *   **stop**:  A pointer to a boolean that when set stops the enumeration.
//% **/
//%- (void)enumerateRawValuesWithBlock:(void (NS_NOESCAPE ^)(TYPE value, NSUInteger idx,
//%                                                          BOOL *stop))block;
//%
//%/**
//% * Enumerates the values on this array with the given block.
//% *
//% * @param opts  Options to control the enumeration.
//% * @param block The block to enumerate with.
//% *   **value**: The current value being enumerated.
//% *   **idx**:   The index of the current value.
//% *   **stop**:  A pointer to a boolean that when set stops the enumeration.
//% **/
//%- (void)enumerateRawValuesWithOptions:(NSEnumerationOptions)opts
//%                           usingBlock:(void (NS_NOESCAPE ^)(TYPE value, NSUInteger idx,
//%                                                          BOOL *stop))block;
//%
//%// If value is not a valid enumerator as defined by validationFunc, these
//%// methods will assert in debug, and will log in release and assign the value
//%// to the default value. Use the rawValue methods below to assign non enumerator
//%// values.
//%
//%ARRAY_MUTABLE_INTERFACE(NAME, TYPE, NAME)
//%
//%@end
//%

//%PDDM-DEFINE ARRAY_IMMUTABLE_INTERFACE(NAME, TYPE, HELPER_NAME)
//%/**
//% * Gets the value at the given index.
//% *
//% * @param index The index of the value to get.
//% *
//% * @return The value at the given index.
//% **/
//%- (TYPE)valueAtIndex:(NSUInteger)index;
//%
//%/**
//% * Enumerates the values on this array with the given block.
//% *
//% * @param block The block to enumerate with.
//% *   **value**: The current value being enumerated.
//% *   **idx**:   The index of the current value.
//% *   **stop**:  A pointer to a boolean that when set stops the enumeration.
//% **/
//%- (void)enumerateValuesWithBlock:(void (NS_NOESCAPE ^)(TYPE value, NSUInteger idx,
//%                                                       BOOL *stop))block;
//%
//%/**
//% * Enumerates the values on this array with the given block.
//% *
//% * @param opts  Options to control the enumeration.
//% * @param block The block to enumerate with.
//% *   **value**: The current value being enumerated.
//% *   **idx**:   The index of the current value.
//% *   **stop**:  A pointer to a boolean that when set stops the enumeration.
//% **/
//%- (void)enumerateValuesWithOptions:(NSEnumerationOptions)opts
//%                        usingBlock:(void (NS_NOESCAPE ^)(TYPE value, NSUInteger idx,
//%                                                         BOOL *stop))block;

//%PDDM-DEFINE ARRAY_MUTABLE_INTERFACE(NAME, TYPE, HELPER_NAME)
//%/**
//% * Adds a value to this array.
//% *
//% * @param value The value to add to this array.
//% **/
//%- (void)addValue:(TYPE)value;
//%
//%/**
//% * Adds values to this array.
//% *
//% * @param values The values to add to this array.
//% * @param count  The number of elements to add.
//% **/
//%- (void)addValues:(const TYPE [__nullable])values count:(NSUInteger)count;
//%
//%ARRAY_EXTRA_MUTABLE_METHODS1_##HELPER_NAME(NAME, TYPE)
//%/**
//% * Inserts a value into the given position.
//% *
//% * @param value The value to add to this array.
//% * @param index The index into which to insert the value.
//% **/
//%- (void)insertValue:(TYPE)value atIndex:(NSUInteger)index;
//%
//%/**
//% * Replaces the value at the given index with the given value.
//% *
//% * @param index The index for which to replace the value.
//% * @param value The value to replace with.
//% **/
//%- (void)replaceValueAtIndex:(NSUInteger)index withValue:(TYPE)value;
//%ARRAY_EXTRA_MUTABLE_METHODS2_##HELPER_NAME(NAME, TYPE)
//%/**
//% * Removes the value at the given index.
//% *
//% * @param index The index of the value to remove.
//% **/
//%- (void)removeValueAtIndex:(NSUInteger)index;
//%
//%/**
//% * Removes all the values from this array.
//% **/
//%- (void)removeAll;
//%
//%/**
//% * Exchanges the values between the given indexes.
//% *
//% * @param idx1 The index of the first element to exchange.
//% * @param idx2 The index of the second element to exchange.
//% **/
//%- (void)exchangeValueAtIndex:(NSUInteger)idx1
//%            withValueAtIndex:(NSUInteger)idx2;

//
// These are hooks invoked by the above to do insert as needed.
//

//%PDDM-DEFINE ARRAY_EXTRA_MUTABLE_METHODS1_Basic(NAME, TYPE)
//%/**
//% * Adds the values from the given array to this array.
//% *
//% * @param array The array containing the elements to add to this array.
//% **/
//%- (void)addValuesFromArray:(VPKGPB##NAME##Array *)array;
//%
//%PDDM-DEFINE ARRAY_EXTRA_MUTABLE_METHODS2_Basic(NAME, TYPE)
// Empty
//%PDDM-DEFINE ARRAY_EXTRA_MUTABLE_METHODS1_Enum(NAME, TYPE)
// Empty
//%PDDM-DEFINE ARRAY_EXTRA_MUTABLE_METHODS2_Enum(NAME, TYPE)
//%
//%// These methods bypass the validationFunc to provide setting of values that were not
//%// known at the time the binary was compiled.
//%
//%/**
//% * Adds a raw enum value to this array.
//% *
//% * @note This method bypass the validationFunc to enable the setting of values that
//% *       were not known at the time the binary was compiled.
//% *
//% * @param value The raw enum value to add to the array.
//% **/
//%- (void)addRawValue:(TYPE)value;
//%
//%/**
//% * Adds raw enum values to this array.
//% *
//% * @note This method bypass the validationFunc to enable the setting of values that
//% *       were not known at the time the binary was compiled.
//% *
//% * @param array Array containing the raw enum values to add to this array.
//% **/
//%- (void)addRawValuesFromArray:(VPKGPB##NAME##Array *)array;
//%
//%/**
//% * Adds raw enum values to this array.
//% *
//% * @note This method bypass the validationFunc to enable the setting of values that
//% *       were not known at the time the binary was compiled.
//% *
//% * @param values Array containing the raw enum values to add to this array.
//% * @param count  The number of raw values to add.
//% **/
//%- (void)addRawValues:(const TYPE [__nullable])values count:(NSUInteger)count;
//%
//%/**
//% * Inserts a raw enum value at the given index.
//% *
//% * @note This method bypass the validationFunc to enable the setting of values that
//% *       were not known at the time the binary was compiled.
//% *
//% * @param value Raw enum value to add.
//% * @param index The index into which to insert the value.
//% **/
//%- (void)insertRawValue:(TYPE)value atIndex:(NSUInteger)index;
//%
//%/**
//% * Replaces the raw enum value at the given index with the given value.
//% *
//% * @note This method bypass the validationFunc to enable the setting of values that
//% *       were not known at the time the binary was compiled.
//% *
//% * @param index The index for which to replace the value.
//% * @param value The raw enum value to replace with.
//% **/
//%- (void)replaceValueAtIndex:(NSUInteger)index withRawValue:(TYPE)value;
//%
//%// No validation applies to these methods.
//%

// clang-format on
