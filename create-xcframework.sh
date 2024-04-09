#!/bin/sh

set -ex

VERSION="2.15.0"

rm -rf RDTensorFlowLite*

mkdir RDTensorFlowLiteC
pushd RDTensorFlowLiteC
	# Download precompiled android binaries from Maven Central
	mkdir android
	pushd android
		wget https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$VERSION/tensorflow-lite-$VERSION.aar
		unzip tensorflow-lite-$VERSION.aar
	popd

	# Clone and compile tensorflow lite for macOS (arm64 and x86_64)
	mkdir -p macos/arm64
	mkdir -p macos/x86_64
	git clone --depth 1 --branch v$VERSION https://github.com/tensorflow/tensorflow.git
	pushd tensorflow
		bazel build --config=monolithic -c opt --cpu=darwin_x86_64 --host_cpu=darwin_arm64 --macos_minimum_os=10.15 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../macos/x86_64

		bazel build --config=monolithic -c opt --cpu=darwin_arm64 --host_cpu=darwin_arm64 --macos_minimum_os=10.15 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../macos/arm64

		# Merge 2 dylib to fat binary
		lipo ../macos/arm64/libtensorflowlite_c.dylib \
	 		../macos/x86_64/libtensorflowlite_c.dylib \
	 		-output ../macos/libtensorflowlite_c.dylib -create
	popd

	# Copy headers
	mkdir -p Headers
	cp tensorflow/tensorflow/lite/builtin_ops.h Headers
	cp tensorflow/tensorflow/lite/core/c/c_api_experimental.h Headers
	cp tensorflow/tensorflow/lite/core/c/c_api_opaque.h Headers
	cp tensorflow/tensorflow/lite/core/c/c_api_types.h Headers
	cp tensorflow/tensorflow/lite/core/c/c_api.h Headers
	cp tensorflow/tensorflow/lite/core/c/common.h Headers
	cp tensorflow/tensorflow/lite/core/c/registration_external.h Headers
	cp tensorflow/tensorflow/lite/delegates/xnnpack/xnnpack_delegate.h Headers
	cp tensorflow/tensorflow/lite/core/async/c/types.h Headers

	# Fixed headers includes
	find Headers -type f -name "*.h" -print0 | xargs -0 sed -i '' -e 's|#include "\(.*\)/\([^/]*\)"|#include "\2"|g'

	# Add module map and umberlla header
	echo """module RDTensorFlowLiteC [extern_c] {
	header \"RDTensorFlowLiteC.h\"
	export *
}
	""" > Headers/module.modulemap
	
	echo """#import \"builtin_ops.h\"
#import \"c_api.h\"
#import \"c_api_experimental.h\"
#import \"common.h\"
#import \"c_api_types.h\"
#import \"xnnpack_delegate.h\"
	""" > Headers/RDTensorFlowLiteC.h
popd

# Create tar gz for macOS CocoaPods
mkdir RDTensorFlowLiteC-$VERSION-macos-arm64_x86_64
cp RDTensorFlowLiteC/macos/libtensorflowlite_c.dylib RDTensorFlowLiteC-$VERSION-macos-arm64_x86_64
cp -r RDTensorFlowLiteC/Headers RDTensorFlowLiteC-$VERSION-macos-arm64_x86_64
tar -zcvf RDTensorFlowLiteC-$VERSION-macos-arm64_x86_64.tar.gz RDTensorFlowLiteC-$VERSION-macos-arm64_x86_64

# Copy Android binaries to xcframework
mkdir -p RDTensorFlowLiteC-$VERSION-android/include
cp -r RDTensorFlowLiteC/Headers/* RDTensorFlowLiteC-$VERSION-android/include
cp -r RDTensorFlowLiteC/android/jni/* RDTensorFlowLiteC-$VERSION-android
tar -zcvf RDTensorFlowLiteC-$VERSION-android.tar.gz RDTensorFlowLiteC-$VERSION-android

# Create xcframework for macOS
xcodebuild -create-xcframework \
	-library RDTensorFlowLiteC/macos/libtensorflowlite_c.dylib \
	-headers RDTensorFlowLiteC/Headers \
	-output ./RDTensorFlowLiteC.xcframework
zip -ry RDTensorFlowLiteC-$VERSION.xcframework.zip RDTensorFlowLiteC.xcframework
