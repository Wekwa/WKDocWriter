/*
 WKDocWriter.m
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

#import <CoreText/CoreText.h>
#import "WKDocWriter.h"
#import "FileInformationBlock.h"
#import "FormattedDiskPage.h"
#import "CompoundFileBinary.h"
#import "CharacterProperties.h"
#import "ParagraphProperties.h"
#import "SummaryInformation.h"
#import "FontTable.h"
#import "TableStream.h"
#import "WKUtilities.h"

static NSDictionary *defaultAttrs = nil;

@interface WKDocWriter (Private)

-(uint32_t)_characterPositionToFileOffset:(uint32_t)cp;
-(void)_ensureDefaultAttributes;
-(NSAttributedString *)_attributedStringByFillingInDefaultAttributes:(NSAttributedString *)attributedString;

@end

@implementation WKDocWriter

-(id)initWithAttributedString:(NSAttributedString *)attrStr
{
	self = [super init];
	if(self) {
		[self _ensureDefaultAttributes];
		_attrStr = [[self _attributedStringByFillingInDefaultAttributes:attrStr] copy];
		_fkps = [[NSMutableArray alloc] init];
		_cfb = [[CompoundFileBinary alloc] init];
		_fib = [[FileInformationBlock alloc] init];
		_ffn = [[FontTable alloc] init];
	}
	return self;
}

-(uint32_t)_characterPositionToFileOffset:(uint32_t)cp
{
	return (cp * 2) + (PAGESIZE * 3);
}

-(void)_ensureDefaultAttributes
{
	if(defaultAttrs) return;
	
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	
	CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), 12.0, NULL);
	[attrs setObject:(id)font forKey:(id)kCTFontAttributeName];
	
	[attrs setObject:(id)[[UIColor blackColor] CGColor] forKey:(id)kCTForegroundColorAttributeName];
	
	CTTextAlignment alignment = kCTLeftTextAlignment;
	CGFloat lineHeightMult = 1.0;
	CTParagraphStyleSetting settings[] = {{kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment}, {kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(lineHeightMult), &lineHeightMult}};
	CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 2);
	[attrs setObject:(id)paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
	CFRelease(paragraphStyle);
	CFRelease(font);
	defaultAttrs = [attrs copy];
}

-(NSAttributedString *)_attributedStringByFillingInDefaultAttributes:(NSAttributedString *)attributedString
{
	NSMutableAttributedString *attrStr = [attributedString mutableCopy];
	[self _ensureDefaultAttributes];
	[attributedString enumerateAttributesInRange:NSMakeRange(0, [attributedString length]) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		for(id key in [attrs allKeys]) {
			if(![attrs objectForKey:key]) {
				[attrStr addAttribute:key value:[defaultAttrs objectForKey:key] range:range];
			}
		}
	}];
	return SAFE_AUTORELEASE(attrStr);
}

/*For now I've given the -write method a BOOL return value to follow Foundation's
 pattern. (eg, all NSData and NSString "write..." methods return a BOOL for success.)
 However, currently, it is always YES because these classes do not know when they make
 a mistake writing the file. I may change it to a void return in a later revision.
 */

-(BOOL)write
{
	BOOL success = YES;
	_docFormatData = [[NSMutableData alloc] init];
	[_attrStr enumerateAttribute:(id)kCTFontAttributeName inRange:NSMakeRange(0, [_attrStr length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
		if(value != nil)
			[_ffn addFont:(CTFontRef)value];
	}];
	NSData *fontTable = [_ffn data];
	
	/*Due to limited features, these values can be calculated before writing the rest of the document.*/
	_fib.textStartLocation = (PAGESIZE * 3);
	_fib.textEndLocation = (PAGESIZE * 3) + ([_attrStr length] + 1) * 2; /*Multiply by 2 due to Unicode encoding*/
	_fib.textLength = [_attrStr length];
	_fib.stylesheetLocation = 0;
	_fib.stylesheetSize = 162;
	_fib.sedLocation = 162;
	_fib.sedSize = 20;
	_fib.characterPropertiesPlexLocation = 182;
	_fib.fontTableSize = [fontTable length];
	
	[_docFormatData appendData:[_cfb headerData]];
	
	[_docFormatData appendData:[_fib data]];
	
	NSString *paragraphEndedString = [NSString stringWithFormat:@"%@%c%c", [_attrStr string], 0x0D, 0x0D];
	NSData *stringData =[paragraphEndedString dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
	[_docFormatData appendData:stringData];
	
	int remainder = PAGESIZE - ([_docFormatData length] % PAGESIZE);
	uint8_t zeroByte = 0;
	for(int i = 0; i < remainder; i++)
		[_docFormatData appendBytes:&zeroByte length:1];
	
	_tbl = [[TableStream alloc] initWithDefaultTableStream];
	[_tbl setFontTable:_ffn];
	
	FormattedDiskPage *currentChpxFkp = [[FormattedDiskPage alloc] initAsParagraphProperties:NO];
	[currentChpxFkp setNullTerminatingFileOffset:[self _characterPositionToFileOffset:[_attrStr length] + 1]];
	FormattedDiskPage *currentPapxFkp = [[FormattedDiskPage alloc] initAsParagraphProperties:YES];
	[currentPapxFkp setNullTerminatingFileOffset:[self _characterPositionToFileOffset:[_attrStr length] + 1]];
	
	[_attrStr enumerateAttributesInRange:NSMakeRange(0, [_attrStr length]) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		CharacterProperties *characterProps = [[CharacterProperties alloc] initWithAttributes:attrs fontTable:_ffn];
		if([currentChpxFkp wouldAttributesNeedNewFKP:characterProps]) {
			[_tbl addFormattedDiskPageToPlexes:currentChpxFkp pageNumber:([_docFormatData length] / PAGESIZE) - 1];
			[_docFormatData appendData:[currentChpxFkp data]];
			[currentChpxFkp reset];
		}
		[currentChpxFkp addProperties:characterProps startingAtFileOffset:[self _characterPositionToFileOffset:range.location]];
		SAFE_RELEASE(characterProps);
		
		ParagraphProperties *paragraphProps = [[ParagraphProperties alloc] initWithAttributes:attrs];
		if([currentPapxFkp wouldAttributesNeedNewFKP:paragraphProps]) {
			[_tbl addFormattedDiskPageToPlexes:currentPapxFkp pageNumber:([_docFormatData length] / PAGESIZE) - 1];
			[_docFormatData appendData:[currentPapxFkp data]];
			[currentPapxFkp reset];
		}
		[currentPapxFkp addProperties:paragraphProps startingAtFileOffset:[self _characterPositionToFileOffset:range.location]];
		SAFE_RELEASE(paragraphProps);
	}];
	
	[_tbl addFormattedDiskPageToPlexes:currentChpxFkp pageNumber:([_docFormatData length] / PAGESIZE) - 1];
	[_docFormatData appendData:[currentChpxFkp data]];
	[_tbl addFormattedDiskPageToPlexes:currentPapxFkp pageNumber:([_docFormatData length] / PAGESIZE) - 1];
	[_docFormatData appendData:[currentPapxFkp data]];
	SAFE_RELEASE(currentChpxFkp), SAFE_RELEASE(currentPapxFkp);
	
	for(int j = 0; j < PAGESIZE; j++) {
		uint8_t empty = 0;
		[_docFormatData appendBytes:&empty length:1];
	}
	
	_cfb.wordStreamLength = ([_docFormatData length] / PAGESIZE) - 1;
	_fib.wordStreamLength = _cfb.wordStreamLength;
	
	for(int k = 0; k < PAGESIZE; k++) {
		uint8_t empty = 0;
		[_docFormatData appendBytes:&empty length:1];
	}
	_cfb.tableStreamSectorNumber = ([_docFormatData length] / PAGESIZE) - 1;
	[_docFormatData appendData:[_tbl data]];
	_cfb.tableStreamLength = 8; /*May be variable in ridiculously long documents. ie, hundreds of thousands of pages.*/
	
	SummaryInformation *summaryInfo = [[SummaryInformation alloc] initDefaultSummaryInformation];
	[_docFormatData appendData:[summaryInfo data]];
	SAFE_RELEASE(summaryInfo);
	_cfb.fileAllocationTableSectorNumber = ([_docFormatData length] / PAGESIZE) - 1;
	[_docFormatData appendData:[_cfb fileAllocationTableData]];
	_cfb.directorySectorNumber = ([_docFormatData length] / PAGESIZE) - 1;
	[_docFormatData appendData:[_cfb directoryEntryData]];
	
	_fib.characterPropertiesPlexSize = [_tbl characterPlexSize];
	_fib.paragraphPropertiesPlexLocation = [_tbl paragraphPlexLocation];
	_fib.paragraphPropertiesPlexSize = [_tbl paragraphPlexSize];
	_fib.fontTableLocation = [_tbl fontTableLocation];
	_fib.listPropertiesLocation = [_tbl paragraphPlexLocation] + [_tbl paragraphPlexSize];
	_fib.listPropertiesSize = 12;
	_fib.clxLocation = _fib.listPropertiesLocation + _fib.listPropertiesSize;
	_fib.clxSize = 21;
	_fib.documentPropertiesLocation = _fib.fontTableLocation + _fib.fontTableSize;
	_fib.documentPropertiesSize = 544;
	[_docFormatData replaceBytesInRange:NSMakeRange(0, PAGESIZE) withBytes:[[_cfb headerData] bytes]];
	[_docFormatData replaceBytesInRange:NSMakeRange(PAGESIZE, (PAGESIZE * 3)) withBytes:[[_fib data] bytes]];
	
	return success;
}

-(NSData *)docFormatData
{
	if(!_docFormatData) [self write];
	return SAFE_AUTORELEASE([_docFormatData copy]);
}

#if !ARC

-(void)dealloc
{
	[_attrStr release];
	[_fkps release];
	[_cfb release];
	[_fib release];
	[_tbl release];
	[_ffn release];
	[_docFormatData release];
	[super dealloc];
}

#endif

@end
