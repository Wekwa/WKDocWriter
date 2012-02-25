/*
 SummaryInformation.m
 WKDocWriter
 
 Copyright 2012 Wyatt Kaufman
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "SummaryInformation.h"
#import "OFDataBuffer.h"
#import "../WKUtilities.h"

/*Summary Info is static for now.*/

@implementation SummaryInformation

-(id)initDefaultSummaryInformation
{
	self = [super init];
	if(self) {
		
	}
	return self;
}

-(NSData *)data
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	OFDataBufferAppendShortInt(&db, 0xFFFE); /*ByteOrder*/
	OFDataBufferAppendShortInt(&db, 0); /*Version*/
	OFDataBufferAppendLongInt(&db, (int)(NSFoundationVersionNumber * 100)); /*SystemIdentifier*/
	for(int i = 0; i < 4; i++) {
		OFDataBufferAppendLongInt(&db, 0); /*CLSID*/
	}
	OFDataBufferAppendLongInt(&db, 0x01); /*NumPropertySets*/
	OFDataBufferAppendLongInt(&db, 0xF29F85E0); /*FMTID0*/
	OFDataBufferAppendLongInt(&db, 0x10684FF9); /*FMTID0*/
	OFDataBufferAppendLongInt(&db, 0xAB910800); /*FMTID0*/
	OFDataBufferAppendLongInt(&db, 0xD9B3272B); /*FMTID0*/
	OFDataBufferAppendLongInt(&db, 0x30); /*Offset0*/
	OFDataBufferAppendLongInt(&db, 0x18); /*Size*/
	OFDataBufferAppendLongInt(&db, 0x01);
	OFDataBufferAppendLongInt(&db, 0x01);
	OFDataBufferAppendLongInt(&db, 0x10);
	OFDataBufferAppendLongInt(&db, 0x02);
	OFDataBufferAppendLongInt(&db, 0xFDE9);
	
	while(OFDataBufferSpaceOccupied(&db) % 4096) OFDataBufferAppendByte(&db, 0);
	
	OFDataBufferAppendShortInt(&db, 0xFFFE); /*ByteOrder*/
	OFDataBufferAppendShortInt(&db, 0); /*Version*/
	OFDataBufferAppendLongInt(&db, (int)(NSFoundationVersionNumber * 100)); /*SystemIdentifier*/
	for(int i = 0; i < 4; i++) {
		OFDataBufferAppendLongInt(&db, 0); /*CLSID*/
	}
	OFDataBufferAppendLongInt(&db, 0x01); /*NumPropertySets*/
	OFDataBufferAppendLongInt(&db, 0xD5CDD502); /*FMTID0*/
	OFDataBufferAppendLongInt(&db, 0x101B2E9C); /*FMTID0*/
	OFDataBufferAppendLongInt(&db, 0x00089793); /*FMTID0*/
	OFDataBufferAppendLongInt(&db, 0xAEF92C2B); /*FMTID0*/
	OFDataBufferAppendLongInt(&db, 0x30); /*Offset0*/
	OFDataBufferAppendLongInt(&db, 0x18); /*Size*/
	OFDataBufferAppendLongInt(&db, 0x01);
	OFDataBufferAppendLongInt(&db, 0x01);
	OFDataBufferAppendLongInt(&db, 0x10);
	OFDataBufferAppendLongInt(&db, 0x02);
	OFDataBufferAppendLongInt(&db, 0xFDE9);
	
	while(OFDataBufferSpaceOccupied(&db) % 4096) OFDataBufferAppendByte(&db, 0);
	
	CFDataRef data;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &data);
	return SAFE_AUTORELEASE((NSData *)data);
}

@end
