/*
 TableStream.m
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

#import "TableStream.h"
#import "FormattedDiskPage.h"
#import "FontTable.h"
#import "DocumentProperties.h"
#import "OFDataBuffer.h"
#import "../WKUtilities.h"

@implementation TableStream

@synthesize fontTable, documentProperties;

-(id)initWithDefaultTableStream
{
	self = [super init];
	if(self) {
		_characterPlex = [[NSMutableData alloc] init];
		_paragraphPlex = [[NSMutableData alloc] init];
		documentProperties = [[DocumentProperties alloc] init];
	}
	return self;
}

#if !ARC

-(void)dealloc
{
	[_characterPlex release];
	[_paragraphPlex release];
	[documentProperties release];
	[super dealloc];
}

#endif

-(void)addFormattedDiskPageToPlexes:(FormattedDiskPage *)fkp pageNumber:(uint32_t)fkpPage
{
	if(![[fkp data] length]) return;
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	OFDataBufferAppendLongInt(&db, [fkp firstFC]);
	OFDataBufferAppendLongInt(&db, fkpPage);
	if(!_textEnd)
		_textEnd = [fkp nullTerminatingFileOffset];
	
	CFDataRef data;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &data);
	if([fkp containsParagraphProperties]) {
		[_paragraphPlex appendData:(NSData *)data];
	} else {
		[_characterPlex appendData:(NSData *)data];
	}
	CFRelease(data);
}

-(uint32_t)characterPlexLocation
{
	return 182;
}

-(uint32_t)characterPlexSize
{
	return [_characterPlex length] + 4;
}

-(uint32_t)paragraphPlexLocation
{
	return [self characterPlexLocation] + [self characterPlexSize];
}

-(uint32_t)paragraphPlexSize
{
	return [_paragraphPlex length] + 4;
}

-(uint32_t)fontTableLocation
{
	return [self paragraphPlexLocation] + [self paragraphPlexSize] + 33;
}

-(uint32_t)fontTableSize
{
	return [[fontTable data] length];
}

-(NSData *)data
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	/*Stsh - the document stylesheet. For now, this is unsupported
	 and is therefore written statically. This may be supported in
	 the future.*/
	
	static uint8_t stshBytes[162] = { 
		0x12, 0x00, 0x0F, 0x00, 0x0A, 0x00, 0x01, 0x00,
		0x69, 0x00, 0x0F, 0x00, 0x02, 0x00, 0x03, 0x00,
		0x03, 0x00, 0x03, 0x00, 0x34, 0x00, 0x00, 0x40,
		0xF1, 0xFF, 0x02, 0x00, 0x34, 0x00, 0x00, 0x00,
		0x06, 0x00, 0x4E, 0x00, 0x6F, 0x00, 0x72, 0x00,
		0x6D, 0x00, 0x61, 0x00, 0x6C, 0x00, 0x00, 0x00,
		0x02, 0x00, 0x00, 0x00, 0x14, 0x00, 0x43, 0x4A,
		0x18, 0x00, 0x4F, 0x4A, 0x00, 0x00, 0x50, 0x4A, 
		0x03, 0x00, 0x51, 0x4A, 0x03, 0x00, 0x6D, 0x48,
		0x09, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x3C, 0x00, 0x41, 0x40,
		0xF2, 0xFF, 0xA1, 0x00, 0x3C, 0x00, 0x00, 0x00,
		0x16, 0x00, 0x44, 0x00, 0x65, 0x00, 0x66, 0x00,
		0x61, 0x00, 0x75, 0x00, 0x6C, 0x00, 0x74, 0x00,
		0x20, 0x00, 0x50, 0x00, 0x61, 0x00, 0x72, 0x00,
		0x61, 0x00, 0x67, 0x00, 0x72, 0x00, 0x61, 0x00,
		0x70, 0x00, 0x68, 0x00, 0x20, 0x00, 0x46, 0x00,
		0x6F, 0x00, 0x6E, 0x00, 0x74, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00
	};
	OFDataBufferAppendBytes(&db, stshBytes, 162);
	
	/*PlcfSed*/
	OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, (_textEnd - (PAGESIZE * 3)) / 2);
	OFDataBufferAppendShortInt(&db, 0); /*fn*/
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF); /*fcSepx*/
	OFDataBufferAppendShortInt(&db, 0); /*fnMpr*/
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF); /*fcMpr*/
	
	/*PlcfBteChpx - the plex describing where character FormattedDiskPages are in the file.*/
	NSData *chpxFCs = [_characterPlex subdataWithRange:NSMakeRange(0, [_characterPlex length] / 2)];
	NSData *chpxFKPFCs = [_characterPlex subdataWithRange:NSMakeRange([_characterPlex length] / 2, [_characterPlex length] / 2)];
	OFDataBufferAppendData(&db, chpxFCs);
	OFDataBufferAppendLongInt(&db, _textEnd);
	OFDataBufferAppendData(&db, chpxFKPFCs);
	
	/*PlcfBtePapx - the plex describing where paragraph FormattedDiskPages are in the file.*/
	NSData *papxFCs = [_paragraphPlex subdataWithRange:NSMakeRange(0, [_paragraphPlex length] / 2)];
	NSData *papxFKPFCs = [_paragraphPlex subdataWithRange:NSMakeRange([_paragraphPlex length] / 2, [_paragraphPlex length] / 2)];
	OFDataBufferAppendData(&db, papxFCs);
	OFDataBufferAppendLongInt(&db, _textEnd);
	OFDataBufferAppendData(&db, papxFKPFCs);
	
	/*PlcfBteLvc - Deprecated information concerning lists or bullets. We write it anyway because TextEdit does.*/
	OFDataBufferAppendLongInt(&db, (PAGESIZE * 3));
	OFDataBufferAppendLongInt(&db, _textEnd);
	uint32_t lastpapxfkp;
	[papxFKPFCs getBytes:&lastpapxfkp range:NSMakeRange([papxFKPFCs length] - 4, 4)];
	OFDataBufferAppendLongInt(&db, lastpapxfkp);
	
	/*Clx - describes where the ranges of text are in the document. Mostly static since we don't support
	 textboxes or headers or anything like that.*/
	OFDataBufferAppendByte(&db, 0x02);
	OFDataBufferAppendLongInt(&db, 0x10);
	OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, (_textEnd - (PAGESIZE * 3)) / 2);
	OFDataBufferAppendShortInt(&db, 0);
	OFDataBufferAppendLongInt(&db, (PAGESIZE * 3));
	OFDataBufferAppendShortInt(&db, 0);
	
	/*SttbfFfn - the document font table*/
	OFDataBufferAppendData(&db, [fontTable data]);
	
	OFDataBufferAppendData(&db, [documentProperties data]);
	
	/*Round the table stream to 4096 bytes. Makes the CompoundFileBinary easier to work with.*/
	while(OFDataBufferSpaceOccupied(&db) % 4096) OFDataBufferAppendByte(&db, 0);
	
	CFDataRef resultData;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &resultData);
	return SAFE_AUTORELEASE((NSData *)resultData);
}

@end
