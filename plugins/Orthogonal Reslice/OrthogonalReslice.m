//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "OrthogonalReslice.h"
#include <Accelerate/Accelerate.h>

@implementation OrthogonalReslicePlugin

-(void) executeReslice:(long) directionm :(BOOL) square
{
	// Contains a list of DCMPix objects: they contain the pixels of current series
		NSArray				*pixList = [viewerController pixList];	
		DCMPix				*firstPix = [pixList objectAtIndex: 0];
		DCMPix				*lastPix = [pixList lastObject];
		long				i, newTotal;
		unsigned char		*emptyData;
		ViewerController	*new2DViewer;
		long				imageSize, size, x, y, newX, newY;
		float				orientation[ 9], newXSpace, newYSpace, origin[ 3], sign, ratio;
		
		NSLog(@"Start-Reslice");
		
		// Get Values
		if( directionm == 0)		// X - RESLICE
		{
			newTotal = [firstPix pheight];
			
			newX = [firstPix pwidth];
			
			if( square)
			{
				newXSpace = [firstPix pixelSpacingX];
				newYSpace = [firstPix pixelSpacingX];
				
				ratio = fabs( [firstPix sliceInterval]) / [firstPix pixelSpacingX];
				
				newY = ([pixList count] * fabs( [firstPix sliceInterval])) / [firstPix pixelSpacingX];
			}
			else
			{
				newXSpace = [firstPix pixelSpacingX];
				newYSpace = fabs( [firstPix sliceInterval]);
				newY = [pixList count];
			}
		}
		else
		{
			newTotal = [firstPix pwidth];				// Y - RESLICE
			
			newX = [firstPix pheight];
			
			if( square)
			{
				newXSpace = [firstPix pixelSpacingY];
				newYSpace = [firstPix pixelSpacingY];
				
				ratio = fabs( [firstPix sliceInterval]) / [firstPix pixelSpacingY];
				
				newY = ([pixList count]  * fabs( [firstPix sliceInterval])) / [firstPix pixelSpacingY];
			}
			else
			{
				newY = [pixList count];
				
				newXSpace = [firstPix pixelSpacingY];
				newYSpace = fabs( [firstPix sliceInterval]);
			}
		}
		
		// Display a waiting window
		id waitWindow = [viewerController startWaitProgressWindow:@"I'm working for you!" :newTotal];
		
		if( [firstPix sliceInterval] > 0) sign = 1.0;
		else sign = -1.0;
		
		imageSize = sizeof(float) * newX * newY;
		size = newTotal * imageSize;
		
		// CREATE A NEW SERIES WITH ALL IMAGES !
		emptyData = malloc( size);
		if( emptyData)
		{
			NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
			NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
			
			NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
			
			for( i = 0 ; i < newTotal; i ++)
			{
				[viewerController waitIncrementBy: waitWindow :1];
				
				[newPixList addObject: [[pixList objectAtIndex: 0] copy]];
				
				[[newPixList lastObject] setPwidth: newX];
				[[newPixList lastObject] setPheight: newY];
				
				[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * ([newPixList count] - 1))];
				[[newPixList lastObject] setTot: newTotal];
				[[newPixList lastObject] setFrameNo: [newPixList count]-1];
				[[newPixList lastObject] setID: [newPixList count]-1];
				
				[newDcmList addObject: [[viewerController fileList] objectAtIndex: 0] ];
				
				if( directionm == 0)		// X - RESLICE
				{
					DCMPix	*curPix = [newPixList lastObject];
					long	rowBytes = [firstPix pwidth];
					float	*srcPtr;
					float	left, right, s;
					
					if( sign > 0)
					{
						for( y = 0; y < [pixList count]; y++)
						{
							BlockMoveData(	[[pixList objectAtIndex: y] fImage] + i * [[pixList objectAtIndex: y] pwidth],
											[curPix fImage] + ([pixList count]-y-1) * newX,
											newX * sizeof( float));
						}
					}
					else
					{
						for( y = 0; y < [pixList count]; y++)
						{
							BlockMoveData(	[[pixList objectAtIndex: y] fImage] + i * [[pixList objectAtIndex: y] pwidth],
											[curPix fImage] + y * newX,
											newX * sizeof( float));
						}
					}
					
					if( square)
					{
						vImage_Buffer	srcVimage, dstVimage;
						
						srcVimage.data = [curPix fImage];
						srcVimage.height =  [pixList count];
						srcVimage.width = newX;
						srcVimage.rowBytes = newX*4;
						
						dstVimage.data = [curPix fImage];
						dstVimage.height =  newY;
						dstVimage.width = newX;
						dstVimage.rowBytes = newX*4;
						
						vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, 0);
												
//						for( x = 0; x < newX; x++)
//						{
//							srcPtr = [curPix fImage] + x ;
//							
//							for( y = newY-1; y >= 0; y--)
//							{
//								s = y / ratio;
//								left = s - floor(s);
//								right = 1-left;
//								
//								*(srcPtr + y * rowBytes) = right * *(srcPtr + (long) (s) * rowBytes) + left * *(srcPtr + (long) ((s)+1) * rowBytes);
//							}
//						}
					}
					
					if( sign > 0)
							[lastPix orientation: orientation];
					else
							[firstPix orientation: orientation];
					
					float cc[ 3];
					
					cc[ 0] = orientation[ 3];
					cc[ 1] = orientation[ 4];
					cc[ 2] = orientation[ 5];
					
					if( sign > 0)
					{
						// Y Vector = Normal Vector
						orientation[ 3] = orientation[ 6] * -sign;
						orientation[ 4] = orientation[ 7] * -sign;
						orientation[ 5] = orientation[ 8] * -sign;
					}
					else
					{
						// Y Vector = Normal Vector
						orientation[ 3] = orientation[ 6] * sign;
						orientation[ 4] = orientation[ 7] * sign;
						orientation[ 5] = orientation[ 8] * sign;
					}
					
					[curPix setOrientation: orientation];	// Normal vector is recomputed in this procedure
					
					[curPix setPixelSpacingX: newXSpace];
					[curPix setPixelSpacingY: newYSpace];
					
					[curPix setPixelRatio:  newYSpace / newXSpace];
					
					[curPix orientation: orientation];
					
					if( sign > 0)
					{
						origin[ 0] = [lastPix originX] + (i * [firstPix pixelSpacingY]) * orientation[ 6] * sign;
						origin[ 1] = [lastPix originY] + (i * [firstPix pixelSpacingY]) * orientation[ 7] * sign;
						origin[ 2] = [lastPix originZ] + (i * [firstPix pixelSpacingY]) * orientation[ 8] * sign;
					}
					else
					{
						origin[ 0] = [firstPix originX] + (i * [firstPix pixelSpacingY]) * orientation[ 6] * -sign;
						origin[ 1] = [firstPix originY] + (i * [firstPix pixelSpacingY]) * orientation[ 7] * -sign;
						origin[ 2] = [firstPix originZ] + (i * [firstPix pixelSpacingY]) * orientation[ 8] * -sign;
					}
					
					if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 0]];
					}
					if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 1]];
					}
					if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 2]];
					}
					
					[[newPixList lastObject] setSliceThickness: [firstPix pixelSpacingY]];
					[[newPixList lastObject] setSliceInterval: [firstPix pixelSpacingY]];
					[curPix setOrigin: origin];
				}
				else											// Y - RESLICE
				{
					DCMPix	*curPix = [newPixList lastObject];
					float	*srcPtr;
					float	*dstPtr;
					long	rowBytes = [firstPix pwidth];
					float	left, right, s;
					
					for(x = 0; x < [pixList count]; x++)
					{
						if( sign > 0)
							srcPtr = [[pixList objectAtIndex: [pixList count]-x-1] fImage] + i;
						else
							srcPtr = [[pixList objectAtIndex: x] fImage] + i;
						dstPtr = [curPix fImage] + x * newX;
						
						y = newX;
						while (y-->0)
						{
							*dstPtr = *srcPtr;
							dstPtr++;
							srcPtr += rowBytes;
						}
					}
										
					if( square)
					{
						vImage_Buffer	srcVimage, dstVimage;
						
						srcVimage.data = [curPix fImage];
						srcVimage.height =  [pixList count];
						srcVimage.width = newX;
						srcVimage.rowBytes = newX*4;
						
						dstVimage.data = [curPix fImage];
						dstVimage.height =  newY;
						dstVimage.width = newX;
						dstVimage.rowBytes = newX*4;
						
						vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, 0);
						
//						for( x = 0; x < newX; x++)
//						{
//							srcPtr = [curPix fImage] + x ;
//							
//							for( y = newY-1; y >= 0; y--)
//							{
//								s = y / ratio;
//								left = s - floor(s);
//								right = 1-left;
//								
//								*(srcPtr + y * rowBytes) = right * *(srcPtr + (long) (s) * rowBytes) + left * *(srcPtr + (long) ((s)+1) * rowBytes);
//							}
//						}
					}
					
					if( sign > 0)
							[lastPix orientation: orientation];
					else
							[firstPix orientation: orientation];
					
					// Y Vector = Normal Vector
					orientation[ 0] = orientation[ 3];
					orientation[ 1] = orientation[ 4];
					orientation[ 2] = orientation[ 5];
					
					if( sign > 0)
					{
						orientation[ 3] = orientation[ 6] * -sign;
						orientation[ 4] = orientation[ 7] * -sign;
						orientation[ 5] = orientation[ 8] * -sign;
					}
					else
					{
						orientation[ 3] = orientation[ 6] * sign;
						orientation[ 4] = orientation[ 7] * sign;
						orientation[ 5] = orientation[ 8] * sign;
					}
					
					[curPix setOrientation: orientation];	// Normal vector is recomputed in this procedure
					
					[curPix setPixelSpacingX: newXSpace];
					[curPix setPixelSpacingY: newYSpace];
					
					[curPix setPixelRatio:  newYSpace / newXSpace];
					
					[curPix orientation: orientation];
					if( sign > 0)
					{
						origin[ 0] = [lastPix originX] + (i * [firstPix pixelSpacingX]) * orientation[ 6] * -sign;
						origin[ 1] = [lastPix originY] + (i * [firstPix pixelSpacingX]) * orientation[ 7] * -sign;
						origin[ 2] = [lastPix originZ] + (i * [firstPix pixelSpacingX]) * orientation[ 8] * -sign;
					}
					else
					{
						origin[ 0] = [firstPix originX] + (i * [firstPix pixelSpacingX]) * orientation[ 6] * sign;
						origin[ 1] = [firstPix originY] + (i * [firstPix pixelSpacingX]) * orientation[ 7] * sign;
						origin[ 2] = [firstPix originZ] + (i * [firstPix pixelSpacingX]) * orientation[ 8] * sign;
					}
					
					if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 0]];
					}
					if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 1]];
					}
					if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 2]];
					}
					
					[[newPixList lastObject] setSliceThickness: [firstPix pixelSpacingX]];
					[[newPixList lastObject] setSliceInterval: [firstPix pixelSpacingY]];
					
					[curPix setOrigin: origin];
				}
			}
			
			// CREATE A SERIES
			new2DViewer = [viewerController newWindow	:newPixList
														:newDcmList
														:newData];
		}
		
		// Close the waiting window
		[viewerController endWaitWindow: waitWindow];
		
		NSLog(@"End-Reslice");
}

static volatile long countThread;

-(void) executeResliceSquareX:(id) obj
{
	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
	[self executeReslice:0 :YES];
	countThread--;
	[pool release];
}

-(void) executeResliceNonSquareX:(id) obj
{
	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
	[self executeReslice:0 :NO];
	countThread--;
	[pool release];
}

-(void) executeResliceSquareY:(id) obj
{
	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
	[self executeReslice:1 :YES];
	countThread--;
	[pool release];
}

-(void) executeResliceNonSquareY:(id) obj
{
	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
	[self executeReslice:1 :NO];
	countThread--;
	[pool release];
}

-(IBAction) endDialog:(id) sender
{
    [window orderOut:sender];
    
    [NSApp endSheet:window returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		if( [[direction selectedCell] tag] == 2)
		{
			[self executeReslice: 0 :[squarePixels state]];
			[self executeReslice: 1 :[squarePixels state]];
		}
		else [self executeReslice: [[direction selectedCell] tag] :[squarePixels state]];
		
		// We modified the pixels: OsiriX please update the display!
		[viewerController needsDisplayUpdate];
    }
}

- (long) filterImage:(NSString*) menuName
{
	NSArray				*pixList = [viewerController pixList];	
	DCMPix				*firstPix = [pixList objectAtIndex: 0];
	long				im;
	float				thick;
	
	[NSBundle loadNibNamed:@"OrthogonalReslice" owner:self];
	
	[viewerController computeInterval];
	
	im = [firstPix pheight];		thick = [firstPix pixelSpacingY];
	[xResolution setStringValue: [NSString stringWithFormat: @"%d images, %2.2f thickness", im, thick]];
	
	im = [firstPix pwidth];			thick = [firstPix pixelSpacingX];
	[yResolution setStringValue: [NSString stringWithFormat: @"%d images, %2.2f thickness", im, thick]];
	
	[squarePixels setEnabled: NO];
	
	NSLog(@"X: %2.2f, Y: %2.2f, Interval: %2.2f", [firstPix pixelSpacingX], [firstPix pixelSpacingY], fabs( [firstPix sliceInterval]));
	
	if( fabs( [firstPix sliceInterval]) != [firstPix pixelSpacingX] || fabs( [firstPix sliceInterval]) != [firstPix pixelSpacingY])
	{
		if( fabs( [firstPix sliceInterval]) > [firstPix pixelSpacingX] && fabs( [firstPix sliceInterval]) > [firstPix pixelSpacingY])
		{
			[squarePixels setEnabled: YES];
		}
	}
	
	[NSApp beginSheet: window modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	return 0;   // No Errors
}

@end
