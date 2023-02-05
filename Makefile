TARGET := iphone:clang:latest:14.0


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Vendetta

Vendetta_FILES = $(shell find Sources/Vendetta -name '*.swift') $(shell find Sources/VendettaC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
Vendetta_SWIFTFLAGS = -ISources/VendettaC/include
Vendetta_CFLAGS = -fobjc-arc -ISources/VendettaC/include

BUNDLE_NAME = VendettaPatches
VendettaPatches_RESOURCE_DIRS = "VendettaXposed/App/src/main/assets/js"
VendettaPatches_INSTALL_PATH = "/Library/Application\ Support/Vendetta"

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
