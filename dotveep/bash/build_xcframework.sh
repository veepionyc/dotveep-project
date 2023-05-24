
#://eladnava.com/publish-a-universal-binary-ios-framework-in-swift-using-cocoapods/
# https://gist.github.com/eladnava/0824d08da8f99419ef2c7b7fb6d4cc78
# https://instabug.com/blog/ios-binary-framework/  (using aggregate and putting THIS script into run script build phase)

#exec > /tmp/${PROJECT_NAME}_archive.log 2>&1

# Fix errors:
# conflicting deployment targets, both 'MACOSX_DEPLOYMENT_TARGET' and 'IPHONEOS_DEPLOYMENT_TARGET' are present in environment
unset MACOSX_DEPLOYMENT_TARGET
unset TVOS_DEPLOYMENT_TARGET
unset WATCHOS_DEPLOYMENT_TARGET
unset DRIVERKIT_DEPLOYMENT_TARGET

echo "starting fat binary bash script"
echo "${BUILD_DIR}"
UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal

if [ "true" == ${ALREADYINVOKED:-false} ]
then
echo "RECURSION: Detected, stopping"
else
export ALREADYINVOKED="true"

# make sure the output directory exists
rm -R "${UNIVERSAL_OUTPUTFOLDER}"
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

echo "Building for iPhoneSimulator - generic"
#xcodebuild \
#-sdk iphonesimulator               \
#-destination "generic/platform=iOS Simulator" \
#SKIP_INSTALL=NO \
#BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
#ENABLE_BITCODE=NO                  \
#clean build



xcodebuild clean build \
-workspace "${WORKSPACE_PATH}"     \
-scheme "${TARGET_NAME}"           \
-configuration ${CONFIGURATION}    \
-sdk iphonesimulator               \
-destination "generic/platform=iOS Simulator" \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
ENABLE_BITCODE=NO                 \
BUILD_DIR="${BUILD_DIR}"           \
#BUILD_ROOT="${BUILD_DIR}"   \


status=$?

echo "$(date) Build status: $status"
if [ $status -eq 0 ]
then
    echo "$(date) xcodebuild was successful"
else
    echo "$(date) xcodebuild failed: $status"
exit 1
fi



## Step 2. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
#SIMULATOR_SWIFT_MODULES_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${TARGET_NAME}.framework/Modules/${TARGET_NAME}.swiftmodule/."
#if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
#cp -R "${SIMULATOR_SWIFT_MODULES_DIR}" "${UNIVERSAL_OUTPUTFOLDER}/${TARGET_NAME}.framework/Modules/${TARGET_NAME}.swiftmodule"
#fi
#

# Step 4. Generate an xc framework
echo "xc input 1 ${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PRODUCT_NAME}.framework"
echo "xc input 2 ${ARCHIVE_PRODUCTS_PATH}${INSTALL_PATH}/${PRODUCT_NAME}.framework"
echo "xc output 3 ${UNIVERSAL_OUTPUTFOLDER}/${TARGET_NAME}.xcframework"

SIMULATOR_FRAMEWORK="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PRODUCT_NAME}.framework"
DEVICE_FRAMEWORK="${ARCHIVE_PRODUCTS_PATH}${INSTALL_PATH}/${PRODUCT_NAME}.framework"
OUT_XCFRAMEWORK="${UNIVERSAL_OUTPUTFOLDER}/${PRODUCT_NAME}.xcframework"
xcodebuild -create-xcframework -framework "$DEVICE_FRAMEWORK" -framework "$SIMULATOR_FRAMEWORK" -output "$OUT_XCFRAMEWORK"


# Step 5. Convenience step to copy the framework to the project's directory
echo "Copying to project dir"
echo "${UNIVERSAL_OUTPUTFOLDER}/${FULL_PRODUCT_NAME}" "${PROJECT_DIR}"
if [ -d "${PROJECT_DIR}/../frameworks/${TARGET_NAME}/${PRODUCT_NAME}.xcframework" ]; then
    echo "rsync"
    yes | rsync -r --delete "${OUT_XCFRAMEWORK}" "${PROJECT_DIR}/../frameworks/${TARGET_NAME}/"
else
    echo "cp"
    mkdir -p "${PROJECT_DIR}/../frameworks/${TARGET_NAME}/"
    cp -R "${OUT_XCFRAMEWORK}" "${PROJECT_DIR}/../frameworks/${TARGET_NAME}/${PRODUCT_NAME}.xcframework"
fi

open "${PROJECT_DIR}/../frameworks/${TARGET_NAME}/"

fi
