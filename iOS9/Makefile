# Builds Govee apps for iOS 9 / armv7 (iPhone 4S) with Embedded Swift.
#
#   make                       build the app in APP (default Scanner)
#   make install               copy it to a jailbroken device over SSH
#
# Uses SwiftUI-iOS9 (https://github.com/colemancda/SwiftUI-iOS9) for the UI,
# its CoreBluetooth central (DarwinGATT), its iOS 9.3 SDK (`make sdk` there)
# and its concurrency runtime fixes, and the Bluetooth and GATT versions
# SwiftPM resolves for the Govee package.

APP      ?= Scanner
BUNDLE   := build/$(APP).app
MIN_IOS  := 9.0
ARCH     := armv7

SWIFTUI_IOS9 ?= ../../SwiftUI-iOS9
SDK          := $(SWIFTUI_IOS9)/sdk/iPhoneOS9.3.sdk
CHECKOUTS    := ../.build/checkouts

SWIFT_TOOLCHAIN ?= $(HOME)/Library/Developer/Toolchains/swift-6.4.2-RELEASE.xctoolchain
SWIFTC := $(SWIFT_TOOLCHAIN)/usr/bin/swiftc
SWIFT_EMBEDDED_LIB := $(SWIFT_TOOLCHAIN)/usr/lib/swift/embedded/armv7-apple-none-macho
CC     := xcrun clang

SWIFTUI_BACKEND := $(SWIFTUI_IOS9)/Sources/CSwiftUIBackend
GATT_BACKEND    := $(SWIFTUI_IOS9)/Sources/CDarwinGATT
RUNTIME := build/runtime/libswift_Concurrency.a

# See SwiftUI-iOS9's Makefile for why everything is ARM, r9 is reserved and
# the executor and runtime are compiled for the bare-metal target.
CFLAGS  := -arch $(ARCH) -isysroot $(SDK) -miphoneos-version-min=$(MIN_IOS) \
           -marm -fobjc-arc -O2 -Wall
EXECUTOR_CFLAGS := -target armv7-apple-none-macho -ffreestanding -marm -ffixed-r9 \
                   -O2 -Wall -I$(SWIFTUI_BACKEND)/include
LDFLAGS := -arch $(ARCH) -isysroot $(SDK) -miphoneos-version-min=$(MIN_IOS) \
           -framework UIKit -framework Foundation -framework CoreBluetooth \
           -lc++ -Wl,-dead_strip \
           $(SWIFT_EMBEDDED_LIB)/libswiftUnicodeDataTables.a $(RUNTIME)
SWIFTFLAGS := -target armv7-apple-none-macho -enable-experimental-feature Embedded \
              -wmo -Osize -Xcc -marm -Xcc -ffixed-r9 -parse-as-library \
              -I$(SWIFTUI_BACKEND)/include -I$(GATT_BACKEND)/include -Ibuild/modules

BLUETOOTH_SRCS = $(shell find $(CHECKOUTS)/Bluetooth/Sources/Bluetooth -name '*.swift')
GATT_SRCS      = $(shell find $(CHECKOUTS)/GATT/Sources/GATT -name '*.swift')
GOVEE_SRCS     = $(shell find ../Sources/Govee -name '*.swift')
SWIFTUI_SRCS   = $(wildcard $(SWIFTUI_IOS9)/Sources/SwiftUI/*.swift)
DARWINGATT_SRCS = $(wildcard $(SWIFTUI_IOS9)/Sources/DarwinGATT/*.swift)
APP_SRCS       = $(wildcard $(APP)/*.swift)

OBJS := build/obj/$(APP).o build/obj/DarwinGATT.o build/obj/Govee.o build/obj/GATT.o \
        build/obj/Bluetooth.o build/obj/SwiftUI.o \
        build/obj/SwiftUIBackend.o build/obj/DarwinGATTBackend.o build/obj/Executor.o

# iOS 9's Bluetooth daemon only treats an app as foreground, and gives it
# scan results without a service filter, if its signature has a team
# identifier, which ad-hoc (ldid) signatures lack. So apps are signed with a
# development identity; AppSync on the device accepts it without a profile.
SIGN_IDENTITY ?= Apple Development
TEAM_ID       ?= 4W79SG34MW
BUNDLE_ID      = $(shell plutil -extract CFBundleIdentifier raw $(APP)/Info.plist)

SSH_CONF ?= /Volumes/4TB/Downloads/IPA/4s-ssh.conf
SSH_HOST ?= 4s

.PHONY: all install resolve clean distclean
.DEFAULT_GOAL := all

all: $(BUNDLE)/$(APP)

# Checks out Bluetooth and GATT at the versions Package.swift requires.
resolve: $(CHECKOUTS)/GATT/Package.swift

$(CHECKOUTS)/GATT/Package.swift: ../Package.swift
	cd .. && swift package resolve
	touch $@

# Each rule also writes build/modules/<Module>.swiftmodule.
build/obj/Bluetooth.o: $(CHECKOUTS)/GATT/Package.swift
	@mkdir -p build/obj build/modules
	$(SWIFTC) $(SWIFTFLAGS) -module-name Bluetooth -package-name bluetooth \
	  -emit-module -emit-module-path build/modules/Bluetooth.swiftmodule -c $(BLUETOOTH_SRCS) -o $@

build/obj/GATT.o: build/obj/Bluetooth.o
	$(SWIFTC) $(SWIFTFLAGS) -module-name GATT -package-name gatt \
	  -emit-module -emit-module-path build/modules/GATT.swiftmodule -c $(GATT_SRCS) -o $@

build/obj/Govee.o: build/obj/GATT.o $(GOVEE_SRCS)
	$(SWIFTC) $(SWIFTFLAGS) -enable-experimental-feature Extern -module-name Govee -package-name govee \
	  -emit-module -emit-module-path build/modules/Govee.swiftmodule -c $(GOVEE_SRCS) -o $@

build/obj/SwiftUI.o: $(SWIFTUI_SRCS) $(SWIFTUI_BACKEND)/include/SwiftUIBackend.h
	@mkdir -p build/obj build/modules
	$(SWIFTC) $(SWIFTFLAGS) -module-name SwiftUI \
	  -emit-module -emit-module-path build/modules/SwiftUI.swiftmodule -c $(SWIFTUI_SRCS) -o $@

build/obj/DarwinGATT.o: build/obj/GATT.o $(DARWINGATT_SRCS) $(GATT_BACKEND)/include/DarwinGATTBackend.h
	$(SWIFTC) $(SWIFTFLAGS) -module-name DarwinGATT \
	  -emit-module -emit-module-path build/modules/DarwinGATT.swiftmodule -c $(DARWINGATT_SRCS) -o $@

build/obj/$(APP).o: $(APP_SRCS) build/obj/DarwinGATT.o build/obj/Govee.o build/obj/SwiftUI.o
	$(SWIFTC) $(SWIFTFLAGS) -module-name $(APP) -c $(APP_SRCS) -o $@

build/obj/SwiftUIBackend.o: $(SWIFTUI_BACKEND)/Backend.m $(SWIFTUI_BACKEND)/include/SwiftUIBackend.h
	@mkdir -p build/obj
	$(CC) $(CFLAGS) -I$(SWIFTUI_BACKEND)/include -c $< -o $@

build/obj/DarwinGATTBackend.o: $(GATT_BACKEND)/DarwinGATTBackend.m $(GATT_BACKEND)/include/DarwinGATTBackend.h
	@mkdir -p build/obj
	$(CC) $(CFLAGS) -I$(GATT_BACKEND)/include -c $< -o $@

build/obj/Executor.o: $(SWIFTUI_BACKEND)/Executor.c $(SWIFTUI_BACKEND)/include/SwiftUIBackend.h
	@mkdir -p build/obj
	$(CC) $(EXECUTOR_CFLAGS) -c $< -o $@

$(RUNTIME): $(SWIFTUI_IOS9)/Scripts/build-concurrency-runtime.sh
	$(SWIFTUI_IOS9)/Scripts/build-concurrency-runtime.sh $(SWIFT_TOOLCHAIN) build/runtime

# The linker warns "no platform load command found" for the Swift objects
# (bare-metal target) and assumes iOS, which is what we want.
$(BUNDLE)/$(APP): $(OBJS) $(RUNTIME) $(APP)/Info.plist
	@mkdir -p $(BUNDLE)
	$(CC) $(LDFLAGS) $(OBJS) -o $@
	plutil -convert binary1 -o $(BUNDLE)/Info.plist $(APP)/Info.plist
	printf 'APPL????' > $(BUNDLE)/PkgInfo
	printf '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0"><dict><key>application-identifier</key><string>%s.%s</string><key>com.apple.developer.team-identifier</key><string>%s</string></dict></plist>\n' \
	  $(TEAM_ID) $(BUNDLE_ID) $(TEAM_ID) > build/$(APP).entitlements
	codesign -f -s "$(SIGN_IDENTITY)" --entitlements build/$(APP).entitlements $(BUNDLE)

# Copies the app into /Applications (runs without AppSync on a jailbroken
# device) and refreshes the home screen.
install: $(BUNDLE)/$(APP)
	COPYFILE_DISABLE=1 tar --no-xattrs --no-mac-metadata -C build -cf - $(APP).app | \
	  ssh -F $(SSH_CONF) $(SSH_HOST) 'cd / && rm -rf /Applications/$(APP).app && tar -C /Applications -xf - && chown -R root:wheel /Applications/$(APP).app && su mobile -c uicache'

# Keeps the rebuilt runtime; `make distclean` removes it too.
clean:
	find build -mindepth 1 -maxdepth 1 ! -name runtime -exec rm -rf {} +

distclean:
	rm -rf build
