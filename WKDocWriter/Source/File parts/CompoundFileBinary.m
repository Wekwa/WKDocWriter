/*
 CompoundFileBinary.m
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

#import "CompoundFileBinary.h"
#import "OFDataBuffer.h"
#import "../WKUtilities.h"

@implementation CompoundFileBinary

@synthesize fileAllocationTableSectorNumber, directorySectorNumber, wordStreamLength, tableStreamSectorNumber, tableStreamLength;

-(NSData *)headerData
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	OFDataBufferAppendByte(&db, 0xD0);
	OFDataBufferAppendByte(&db, 0xCF);
	OFDataBufferAppendByte(&db, 0x11);
	OFDataBufferAppendByte(&db, 0xE0);
	OFDataBufferAppendByte(&db, 0xA1);
	OFDataBufferAppendByte(&db, 0xB1);
	OFDataBufferAppendByte(&db, 0x1A);
	OFDataBufferAppendByte(&db, 0xE1); /*Signature*/
	for(int i = 0; i < 4; i++) OFDataBufferAppendLongInt(&db, 0); /*CLSID*/
	OFDataBufferAppendShortInt(&db, 0x003E); /*Minor version*/
	OFDataBufferAppendShortInt(&db, 0x0003); /*Major version*/
	OFDataBufferAppendShortInt(&db, 0xFFFE); /*Byte order*/
	OFDataBufferAppendShortInt(&db, 0x0009); /*Sector shift*/
	OFDataBufferAppendShortInt(&db, 0x0006); /*Mini sector shift*/
	for(int i = 0; i < 6; i++) OFDataBufferAppendByte(&db, 0);
	OFDataBufferAppendLongInt(&db, 0x0000); /*Number of directory sectors*/
	OFDataBufferAppendLongInt(&db, 0x0001); /*Number of file allocation table sectors*/
	OFDataBufferAppendLongInt(&db, directorySectorNumber);
	OFDataBufferAppendLongInt(&db, 0x0000); /*Transaction signture number*/
	OFDataBufferAppendLongInt(&db, 0x1000); /*Mini stream cutoff size*/
	OFDataBufferAppendLongInt(&db, directorySectorNumber + 2);
	OFDataBufferAppendLongInt(&db, 0x0001); /*Number of mini stream sectors*/
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE); /*First DIFAT sector location*/
	OFDataBufferAppendLongInt(&db, 0); /*Number of DIFAT sectors*/
	OFDataBufferAppendLongInt(&db, fileAllocationTableSectorNumber);
	for(int i = 0; i < 108; i++) OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	
	
	CFDataRef resultData;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &resultData);
	return SAFE_AUTORELEASE((NSData *)resultData);
}

-(NSData *)fileAllocationTableData
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	int j = 0;
	int k = 0;
	for(int i = 0; i < wordStreamLength; i++) {
		uint32_t sector = i + 1;
		OFDataBufferAppendLongInt(&db, sector);
		j++;
	}
	j++;
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE); /*endChain*/
	
	for(int i = 0; i < tableStreamLength - 1; i++) {
		uint32_t sector = tableStreamSectorNumber + i + 1;
		OFDataBufferAppendLongInt(&db, sector);
		j++;
	}
	
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE); /*endChain*/
	
	for(int i = 0; i < 7; i++) {
		uint32_t sector = (tableStreamSectorNumber + tableStreamLength) + i + 1;
		OFDataBufferAppendLongInt(&db, sector);
		j++;
	}
	j++;
	k = j;
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE);
	
	for(int i = 0; i < 7; i++) {
		uint32_t sector = j + i + 2;
		OFDataBufferAppendLongInt(&db, sector);
		k++;
	}
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE);
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE);
	OFDataBufferAppendLongInt(&db, k + 4);
	
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE); /*endChain*/
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE); /*endChain*/
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFE); /*endChain*/
	
	while(OFDataBufferSpaceOccupied(&db) % PAGESIZE) {
		OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	}
	
	CFDataRef resultData;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &resultData);
	return SAFE_AUTORELEASE((NSData *)resultData);
}

-(NSData *)directoryEntryData
{
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	/*Root Entry*/
	OFDataBufferAppendString(&db, CFSTR("Root Entry"), kCFStringEncodingUTF16LE); /*Entry Name*/
	for(int i = 0; i < 11; i++) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	OFDataBufferAppendShortInt(&db, 0x0016); /*Entry Name Length*/
	OFDataBufferAppendByte(&db, 0x05); /*Object Type*/
	OFDataBufferAppendByte(&db, 0x01); /*Color Flag*/
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF); /*Left Sibling*/
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF); /*Right Sibling*/
	OFDataBufferAppendLongInt(&db, 0x03); /*Child*/
	for(int i = 0; i < 9; i++) {
		OFDataBufferAppendLongInt(&db, 0); /*CLSID + State Bits + Creation Time + Modification Time*/
	}
	OFDataBufferAppendLongInt(&db, directorySectorNumber + 2); /*Mini-stream location (Root Entry only)*/
	OFDataBufferAppendLongInt(&db, 0x80); /*Mini-stream size (Root Entry Only)*/
	OFDataBufferAppendLongInt(&db, 0);
	
	/*Table Stream*/
	OFDataBufferAppendString(&db, CFSTR("1Table"), kCFStringEncodingUTF16LE);
	for(int j = 0; j < 13; j++) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	OFDataBufferAppendShortInt(&db, 0x000E);
	OFDataBufferAppendByte(&db, 0x02);
	OFDataBufferAppendByte(&db, 0x00);
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	for(int j = 0; j < 9; j++) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	OFDataBufferAppendLongInt(&db, tableStreamSectorNumber);
	OFDataBufferAppendLongInt(&db, 0x1000);
	OFDataBufferAppendLongInt(&db, 0);
	
	/*Word Stream*/
	OFDataBufferAppendString(&db, CFSTR("WordDocument"), kCFStringEncodingUTF16LE);
	for(int k = 0; k < 10; k++) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	OFDataBufferAppendShortInt(&db, 0x001A);
	OFDataBufferAppendByte(&db, 0x02);
	OFDataBufferAppendByte(&db, 0x01);
	OFDataBufferAppendLongInt(&db, 0x01);
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	for(int k = 0; k < 10; k++) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	OFDataBufferAppendLongInt(&db, 0x1000);
	OFDataBufferAppendLongInt(&db, 0);
	
	/*Summary Information Stream*/
	OFDataBufferAppendShortInt(&db, 0x0005);
	OFDataBufferAppendString(&db, CFSTR("SummaryInformation"), kCFStringEncodingUTF16LE);
	for(int l = 0; l < 26; l++) {
		OFDataBufferAppendByte(&db, 0);
	}
	OFDataBufferAppendShortInt(&db, 0x0028);
	OFDataBufferAppendByte(&db, 0x02);
	OFDataBufferAppendByte(&db, 0x01);
	OFDataBufferAppendLongInt(&db, 0x02);
	OFDataBufferAppendLongInt(&db, 0x04);
	OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	for(int l = 0; l < 9; l++) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	OFDataBufferAppendLongInt(&db, tableStreamSectorNumber + tableStreamLength);
	OFDataBufferAppendLongInt(&db, 0x1000);
	OFDataBufferAppendLongInt(&db, 0);
	
	/*Document Summary Information Stream*/
	OFDataBufferAppendShortInt(&db, 0x0005);
	OFDataBufferAppendString(&db, CFSTR("DocumentSummaryInformation"), kCFStringEncodingUTF16LE);
	for(int m = 0; m < 10; m++) {
		OFDataBufferAppendByte(&db, 0);
	}
	OFDataBufferAppendShortInt(&db, 0x0038);
	OFDataBufferAppendByte(&db, 0x02);
	OFDataBufferAppendByte(&db, 0x01);
	for(int m = 0; m < 3; m++) {
		OFDataBufferAppendLongInt(&db, 0xFFFFFFFF);
	}
	for(int m = 0; m < 9; m++) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	OFDataBufferAppendLongInt(&db, tableStreamSectorNumber + tableStreamLength + 8);
	OFDataBufferAppendLongInt(&db, 0x1000);
	OFDataBufferAppendLongInt(&db, 0);
	
	while(OFDataBufferSpaceOccupied(&db) % PAGESIZE) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	
	for(int n = 0; n < 256; n++) {
		OFDataBufferAppendLongInt(&db, 0);
	}
	
	CFDataRef resultData;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &resultData);
	return SAFE_AUTORELEASE((NSData *)resultData);
}

@end
