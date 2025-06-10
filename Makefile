include dependencies.properties

BINDIR=./libcore/bin
ANDROID_OUT=./android/app/libs
GEO_ASSETS_DIR=./assets/core

CORE_PRODUCT_NAME=libcore
CORE_NAME=hiddify-$(CORE_PRODUCT_NAME)
ifeq ($(CHANNEL),prod)
CORE_URL=https://github.com/hiddify/hiddify-next-core/releases/download/v$(core.version)
else
CORE_URL=https://github.com/hiddify/hiddify-next-core/releases/download/draft
endif

ifeq ($(CHANNEL),prod)
TARGET=lib/main_prod.dart
else
TARGET=lib/main.dart
endif

BUILD_ARGS=--dart-define sentry_dsn=$(SENTRY_DSN)
DISTRIBUTOR_ARGS=--skip-clean --build-target $(TARGET) --build-dart-define sentry_dsn=$(SENTRY_DSN)

get:
	flutter pub get

gen:
	dart run build_runner build --delete-conflicting-outputs

translate:
	dart run slang

prepare: get-geo-assets get gen translate
	@echo "Available platforms:"
	@echo "android"
	if [ -z "$$platform" ]; then \
		read -p "run make prepare platform=ios or Enter platform name: " choice; \
	else \
		choice=$$platform; \
	fi; \
	make $$choice-libs

sync_translate:
	cd .github && bash sync_translate.sh
	make translate

android-release: android-apk-release

android-apk-release: build-android-libs # DEPENDS ON BUILDING THE AAR
	cd android && ./gradlew clean # Clean Android Gradle project
	flutter clean # Clean Flutter project
	flutter build apk --target-platform android-arm,android-arm64,android-x64 --split-per-abi --target $(TARGET) $(BUILD_ARGS)
	ls -R build/app/outputs

android-aab-release: build-android-libs # DEPENDS ON BUILDING THE AAR
	cd android && ./gradlew clean # Clean Android Gradle project
	flutter clean # Clean Flutter project
	flutter build appbundle --target $(TARGET) $(BUILD_ARGS) --dart-define release=google-play
	ls -R build/app/outputs

# Esta regla construye el AAR de Android desde el submódulo libcore
build-android-libs:
	cd libcore && make -f mobile/Makefile android && mv ./bin/hiddify-libcore-android.aar ../android/app/libs/libcore.aar

get-geo-assets:
	curl -L https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db -o $(GEO_ASSETS_DIR)/geoip.db
	curl -L https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db -o $(GEO_ASSETS_DIR)/geosite.db

.PHONY: get gen translate prepare sync_translate android-release android-apk-release android-aab-release build-android-libs get-geo-assets
