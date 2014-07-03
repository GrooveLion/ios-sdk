#!/bin/sh

TARGET=GLESDK
ACTION="clean build"
FILE_NAME=libGLESDK.a

DEVICE=iphoneos7.1
SIMULATOR=iphonesimulator7.1

DDPATH="${SYMROOT}/../.."

xcodebuild -configuration Release -scheme ${TARGET} -sdk ${DEVICE} -derivedDataPath ${DDPATH} ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO
xcodebuild -configuration Release ARCHS="i386 x86_64" VALID_ARCHS="i386 x86_64" -scheme ${TARGET} -sdk ${SIMULATOR} -derivedDataPath ${DDPATH} ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO

RELEASE_DEVICE_DIR=${SYMROOT}/Release-iphoneos
RELEASE_SIMULATOR_DIR=${SYMROOT}/Release-iphonesimulator
RELEASE_UNIVERSAL_DIR=${SYMROOT}/Release-universal

rm -rf "${RELEASE_UNIVERSAL_DIR}"
mkdir "${RELEASE_UNIVERSAL_DIR}"

lipo -create -output "${RELEASE_UNIVERSAL_DIR}/${FILE_NAME}" "${RELEASE_DEVICE_DIR}/${FILE_NAME}" "${RELEASE_SIMULATOR_DIR}/${FILE_NAME}"

open ${RELEASE_UNIVERSAL_DIR}
