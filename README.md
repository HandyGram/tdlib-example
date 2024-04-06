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

**How to build:**
1. If you don't have Android SDK installed: `./fetch-sdk.sh`
2. Run `./build-openssl.sh [sdk path if not using fetch-sdk]`
3. Run `./build-tdlib.sh [sdk path if not using fetch-sdk]`
4. Profit
