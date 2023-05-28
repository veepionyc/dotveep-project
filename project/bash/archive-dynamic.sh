#/bin/bash
 xcodebuild archive \
 -scheme 'dotveep-dynamic' \
 -project '../dotveep.xcodeproj' \
 -destination 'generic/platform=iOS' \
 clean
