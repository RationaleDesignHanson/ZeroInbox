#import <Foundation/Foundation.h>

/**
 * Minimal stub for ReactAppDependencyProvider.
 * No React imports - avoids EAS header path issues.
 */
@interface RCTAppDependencyProvider : NSObject
- (NSDictionary<NSString *, Class> *)thirdPartyFabricComponents;
@end
