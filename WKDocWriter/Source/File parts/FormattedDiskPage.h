/*
 FormattedDiskPage.h
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

/*
 A Formatted Disk Page, or FKP, contains the formatting information about
 the document. It mainly consists of an array of CharacterProperties or
 Paragraph Properties that are stored in a compressed form. It also consists
 of an array of file offsets that can be translated into character indices
 where these formatting changes take place.
 
 FKPs are separated into Character FKPs and Paragraph FKPs. They are almost
 structurally identical, the only difference being that Paragraph FKPs
 have 12 extra bytes per Paragraph Properties. (The documentation does not
 explain why.)
 
 Regardless of how much information they actually contain, FKPs must be
 padded to 512 bytes in length.
 */

#import <Foundation/Foundation.h>

@class CharacterProperties, ParagraphProperties;

@interface FormattedDiskPage : NSObject {
	BOOL _isPapxFKP;
	NSMutableArray *_properties;
	NSMutableArray *_fcs;
	NSMutableData *_propertyData;
	NSMutableArray *_offsets;
}

@property (nonatomic, assign) uint32_t nullTerminatingFileOffset; /*Like many Foundation classes, FKPs must be "null terminated." However,
																   "null termination" in this case means passing a file offset that is the text
																   length + 1.*/

-(id)initAsParagraphProperties:(BOOL)isPapxFKP;
-(void)reset;
-(void)addProperties:(id)properties startingAtFileOffset:(uint32_t)fc; /*we use id, because it can be CharacterProperties or ParagraphProperties*/
-(BOOL)wouldAttributesNeedNewFKP:(id)futureAttributes;
-(BOOL)containsParagraphProperties;
-(NSData *)data;
-(uint32_t)firstFC;

@end
