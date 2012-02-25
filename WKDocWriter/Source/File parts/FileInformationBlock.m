/*
 FileInformationBlock.m
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

#import "FileInformationBlock.h"
#import "OFDataBuffer.h"
#import "../WKUtilities.h"

/*These are parallel arrays, consisting of all the locales supported by iOS *and* MS Word.*/

static const char *locales[34] = { 
	"en", "fr", "de", "ja", "nl", "it", "es" "pt-PT", "da", 
	"fi", "nb", "sv", "ko", "zh-Hans", "zh-Hant", "ru", 
	"pl", "tr", "uk", "ar", "hr", "cs", "el", "he", "ro", 
	"sk", "th", "id", "ms", "en-GB", "ca", "hu", "vi",
};

static const int languageIDs[34] = {
	0x0409, 0x040C, 0x0407, 0x0411, 0x0813, 0x0410, 0x2C0A, 0x0416, 0x0816, 0x0406,
	0x0408, 0x0414, 0x041D, 0x0412, 0x0804, 0x0804, 0x0419,
	0x0415, 0x041F, 0x0422, 0x1401, 0x041A, 0x0405, 0x0408, 0x040D, 0x0418,
	0x041B, 0x041E, 0x0421, 0x043E, 0x0809, 0x0403, 0x040E, 0x042A
};

@implementation FileInformationBlock

@synthesize readOnly,
			textStartLocation,
			textEndLocation,
			textLength,
			wordStreamLength,
			stylesheetLocation,
			stylesheetSize,
			sedLocation,
			sedSize,
			characterPropertiesPlexLocation,
			characterPropertiesPlexSize,
			paragraphPropertiesPlexLocation,
			paragraphPropertiesPlexSize,
			fontTableLocation,
			fontTableSize,
			clxLocation,
			clxSize,
			documentPropertiesLocation,
			documentPropertiesSize,
			listPropertiesLocation,
			listPropertiesSize;

-(uint16_t)_getLanguageIDForCurrentLocale
{
	NSString *langStr = [[NSLocale preferredLanguages] objectAtIndex:0];
	const char *lang = [langStr UTF8String];
	static int langCode = 0;
	if(langCode) return langCode;
	
	for(int i = 0; i < sizeof(languageIDs) / sizeof(int); i++) {
		if(strcmp(lang, locales[i]) == 0) langCode = languageIDs[i];
		break;
	}
	
	return langCode;
}

-(NSData *)data
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	/*FibBase*/
	
	OFDataBufferAppendShortInt(&db, 0xA5EC); /*wIdent*/
	OFDataBufferAppendShortInt(&db, 0x00C1); /*nFib*/
	OFDataBufferAppendShortInt(&db, 0); /*unused*/
	OFDataBufferAppendShortInt(&db, [self _getLanguageIDForCurrentLocale]); /*lid*/
	OFDataBufferAppendShortInt(&db, 0); /*pnNext*/
	uint16_t flags = 0x1200;
	if(readOnly) flags |= 0x1600;
	OFDataBufferAppendShortInt(&db, flags); /*fDot - fObfuscated*/
	OFDataBufferAppendShortInt(&db, 0x00BF); /*nFibBack*/
	OFDataBufferAppendLongInt(&db, 0); /*lKey*/
	OFDataBufferAppendByte(&db, 0x01); /*envr*/
	OFDataBufferAppendByte(&db, 0x11); /*fMac - fSpare0*/
	OFDataBufferAppendShortInt(&db, 0);
	OFDataBufferAppendShortInt(&db, 0);
	OFDataBufferAppendLongInt(&db, textStartLocation); /*fcMin*/
	OFDataBufferAppendLongInt(&db, textEndLocation); /*fcMac*/
	
	/*FibRgW97*/
	
	OFDataBufferAppendShortInt(&db, 0x000E); /*csw*/
	OFDataBufferAppendShortInt(&db, 0x4B57); /*creatorID*/
	OFDataBufferAppendShortInt(&db, 0x4B57); /*modifierID*/
	for(int i = 0; i < 6; i++) OFDataBufferAppendLongInt(&db, 0);
	
	/*FibRgLw97*/
	
	OFDataBufferAppendShortInt(&db, 0x0016); /*cslw*/
	OFDataBufferAppendLongInt(&db, wordStreamLength); /*cbMac*/
	OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, textLength); /*ccpText*/
	for(int i = 0; i < 18; i++) OFDataBufferAppendLongInt(&db, 0);
	
	/*FibRgFcLcb97*/
	
	OFDataBufferAppendShortInt(&db, 0x006C);
	OFDataBufferAppendLongInt(&db, stylesheetLocation); /*fcStshf*/
	OFDataBufferAppendLongInt(&db, stylesheetSize); /*lcbStshf*/
	OFDataBufferAppendLongInt(&db, stylesheetLocation); /*fcStshfOrig*/
	OFDataBufferAppendLongInt(&db, stylesheetSize); /*lcbStshfOrig*/
	for(int i = 0; i < 8; i++) OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, sedLocation); /*fcPlcfSed*/
	OFDataBufferAppendLongInt(&db, sedSize); /*lcbPlcfSed*/
	for(int i = 0; i < 10; i++) OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, characterPropertiesPlexLocation);
	OFDataBufferAppendLongInt(&db, characterPropertiesPlexSize);
	OFDataBufferAppendLongInt(&db, paragraphPropertiesPlexLocation);
	OFDataBufferAppendLongInt(&db, paragraphPropertiesPlexSize);
	OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, fontTableLocation);
	OFDataBufferAppendLongInt(&db, fontTableSize);
	for(int i = 0; i < 30; i++) OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, documentPropertiesLocation);
	OFDataBufferAppendLongInt(&db, documentPropertiesSize);
	OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, clxLocation);
	OFDataBufferAppendLongInt(&db, clxSize);
	for(int i = 0; i < 104; i++) OFDataBufferAppendLongInt(&db, 0);
	OFDataBufferAppendLongInt(&db, listPropertiesLocation);
	OFDataBufferAppendLongInt(&db, listPropertiesSize);
	
	while(OFDataBufferSpaceOccupied(&db) < textStartLocation) OFDataBufferAppendShortInt(&db, 0);
	
	CFDataRef resultData;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &resultData);
	return SAFE_AUTORELEASE((NSData *)resultData);
}


@end
