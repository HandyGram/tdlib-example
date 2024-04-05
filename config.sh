# it's easier to setup all this stuff in a single place
export \
    ANDROID_NDK_VERSION=26.2.11394342 \
    ANDROID_SDK_ROOT=${1:-SDK} \
    OPENSSL_VERSION=openssl-3.2.1 \
    OPENSSL_INSTALL_DIR=third-party/openssl \
    ANDROID_STL=c++_static \
    COMMANDLINETOOLS_VERSION=11076708 \
    CMAKE_VERSION=3.22.1 \
    ANDROID_PLATFORM=34 \
    ANDROID_MIN_SDK=21

export TD_ROOT="$(dirname $(realpath $0 2>/dev/null || readlink -f $0 2>/dev/null))/../.."

if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    FALLBACK_PATH="$(pwd)/sdk"
    echo "Warning: Android SDK path isn't defined. Using $FALLBACK_PATH"
    ANDROID_SDK_ROOT="$FALLBACK_PATH"
fi
