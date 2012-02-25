/*
 CharacterProperties.m
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

#import "CharacterProperties.h"
#import "OFDataBuffer.h"
#import "FontTable.h"
#import "../WKUtilities.h"

@implementation CharacterProperties

@synthesize fontTableIndex, fontSize, bold, italic, underlineStyle, textColor;

-(id)init
{
	self = [super init];
	if(self) {
		fontTableIndex = 0;
		fontSize = 12.0;
		bold = NO;
		italic = NO;
		underlineStyle = kCTUnderlineStyleNone;
		textColor = [UIColor blackColor];
	}
	return self;
}

+(CharacterProperties *)characterProperties
{
	CharacterProperties *props = [[CharacterProperties alloc] init];
	return SAFE_AUTORELEASE(props);
}

-(id)initWithAttributes:(NSDictionary *)attrs fontTable:(FontTable *)ffn
{
	self = [self init];
	if(self) {
		CTFontRef font = (CTFontRef)[attrs objectForKey:(id)kCTFontAttributeName];
		CTFontSymbolicTraits traits = CTFontGetSymbolicTraits(font);
		bold = (traits & kCTFontBoldTrait);
		italic = (traits & kCTFontItalicTrait);
		CFNumberRef underlineNum = (CFNumberRef)[attrs objectForKey:(id)kCTUnderlineStyleAttributeName];
		if(underlineNum) CFNumberGetValue(underlineNum, kCFNumberIntType, &underlineStyle);
		NSString *fontName = (NSString *)CTFontCopyFamilyName(font);
		NSUInteger fontIndex = [ffn indexOfFontWithName:fontName];
		fontSize = CTFontGetSize(font);
		textColor = [[UIColor alloc] initWithCGColor:(CGColorRef)[attrs objectForKey:(id)kCTForegroundColorAttributeName]];
		if(fontIndex != NSNotFound) fontTableIndex = fontIndex;
		SAFE_RELEASE(fontName);
	}
	return self;
}

-(id)copy
{
	CharacterProperties *newProps = [[CharacterProperties alloc] init];
	newProps.fontTableIndex = fontTableIndex;
	newProps.fontSize = fontSize;
	newProps.bold = bold;
	newProps.italic = italic;
	newProps.underlineStyle = underlineStyle;
	
	return newProps;
}

/*This method is used to write the first set of properties in an FKP. ie, it will write
 all the properties that are anything other than default values. (Default values discussed in MS-DOC)
 */

-(NSData *)_dataWithNoExceptions
{
	OFDataBuffer databuf;
	OFDataBufferInit(&databuf);
	
	OFDataBufferAppendShortInt(&databuf, sprmFont);
	OFDataBufferAppendShortInt(&databuf, fontTableIndex);
	OFDataBufferAppendShortInt(&databuf, sprmFontSize);
	int16_t halfPoints = (int16_t)(fontSize * 2);
	if(!halfPoints) halfPoints = 24;
	OFDataBufferAppendShortInt(&databuf, halfPoints);
	
	if(bold) {
		OFDataBufferAppendShortInt(&databuf, sprmBold);
		OFDataBufferAppendByte(&databuf, 0x01);
	}
	if(italic) {
		OFDataBufferAppendShortInt(&databuf, sprmItalic);
		OFDataBufferAppendByte(&databuf, 0x01);
	}
	if(underlineStyle) {
		OFDataBufferAppendShortInt(&databuf, sprmUnderline);
		uint8_t kul = 0x00;
		if(underlineStyle & kCTUnderlineStyleSingle) kul = 0x01;
		if(underlineStyle & kCTUnderlineStyleDouble) kul = 0x02; 
		if((underlineStyle & kCTUnderlineStyleSingle) && (underlineStyle & kCTUnderlinePatternDot)) kul = 0x04;
		if(underlineStyle & kCTUnderlineStyleThick) kul = 0x06;
		if((underlineStyle & kCTUnderlineStyleSingle) && (underlineStyle & kCTUnderlinePatternDash)) kul = 0x07;
		if((underlineStyle & kCTUnderlineStyleSingle) && (underlineStyle & kCTUnderlinePatternDashDot)) kul = 0x09;
		if((underlineStyle & kCTUnderlineStyleSingle) && (underlineStyle & kCTUnderlinePatternDashDotDot)) kul = 0x0A;
		if((underlineStyle & kCTUnderlineStyleThick) && (underlineStyle & kCTUnderlinePatternDot)) kul = 0x14;
		if((underlineStyle & kCTUnderlineStyleThick) && (underlineStyle & kCTUnderlinePatternDashDot)) kul = 0x19;
		if((underlineStyle & kCTUnderlineStyleThick) && (underlineStyle & kCTUnderlinePatternDashDotDot)) kul = 0x1A;
		OFDataBufferAppendByte(&databuf, kul);
	}
	
	if(![textColor isEqual:[UIColor blackColor]]) {
		OFDataBufferAppendShortInt(&databuf, sprmForegroundColor);
		CGFloat redF, greenF, blueF;
		uint8_t red, green, blue;
		[textColor getRed:&redF green:&greenF blue:&blueF alpha:NULL];
		red = (uint8_t)(redF * 256);
		green = (uint8_t)(greenF * 256);
		blue = (uint8_t)(blueF * 256);
		OFDataBufferAppendByte(&databuf, red);
		OFDataBufferAppendByte(&databuf, green);
		OFDataBufferAppendByte(&databuf, blue);
		OFDataBufferAppendByte(&databuf, 0x00);
	}
	
	CFDataRef data;
	OFDataBufferRelease(&databuf, kCFAllocatorDefault, &data);
	
	/*Chpxs start with a byte indicating their size in bytes, so we have to go
	 back and write that.*/
	OFDataBuffer secondaryDatabuf;
	OFDataBufferInit(&secondaryDatabuf);
	OFDataBufferAppendByte(&secondaryDatabuf, CFDataGetLength(data));
	OFDataBufferAppendData(&secondaryDatabuf, (NSData *)data);
	if(OFDataBufferSpaceOccupied(&secondaryDatabuf) % 2) OFDataBufferAppendByte(&databuf, 0);
	CFDataRef secondData;
	OFDataBufferRelease(&secondaryDatabuf, kCFAllocatorDefault, &secondData);
	return SAFE_AUTORELEASE((NSData *)secondData);
}

/*This method is used to write properties for any subsequent properties. It automatically
 redirects to the previous method if previousProperties is nil, meaning we're dealing
 with the first properties in a chain.
 */

-(NSData *)dataWithExceptionsFromProperties:(CharacterProperties *)previousProperties
{
	if(!previousProperties) return [self _dataWithNoExceptions];
	OFDataBuffer databuf;
	OFDataBufferInit(&databuf);
	
	if(fontTableIndex != previousProperties.fontTableIndex) {
		OFDataBufferAppendShortInt(&databuf, sprmFont);
		OFDataBufferAppendShortInt(&databuf, fontTableIndex);
	}
	//if(fontSize != previousProperties.fontSize) {
		int16_t halfPoints = (int16_t)(fontSize * 2);
		if(!halfPoints) halfPoints = 24;
		OFDataBufferAppendShortInt(&databuf, sprmFontSize);
		OFDataBufferAppendShortInt(&databuf, halfPoints);
	//}
	if(bold != previousProperties.bold) {
		OFDataBufferAppendShortInt(&databuf, sprmBold);
		OFDataBufferAppendByte(&databuf, (bold) ? 0x01 : 0x00);
	}
	if(italic != previousProperties.italic) {
		OFDataBufferAppendShortInt(&databuf, sprmItalic);
		OFDataBufferAppendShortInt(&databuf, (italic) ? 0x01 :0x00);
	}
	if(underlineStyle != previousProperties.underlineStyle) {
		OFDataBufferAppendShortInt(&databuf, sprmUnderline);
		uint8_t kul = 0x00;
		if(underlineStyle & kCTUnderlineStyleSingle) kul = 0x01;
		if(underlineStyle & kCTUnderlineStyleDouble) kul = 0x02; 
		if((underlineStyle & kCTUnderlineStyleSingle) && (underlineStyle & kCTUnderlinePatternDot)) kul = 0x04;
		if(underlineStyle & kCTUnderlineStyleThick) kul = 0x06;
		if((underlineStyle & kCTUnderlineStyleSingle) && (underlineStyle & kCTUnderlinePatternDash)) kul = 0x07;
		if((underlineStyle & kCTUnderlineStyleSingle) && (underlineStyle & kCTUnderlinePatternDashDot)) kul = 0x09;
		if((underlineStyle & kCTUnderlineStyleSingle) && (underlineStyle & kCTUnderlinePatternDashDotDot)) kul = 0x0A;
		if((underlineStyle & kCTUnderlineStyleThick) && (underlineStyle & kCTUnderlinePatternDot)) kul = 0x14;
		if((underlineStyle & kCTUnderlineStyleThick) && (underlineStyle & kCTUnderlinePatternDashDot)) kul = 0x19;
		if((underlineStyle & kCTUnderlineStyleThick) && (underlineStyle & kCTUnderlinePatternDashDotDot)) kul = 0x1A;
		OFDataBufferAppendByte(&databuf, kul);
	}
	if(![textColor isEqual:previousProperties.textColor]) {
		OFDataBufferAppendShortInt(&databuf, sprmForegroundColor);
		CGFloat redF, greenF, blueF;
		uint8_t red, green, blue;
		[textColor getRed:&redF green:&greenF blue:&blueF alpha:NULL];
		red = (uint8_t)(redF * 256);
		green = (uint8_t)(greenF * 256);
		blue = (uint8_t)(blueF * 256);
		OFDataBufferAppendByte(&databuf, red);
		OFDataBufferAppendByte(&databuf, green);
		OFDataBufferAppendByte(&databuf, blue);
		OFDataBufferAppendByte(&databuf, 0x00);
	}
	
	CFDataRef data;
	OFDataBufferRelease(&databuf, kCFAllocatorDefault, &data);
	
	/*Chpxs start with a byte indicating their size in bytes, so we have to go
	back and write that.*/
	OFDataBuffer secondaryDatabuf;
	OFDataBufferInit(&secondaryDatabuf);
	OFDataBufferAppendByte(&secondaryDatabuf, CFDataGetLength(data));
	OFDataBufferAppendData(&secondaryDatabuf, (NSData *)data);
	if(OFDataBufferSpaceOccupied(&secondaryDatabuf) % 2) OFDataBufferAppendByte(&secondaryDatabuf, 0);
	CFDataRef secondData;
	OFDataBufferRelease(&secondaryDatabuf, kCFAllocatorDefault, &secondData);
	return SAFE_AUTORELEASE((NSData *)secondData);
}

#if !ARC

-(void)dealloc
{
	[textColor release];
	[super dealloc];
}

#endif

@end
