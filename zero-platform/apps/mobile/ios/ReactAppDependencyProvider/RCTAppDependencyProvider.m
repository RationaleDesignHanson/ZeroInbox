#import "RCTAppDependencyProvider.h"
#import <objc/runtime.h>

static const void *kDependencyProviderKey = &kDependencyProviderKey;

@implementation NSObject (DependencyProvider)

- (id)dependencyProvider {
    return objc_getAssociatedObject(self, kDependencyProviderKey);
}

- (void)setDependencyProvider:(id)dependencyProvider {
    objc_setAssociatedObject(self, kDependencyProviderKey, dependencyProvider, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation RCTAppDependencyProvider

- (NSDictionary<NSString *, Class> *)thirdPartyFabricComponents {
    return @{};
}

@end
