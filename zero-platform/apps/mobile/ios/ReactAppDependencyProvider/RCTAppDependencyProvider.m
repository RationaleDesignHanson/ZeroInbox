#import "RCTAppDependencyProvider.h"
#import <objc/runtime.h>

static const void *kDependencyProviderKey = &kDependencyProviderKey;

@implementation NSObject (DependencyProvider)

- (id<RCTDependencyProvider>)dependencyProvider {
    id provider = objc_getAssociatedObject(self, kDependencyProviderKey);
    if (!provider) {
        // Auto-create a default provider if none exists
        provider = [[RCTAppDependencyProvider alloc] init];
        [self setDependencyProvider:provider];
    }
    return provider;
}

- (void)setDependencyProvider:(id<RCTDependencyProvider>)dependencyProvider {
    objc_setAssociatedObject(self, kDependencyProviderKey, dependencyProvider, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation RCTAppDependencyProvider

- (NSDictionary<NSString *, Class> *)thirdPartyFabricComponents {
    return @{};
}

@end
