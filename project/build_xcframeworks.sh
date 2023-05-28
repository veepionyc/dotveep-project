#/bin/bash

# use this bash script to build the xcframeworks

function cleanup () {
   rm -r archives
   rm -r ../xcframeworks_new
   rm -r ../xcframeworks_old
}

function checkstatus () {
    if [ $1 -eq 0 ]
    then
        echo "$(date) xcodebuild was successful"

    else
        echo "$(date) xcodebuild failed: $1"
        say "X Code build failed with error code $1"
        cleanup
    exit 1
    fi
}

function build_archives() {
    rm -r archives

    schemename=$1

     xcodebuild archive \
     -scheme $schemename \
     -project 'dotveep.xcodeproj' \
     -destination 'generic/platform=iOS' \
     -archivePath "archives/dotveep-iOS" \
     clean

    checkstatus $?

     xcodebuild archive \
     -scheme $schemename\
     -project 'dotveep.xcodeproj' \
     -destination 'generic/platform=iOS Simulator' \
     -archivePath "archives/dotveep-iOS_Simulator" \
     clean
     
    checkstatus $?
    
    xcodebuild \
    -create-xcframework \
    -archive archives/dotveep-iOS.xcarchive -framework dotveep.framework \
    -archive archives/dotveep-iOS_Simulator.xcarchive -framework dotveep.framework \
    -output ../xcframeworks_new/$schemename/dotveep.xcframework
    
    checkstatus $?
 

}

#exec > archive.log 2>&1


build_archives 'dotveep-dynamic'
build_archives 'dotveep-static'


mv ../xcframeworks ../xcframeworks_old
mv ../xcframeworks_new ../xcframeworks
cleanup

bold=$(tput bold)
normal=$(tput sgr0)

echo ""
echo "${bold}** XCFrameworks built successfully **${normal}"

