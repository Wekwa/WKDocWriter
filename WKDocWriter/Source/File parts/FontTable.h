/*
 FontTable.h
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
 The Table Stream of a Word File contains the Font Table, which lists 
 all the font names, as well as some other information about them. Some
 word processors may add additional fonts to the table in case the user
 does not have a particular font installed. (However, because iOS rarely
 deals with uncommon fonts, this implementation only writes the fonts used.)
 */

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface FontTable : NSObject {
	NSMutableArray *_fonts;
}

-(void)addFont:(CTFontRef)font;
-(NSUInteger)indexOfFont:(CTFontRef)font;
-(NSUInteger)indexOfFontWithName:(NSString *)name;
-(NSData *)data;

@end
