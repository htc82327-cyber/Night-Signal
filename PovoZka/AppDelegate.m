#import "AppDelegate.h"
#import "ChatViewController.h"
@implementation AppDelegate
- (BOOL)application:(UIApplication*)a didFinishLaunchingWithOptions:(NSDictionary*)o{
 self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:[ChatViewController new]];
 [self.window makeKeyAndVisible];return YES;
}
@end
