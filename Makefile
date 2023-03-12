TARGET := iphone:clang:latest:12.2


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VendettaTweak

VendettaTweak_FILES = $(shell find Sources/VendettaTweak -name '*.swift') $(shell find Sources/VendettaTweakC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
VendettaTweak_SWIFTFLAGS = -ISources/VendettaTweakC/include
VendettaTweak_CFLAGS = -fobjc-arc -ISources/VendettaTweakC/include

include $(THEOS_MAKE_PATH)/tweak.mk
