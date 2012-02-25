//
//  WKDocWriter.h
//  WKDocWriter
//
//  Created by Wyatt Kaufman on 1/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FormattedDiskPage, FileInformationBlock, CompoundFileBinary, FontTable, TableStream;

@interface WKDocWriter : NSObject {
	NSAttributedString *_attrStr;
	NSMutableArray *_fkps;
	CompoundFileBinary *_cfb;
	FileInformationBlock *_fib;
	FontTable *_ffn;
	TableStream *_tbl;
	NSMutableData *_docFormatData;
	
}

-(id)initWithAttributedString:(NSAttributedString *)attrStr;
-(BOOL)write;
-(NSData *)docFormatData;

@end
