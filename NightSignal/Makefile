include $(THEOS)/makefiles/common.mk
APPLICATION_NAME = NightSignal
NightSignal_FILES = main.m AppDelegate.m RootViewController.m
NightSignal_FRAMEWORKS = UIKit Foundation QuartzCore
NightSignal_CFLAGS = -fobjc-arc
NightSignal_CODESIGN_FLAGS = -Sentitlements.plist
NightSignal_RESOURCE_DIRS = Resources
NightSignal_RESOURCE_FILES = Info.plist
NightSignal_INSTALL_PATH = /Applications
include $(THEOS_MAKE_PATH)/application.mk
