#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 * Protocol declaring thirdPartyFabricComponents so it can be called on id types.
 */
@protocol RCTDependencyProvider <NSObject>
@optional
- (NSDictionary<NSString *, Class> *)thirdPartyFabricComponents;
@end

/**
 * Category on NSObject to provide dependencyProvider property.
 * This works for any object type including EXAppDelegateWrapper.
 */
@interface NSObject (DependencyProvider)
@property (nonatomic, strong) id<RCTDependencyProvider> dependencyProvider;
@end

/**
 * Minimal stub for ReactAppDependencyProvider.
 */
@interface RCTAppDependencyProvider : NSObject <RCTDependencyProvider>
- (NSDictionary<NSString *, Class> *)thirdPartyFabricComponents;
@end
