/*
 CompoundFileBinary.h
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

/*The Compound File Binary dictates the general structure of a Word document.
 (It is also the backbone of Powerpoint and Excel documents.) A Word document
 can be thought of like a file stream, in that it contains several pieces of
 data with no specific order. However, because the data does have to be read
 somehow, the various pieces of the Compound File Binary tell us how to organize
 and read certain data from the file.
 */

@interface CompoundFileBinary : NSObject

@property (nonatomic, assign) uint32_t fileAllocationTableSectorNumber;
@property (nonatomic, assign) uint32_t directorySectorNumber;
@property (nonatomic, assign) uint32_t wordStreamLength; /*in sectors*/
@property (nonatomic, assign) uint32_t tableStreamSectorNumber;
@property (nonatomic, assign) uint32_t tableStreamLength; /*in sectors*/

-(NSData *)headerData;
/*The first 512 bytes of the file, the header contains miscellaneous (usually
 static) information such as the location of the File Allocation Tables and
 Directory Entries, the sector size, etc.
 */

-(NSData *)fileAllocationTableData;
/*The File Allocation Tables tell the application how to properly
 arrange the data for reading. (Again, like a file system, Word Documents
 are organized hierarchally rather than sequentially.) It is an
 array of 4-byte integers, where each element is the next 512-byte sector
 to be read.
 */

-(NSData *)directoryEntryData;
/*The table of directory entries is a list of all
 the streams in the file. (The ones this API implements
 are the Word Stream, Table Stream, SummaryInformation,
 and DocumentSummaryInformation.) Chiefly, the directory
 entries tell where in the fileAllocationTable the streams
 are located.
 */

@end
