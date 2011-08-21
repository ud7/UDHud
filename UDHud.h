//
//  UDHud.h
//
//  Created by Rolandas Razma on 8/16/11.
//  Copyright (c) 2011 UD7. All rights reserved.
//
//  Requires:
//          CoreGraphics.framework
//

#import <Foundation/Foundation.h>


@interface UDHud : UIView

+ (UDHud *)sharedInstance;
- (void)showWithText:(NSString *)text image:(UIImage *)image;   // max image size is 65x51

@end
