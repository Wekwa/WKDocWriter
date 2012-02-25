/*
 ParagraphProperties.m
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

#import "ParagraphProperties.h"
#import "OFDataBuffer.h"
#import "../WKUtilities.h"

@implementation ParagraphProperties

@synthesize alignment, lineHeightMultiple, firstLineIndent, leftIndent, rightIndent;

-(id)init
{
	self = [super init];
	if(self) {
		alignment = kCTLeftTextAlignment;
		firstLineIndent = 0.0;
		lineHeightMultiple = 1.0;
		leftIndent = 0.0;
		rightIndent = 0.0;
	}
	return self;
}

+(ParagraphProperties *)paragraphProperties
{
	ParagraphProperties *props = [[ParagraphProperties alloc] init];
	return SAFE_AUTORELEASE(props);
}

-(id)initWithAttributes:(NSDictionary *)attrs
{
	self = [self init];
	if(self) {
		CTParagraphStyleRef paraStyle = (CTParagraphStyleRef)[attrs objectForKey:(id)kCTParagraphStyleAttributeName];
		CTParagraphStyleGetValueForSpecifier(paraStyle, kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment);
		CTParagraphStyleGetValueForSpecifier(paraStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(lineHeightMultiple), &lineHeightMultiple);
		CTParagraphStyleGetValueForSpecifier(paraStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent);
		CTParagraphStyleGetValueForSpecifier(paraStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(leftIndent), &leftIndent);
		CTParagraphStyleGetValueForSpecifier(paraStyle, kCTParagraphStyleSpecifierTailIndent, sizeof(rightIndent), &rightIndent);
	}
	return self;
}

-(NSData *)_dataWithNoExceptions
{
	OFDataBuffer dataBuf;
	OFDataBufferInit(&dataBuf);
	OFDataBufferAppendByte(&dataBuf, 0x00);
	OFDataBufferAppendByte(&dataBuf, 0x00);
	OFDataBufferAppendShortInt(&dataBuf, sprmAlignment);
	uint8_t PJc;
	switch(alignment) {
		case kCTLeftTextAlignment:
			PJc = 0x00;
			break;
		case kCTCenterTextAlignment:
			PJc = 0x01;
			break;
		case kCTRightTextAlignment:
			PJc = 0x02;
			break;
		case kCTJustifiedTextAlignment:
			PJc = 0x04;
			break;
	}
	OFDataBufferAppendByte(&dataBuf, PJc);
	
	OFDataBufferAppendShortInt(&dataBuf, sprmLineHeightMultiple);
	uint16_t dyaLine = 240;
	if(lineHeightMultiple > 1.0 && lineHeightMultiple <= 1.5) {
		dyaLine = 360;
	} else if(lineHeightMultiple >= 1.5) {
		dyaLine = 480;
	}
	OFDataBufferAppendShortInt(&dataBuf, dyaLine);
	OFDataBufferAppendShortInt(&dataBuf, 0x0001);
	
	OFDataBufferAppendShortInt(&dataBuf, sprmRightIndent);
	uint16_t dxaRight = (rightIndent * 20);
	OFDataBufferAppendShortInt(&dataBuf, dxaRight);
	
	OFDataBufferAppendShortInt(&dataBuf, sprmLeftIndent);
	uint16_t dxaLeft = (leftIndent * 20);
	OFDataBufferAppendShortInt(&dataBuf, dxaLeft);
	
	OFDataBufferAppendShortInt(&dataBuf, sprmFirstLineIndent);
	uint16_t dxaLeft1 = (firstLineIndent * 20);
	OFDataBufferAppendShortInt(&dataBuf, dxaLeft1);
	
	if(OFDataBufferSpaceOccupied(&dataBuf) % 2) OFDataBufferAppendByte(&dataBuf, 0);
	CFDataRef data;
	OFDataBufferRelease(&dataBuf, kCFAllocatorDefault, &data);
	NSMutableData *mutableData = [(NSData *)data mutableCopy];
	int dataLen = ([mutableData length] - 2);
	if(dataLen % 2) {
		uint8_t empty = 0;
		[mutableData appendBytes:&empty length:1];
		dataLen++;
	}
	dataLen /= 2;
	[mutableData replaceBytesInRange:NSMakeRange(1, 1) withBytes:&dataLen];
	return SAFE_AUTORELEASE(mutableData);
}

-(NSData *)dataWithExceptionsFromProperties:(ParagraphProperties *)previousProperties
{
	if(!previousProperties)
		return [self _dataWithNoExceptions];
	OFDataBuffer dataBuf;
	OFDataBufferInit(&dataBuf);
	OFDataBufferAppendByte(&dataBuf, 0x00);
	OFDataBufferAppendByte(&dataBuf, 0x00);
	if(previousProperties.alignment != alignment) {
		OFDataBufferAppendShortInt(&dataBuf, sprmAlignment);
		uint8_t PJc;
		switch(alignment) {
			case kCTLeftTextAlignment:
				PJc = 0x00;
				break;
			case kCTCenterTextAlignment:
				PJc = 0x01;
				break;
			case kCTRightTextAlignment:
				PJc = 0x02;
				break;
			case kCTJustifiedTextAlignment:
				PJc = 0x04;
				break;
		}
		OFDataBufferAppendByte(&dataBuf, PJc);
	}
	if(previousProperties.lineHeightMultiple != lineHeightMultiple) {
		OFDataBufferAppendShortInt(&dataBuf, sprmLineHeightMultiple);
		uint16_t dyaLine = 240;
		if(lineHeightMultiple > 1.0 && lineHeightMultiple <= 1.5) {
			dyaLine = 360;
		} else if(lineHeightMultiple >= 1.5) {
			dyaLine = 480;
		}
		OFDataBufferAppendShortInt(&dataBuf, dyaLine);
		OFDataBufferAppendShortInt(&dataBuf, 0x0001);
	}
	
	if(previousProperties.rightIndent != rightIndent) {
		OFDataBufferAppendShortInt(&dataBuf, sprmRightIndent);
		uint16_t dxaRight = (rightIndent * 20);
		OFDataBufferAppendShortInt(&dataBuf, dxaRight);
	}
	
	if(previousProperties.leftIndent != leftIndent) {
		OFDataBufferAppendShortInt(&dataBuf, sprmLeftIndent);
		uint16_t dxaLeft = (leftIndent * 20);
		OFDataBufferAppendShortInt(&dataBuf, dxaLeft);
	}
	
	if(previousProperties.firstLineIndent != firstLineIndent) {
		OFDataBufferAppendShortInt(&dataBuf, sprmFirstLineIndent);
		uint16_t dxaLeft1 = (firstLineIndent * 20);
		OFDataBufferAppendShortInt(&dataBuf, dxaLeft1);
	}
	
	if(OFDataBufferSpaceOccupied(&dataBuf) % 2) OFDataBufferAppendByte(&dataBuf, 0);
	CFDataRef data;
	OFDataBufferRelease(&dataBuf, kCFAllocatorDefault, &data);
	NSMutableData *mutableData = [(NSData *)data mutableCopy];
	int dataLen = ([mutableData length] - 2);
	if(dataLen % 2) {
		uint8_t empty = 0;
		[mutableData appendBytes:&empty length:1];
		dataLen++;
	}
	dataLen /= 2;
	[mutableData replaceBytesInRange:NSMakeRange(1, 1) withBytes:&dataLen];
	return SAFE_AUTORELEASE((NSData *)mutableData);
}

@end
