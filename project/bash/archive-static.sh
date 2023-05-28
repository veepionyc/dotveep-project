#/bin/bash
 xcodebuild archive \
 -scheme 'dotveep-static' \
 -project "../dotveep.xcodeproj" \
 -destination 'generic/platform=iOS' \
 clean
