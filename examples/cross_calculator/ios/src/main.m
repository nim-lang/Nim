#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "backend.h"

int main(int argc, char *argv[])
{
	@autoreleasepool {
		NimMain();
		return UIApplicationMain(argc, argv, nil,
			NSStringFromClass([AppDelegate class]));
	}
}
