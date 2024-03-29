// Generated by the protocol buffer compiler.  DO NOT EDIT!
// clang-format off
// source: google/protobuf/type.proto

#import "VPKGPBDescriptor.h"
#import "VPKGPBMessage.h"
#import "VPKGPBRootObject.h"
#import "VPKGPBAny.pbobjc.h"
#import "VPKGPBSourceContext.pbobjc.h"

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30007
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30007 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

@class VPKGPBEnumValue;
@class VPKGPBField;
@class VPKGPBOption;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum VPKGPBSyntax

/** The syntax in which a protocol buffer element is defined. */
typedef VPKGPB_ENUM(VPKGPBSyntax) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  VPKGPBSyntax_VPKGPBUnrecognizedEnumeratorValue = kVPKGPBUnrecognizedEnumeratorValue,
  /** Syntax `proto2`. */
  VPKGPBSyntax_SyntaxProto2 = 0,

  /** Syntax `proto3`. */
  VPKGPBSyntax_SyntaxProto3 = 1,
};

VPKGPBEnumDescriptor *VPKGPBSyntax_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL VPKGPBSyntax_IsValidValue(int32_t value);

#pragma mark - Enum VPKGPBField_Kind

/** Basic field types. */
typedef VPKGPB_ENUM(VPKGPBField_Kind) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  VPKGPBField_Kind_VPKGPBUnrecognizedEnumeratorValue = kVPKGPBUnrecognizedEnumeratorValue,
  /** Field type unknown. */
  VPKGPBField_Kind_TypeUnknown = 0,

  /** Field type double. */
  VPKGPBField_Kind_TypeDouble = 1,

  /** Field type float. */
  VPKGPBField_Kind_TypeFloat = 2,

  /** Field type int64. */
  VPKGPBField_Kind_TypeInt64 = 3,

  /** Field type uint64. */
  VPKGPBField_Kind_TypeUint64 = 4,

  /** Field type int32. */
  VPKGPBField_Kind_TypeInt32 = 5,

  /** Field type fixed64. */
  VPKGPBField_Kind_TypeFixed64 = 6,

  /** Field type fixed32. */
  VPKGPBField_Kind_TypeFixed32 = 7,

  /** Field type bool. */
  VPKGPBField_Kind_TypeBool = 8,

  /** Field type string. */
  VPKGPBField_Kind_TypeString = 9,

  /** Field type group. Proto2 syntax only, and deprecated. */
  VPKGPBField_Kind_TypeGroup = 10,

  /** Field type message. */
  VPKGPBField_Kind_TypeMessage = 11,

  /** Field type bytes. */
  VPKGPBField_Kind_TypeBytes = 12,

  /** Field type uint32. */
  VPKGPBField_Kind_TypeUint32 = 13,

  /** Field type enum. */
  VPKGPBField_Kind_TypeEnum = 14,

  /** Field type sfixed32. */
  VPKGPBField_Kind_TypeSfixed32 = 15,

  /** Field type sfixed64. */
  VPKGPBField_Kind_TypeSfixed64 = 16,

  /** Field type sint32. */
  VPKGPBField_Kind_TypeSint32 = 17,

  /** Field type sint64. */
  VPKGPBField_Kind_TypeSint64 = 18,
};

VPKGPBEnumDescriptor *VPKGPBField_Kind_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL VPKGPBField_Kind_IsValidValue(int32_t value);

#pragma mark - Enum VPKGPBField_Cardinality

/** Whether a field is optional, required, or repeated. */
typedef VPKGPB_ENUM(VPKGPBField_Cardinality) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  VPKGPBField_Cardinality_VPKGPBUnrecognizedEnumeratorValue = kVPKGPBUnrecognizedEnumeratorValue,
  /** For fields with unknown cardinality. */
  VPKGPBField_Cardinality_CardinalityUnknown = 0,

  /** For optional fields. */
  VPKGPBField_Cardinality_CardinalityOptional = 1,

  /** For required fields. Proto2 syntax only. */
  VPKGPBField_Cardinality_CardinalityRequired = 2,

  /** For repeated fields. */
  VPKGPBField_Cardinality_CardinalityRepeated = 3,
};

VPKGPBEnumDescriptor *VPKGPBField_Cardinality_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL VPKGPBField_Cardinality_IsValidValue(int32_t value);

#pragma mark - VPKGPBTypeRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (VPKGPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c VPKGPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
VPKGPB_FINAL @interface VPKGPBTypeRoot : VPKGPBRootObject
@end

#pragma mark - VPKGPBType

typedef VPKGPB_ENUM(VPKGPBType_FieldNumber) {
  VPKGPBType_FieldNumber_Name = 1,
  VPKGPBType_FieldNumber_FieldsArray = 2,
  VPKGPBType_FieldNumber_OneofsArray = 3,
  VPKGPBType_FieldNumber_OptionsArray = 4,
  VPKGPBType_FieldNumber_SourceContext = 5,
  VPKGPBType_FieldNumber_Syntax = 6,
};

/**
 * A protocol buffer message type.
 **/
VPKGPB_FINAL @interface VPKGPBType : VPKGPBMessage

/** The fully qualified message name. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *name;

/** The list of fields. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<VPKGPBField*> *fieldsArray;
/** The number of items in @c fieldsArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger fieldsArray_Count;

/** The list of types appearing in `oneof` definitions in this type. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<NSString*> *oneofsArray;
/** The number of items in @c oneofsArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger oneofsArray_Count;

/** The protocol buffer options. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<VPKGPBOption*> *optionsArray;
/** The number of items in @c optionsArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger optionsArray_Count;

/** The source context. */
@property(nonatomic, readwrite, strong, null_resettable) VPKGPBSourceContext *sourceContext;
/** Test to see if @c sourceContext has been set. */
@property(nonatomic, readwrite) BOOL hasSourceContext;

/** The source syntax. */
@property(nonatomic, readwrite) VPKGPBSyntax syntax;

@end

/**
 * Fetches the raw value of a @c VPKGPBType's @c syntax property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t VPKGPBType_Syntax_RawValue(VPKGPBType *message);
/**
 * Sets the raw value of an @c VPKGPBType's @c syntax property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetVPKGPBType_Syntax_RawValue(VPKGPBType *message, int32_t value);

#pragma mark - VPKGPBField

typedef VPKGPB_ENUM(VPKGPBField_FieldNumber) {
  VPKGPBField_FieldNumber_Kind = 1,
  VPKGPBField_FieldNumber_Cardinality = 2,
  VPKGPBField_FieldNumber_Number = 3,
  VPKGPBField_FieldNumber_Name = 4,
  VPKGPBField_FieldNumber_TypeURL = 6,
  VPKGPBField_FieldNumber_OneofIndex = 7,
  VPKGPBField_FieldNumber_Packed = 8,
  VPKGPBField_FieldNumber_OptionsArray = 9,
  VPKGPBField_FieldNumber_JsonName = 10,
  VPKGPBField_FieldNumber_DefaultValue = 11,
};

/**
 * A single field of a message type.
 **/
VPKGPB_FINAL @interface VPKGPBField : VPKGPBMessage

/** The field type. */
@property(nonatomic, readwrite) VPKGPBField_Kind kind;

/** The field cardinality. */
@property(nonatomic, readwrite) VPKGPBField_Cardinality cardinality;

/** The field number. */
@property(nonatomic, readwrite) int32_t number;

/** The field name. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *name;

/**
 * The field type URL, without the scheme, for message or enumeration
 * types. Example: `"type.googleapis.com/google.protobuf.Timestamp"`.
 **/
@property(nonatomic, readwrite, copy, null_resettable) NSString *typeURL;

/**
 * The index of the field type in `Type.oneofs`, for message or enumeration
 * types. The first type has index 1; zero means the type is not in the list.
 **/
@property(nonatomic, readwrite) int32_t oneofIndex;

/** Whether to use alternative packed wire representation. */
@property(nonatomic, readwrite) BOOL packed;

/** The protocol buffer options. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<VPKGPBOption*> *optionsArray;
/** The number of items in @c optionsArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger optionsArray_Count;

/** The field JSON name. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *jsonName;

/** The string value of the default value of this field. Proto2 syntax only. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *defaultValue;

@end

/**
 * Fetches the raw value of a @c VPKGPBField's @c kind property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t VPKGPBField_Kind_RawValue(VPKGPBField *message);
/**
 * Sets the raw value of an @c VPKGPBField's @c kind property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetVPKGPBField_Kind_RawValue(VPKGPBField *message, int32_t value);

/**
 * Fetches the raw value of a @c VPKGPBField's @c cardinality property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t VPKGPBField_Cardinality_RawValue(VPKGPBField *message);
/**
 * Sets the raw value of an @c VPKGPBField's @c cardinality property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetVPKGPBField_Cardinality_RawValue(VPKGPBField *message, int32_t value);

#pragma mark - VPKGPBEnum

typedef VPKGPB_ENUM(VPKGPBEnum_FieldNumber) {
  VPKGPBEnum_FieldNumber_Name = 1,
  VPKGPBEnum_FieldNumber_EnumvalueArray = 2,
  VPKGPBEnum_FieldNumber_OptionsArray = 3,
  VPKGPBEnum_FieldNumber_SourceContext = 4,
  VPKGPBEnum_FieldNumber_Syntax = 5,
};

/**
 * Enum type definition.
 **/
VPKGPB_FINAL @interface VPKGPBEnum : VPKGPBMessage

/** Enum type name. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *name;

/** Enum value definitions. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<VPKGPBEnumValue*> *enumvalueArray;
/** The number of items in @c enumvalueArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger enumvalueArray_Count;

/** Protocol buffer options. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<VPKGPBOption*> *optionsArray;
/** The number of items in @c optionsArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger optionsArray_Count;

/** The source context. */
@property(nonatomic, readwrite, strong, null_resettable) VPKGPBSourceContext *sourceContext;
/** Test to see if @c sourceContext has been set. */
@property(nonatomic, readwrite) BOOL hasSourceContext;

/** The source syntax. */
@property(nonatomic, readwrite) VPKGPBSyntax syntax;

@end

/**
 * Fetches the raw value of a @c VPKGPBEnum's @c syntax property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t VPKGPBEnum_Syntax_RawValue(VPKGPBEnum *message);
/**
 * Sets the raw value of an @c VPKGPBEnum's @c syntax property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetVPKGPBEnum_Syntax_RawValue(VPKGPBEnum *message, int32_t value);

#pragma mark - VPKGPBEnumValue

typedef VPKGPB_ENUM(VPKGPBEnumValue_FieldNumber) {
  VPKGPBEnumValue_FieldNumber_Name = 1,
  VPKGPBEnumValue_FieldNumber_Number = 2,
  VPKGPBEnumValue_FieldNumber_OptionsArray = 3,
};

/**
 * Enum value definition.
 **/
VPKGPB_FINAL @interface VPKGPBEnumValue : VPKGPBMessage

/** Enum value name. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *name;

/** Enum value number. */
@property(nonatomic, readwrite) int32_t number;

/** Protocol buffer options. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<VPKGPBOption*> *optionsArray;
/** The number of items in @c optionsArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger optionsArray_Count;

@end

#pragma mark - VPKGPBOption

typedef VPKGPB_ENUM(VPKGPBOption_FieldNumber) {
  VPKGPBOption_FieldNumber_Name = 1,
  VPKGPBOption_FieldNumber_Value = 2,
};

/**
 * A protocol buffer option, which can be attached to a message, field,
 * enumeration, etc.
 **/
VPKGPB_FINAL @interface VPKGPBOption : VPKGPBMessage

/**
 * The option's name. For protobuf built-in options (options defined in
 * descriptor.proto), this is the short name. For example, `"map_entry"`.
 * For custom options, it should be the fully-qualified name. For example,
 * `"google.api.http"`.
 **/
@property(nonatomic, readwrite, copy, null_resettable) NSString *name;

/**
 * The option's value packed in an Any message. If the value is a primitive,
 * the corresponding wrapper type defined in google/protobuf/wrappers.proto
 * should be used. If the value is an enum, it should be stored as an int32
 * value using the google.protobuf.Int32Value type.
 **/
@property(nonatomic, readwrite, strong, null_resettable) VPKGPBAny *value;
/** Test to see if @c value has been set. */
@property(nonatomic, readwrite) BOOL hasValue;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)

// clang-format on
