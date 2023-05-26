# Veepio protobuf format

## Veep file format

A file format for annotating media (photos and videos) with URLs

## Veepio APIs

Our APIs will be available in protobuf format.

## Veeps are streamable

We need to support annotation of all objects in a two hour movie. We
can't delay playback until the veep is fully loaded, so veeps must be
streamable. test/demo_protobuf_streaming demonstrates that although the
protobuf parser does not support streaming, messages can be broken down
and parsed separately.

## Dependencies

  - `protoc` that supports protocol buffers version 3

  get `protoc` from here:  
  https://github.com/google/protobuf/releases  
  Find the correct version for your platform, eg  
  `protoc-22.0-osx-x86_64.zip`
  To install, place the `protoc` binary somewhere in your PATH  
  eg `/usr/local/bin`
  

## Usage

   protoc -I=src --objc_out=objc_bindings src/veep.proto
   

#current version is (3).22.0
