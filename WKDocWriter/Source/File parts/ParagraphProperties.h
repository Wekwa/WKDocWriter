/*
 ParagraphProperties.h
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
 Paragraph Properties describe paragraph formatting information. They are stored,
 in their compressed "exception" form, in FKPs. They are essentially structurally
 identical to Character Properties. 
 
 Unlike Character Properties, paragraph properties can *only* span the range of
 an entire paragraph.
 */

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

enum
{
	sprmAlignment = 0x2461,
	sprmLineHeightMultiple = 0x6412,
	sprmRightIndent = 0x840E,
	sprmLeftIndent = 0x840F,
	sprmFirstLineIndent = 0x8411
};

@interface ParagraphProperties : NSObject

+(ParagraphProperties *)paragraphProperties;
-(id)initWithAttributes:(NSDictionary*)attrs;

@property (nonatomic, assign) CTTextAlignment alignment;
@property (nonatomic, assign) CGFloat lineHeightMultiple;
@property (nonatomic, assign) CGFloat firstLineIndent;
@property (nonatomic, assign) CGFloat leftIndent;
@property (nonatomic, assign) CGFloat rightIndent;

/*See CharacterProperties.h for an explanation of the "Exceptions" concept.*/
-(NSData *)dataWithExceptionsFromProperties:(ParagraphProperties *)previousProperties;


@end
