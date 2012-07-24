//
//  NTICoverageFix.m
//  NTIFoundation
//
//  Created by Christopher Utz on 7/24/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTICoverageFix.h"

#ifdef DEBUG

@implementation NTICoverageFix

FILE* fopen$UNIX2003(const char* filename, const char* mode) {
    return fopen(filename, mode);
}

size_t fwrite$UNIX2003(const void* ptr, size_t size, size_t nitems, FILE* stream) {
    return fwrite(ptr, size, nitems, stream);
}

@end

#endif
