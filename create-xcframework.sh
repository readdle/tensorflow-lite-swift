#!/bin/sh

set -ex

VERSION="2.17.0"

rm -rf TensorFlowLiteC*

mkdir TensorFlowLiteC
pushd TensorFlowLiteC
	# Download precompiled android binaries from Maven Central
	# mkdir android
	# pushd android
	# 	wget https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$VERSION/tensorflow-lite-$VERSION.aar
	# 	unzip tensorflow-lite-$VERSION.aar
	# popd

	# Clone and compile tensorflow lite for macOS (arm64 and x86_64) and ios/ios simulator (arm64)
	mkdir -p macos/arm64
	mkdir -p macos/x86_64
	mkdir -p ios_sim
	mkdir -p ios
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

		# Firstly we build framework to gte proper headers and module file
		bazel build --config=ios_arm64 -c opt //tensorflow/lite/ios:TensorFlowLiteC_framework --verbose_failures --jobs=4
		pushd bazel-bin/tensorflow/lite/ios
		    if [ -d "TensorFlowLiteC.framework" ]; then
		        echo "TensorFlowLiteC.framework exists."
		    else
		        unzip TensorFlowLiteC_framework.zip
		    fi
		popd
		
		cp -r bazel-bin/tensorflow/lite/ios/TensorFlowLiteC.framework/Headers ../
		cp -r bazel-bin/tensorflow/lite/ios/TensorFlowLiteC.framework/Modules ../

		bazel build --config=monolithic -c opt --cpu=darwin_x86_64 --host_cpu=darwin_arm64 --macos_minimum_os=10.15 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../macos/x86_64

		bazel build --config=monolithic -c opt --cpu=darwin_arm64 --host_cpu=darwin_arm64 --macos_minimum_os=10.15 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../macos/arm64

		bazel build --config=ios_sim_arm64 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../ios_sim

		bazel build --config=ios_arm64 tensorflow/lite/c:libtensorflowlite_c.dylib --verbose_failures --jobs=4
		cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ../ios
	popd

	# Create framework for macos
	pushd macos
		# Merge 2 dylib to fat binary
		lipo arm64/libtensorflowlite_c.dylib \
	 		x86_64/libtensorflowlite_c.dylib \
	 		-output libtensorflowlite_c.dylib -create

		mkdir TensorFlowLiteC.framework
		mkdir TensorFlowLiteC.framework/Headers
		mkdir TensorFlowLiteC.framework/Modules

		install_name_tool -id @rpath/TensorFlowLiteC.framework/TensorFlowLiteC libtensorflowlite_c.dylib
		mv libtensorflowlite_c.dylib TensorFlowLiteC.framework/TensorFlowLiteC
		cp ../Headers/* TensorFlowLiteC.framework/Headers/
		cp ../Modules/* TensorFlowLiteC.framework/Modules/

		cp ../../Info-macos.plist TensorFlowLiteC.framework/
		mv TensorFlowLiteC.framework/Info-macos.plist TensorFlowLiteC.framework/Info.plist
	popd

	# Create framework for iOS Simulator
	pushd ios_sim
		mkdir TensorFlowLiteC.framework
		mkdir TensorFlowLiteC.framework/Headers
		mkdir TensorFlowLiteC.framework/Modules

		install_name_tool -id @rpath/TensorFlowLiteC.framework/TensorFlowLiteC libtensorflowlite_c.dylib
		mv libtensorflowlite_c.dylib TensorFlowLiteC.framework/TensorFlowLiteC
		cp ../Headers/* TensorFlowLiteC.framework/Headers/
		cp ../Modules/* TensorFlowLiteC.framework/Modules/

		cp ../../Info-ios-sim.plist TensorFlowLiteC.framework/
		mv TensorFlowLiteC.framework/Info-ios-sim.plist TensorFlowLiteC.framework/Info.plist
	popd

	# Create framework for iOS
	pushd ios
		mkdir TensorFlowLiteC.framework
		mkdir TensorFlowLiteC.framework/Headers
		mkdir TensorFlowLiteC.framework/Modules

		install_name_tool -id @rpath/TensorFlowLiteC.framework/TensorFlowLiteC libtensorflowlite_c.dylib
		mv libtensorflowlite_c.dylib TensorFlowLiteC.framework/TensorFlowLiteC
		cp ../Headers/* TensorFlowLiteC.framework/Headers/
		cp ../Modules/* TensorFlowLiteC.framework/Modules/

		cp ../../Info-ios.plist TensorFlowLiteC.framework/
		mv TensorFlowLiteC.framework/Info-ios.plist TensorFlowLiteC.framework/Info.plist
	popd
popd

# Create xcframework for all platforms
xcodebuild -create-xcframework \
	-framework "TensorFlowLiteC/macos/TensorFlowLiteC.framework" \
	-framework "TensorFlowLiteC/ios_sim/TensorFlowLiteC.framework" \
	-framework "TensorFlowLiteC/ios/TensorFlowLiteC.framework" \
	-output ./TensorFlowLiteC.xcframework
zip -ry TensorFlowLiteC-$VERSION.xcframework.zip TensorFlowLiteC.xcframework
