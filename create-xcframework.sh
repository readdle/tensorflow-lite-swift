#!/bin/sh

set -ex

VERSION="2.16.1"

rm -rf TensorFlowLiteC*

mkdir TensorFlowLiteC
pushd TensorFlowLiteC
	# Download precompiled android binaries from Maven Central
	mkdir android
	pushd android
		wget https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$VERSION/tensorflow-lite-$VERSION.aar
		unzip tensorflow-lite-$VERSION.aar
	popd

	# Clone and compile tensorflow lite for macOS (arm64 and x86_64) and ios/ios simulator (arm64)
	mkdir -p macos/arm64
	mkdir -p macos/x86_64
	mkdir -p ios_sim_arm64
	mkdir -p ios_arm64
	git clone --depth 1 --branch v$VERSION https://github.com/tensorflow/tensorflow.git
	pushd tensorflow

		# Prepare Configuration Answers (Modify as needed)
		answers=(
		"" 	# Python? Default 
		""  # Python library paths? Default 
		n   # Radeon Open Compute? NO 
		n   # CUDA? NO 
		""  # Optimizations? Default 
		n   # Android? NO 
		y   # iOS? YES 
		) 

		configure_command="./configure"

		# Function to send answers to ./configure (updated)
		send_answers() {
    		for answer in "${answers[@]}"; do
        		if [ -z "$answer" ]; then   # Check if the answer is empty
            		printf '\n'            # Send a newline character (Enter key)
        		else
            		printf '%s\n' "$answer"  # Send the answer followed by newline
        		fi
    		done
		}

		# Execute ./configure with automated answers
		send_answers | $configure_command

		bazel build --config=monolithic -c opt --cpu=darwin_x86_64 --host_cpu=darwin_arm64 --macos_minimum_os=10.15 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../macos/x86_64

		bazel build --config=monolithic -c opt --cpu=darwin_arm64 --host_cpu=darwin_arm64 --macos_minimum_os=10.15 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../macos/arm64

		bazel build --config=ios_sim_arm64 -c opt //tensorflow/lite/ios:TensorFlowLiteC_framework --verbose_failures --jobs=4
		rm -rf bazel-bin/tensorflow/lite/ios/TensorFlowLiteC.framework
		unzip bazel-bin/tensorflow/lite/ios/TensorFlowLiteC_framework.zip -d bazel-bin/tensorflow/lite/ios/
		cp -r bazel-bin/tensorflow/lite/ios/TensorFlowLiteC.framework ../ios_sim_arm64

		bazel build --config=ios_arm64 -c opt //tensorflow/lite/ios:TensorFlowLiteC_framework --verbose_failures --jobs=4
		rm -rf bazel-bin/tensorflow/lite/ios/TensorFlowLiteC.framework
		unzip bazel-bin/tensorflow/lite/ios/TensorFlowLiteC_framework.zip -d bazel-bin/tensorflow/lite/ios/
		cp -r bazel-bin/tensorflow/lite/ios/TensorFlowLiteC.framework ../ios_arm64
	popd

	# Create framework for macOS
	pushd macos
		# Merge 2 dylib to fat binary
		lipo arm64/libtensorflowlite_c.dylib \
	 		x86_64/libtensorflowlite_c.dylib \
	 		-output libtensorflowlite_c.dylib -create

		mkdir TensorFlowLiteC.framework
		mkdir TensorFlowLiteC.framework/Versions
		mkdir TensorFlowLiteC.framework/Versions/A
		mkdir TensorFlowLiteC.framework/Versions/A/Headers
		mkdir TensorFlowLiteC.framework/Versions/A/Modules

		install_name_tool -id @rpath/TensorFlowLiteC.framework/TensorFlowLiteC libtensorflowlite_c.dylib
		cp libtensorflowlite_c.dylib TensorFlowLiteC.framework/Versions/A/
		cp ../ios_arm64/TensorFlowLiteC.framework/Headers/* TensorFlowLiteC.framework/Versions/A/Headers/
		cp ../ios_arm64/TensorFlowLiteC.framework/Modules/* TensorFlowLiteC.framework/Versions/A/Modules/

		pushd TensorFlowLiteC.framework
			ln -sf A Versions/Current
			ln -sf Versions/Current/Headers Headers
			ln -sf Versions/Current/Modules Modules
			ln -sf Versions/Current/libtensorflowlite_c.dylib TensorFlowLiteC
		popd
	popd
popd

# Create xcframework for all platforms
xcodebuild -create-xcframework \
	-framework "TensorFlowLiteC/macos/TensorFlowLiteC.framework" \
	-framework "TensorFlowLiteC/ios_sim_arm64/TensorFlowLiteC.framework" \
	-framework "TensorFlowLiteC/ios_arm64/TensorFlowLiteC.framework" \
	-output ./TensorFlowLiteC.xcframework
zip -ry TensorFlowLiteC-$VERSION.xcframework.zip TensorFlowLiteC.xcframework
