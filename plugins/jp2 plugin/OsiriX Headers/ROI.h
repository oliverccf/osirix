//
//  ROI.h
//  OsiriX
//
//  Created by rossetantoine on Wed Jan 21 2004.
//  Copyright (c) 2004 ROSSET Antoine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyPoint.h"

enum
{
	ROI_sleep = 0,
	ROI_drawing = 1,
	ROI_selected = 2,
	ROI_selectedModify = 3
};

@class DCMView;
@class DCMPix;
@class StringTexture;

@interface ROI : NSObject <NSCoding>
{
	NSMutableArray  *points;
	NSRect			rect;
	
	long			type;
	long			mode;
	BOOL			needQuartz;
	
	float			thickness;
	
	BOOL			fill;
	float			opacity;
	RGBColor		color;
	
	BOOL			closed;
	
	NSString		*name;
	NSString		*comments;
	
	float			pixelSpacing;
	NSPoint			imageOrigin;
	
	// **** **** **** **** **** **** **** **** **** **** TRACKING
	
	long			selectedModifyPoint;
	NSPoint			clickPoint;
	long			fontListGL;
	DCMView			*curView;
	
	float			rmean, rmax, rmin, rdev, rtotal;
	
	float			mousePosMeasure;
	
	StringTexture			*stringTex;
	NSMutableDictionary		*stanStringAttrib;
}

// Create a new ROI, needs the current pixel resolution and image origin
- (id) initWithType: (long) itype :(float) ipixelSpacing :(NSPoint) iimageOrigin;

// Return/Set the name of the ROI
- (NSString*) name;
- (void) setName:(NSString*) a;

// Return/Set the comments of the ROI
- (NSString*) comments;
- (void) setComments:(NSString*) a;

// Return the type of the ROI
- (long) type;

// Return the current state of the ROI
- (long) ROImode;

// Return the points state of the ROI
- (NSMutableArray*) points;

// Set resolution and origin associated to the ROI
- (void) setOriginAndSpacing :(float) ipixelSpacing :(NSPoint) iimageOrigin;

// Compute the roiArea in cm2
- (float) roiArea;

// Compute the length for tMeasure ROI in cm
- (float) MesureLength: (float*) pixels;

// Compute an angle between 2 lines
- (float) Angle:(NSPoint) p2 :(NSPoint) p1 :(NSPoint) p3;

// To create a Rectangular ROI (tROI) or an Oval ROI (tOval)
- (void) setROIRect:(NSRect) rect;

- (float*) dataValuesAsFloatPointer :(long*) no;

// Return the DCMPix associated to this ROI
- (DCMPix*) pix;

// Return the DCMView associated to this ROI
- (DCMView*) curView;

- (void) setMousePosMeasure:(float) p;
- (NSData*) data;
- (void) roiMove:(NSPoint) offset;
- (long) clickInROI:(NSPoint) pt :(float) scale;
- (BOOL) mouseRoiDown:(NSPoint) pt :(float) scale;
- (BOOL) mouseRoiDragged:(NSPoint) pt :(unsigned int) modifier :(float) scale;
- (NSMutableArray*) dataValues;
- (BOOL) valid;
- (void) drawROI :(float) scaleValue :(float) offsetx :(float) offsety :(float) PS;
- (BOOL) needQuartz;
- (void) setROIMode :(long) v;
- (BOOL) deleteSelectedPoint;
- (RGBColor) color;
- (void) setColor:(RGBColor) a;
- (float) thickness;
- (void) setThickness:(float) a;
- (NSMutableDictionary*) dataString;
- (BOOL) mouseRoiUp:(NSPoint) pt;
- (void) setRoiFont: (long) f :(DCMView*) v;
- (void) glStr: (char *) cstrOut :(float) x :(float) y :(float) line;
- (void) recompute;


@end
