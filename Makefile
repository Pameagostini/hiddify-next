include dependencies.properties

BINDIR=./libcore/bin
ANDROID_OUT=./android/app/libs
GEO_ASSETS_DIR=./assets/core

CORE_PRODUCT_NAME=libcore
CORE_NAME=hiddify-$(CORE_PRODUCT_NAME)
ifeq ($(CHANNEL),prod)
CORE_URL=https://github.com/hiddify/hiddify-next-core/releases/download/v$(core.version)
else
CORE_URL=https://github.com/hiddify/hiddify-next-core/releases/download/latest
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

android-apk-release:
	cd android && ./gradlew clean
	flutter clean
	flutter build apk --target-platform android-arm,android-arm64,android-x64 --split-per-abi --target $(TARGET) $(BUILD_ARGS)
	ls -R build/app/outputs

android-aab-release:
	cd android && ./gradlew clean
	flutter clean
	flutter build appbundle --target $(TARGET) $(BUILD_ARGS) --dart-define release=google-play
	ls -R build/app/outputs

android-libs:
	mkdir -p $(ANDROID_OUT)
	rm -f $(ANDROID_OUT)/libcore.aar
	echo "Downloading from: $(CORE_URL)/$(CORE_NAME)-android.aar"
	curl -L -v $(CORE_URL)/$(CORE_NAME)-android.aar -o $(ANDROID_OUT)/libcore.aar
	echo "Verifying downloaded file:"
	file $(ANDROID_OUT)/libcore.aar
	ls -l $(ANDROID_OUT)/libcore.aar
	unzip -t $(ANDROID_OUT)/libcore.aar || echo "Warning: AAR file might be invalid"
	cd android && ./gradlew clean

android-apk-libs: android-libs
android-aab-libs: android-libs

get-geo-assets:
	curl -L https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db -o $(GEO_ASSETS_DIR)/geoip.db
	curl -L https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db -o $(GEO_ASSETS_DIR)/geosite.db

.PHONY: get gen translate prepare sync_translate android-release android-apk-release android-aab-release android-libs android-apk-libs android-aab-libs get-geo-assets
