//Miscelaneous utility functions and macros

#include <sys/xattr.h>

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

#if __has_feature(objc_arc)
#define NTI_RELEASE(name) 
#else
#define NTI_RELEASE(name) do {[name release]; name = nil;}while(0)
#endif

#ifndef NS_CONSUMED
#if __has_feature(attribute_ns_consumed)
#define NS_CONSUMED __attribute__((ns_consumed))
#else
#define NS_CONSUMED
#endif
#endif

#ifndef NS_RETURNS_NOT_RETAINED
#if __has_feature(attribute_ns_returns_not_retained)
#define NS_RETURNS_NOT_RETAINED __attribute__((ns_returns_not_retained))
#else
#define NS_RETURNS_NOT_RETAINED
#endif
#endif

#ifndef NS_RETURNS_RETAINED
#if __has_feature(attribute_ns_returns_retained)
#define NS_RETURNS_RETAINED __attribute__((ns_returns_retained))
#else
#define NS_RETURNS_RETAINED
#endif
#endif

#ifndef NS_CONSUMES_SELF
#if __has_feature(attribute_ns_consumes_self)
#define NS_CONSUMES_SELF __attribute__((ns_consumes_self))
#else
#define NS_CONSUMES_SELF
#endif
#endif

//A procedure block takes an object, returns nothing.
typedef void(^NTIObjectProcBlock)(id);

#if __has_feature(objc_arc)
#define NTI_METHOD_FAMILY_NEW __attribute__((objc_method_family(new)))
#else
#define NTI_METHOD_FAMILY_NEW
#endif
