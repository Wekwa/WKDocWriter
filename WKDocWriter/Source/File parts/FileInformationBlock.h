/*
 FileInformationBlock.h
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

/*The File Information Block, or FIB, contains information about where
 other things in the file are located. It also contains some preliminary
 document properties, such as the localization language, whether the file
 is read-only, whether it is encrypted, etc.
 */

#import <Foundation/Foundation.h>

@interface FileInformationBlock : NSObject {
	
}

/*The FIB generally follows a fc/lcb pattern--there's an array of 8-byte pairs.
 The first 4-byte integer in the pair describes a file offset of something and
 the second 4-byte integer describes the size of it.
 */

@property (nonatomic, assign) BOOL readOnly;
@property (nonatomic, assign) uint32_t textStartLocation;
@property (nonatomic, assign) uint32_t textEndLocation;
@property (nonatomic, assign) uint32_t textLength; /*Due UTF-16 to encoding, not necessarily equal to textEndLocation - textStartLocation*/
@property (nonatomic, assign) uint32_t wordStreamLength;
@property (nonatomic, assign) uint32_t stylesheetLocation;
@property (nonatomic, assign) uint32_t stylesheetSize;
@property (nonatomic, assign) uint32_t sedLocation;
@property (nonatomic, assign) uint32_t sedSize;
@property (nonatomic, assign) uint32_t characterPropertiesPlexLocation;
@property (nonatomic, assign) uint32_t characterPropertiesPlexSize;
@property (nonatomic, assign) uint32_t paragraphPropertiesPlexLocation;
@property (nonatomic, assign) uint32_t paragraphPropertiesPlexSize;
@property (nonatomic, assign) uint32_t fontTableLocation;
@property (nonatomic, assign) uint32_t fontTableSize;
@property (nonatomic, assign) uint32_t clxLocation;
@property (nonatomic, assign) uint32_t clxSize;
@property (nonatomic, assign) uint32_t documentPropertiesLocation;
@property (nonatomic, assign) uint32_t documentPropertiesSize;
@property (nonatomic, assign) uint32_t listPropertiesLocation;
@property (nonatomic, assign) uint32_t listPropertiesSize;

-(NSData *)data;

@end
