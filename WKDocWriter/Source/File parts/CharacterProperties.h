/*
 CharacterProperties.h
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
 CharacterProperties describe character formatting information. They are stored,
 in their compressed "exception" form, in FKPs. (See comment at the bottom.) They
 consist of an array of Prls, which modify individual properties.
 
 Prls contain two segments: a 16-bit Single Property Modifier (a Sprm), and the operand. The
 Single Property Modifier tells which attribute is being modified. The operand
 describes what value the Sprm changes to. The operand's size and meaning 
 varies for different Sprms.
 */

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@class FontTable;

enum
{
	sprmFont = 0x4A4F,
	sprmFontSize = 0x4A43,
	sprmBold = 0x0835,
	sprmItalic = 0x0836,
	sprmUnderline = 0x2A3E,
	sprmForegroundColor = 0x6870
};

@interface CharacterProperties : NSObject {
	
}

+(CharacterProperties *)characterProperties;
-(id)initWithAttributes:(NSDictionary*)attrs fontTable:(FontTable *)ffn; /*We need the font table because font modifiers
																		  are described by their index in the font table
																		  */

-(id)copy;

@property (nonatomic, assign) uint32_t fontTableIndex;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) BOOL bold;
@property (nonatomic, assign) BOOL italic;
@property (nonatomic, assign) CTUnderlineStyle underlineStyle;
@property (nonatomic, retain) UIColor *textColor;

-(NSData *)dataWithExceptionsFromProperties:(CharacterProperties *)previousProperties;

/*In Word files, entire Character Properties are not entirely written. Rather, their
 "exceptions" are written. (Chpx = Character Property Exceptions; Papx = Paragraph Property Exceptions)
 
 For example, let's say there's a CharacterProperties that is italic. After it there is a CharacterProperties
 that is italic and bold. It would be inefficient to write the "italic" modifier for each property, so it's
 only written for the first one. Then, the second CharacterProperties only writes its "bold" modifier.
 The second character properties inherits everything from the first one, and then adds its own modifications.
 */

@end
