veepio protobuf model 
===
bindings, runtime, project, xcframeworks



bindings
===

- src/veep.proto
    the veep protobuf model

- objc bindings
    the generated bindings for the veep protobuf model
    
  see bindgs/README.md on how to generate the bindings from the veep.proto model using `protoc`
    
runtime
===

the Objective-C protobuf runtime 

`_namespaces.sh` prefixes GPB namespace to VPKGPB


project
===

(Deprecated - for VPKit use dotveep-spm)

the XCode framework project to build dotveep.xcframework

    
the objective-c language bindings for our veep.proto model 

- version of protobuf must match the version of protoc used to generate our veep protobuf models
    `Veep.pbobjc.h` 
    `Veep.pbobjc.m`
    
    
see also
VPKProtbuf/README.md


xcframeworks
===

(Deprecated - for VPKit use dotveep-spm)

build script - project/build_xcframeworks.sh




see also
===

## dotveep-spm   
 Swift Package Manager distribution of dotveep bindings and VPKGPB runtime

## dotveep  
Previous docker-based generation scripts and tests for dotveep bindings
