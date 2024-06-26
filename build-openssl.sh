#!/usr/bin/env bash

source ./check-environment.sh || exit 1

cd $(dirname $0)

if [ -e "$OPENSSL_INSTALL_DIR" ]; then
  echo "Warning: file or directory \"$OPENSSL_INSTALL_DIR\" already exists."
  rm -rf $OPENSSL_INSTALL_DIR
fi

mkdir -p $OPENSSL_INSTALL_DIR || exit 1
echo "Downloading OpenSSL sources..."
rm -f $OPENSSL_VERSION.tar.gz || exit 1
$WGET https://github.com/openssl/openssl/archive/refs/tags/$OPENSSL_VERSION.tar.gz || exit 1
rm -rf ./openssl-$OPENSSL_VERSION || exit 1
tar xzf $OPENSSL_VERSION.tar.gz || exit 1
rm $OPENSSL_VERSION.tar.gz || exit 1
cd openssl-$OPENSSL_VERSION

export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION  # for OpenSSL 3.0
export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT                           # for OpenSSL 1.1.1
PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$HOST_ARCH/bin:$PATH

if ! clang --help >/dev/null 2>&1 ; then
  echo "Error: failed to run clang from Android NDK."
  if [[ "$OS_NAME" == "linux" ]] ; then
    echo "Prebuilt Android NDK binaries are linked against glibc, so glibc must be installed."
  fi
  exit 1
fi

OPENSSL_FLAGS="shared"

for ABI in arm64-v8a armeabi-v7a x86_64 x86 ; do
  if [[ $ABI == "x86" ]] ; then
    ./Configure android-x86 $OPENSSL_FLAGS -U__ANDROID_API__ -D__ANDROID_API__=$ANDROID_MIN_SDK || exit 1
  elif [[ $ABI == "x86_64" ]] ; then
    ./Configure android-x86_64 $OPENSSL_FLAGS -U__ANDROID_API__ -D__ANDROID_API__=$ANDROID_MIN_SDK || exit 1
  elif [[ $ABI == "armeabi-v7a" ]] ; then
    ./Configure android-arm $OPENSSL_FLAGS -U__ANDROID_API__ -D__ANDROID_API__=$ANDROID_MIN_SDK -D__ARM_MAX_ARCH__=8 || exit 1
  elif [[ $ABI == "arm64-v8a" ]] ; then
    ./Configure android-arm64 $OPENSSL_FLAGS -U__ANDROID_API__ -D__ANDROID_API__=$ANDROID_MIN_SDK || exit 1
  fi

  sed -i.bak 's/-O3/-O3 -ffunction-sections -fdata-sections/g' Makefile || exit 1

  make depend -s || exit 1
  make -s || exit 1

  mkdir -p $OPENSSL_INSTALL_DIR/$ABI/lib/ || exit 1
  cp libcrypto.so libssl.so $OPENSSL_INSTALL_DIR/$ABI/lib/ || exit 1
  cp -r include $OPENSSL_INSTALL_DIR/$ABI/ || exit 1

  llvm-strip -s $OPENSSL_INSTALL_DIR/$ABI/lib/* || exit 1

  make distclean || exit 1
done

cd ..

rm -rf ./openssl-$OPENSSL_VERSION || exit 1
