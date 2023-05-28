veepio protobuf model framework
===

bindings
===

- src/veep.proto
    the veep protobuf model

- objc bindings
    the generated bindings for the veep protobuf model
    
  see bindgs/README.md on how to generate the bindings from the veep.proto model using `protoc`
    
project
===

the XCode framework project to build dotveep.xcframework

    
the objective-c language bindings for our veep.proto model 

- version of protobuf must match the version of protoc used to generate our veep protobuf models
    `Veep.pbobjc.h` 
    `Veep.pbobjc.m`
    
    
see also
VPKProtbuf/README.md


xcframeworks
===
build script - project/build_xcframeworks.sh

