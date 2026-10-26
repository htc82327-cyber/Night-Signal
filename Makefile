THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64
TARGET = iphone:clang:latest:15.0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NightSignalTweak
NightSignalTweak_FILES = Tweak.xm
NightSignalTweak_CFLAGS = -fobjc-arc
NightSignalTweak_FRAMEWORKS = UIKit Foundation AudioToolbox QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += NightSignal PovoZka
include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
	@echo "Fixing staged Debian maintainer script permissions..."
	@test -f "$(THEOS_STAGING_DIR)/DEBIAN/postinst"
	@chmod 0755 "$(THEOS_STAGING_DIR)/DEBIAN/postinst"
	@if [ -f "$(THEOS_STAGING_DIR)/DEBIAN/prerm" ]; then chmod 0755 "$(THEOS_STAGING_DIR)/DEBIAN/prerm"; fi
	@stat -c '%a %n' "$(THEOS_STAGING_DIR)/DEBIAN/postinst"
	@if [ -f "$(THEOS_STAGING_DIR)/DEBIAN/prerm" ]; then stat -c '%a %n' "$(THEOS_STAGING_DIR)/DEBIAN/prerm"; fi
	@test "$$(stat -c '%a' "$(THEOS_STAGING_DIR)/DEBIAN/postinst")" = "755"
