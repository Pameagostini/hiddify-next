BUILDTIME=$(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
VERSION=$(shell grep "version:" pubspec.yaml | head -n1 | cut -d ' ' -f2 | cut -d '+' -f1)
COMMIT=$(shell git rev-parse --short HEAD)

gen:
	dart run build_runner build --delete-conflicting-outputs

clean:
	flutter clean
	cd libcore && go mod tidy && go clean -cache

android-prepare:
	cd libcore && \
	gomobile bind -v -androidapi 19 -javapkg=io.nekohasekai.libbox -libname=box -tags="with_gvisor,with_quic,with_dhcp,with_wireguard,with_utls,with_reality,with_acme,with_clash_api" . && \
	mkdir -p ../android/app/libs && \
	cp libbox.aar ../android/app/libs/

android-build:
	flutter build apk --release

android-build-debug:
	flutter build apk --debug

.PHONY: gen clean android-prepare android-build android-build-debug
