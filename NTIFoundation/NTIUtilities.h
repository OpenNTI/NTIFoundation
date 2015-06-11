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

//A procedure block that takes an error.
typedef void(^NTIErrorProcBlock)(NSError* error);

#if __has_feature(objc_arc)
#define NTI_METHOD_FAMILY_NEW __attribute__((objc_method_family(new)))
#else
#define NTI_METHOD_FAMILY_NEW
#endif

#if __has_feature(objc_generics)

#define NTIArrayG(ELEMENT_TYPE) NSArray<ELEMENT_TYPE>
#define NTIMutableArrayG(ELEMENT_TYPE) NSMutableArray<ELEMENT_TYPE>
#define NTISetG(ELEMENT_TYPE) NSSet<ELEMENT_TYPE>
#define NTIMutableSetG(ELEMENT_TYPE) NSMutableSet<ELEMENT_TYPE>
#define NTIOrderedSetG(ELEMENT_TYPE) NSOrderedSet<ELEMENT_TYPE>
#define NTIMutableOrderedSetG(ELEMENT_TYPE) NSMutableOrderedSet<ELEMENT_TYPE>
#define NTIDictionaryG(KEY_TYPE, VALUE_TYPE) NSDictionary<KEY_TYPE, VALUE_TYPE>
#define NTIMutableDictionaryG(KEY_TYPE, VALUE_TYPE) NSMutableDictionary<KEY_TYPE, VALUE_TYPE>
#define NTIHashTableG(ELEMENT_TYPE) NSHashTable<ELEMENT_TYPE>
#define NTIMapTableG(KEY_TYPE, VALUE_TYPE) NSMapTable<KEY_TYPE, VALUE_TYPE>

#else

#define NTIArrayG(ELEMENT_TYPE) NSArray
#define NTIMutableArrayG(ELEMENT_TYPE) NSMutableArray
#define NTISetG(ELEMENT_TYPE) NSSet
#define NTIMutableSetG(ELEMENT_TYPE) NSMutableSet
#define NTIOrderedSetG(ELEMENT_TYPE) NSOrderedSet
#define NTIMutableOrderedSetG(ELEMENT_TYPE) NSMutableOrderedSet
#define NTIDictionaryG(KEY_TYPE, VALUE_TYPE) NSDictionary
#define NTIHashTableG(ELEMENT_TYPE) NSHashTable
#define NTIMapTableG(KEY_TYPE, VALUE_TYPE) NSMapTable

#endif
