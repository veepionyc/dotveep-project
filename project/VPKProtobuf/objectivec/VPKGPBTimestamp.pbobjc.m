// Generated by the protocol buffer compiler.  DO NOT EDIT!
// clang-format off
// source: google/protobuf/timestamp.proto

#import "VPKGPBProtocolBuffers_RuntimeSupport.h"
#import "VPKGPBTimestamp.pbobjc.h"

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30007
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30007 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdollar-in-identifier-extension"

#pragma mark - Objective-C Class declarations
// Forward declarations of Objective-C classes that we can use as
// static values in struct initializers.
// We don't use [Foo class] because it is not a static value.
VPKGPBObjCClassDeclaration(VPKGPBTimestamp);

#pragma mark - VPKGPBTimestampRoot

@implementation VPKGPBTimestampRoot

// No extensions in the file and no imports, so no need to generate
// +extensionRegistry.

@end

static VPKGPBFileDescription VPKGPBTimestampRoot_FileDescription = {
  .package = "google.protobuf",
  .prefix = "VPKGPB",
  .syntax = VPKGPBFileSyntaxProto3
};

#pragma mark - VPKGPBTimestamp

@implementation VPKGPBTimestamp

@dynamic seconds;
@dynamic nanos;

typedef struct VPKGPBTimestamp__storage_ {
  uint32_t _has_storage_[1];
  int32_t nanos;
  int64_t seconds;
} VPKGPBTimestamp__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (VPKGPBDescriptor *)descriptor {
  static VPKGPBDescriptor *descriptor = nil;
  if (!descriptor) {
    VPKGPB_DEBUG_CHECK_RUNTIME_VERSIONS();
    static VPKGPBMessageFieldDescription fields[] = {
      {
        .name = "seconds",
        .dataTypeSpecific.clazz = Nil,
        .number = VPKGPBTimestamp_FieldNumber_Seconds,
        .hasIndex = 0,
        .offset = (uint32_t)offsetof(VPKGPBTimestamp__storage_, seconds),
        .flags = (VPKGPBFieldFlags)(VPKGPBFieldOptional | VPKGPBFieldClearHasIvarOnZero),
        .dataType = VPKGPBDataTypeInt64,
      },
      {
        .name = "nanos",
        .dataTypeSpecific.clazz = Nil,
        .number = VPKGPBTimestamp_FieldNumber_Nanos,
        .hasIndex = 1,
        .offset = (uint32_t)offsetof(VPKGPBTimestamp__storage_, nanos),
        .flags = (VPKGPBFieldFlags)(VPKGPBFieldOptional | VPKGPBFieldClearHasIvarOnZero),
        .dataType = VPKGPBDataTypeInt32,
      },
    };
    VPKGPBDescriptor *localDescriptor =
        [VPKGPBDescriptor allocDescriptorForClass:VPKGPBObjCClass(VPKGPBTimestamp)
                                   messageName:@"Timestamp"
                               fileDescription:&VPKGPBTimestampRoot_FileDescription
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(VPKGPBMessageFieldDescription))
                                   storageSize:sizeof(VPKGPBTimestamp__storage_)
                                         flags:(VPKGPBDescriptorInitializationFlags)(VPKGPBDescriptorInitializationFlag_UsesClassRefs | VPKGPBDescriptorInitializationFlag_Proto3OptionalKnown | VPKGPBDescriptorInitializationFlag_ClosedEnumSupportKnown)];
    #if defined(DEBUG) && DEBUG
      NSAssert(descriptor == nil, @"Startup recursed!");
    #endif  // DEBUG
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end


#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)

// clang-format on