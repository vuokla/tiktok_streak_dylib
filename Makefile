TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TikTokStreak

TikTokStreak_FILES = TikTokStreak.m
TikTokStreak_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
TikTokStreak_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-all::
	@echo "========================================================"
	@echo "Build TikTokStreak.dylib thành công!"
	@echo "File output tại: .theos/obj/debug/TikTokStreak.dylib"
	@echo "========================================================"
