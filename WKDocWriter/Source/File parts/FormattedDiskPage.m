/*
 FormattedDiskPage.m
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

#import "FormattedDiskPage.h"
#import "CharacterProperties.h"
#import "OFDataBuffer.h"
#import "../WKUtilities.h"

@implementation FormattedDiskPage

@synthesize nullTerminatingFileOffset;

-(id)initAsParagraphProperties:(BOOL)isPapxFKP
{
	self = [super init];
	if(self) {
		_isPapxFKP = isPapxFKP;
		_properties = [[NSMutableArray alloc] init];
		_fcs = [[NSMutableArray alloc] init];
		_propertyData = [[NSMutableData alloc] init];
		_offsets = [[NSMutableArray alloc] init];
	}
	return self;
}

#if !ARC

-(void)dealloc
{
	[_properties release];
	[_fcs release];
	[_propertyData release];
	[_offsets release];
	[super dealloc];
}

#endif

-(void)setNullTerminatingFileOffset:(uint32_t)extraOffset
{
	nullTerminatingFileOffset = extraOffset;
}

-(void)addProperties:(id)properties startingAtFileOffset:(uint32_t)fc
{
	[_properties addObject:properties];
	NSData *data;
	if([_properties count] == 1) {
		data = [properties dataWithExceptionsFromProperties:nil];
	} else {
		data = [properties dataWithExceptionsFromProperties:[_properties objectAtIndex:[_properties count] - 2]];
		
	}
	if([_propertyData length] > 0) [_offsets addObject:[NSNumber numberWithUnsignedInt:[_propertyData length]]];
	else [_offsets addObject:[NSNumber numberWithInt:0]];
	[_propertyData appendData:data];
	[_fcs addObject:[NSNumber numberWithUnsignedInt:fc]];
}

-(BOOL)wouldAttributesNeedNewFKP:(id)futureAttributes
{
	NSData *data;
	if([_properties count] == 0) {
		data = [futureAttributes dataWithExceptionsFromProperties:nil];
	} else {
		data = [futureAttributes dataWithExceptionsFromProperties:[_properties objectAtIndex:[_properties count] - 1]];
		
	}
	return (([_fcs count] + 1) * 4) + (([_offsets count] + 1) * (_isPapxFKP ? 13 : 1)) + [_propertyData length] + [data length] > (PAGESIZE - 1) ;
}

-(BOOL)containsParagraphProperties
{
	return _isPapxFKP;
}

-(uint32_t)firstFC
{
	return [[_fcs objectAtIndex:0] unsignedIntValue];
}

-(NSData *)data
{
	if(![_propertyData length]) return [NSData data];
	
	OFDataBuffer db;
	OFDataBufferInit(&db);
	
	/*The FKP begins with an array of file character positions that 
	 describe where a formatting change occurs. It also contains
	 one extra file offset-- the location where the text ends. That
	 makes it easier to translate to something like an NSRange of
	 attributes. The exact formatting changes that occur at these
	 file offsets will be described by the next portion of the FKP.
	 */
	
	for(int i = 0; i < [_fcs count]; i++) {
		OFDataBufferAppendLongInt(&db, [[_fcs objectAtIndex:i] intValue]);
	}
	OFDataBufferAppendLongInt(&db, nullTerminatingFileOffset);
	
	/*After the array of file offsets is an array of offsets within the
	 FKP itself. The items in this array parallel the items in the previous
	 array. For example, let's say the first array has 1536 for the first
	 file offset. In this array, the first element is 250. That means that
	 the formatting at file offset 1536 is described at offset 500 in this
	 FKP. (FKP offsets are stored in halves, that way the value can always 
	 fit in one byte.)
	*/
	
	uint16_t propertyLocations = (PAGESIZE - 1) - [_propertyData length];
	for(int j = 0; j < [_offsets count]; j++) {
		OFDataBufferAppendByte(&db, (uint8_t)((propertyLocations + [[_offsets objectAtIndex:j] charValue]) / 2));
		
		/*If the FKP contains paragraph properties, there's an extra 12 bytes after each FKP offset.*/
		if(_isPapxFKP) {
			for(int k = 0; k < 3; k++) {
				OFDataBufferAppendLongInt(&db, 0);
			}
		}
	}
	
	/*Because FKP offsets are stored in halves, we may need an extra byte 
	 if the property data is not divisible by two.
	 */
	int extra = 0;
	if(OFDataBufferSpaceOccupied(&db) % 2) extra = 1;
	while((OFDataBufferSpaceOccupied(&db) + [_propertyData length] + extra) % (PAGESIZE - 1)) {
		OFDataBufferAppendByte(&db, 0);
	}
	
	/*The rest of the FKP contains the property data that aligns with the array
	 of file offsets and FKP offsets.*/
	OFDataBufferAppendData(&db, _propertyData);
	if(extra) OFDataBufferAppendByte(&db, 0);
	OFDataBufferAppendByte(&db, [_offsets count]); /*The last byte of the FKP tells how many file offsets are described in it*/
	CFDataRef resultData;
	OFDataBufferRelease(&db, kCFAllocatorDefault, &resultData);
	return SAFE_AUTORELEASE((NSData *)resultData);
}

/*FKPs are created in a block, via NSAttributedString's attribute enumeration methods. I tried a few ways
 of getting these to play nice with Blocks, but there were some unfavorable results. So, instead of allocating
 multiple FKPs, we can allocate one, write it's data, reset it, and then repeat the process.
 */

-(void)reset
{
	[_fcs removeAllObjects];
	[_offsets removeAllObjects];
	[_properties removeAllObjects];
	[_propertyData setData:nil];
}

@end
