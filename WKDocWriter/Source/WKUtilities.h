//
//  ../WKUtilities.h
//  WKDocWriter
//
//  Created by Wyatt Kaufman on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ARC __has_feature(objc_arc)
#define PAGESIZE 512

#if ARC

#define SAFE_RELEASE(x)
#define SAFE_RETAIN(x)
#define SAFE_AUTORELEASE(x)

#else

#define SAFE_RELEASE(x) [(x) release]
#define SAFE_RETAIN(x) [(x) retain]
#define SAFE_AUTORELEASE(x) [(x) autorelease]

#endif