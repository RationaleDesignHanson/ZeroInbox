#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 * Category on NSObject to provide dependencyProvider property.
 * This works for any object type including EXAppDelegateWrapper.
 */
@interface NSObject (DependencyProvider)
@property (nonatomic, strong) id dependencyProvider;
@end

/**
 * Minimal stub for ReactAppDependencyProvider.
 */
@interface RCTAppDependencyProvider : NSObject
- (NSDictionary<NSString *, Class> *)thirdPartyFabricComponents;
@end
