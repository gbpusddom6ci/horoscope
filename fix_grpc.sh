#!/bin/bash
DERIVED_DATA_DIR="/Users/malware/Library/Developer/Xcode/DerivedData/horoscope-*"
find $DERIVED_DATA_DIR -name "grpc.xcframework" -exec touch {}/Info.plist \;
find $DERIVED_DATA_DIR -name "grpcpp.xcframework" -exec touch {}/Info.plist \;
find $DERIVED_DATA_DIR -name "openssl_grpc.xcframework" -exec touch {}/Info.plist \;
find $DERIVED_DATA_DIR -name "absl.xcframework" -exec touch {}/Info.plist \;
echo "Created empty Info.plist files"
