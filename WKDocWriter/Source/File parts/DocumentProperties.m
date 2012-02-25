/*
 DocumentProperties.m
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

#import "DocumentProperties.h"
#import "OFDataBuffer.h"
#import "../WKUtilities.h"

/*Documet Properties are mostly static for now.*/

@implementation DocumentProperties

-(id)initDefaultDocumentProperties
{
	self = [super init];
	return self;
}

-(long)_createDTTMWithCurrentDate
{
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSWeekdayOrdinalCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	long dttm = 0;
	dttm |= comps.minute;
	dttm |= comps.hour << 5;
	dttm |= comps.day << 11;
	dttm |= comps.month << 16;
	dttm |= (comps.year - 1900) << 20;
	dttm |= comps.weekdayOrdinal << 29;
	return dttm;
}

-(NSData *)data
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	/*DopBase*/
	OFDataBufferAppendShortInt(&db, 0x20); /*fpc*/
	OFDataBufferAppendShortInt(&db, 0x04); /*nFtn*/
	OFDataBufferAppendShortInt(&db, 0x0830); /*fAutoHyphen*/
	OFDataBufferAppendShortInt(&db, 0x1888); /*fEmbedFonts*/
	OFDataBufferAppendShortInt(&db, 0xF000); /*copts60*/
	OFDataBufferAppendShortInt(&db, 0x020D); /*dxaTab*/
	OFDataBufferAppendShortInt(&db, 0); /*cpgWebOpt*/
	OFDataBufferAppendShortInt(&db, 0x0168); /*dxaHotZ*/
	OFDataBufferAppendShortInt(&db, 0); /*cConsecHypLim*/
	OFDataBufferAppendShortInt(&db, 0); /*wSpare*/
	OFDataBufferAppendLongInt(&db, [self _createDTTMWithCurrentDate]); /*dttmCreated*/
	OFDataBufferAppendLongInt(&db, [self _createDTTMWithCurrentDate]); /*dttmRevised*/
	OFDataBufferAppendLongInt(&db, 0); /*dttmLastPrint*/
	OFDataBufferAppendShortInt(&db, 0); /*nRevision*/
	OFDataBufferAppendLongInt(&db, 0); /*tmEdited*/
	OFDataBufferAppendLongInt(&db, 0); /*cWords*/
	OFDataBufferAppendLongInt(&db, 0); /*cCh*/
	OFDataBufferAppendShortInt(&db, 1); /*cPg*/
	OFDataBufferAppendLongInt(&db, 1); /*cParas*/
	OFDataBufferAppendShortInt(&db, 0x0004); /*nEdn*/
	OFDataBufferAppendByte(&db, 0x03); /*epc*/
	OFDataBufferAppendByte(&db, 0x10); /*fShadeMergeFields*/
	OFDataBufferAppendLongInt(&db, 1); /*cLines*/
	OFDataBufferAppendLongInt(&db, 0); /*cWordsWithSubdocs*/
	OFDataBufferAppendLongInt(&db, 0); /*cChWithSubdocs*/
	OFDataBufferAppendShortInt(&db, 1); /*cPgWithSubdocs*/
	OFDataBufferAppendLongInt(&db, 1); /*cParasWithSubdocs*/
	OFDataBufferAppendLongInt(&db, 1); /*cLinesWithSubdocs*/
	OFDataBufferAppendLongInt(&db, 0); /*lKeyProtDoc*/
	OFDataBufferAppendShortInt(&db, 0x0320); /*wvkoSaved, pctWwdSaved, zkSaved, iGutterPos*/
	
	/*Dop95*/
	OFDataBufferAppendLongInt(&db, 0x0010F000); /*copts80*/
	
	/*Dop97*/
	OFDataBufferAppendShortInt(&db, 0); /*adt*/
	for(int i = 0; i < 310; i++) {
		OFDataBufferAppendByte(&db, 0); /*doptypography*/
	}
	OFDataBufferAppendLongInt(&db, 0x07C006A5); /*dogrid*/
	OFDataBufferAppendLongInt(&db, 0x00B400B4); /*dogrid*/
	OFDataBufferAppendShortInt(&db, 0x0080); /*dogrid*/
	OFDataBufferAppendShortInt(&db, 0x3012); /*lvlDop*/
	OFDataBufferAppendShortInt(&db, 0); /*unused*/
	for(int j = 0; j < 3; j++) {
		OFDataBufferAppendLongInt(&db, 0); /*asumyi*/
	}
	OFDataBufferAppendLongInt(&db, 0); /*cChWS*/
	OFDataBufferAppendLongInt(&db, 0); /*cChWSWithSubdocs*/
	OFDataBufferAppendLongInt(&db, 0); /*grfDocEvents*/
	OFDataBufferAppendLongInt(&db, 0); /*space*/
	OFDataBufferAppendLongInt(&db, 0); /*cpMaxListCacheMainDoc*/
	OFDataBufferAppendShortInt(&db, 0); /*ilfoLastBulletMain*/
	OFDataBufferAppendShortInt(&db, 0); /*ilfoLastNumberMain*/
	OFDataBufferAppendLongInt(&db, 0); /*cDBC*/
	OFDataBufferAppendLongInt(&db, 0); /*cDBCWithSubdocs*/
	OFDataBufferAppendLongInt(&db, 0); /*reserved3a*/
	OFDataBufferAppendShortInt(&db, 0); /*nfcFtnRef*/
	for(int k = 0; k < 30; k++) {
		OFDataBufferAppendByte(&db, 0);
	}
	OFDataBufferAppendShortInt(&db, 0x02); /*nfcEdnRef*/
	OFDataBufferAppendShortInt(&db, 0); /*hpsZoomFontPag*/
	OFDataBufferAppendShortInt(&db, 0x0422); /*dywDispPag*/
	
	/*Dop2000*/
	OFDataBufferAppendByte(&db, 0); /*ilvlLastBulletMain*/
	OFDataBufferAppendByte(&db, 0); /*ilvlLastNumberMain*/
	OFDataBufferAppendShortInt(&db, 0); /*istdClickParaType*/
	OFDataBufferAppendByte(&db, 0); /*empty1*/
	OFDataBufferAppendByte(&db, 0); /*screenSize_WebOpt*/
	OFDataBufferAppendShortInt(&db, 0); /*unused1*/
	OFDataBufferAppendByte(&db, 0);
	OFDataBufferAppendLongInt(&db, 0x080010F0); /*copts*/
	for(int l = 0; l < 27; l++) {
		OFDataBufferAppendByte(&db, 0); /*copts*/
	}
	OFDataBufferAppendShortInt(&db, 0); /*verCompatPre10*/
	OFDataBufferAppendShortInt(&db, 0); /*fAlwaysMergeEmptyNamespace*/
	
	CFDataRef data;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &data);
	return SAFE_AUTORELEASE((NSData *)data);
}

@end
