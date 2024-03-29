#!/bin/sh

set -ex

VERSION="2.15.0"

rm -rf TensorFlowLiteC.xcframework
rm -rf TensorFlowLiteC.xcframework.zip
rm -rf TensorFlowLiteC

mkdir -p TensorFlowLiteC/android
mkdir -p TensorFlowLiteC/macos/arm64
mkdir -p TensorFlowLiteC/macos/x86_64

pushd TensorFlowLiteC
	# Download precompiled android binaries from Maven Central
	pushd android
		wget https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$VERSION/tensorflow-lite-$VERSION.aar
		unzip tensorflow-lite-$VERSION.aar
	popd

	# Clone and compile tensorflow lite for macOS (arm64 and x86_64)
	git clone --depth 1 --branch v$VERSION https://github.com/tensorflow/tensorflow.git
	pushd tensorflow
		bazel build --config=monolithic -c opt --cpu=darwin_x86_64 --host_cpu=darwin_arm64 --macos_minimum_os=11.0 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../macos/x86_64

		bazel build --config=monolithic -c opt --cpu=darwin_arm64 --host_cpu=darwin_arm64 --macos_minimum_os=11.0 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../macos/arm64

		# Merge 2 dylib to fat binary
		lipo ../macos/arm64/libtensorflowlite_c.dylib \
	 		../macos/x86_64/libtensorflowlite_c.dylib \
	 		-output ../macos/libtensorflowlite_c.dylib -create
	popd

	# Copy headers
	mkdir -p Headers/tensorflow/lite/c
	mkdir -p Headers/tensorflow/lite/core/c
	mkdir -p Headers/tensorflow/lite/core/async/c
	mkdir -p Headers/tensorflow/lite/delegates/xnnpack

	cp tensorflow/tensorflow/lite/builtin_ops.h Headers/tensorflow/lite
	cp tensorflow/tensorflow/lite/c/c_api_experimental.h Headers/tensorflow/lite/c
	cp tensorflow/tensorflow/lite/c/c_api_opaque.h Headers/tensorflow/lite/c
	cp tensorflow/tensorflow/lite/c/c_api_types.h Headers/tensorflow/lite/c
	cp tensorflow/tensorflow/lite/c/c_api.h Headers/tensorflow/lite/c
	cp tensorflow/tensorflow/lite/c/common.h Headers/tensorflow/lite/c
	cp tensorflow/tensorflow/lite/core/c/c_api_experimental.h Headers/tensorflow/lite/core/c
	cp tensorflow/tensorflow/lite/core/c/c_api_opaque.h Headers/tensorflow/lite/core/c
	cp tensorflow/tensorflow/lite/core/c/c_api_types.h Headers/tensorflow/lite/core/c
	cp tensorflow/tensorflow/lite/core/c/c_api.h Headers/tensorflow/lite/core/c
	cp tensorflow/tensorflow/lite/core/c/common.h Headers/tensorflow/lite/core/c
	cp tensorflow/tensorflow/lite/core/c/registration_external.h Headers/tensorflow/lite/core/c
	cp tensorflow/tensorflow/lite/delegates/xnnpack/xnnpack_delegate.h Headers/tensorflow/lite/delegates/xnnpack
	cp tensorflow/tensorflow/lite/core/async/c/types.h Headers/tensorflow/lite/core/async/c/types.h

	# Add module map and umberlla header
	echo """module TensorFlowLiteC [extern_c] {
	header \"TensorFlowLiteC.h\"
	export *
}
	""" > Headers/module.modulemap
	
	echo """#import \"tensorflow/lite/builtin_ops.h\"
#import \"tensorflow/lite/c/c_api.h\"
#import \"tensorflow/lite/c/c_api_experimental.h\"
#import \"tensorflow/lite/c/common.h\"
#import \"tensorflow/lite/c/c_api_types.h\"
#import \"tensorflow/lite/delegates/xnnpack/xnnpack_delegate.h\"
	""" > Headers/TensorFlowLiteC.h
popd

# Create xcframework and copy all binaries and headers
mkdir TensorFlowLiteC.xcframework

mkdir -p TensorFlowLiteC.xcframework/macos-arm64_x86_64/Headers
cp -r TensorFlowLiteC/Headers TensorFlowLiteC.xcframework/macos-arm64_x86_64
cp TensorFlowLiteC/macos/libtensorflowlite_c.dylib TensorFlowLiteC.xcframework/macos-arm64_x86_64

mkdir -p TensorFlowLiteC.xcframework/android-arm64-v8a/Headers
cp -r TensorFlowLiteC/Headers TensorFlowLiteC.xcframework/android-arm64-v8a
cp TensorFlowLiteC/android/jni/arm64-v8a/libtensorflowlite_jni.so TensorFlowLiteC.xcframework/android-arm64-v8a

mkdir -p TensorFlowLiteC.xcframework/android-armeabi-v7a/Headers
cp -r TensorFlowLiteC/Headers TensorFlowLiteC.xcframework/android-armeabi-v7a
cp TensorFlowLiteC/android/jni/armeabi-v7a/libtensorflowlite_jni.so TensorFlowLiteC.xcframework/android-armeabi-v7a

mkdir -p TensorFlowLiteC.xcframework/android-x86_64/Headers
cp -r TensorFlowLiteC/Headers TensorFlowLiteC.xcframework/android-x86_64
cp TensorFlowLiteC/android/jni/x86_64/libtensorflowlite_jni.so TensorFlowLiteC.xcframework/android-x86_64

mkdir -p TensorFlowLiteC.xcframework/android-x86/Headers
cp -r TensorFlowLiteC/Headers TensorFlowLiteC.xcframework/android-x86
cp TensorFlowLiteC/android/jni/x86/libtensorflowlite_jni.so TensorFlowLiteC.xcframework/android-x86

# Add Info.plist for all libraries
echo """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>AvailableLibraries</key>
	<array>
		<dict>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>macos-arm64_x86_64</string>
			<key>LibraryPath</key>
			<string>libtensorflowlite_c.dylib</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
				<string>x86_64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>macos</string>
		</dict>
		<dict>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>android-arm64-v8a</string>
			<key>LibraryPath</key>
			<string>libtensorflowlite_jni.so</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>android</string>
		</dict>
		<dict>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>android-armeabi-v7a</string>
			<key>LibraryPath</key>
			<string>libtensorflowlite_jni.so</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>armeabi-v7a</string>
			</array>
			<key>SupportedPlatform</key>
			<string>android</string>
		</dict>
		<dict>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>android-x86_64</string>
			<key>LibraryPath</key>
			<string>libtensorflowlite_jni.so</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>x86_64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>android</string>
		</dict>
		<dict>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>android-x86</string>
			<key>LibraryPath</key>
			<string>libtensorflowlite_jni.so</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>x86</string>
			</array>
			<key>SupportedPlatform</key>
			<string>android</string>
		</dict>
	</array>
	<key>CFBundlePackageType</key>
	<string>XFWK</string>
	<key>XCFrameworkFormatVersion</key>
	<string>1.0</string>
</dict>
</plist>
""" > TensorFlowLiteC.xcframework/Info.plist

zip -ry TensorFlowLiteC-$VERSION.xcframework.zip TensorFlowLiteC.xcframework
