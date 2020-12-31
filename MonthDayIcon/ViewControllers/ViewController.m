//
//  ViewController.m
//  MonthDayIcon
//
//  Created by Leptos on 12/21/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "ViewController.h"

CGPoint CGPointPolarCenter(CGFloat radius, double angle, CGPoint center) {
    double sinAngle, cosAngle;
    __sincos(angle, &sinAngle, &cosAngle);
    return CGPointMake(center.x + radius * cosAngle, center.y + radius * sinAngle);
}

@implementation ViewController

- (UIImage *)iconForDimension:(CGFloat)dimension scale:(CGFloat)scale inset:(BOOL)inset fill:(BOOL)fillBackground {
    CGFloat const offset = inset ? dimension/16 : 0;
    CGRect const fullFrame = CGRectMake(0, 0, dimension, dimension);
    dimension -= (offset * 2);
    CGRect const frame = CGRectMake(offset, offset, dimension, dimension);
    CGFloat const radius = dimension/2 + offset;
    
    UIGraphicsBeginImageContextWithOptions(fullFrame.size, NO, scale);
    
    if (fillBackground) {
        [[UIColor systemBackgroundColor] setFill];
        [[UIBezierPath bezierPathWithRect:fullFrame] fill];
    }
    
    UIColor *const textColor = UIColor.whiteColor;
    
    {
        // move down and to the right a bit
        CGPoint divCenter = CGPointMake(radius + dimension/24, radius + dimension/24);
        CGFloat divLength = dimension*0.364;
        double divAngle = M_PI_4 * 3;
        double sideBias = 1/24.0;
        
        UIBezierPath *divPath = [UIBezierPath bezierPath];
        [divPath moveToPoint:CGPointPolarCenter(divLength*(1 - sideBias), divAngle, divCenter)];
        [divPath addLineToPoint:CGPointPolarCenter(divLength*(1 + sideBias), divAngle + M_PI, divCenter)];
        
        divPath.lineWidth = dimension/27;
        divPath.lineCapStyle = kCGLineCapRound;
        [textColor setStroke];
        [divPath stroke];
    }
    
    {
        NSAttributedString *monthString = [[NSAttributedString alloc] initWithString:@"M" attributes:@{
            NSFontAttributeName : [UIFont fontWithName:@"SF Compact Rounded" size:dimension*0.44],
            NSForegroundColorAttributeName : textColor
        }];
        CGRect monthStringRect = [monthString boundingRectWithSize:frame.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        // align centers
        monthStringRect.origin.x = radius - CGRectGetWidth(monthStringRect)/2;
        monthStringRect.origin.y = radius - CGRectGetHeight(monthStringRect)/2;
        // move up and to the left a bit
        monthStringRect.origin.x -= dimension/6;
        monthStringRect.origin.y -= dimension/6;
        
        [monthString drawWithRect:monthStringRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    }
    
    {
        NSAttributedString *dayString = [[NSAttributedString alloc] initWithString:@"d" attributes:@{
            NSFontAttributeName : [UIFont fontWithName:@"SF Compact Rounded" size:dimension*0.44],
            NSForegroundColorAttributeName : textColor
        }];
        CGRect dayStringRect = [dayString boundingRectWithSize:frame.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        // align centers
        dayStringRect.origin.x = radius - CGRectGetWidth(dayStringRect)/2;
        dayStringRect.origin.y = radius - CGRectGetHeight(dayStringRect)/2;
        // move down and to the right a bit
        dayStringRect.origin.x += dimension/6;
        dayStringRect.origin.y += dimension/6;
        
        [dayString drawWithRect:dayStringRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    }
    
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}

// e.g. "Assets.xcassets/AppIcon.appiconset"
- (void)writeIconAssetsForIconSet:(NSString *)appiconset inset:(BOOL)inset {
    NSString *manifest = [appiconset stringByAppendingPathComponent:@"Contents.json"];
    NSData *parse = [NSData dataWithContentsOfFile:manifest];
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:parse options:(NSJSONReadingMutableContainers) error:&error];
    NSArray<NSString *> *const fillIdioms = @[
        @"iphone",
        @"ipad",
        @"watch", // works fine, but App Store requires fill
        @"ios-marketing",
        @"watch-marketing"
    ];
    NSArray<NSMutableDictionary<NSString *, NSString *> *> *images = dict[@"images"];
    for (NSMutableDictionary<NSString *, NSString *> *image in images) {
        NSString *scale = image[@"scale"];
        NSString *size = image[@"size"];
        NSInteger scaleLastIndex = scale.length - 1;
        assert([scale characterAtIndex:scaleLastIndex] == 'x');
        NSString *numScale = [scale substringToIndex:scaleLastIndex];
        
        NSArray<NSString *> *sizeParts = [size componentsSeparatedByString:@"x"];
        assert(sizeParts.count == 2);
        NSString *numSize = sizeParts.firstObject;
        assert([numSize isEqualToString:sizeParts.lastObject]);
        
        NSString *fileName = [NSString stringWithFormat:@"AppIcon%@@%@.png", size, scale];
        BOOL fill = [fillIdioms containsObject:image[@"idiom"]];
        UIImage *render = [self iconForDimension:numSize.doubleValue scale:numScale.doubleValue inset:inset fill:fill];
        NSData *fileData = UIImagePNGRepresentation(render);
        assert([fileData writeToFile:[appiconset stringByAppendingPathComponent:fileName] atomically:YES]);
        image[@"filename"] = fileName;
    }
    NSData *serial = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    assert([serial writeToFile:manifest atomically:YES]);
}

#if 0
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *file = @__FILE__;
    NSString *projectRoot = file.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSString *nanoSet = [projectRoot stringByAppendingPathComponent:@"nanoMonthDay/Assets.xcassets/AppIcon.appiconset"];
    [self writeIconAssetsForIconSet:nanoSet inset:NO];
}
#endif

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIImageView *imageView = self.imageView;
    CGRect const rect = imageView.frame;
    imageView.image = [self iconForDimension:fmin(rect.size.width, rect.size.height) scale:0 inset:NO fill:NO];
}

@end
