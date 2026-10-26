#import "AppDelegate.h"
#import "RootViewController.h"
@implementation AppDelegate
- (BOOL)application:(UIApplication*)a didFinishLaunchingWithOptions:(NSDictionary*)o{
 self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[RootViewController new];[self.window makeKeyAndVisible];return YES;
}
@end
