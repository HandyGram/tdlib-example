# Handy TDLib tdjson builder

Uses modified official Android example (`example/android`).

Do not request support for third-party packages.
This package is intended to be used only for
[handy_tdlib package](https://pub.dev/packages/handy_tdlib).

**Preparations:**
```sh
git clone https://github.com/tdlib/td
git clone https://github.com/HandyGram/tdlib-example td/example/android-json
cd td/example/android-json
./check-environment.sh
```

**How to update Handy TDLib plugin:**
1. If you don't have Android SDK installed:
    * [Scroll down to command line tools only](https://developer.android.com/studio),
      download appropriate one for your platform
    * Extract command line tools into:
        * macOS: ~/Library/Android/sdk/cmdline-tools/latest
        * Linux: ~/Android/sdk/cmdline-tools/latest
    * Add this directory into PATH variable
    * Run `./check-environment.sh`
2. Build OpenSSL: run `./build-openssl.sh`
3. Build TDLib: run `./build-tdlib.sh`
4. Gather output package from `./tdlib/tdlib.zip`
5. `cd` into Handy TDLib plugin directory
6. Run `./update-tdlib.sh [tdlib.zip path]`
