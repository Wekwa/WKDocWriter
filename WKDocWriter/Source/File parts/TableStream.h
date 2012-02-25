/*
 TableStream.h
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

#import <Foundation/Foundation.h>

/*Contrary to its misleading name, the Table Stream does not contain 
 any table information (in this implementation.) Rather, it contains 
 various structures describing the formatting, in addition to the 
 FormattedDiskPages before it. These include the document stylesheet, 
 the font table, as well as document properties describing margins, 
 zoom scale, view mode, etc.
 */

@class FormattedDiskPage, FontTable, DocumentProperties;

@interface TableStream : NSObject {
	NSMutableData *_characterPlex;
	NSMutableData *_paragraphPlex;
	uint32_t _textEnd;
	
}

-(id)initWithDefaultTableStream;

/*The table stream contains two plexes: one for character formatting and one for paragraph formatting.
 Each plex contains a list of page numbers (That is, "page" referring to a data segment of 512 bytes; not
 a physical page.) that describe the locations of FormattedDiskPages for certain file offsets.
 */

-(void)addFormattedDiskPageToPlexes:(FormattedDiskPage *)fkp pageNumber:(uint32_t)fkpPage;

@property (nonatomic, retain) FontTable *fontTable;
@property (nonatomic, retain) DocumentProperties *documentProperties;

-(NSData *)data;

-(uint32_t)characterPlexLocation;
-(uint32_t)characterPlexSize;
-(uint32_t)paragraphPlexLocation;
-(uint32_t)paragraphPlexSize;
-(uint32_t)fontTableLocation;
-(uint32_t)fontTableSize;

@end
