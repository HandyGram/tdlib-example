mkdir -p "$(dirname $0)/third-party/openssl"

export \
    OPENSSL_INSTALL_DIR="$(realpath $(dirname $0)/third-party/openssl)" \
    ANDROID_STL=c++_static \
    ANDROID_MIN_SDK=21

__sm_get_ver() {
    sdkmanager --list_installed 2>/dev/null | grep "$1;" | cut -d '|' -f 2 | sort --version-sort | tail -n 1 | xargs
}

__sm_get_vern() {
    sdkmanager --list_installed 2>/dev/null | grep "$1;" | cut -d '|' -f 1 | cut -d ';' -f 2 | sort --version-sort | tail -n 1 | xargs
}

__sm_get_latest_ver() {
    sdkmanager --list 2>/dev/null | grep "$1;" | cut -d '|' -f 1 | cut -d ';' -f 2 | sort --version-sort | tail -n 1 | xargs
}

sm_get_ver() {
    VER="$2"
    [ ! "$VER" ] && VER="$(__sm_get_latest_ver $1)" 

    tmp="$(__sm_get_ver "$1")"
    if [ ! "$tmp" ]; then
        sdkmanager "$1;$VER" || { echo "Cannot install $1;$VER with sdkmanager"; exit 1; }
        tmp="$(__sm_get_ver "$1;$VER")"
        [ ! "$tmp" ] && { echo "Cannot get $1;$VER fresh installation with sdkmanager"; exit 1; }
    else
        echo "$tmp"
    fi
}

sm_get_platform() {
    tmp="$(__sm_get_vern "platforms")"
    if [ ! "$tmp" ]; then
        sdkmanager "platforms;android-34" || { echo "Cannot install platforms;android-34 with sdkmanager"; exit 1; }
        tmp="$(__sm_get_vern "platforms")"
        [ ! "$tmp" ] && { echo "Cannot get platforms;android-34 fresh installation with sdkmanager"; exit 1; }
    else
        echo "$tmp"
    fi
}

get_ossl_ver() {
    tmp="$(curl 'https://api.github.com/repos/openssl/openssl/releases' 2>/dev/null | jq -r '.[0].tag_name' 2>/dev/null)"
    if [ ! "$tmp" ]; then
        echo "Failed to retrieve OpenSSL version!" >&1
        echo "  Falling back to openssl-3.2.1" >&1
        echo 'openssl-3.2.1'
    fi
    echo $tmp
}

which -s sdkmanager || { echo "Android SDK manager not found in PATH"; exit 1; }
which -s jq || { echo "jq not found in PATH"; exit 1; }

export \
    ANDROID_SDK_ROOT="$(which sdkmanager | sed 's/\/cmdline-tools.*//g')" \
    CMAKE_VERSION="$(sm_get_ver cmake)" \
    ANDROID_NDK_VERSION="$(sm_get_ver ndk)" \
    ANDROID_PLATFORM="$(sm_get_platform)" \
    OPENSSL_VERSION="$(get_ossl_ver)"

export TD_ROOT="$(dirname $(realpath $0 2>/dev/null || readlink -f $0 2>/dev/null))/../.."

echo -e \
"Build environment:
  Android SDK: $ANDROID_SDK_ROOT
  Android NDK: $ANDROID_NDK_VERSION (STL: $ANDROID_STL)
  Android platform: $ANDROID_PLATFORM (min SDK: $ANDROID_MIN_SDK)
  CMake: $CMAKE_VERSION
  OpenSSL: $OPENSSL_VERSION"
