/*
 FontTable.m
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

#import "FontTable.h"
#import "OFDataBuffer.h"
#import "../WKUtilities.h"

@implementation FontTable

-(id)init
{
	self = [super init];
	if(self) {
		_fonts = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)addFont:(CTFontRef)font
{
	CFStringRef familyName = CTFontCopyFamilyName(font);
	if([self indexOfFontWithName:(NSString *)familyName] == NSNotFound)
		[_fonts addObject:(id)font];
	
	CFRelease(familyName);
}

-(NSUInteger)indexOfFont:(CTFontRef)font
{
	return [_fonts indexOfObject:(id)font];
}

-(NSUInteger)indexOfFontWithName:(NSString *)name
{
	for(int i = 0; i < [_fonts count]; i++) {
		CTFontRef font = (CTFontRef)[_fonts objectAtIndex:i];
		NSString *matchName = SAFE_AUTORELEASE((NSString *)CTFontCopyFamilyName(font));
		if([name isEqualToString:matchName])
			return i;
	}
	return NSNotFound;
}

-(NSData *)_dataForEntry:(NSUInteger)index
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	CTFontRef font = (CTFontRef)[_fonts objectAtIndex:index];
	
	/*The ffid describes information about the font, such as font style class and charset. 
	  I can't find any methods on how to get the charset from a CTFont?
	 */
	uint8_t ffid = 0;
	CTFontSymbolicTraits traits = CTFontGetSymbolicTraits(font);
	CTFontStylisticClass class = traits & kCTFontClassMaskTrait;
	
	switch(class) {
		case kCTFontClarendonSerifsClass:
		case kCTFontOldStyleSerifsClass:
		case kCTFontTransitionalSerifsClass:
		case kCTFontModernSerifsClass:
			ffid |= 0x01 << 4;
			break;
			
		case kCTFontSansSerifClass:
			ffid |= 0x02 << 4;
			break;
			
		case kCTFontFreeformSerifsClass:
		case kCTFontScriptsClass:
			ffid |= 0x04 << 4;
			break;
			
		case kCTFontSymbolicClass:
		case kCTFontOrnamentalsClass:
			ffid |= 0x05 << 4;
			break;
	}
	
	if(!(traits & kCTFontMonoSpaceTrait))
		ffid |= 0x01;
	
	OFDataBufferAppendByte(&db, ffid); /*ffid*/
	OFDataBufferAppendShortInt(&db, 0x0109); /*wWeight - font weight that stays constant. (As opposed to a "bold" modifier in a Chpx)*/
	OFDataBufferAppendByte(&db, 0); /*chs*/
	OFDataBufferAppendByte(&db, 0); /*ixchSzAlt*/
	for(int i = 0; i < 10; i++) OFDataBufferAppendByte(&db, 0); /*panose*/
	for(int i = 0; i < 24; i++) OFDataBufferAppendByte(&db, 0); /*fs*/
	CFStringRef fontName = CTFontCopyFamilyName(font);
	OFDataBufferAppendString(&db, fontName, kCFStringEncodingUTF16LE); /*xszFfn*/
	CFRelease(fontName);
	
	OFDataBufferAppendShortInt(&db, 0);
	
	CFDataRef resultData;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &resultData);
	return SAFE_AUTORELEASE((NSData *)resultData);
}

-(NSData *)data
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	/*The first byte of the font table is the number of entries.*/
	OFDataBufferAppendShortInt(&db, (uint16_t)[_fonts count]); /*cData*/
	OFDataBufferAppendShortInt(&db, 0); /*cbExtra*/
	
	/*The entries are then listed one after the other.*/
	for(int i = 0; i < [_fonts count]; i++) {
		NSData *entryData = [self _dataForEntry:i];
		OFDataBufferAppendByte(&db, (uint8_t)[entryData length]); /*cchData*/
		OFDataBufferAppendData(&db, entryData);
	}
	
	CFDataRef resultData;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &resultData);
	return SAFE_AUTORELEASE((NSData *)resultData);
}

#if !ARC

-(void)dealloc
{
	[_fonts release];
	[super dealloc];
}

#endif

@end
