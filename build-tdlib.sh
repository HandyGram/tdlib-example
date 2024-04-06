#!/usr/bin/env bash

source ./config.sh || exit 1

if [ "$ANDROID_STL" != "c++_static" ] && [ "$ANDROID_STL" != "c++_shared" ] ; then
  echo 'Error: ANDROID_STL must be either "c++_static" or "c++_shared".'
  exit 1
fi

source ./check-environment.sh || exit 1

if [ ! -d "$ANDROID_SDK_ROOT" ] ; then
  echo "Error: directory \"$ANDROID_SDK_ROOT\" doesn't exist. Run ./fetch-sdk.sh first, or provide a valid path to Android SDK."
  exit 1
fi

if [ ! -d "$OPENSSL_INSTALL_DIR" ] ; then
  echo "Error: directory \"$OPENSSL_INSTALL_DIR\" doesn't exists. Run ./build-openssl.sh first."
  exit 1
fi

ANDROID_SDK_ROOT="$(cd "$(dirname -- "$ANDROID_SDK_ROOT")" >/dev/null; pwd -P)/$(basename -- "$ANDROID_SDK_ROOT")"
ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION"
OPENSSL_INSTALL_DIR="$(cd "$(dirname -- "$OPENSSL_INSTALL_DIR")" >/dev/null; pwd -P)/$(basename -- "$OPENSSL_INSTALL_DIR")"
PATH=$ANDROID_SDK_ROOT/cmake/$CMAKE_VERSION/bin:$PATH

cd $(dirname $0)

echo "Generating TDLib source files..."
mkdir -p build-native || exit 1
cd build-native
cmake $TD_ROOT || exit 1
cmake --build . --target prepare_cross_compiling || exit 1
cd ..


echo "Building TDLib..."
for ABI in arm64-v8a armeabi-v7a x86_64 x86 ; do
  mkdir -p build-$ABI install-$ABI || exit 1
  cd build-$ABI
  cmake \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
    -DCMAKE_FIND_ROOT_PATH="$OPENSSL_INSTALL_DIR/$ABI" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_CXX_FLAGS_RELWITHDEBINFO=" -flto=thin -Oz" \
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--gc-sections,--icf=safe" \
    -GNinja \
    -DANDROID_ABI=$ABI \
    -DANDROID_STL=$ANDROID_STL \
    -DANDROID_PLATFORM=android-$ANDROID_MIN_SDK \
    -DCMAKE_INSTALL_PREFIX=../install-$ABI \
    "$TD_ROOT" || exit 1
  
  ninja install || exit 1
  cd ..

  mkdir -p tdlib/libs/$ABI/ || exit 1
  cp -p install-$ABI/lib/libtdjson.so tdlib/libs/$ABI/ || exit 1
  cp $OPENSSL_INSTALL_DIR/$ABI/lib/*.so tdlib/libs/$ABI/
  "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$HOST_ARCH/bin/llvm-strip" tdlib/libs/$ABI/*.so
  if [[ "$ANDROID_STL" == "c++_shared" ]] ; then
    if [[ "$ABI" == "arm64-v8a" ]] ; then
      FULL_ABI="aarch64-linux-android"
    elif [[ "$ABI" == "armeabi-v7a" ]] ; then
      FULL_ABI="arm-linux-androideabi"
    elif [[ "$ABI" == "x86_64" ]] ; then
      FULL_ABI="x86_64-linux-android"
    elif [[ "$ABI" == "x86" ]] ; then
      FULL_ABI="i686-linux-android"
    fi
    cp "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$HOST_ARCH/sysroot/usr/lib/$FULL_ABI/libc++_shared.so" tdlib/libs/$ABI/ || exit 1
    "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$HOST_ARCH/bin/llvm-strip" tdlib/libs/$ABI/libc++_shared.so || exit 1
  fi
done

echo "Generating README.md..."
COMMIT_ID="$(cd $TD_ROOT && git rev-parse --short HEAD)"
TD_VERSION=$(grep 'TDLib VERSION' $TD_ROOT/CMakeLists.txt | cut -d ' ' -f 3)
REMOTE_URL="$(cd $TD_ROOT && git remote get-url $(git remote))"
REMOTE_NAME="$(sed -E 's#https*://[A-Za-z0-9.]*\/##' <<< "$REMOTE_URL")"
DATE="$(LC_ALL=C date "+%b %d %Y %H:%M %Z")"
echo "### TDLib build information
|                 |                                                           |
|:----------------|----------------------------------------------------------:|" > tdlib/README.md
echo \
"| **Build date**  | $(printf '%-57s' "$DATE") |
| **Version**     | $(printf '%-57s' "$TD_VERSION") |
| **Commit**      | $(printf '%-57s' "$COMMIT_ID") |
| **Repository**  | $(printf '%-57s' "[$REMOTE_NAME]($REMOTE_URL)") |" >> tdlib/README.md

echo "Compressing..."

rm -f tdlib.zip || exit 1
mkdir -p tdlib/scheme
cp -f $TD_ROOT/td/generate/scheme/td_api.tl tdlib/scheme/td_api.tl
zip -r tdlib.zip tdlib || exit 1
mv tdlib.zip tdlib || exit 1

echo "Done."
