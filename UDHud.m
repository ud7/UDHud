//
//  UDHud.m
//
// Copyright (c) 2012 Rolandas Razma <rolandas@razma.lt>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "UDHud.h"
#import <QuartzCore/QuartzCore.h>


static void CGContextAddPathWithRectCornerRadius(CGContextRef contextRef, CGRect rect, CGFloat cornerRadius) {
    
    if ( cornerRadius > rect.size.width /2.0f )
        cornerRadius = rect.size.width  /2.0f;
    if ( cornerRadius > rect.size.height/2.0f )
        cornerRadius = rect.size.height /2.0f;
    
    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    
    CGContextBeginPath( contextRef );
    CGContextMoveToPoint(contextRef, minx, midy);
    CGContextAddArcToPoint(contextRef, minx, miny, midx, miny, cornerRadius);
    CGContextAddArcToPoint(contextRef, maxx, miny, maxx, midy, cornerRadius);
    CGContextAddArcToPoint(contextRef, maxx, maxy, midx, maxy, cornerRadius);
    CGContextAddArcToPoint(contextRef, minx, maxy, minx, midy, cornerRadius);
    CGContextClosePath( contextRef );
    
}


@interface UDHud (UDPrivate)

- (void)dismissAnimated;
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

@end


@implementation UDHud {
    CGColorRef  _bazelColor;
    CGColorRef  _backgroundColor;
    UIImage     *_image;
    UIFont      *_textFont;
    NSString    *_text;
    NSTimer     *_dismissTimer;
    CGFloat     _lifeTime;
}


static UDHud *_sharedInstance = nil;


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    CGColorRelease(_bazelColor);
    CGColorRelease(_backgroundColor);
#if !__has_feature(objc_arc)
    [_textFont release];
    [_text release];
    [_image release];
    [super dealloc];
#endif
}


- (id)init {
    if( (self = [super init]) ){
        [self setUserInteractionEnabled:NO];
        
        [self setFrame:CGRectMake(0, 0, 150, 150)];
        [self setBackgroundColor:[UIColor clearColor]];
        
        
        CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
        _bazelColor     = CGColorCreate(grayColorSpace, (CGFloat[]){ 1.0f, 1.0f });
        _backgroundColor= CGColorCreate(grayColorSpace, (CGFloat[]){ 0.0f, 0.48f });
        CGColorSpaceRelease(grayColorSpace);
        
		_textFont = [UIFont systemFontOfSize: 18];
        _lifeTime = 2.0f;
        
#if !__has_feature(objc_arc)
        [_textFont retain];
#endif

        [self setContentMode:UIViewContentModeRedraw];
    }
    return self;
}


#pragma mark -
#pragma mark UDHud


+ (UDHud *)sharedInstance {
	@synchronized( [UDHud class] ) {
		if ( !_sharedInstance ) {
            _sharedInstance = [[self alloc] init];
        }
		return _sharedInstance;
	}
	return nil;
}


- (void)showWithText:(NSString *)text image:(UIImage *)image {
#if !__has_feature(objc_arc)
    [_text release];
#endif
    
    _text = [text copy];
    
    [self setImage:image];
    
    CGSize expectedSize = [_text sizeWithFont:_textFont];
    expectedSize = CGSizeMake(MAX(157, expectedSize.width +40), 150);
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    CGPoint center = CGPointMake(floorf((window.bounds.size.width -expectedSize.width) /2), floorf((window.bounds.size.height -expectedSize.height) /2));
    [self setFrame:CGRectMake(center.x, center.y, expectedSize.width, expectedSize.height)];

    // Schedule dismiss
    [_dismissTimer invalidate];
    _dismissTimer = [NSTimer scheduledTimerWithTimeInterval:_lifeTime target:self selector:@selector(dismissAnimated) userInfo:nil repeats:NO];
    
    // Add to window
    [self.layer removeAllAnimations];
    [self setAlpha:1.0f];
    [self setNeedsDisplay];
    [window addSubview: self];
}


- (void)setImage:(UIImage *)image {
#if !__has_feature(objc_arc)
    [_image release];
#endif

    _image    = image;
    
#if !__has_feature(objc_arc)
    [_image retain];
#endif
    
    [self setNeedsDisplay];
}


- (void)dismissAnimated {
    [_dismissTimer invalidate], _dismissTimer = nil;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.33f];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate: self];
    [UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
    
    [self setAlpha:0.0f];
    
    [UIView commitAnimations];
}


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if( self.alpha == 0.0f ){
        [self removeFromSuperview];
        [self setAlpha:1.0f];
        
#if !__has_feature(objc_arc)
        [_text release];
        [_image release];
#endif
        
        _text = nil;
        _image = nil;
    }
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
    CGContextRef contextRef = UIGraphicsGetCurrentContext();

    // Draw background
    CGContextSetFillColorWithColor(contextRef, _backgroundColor);
    CGContextAddPathWithRectCornerRadius(contextRef, rect, 15);
    CGContextDrawPath(contextRef, kCGPathFill);
    
    // Draw bazel
    CGRect bazelRect = CGRectMake(roundf((rect.size.width -81) /2), 32, 81, 67);
    CGContextSetLineWidth(contextRef, 5);    
    CGContextSetStrokeColorWithColor(contextRef, _bazelColor);
    CGContextAddPathWithRectCornerRadius(contextRef, bazelRect, 8);
    CGContextDrawPath(contextRef, kCGPathStroke);

    // Draw image
    [_image drawAtPoint:CGPointMake(roundf(bazelRect.origin.x +(bazelRect.size.width -_image.size.width) /2), roundf(bazelRect.origin.y +(bazelRect.size.height -_image.size.height) /2))];
    
    // Draw text
    CGContextSetShadow(contextRef, CGSizeMake(0.0f, 2.0f), 2.0f);
    CGContextSetFillColorWithColor(contextRef, _bazelColor);
    [_text drawInRect: CGRectMake(20, rect.size.height -40, rect.size.width -40, 20) 
             withFont: _textFont
        lineBreakMode: UILineBreakModeClip
            alignment: UITextAlignmentCenter];
}


@synthesize lifeTime=_lifeTime;
@end
