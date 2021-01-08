//
//  MDComplicationSource.m
//  MonthDay WatchKit Extension
//
//  Created by Leptos on 1/27/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "MDComplicationSource.h"

NSString *const MDComplicationIdentifierSwapped = @"null.leptos.MonthDay.complication.swapped";
NSString *const MDComplicationIdentifierDateOnly = @"null.leptos.MonthDay.complication.dateOnly";

@implementation MDComplicationSource {
    /// Source-of-truth calendar
    NSCalendar *_calendar;
    /// d/M format (localized)
    NSDateFormatter *_dayMonthFormatter;
    /// d/M/yy format (localized)
    NSDateFormatter *_shortStyleFormatter;
}

- (instancetype)init {
    if (self = [super init]) {
        NSLocale *locale = NSLocale.autoupdatingCurrentLocale;
        NSTimeZone *timeZone = NSTimeZone.localTimeZone;
        
        _calendar = NSCalendar.autoupdatingCurrentCalendar;
        _calendar.locale = locale;
        _calendar.timeZone = timeZone;
        
        _dayMonthFormatter = [NSDateFormatter new];
        _dayMonthFormatter.localizedDateFormatFromTemplate = @"d/M";
        _dayMonthFormatter.locale = locale;
        _dayMonthFormatter.calendar = _calendar;
        _dayMonthFormatter.timeZone = timeZone;
        
        _shortStyleFormatter = [NSDateFormatter new];
        _shortStyleFormatter.dateStyle = NSDateFormatterShortStyle;
        _shortStyleFormatter.locale = locale;
        _shortStyleFormatter.calendar = _calendar;
        _shortStyleFormatter.timeZone = timeZone;
        
        NSNotificationCenter *notifCenter = NSNotificationCenter.defaultCenter;
        [notifCenter addObserver:self selector:@selector(_invalidateComplications) name:NSSystemTimeZoneDidChangeNotification object:nil];
        [notifCenter addObserver:self selector:@selector(_invalidateComplications) name:NSSystemClockDidChangeNotification    object:nil];
    }
    return self;
}

- (void)_invalidateComplications {
    CLKComplicationServer *const complicationServer = [CLKComplicationServer sharedInstance];
    for (CLKComplication *complication in complicationServer.activeComplications) {
        [complicationServer reloadTimelineForComplication:complication];
    }
}

- (CLKComplicationTemplate *)_templateForDate:(NSDate *)date complication:(CLKComplication *)complication {
    CLKComplicationFamily const family = complication.family;
    NSString *complicationIdentifier = nil;
    if (@available(watchOS 7.0, *)) {
        complicationIdentifier = complication.identifier;
    }
    BOOL const isSwapped = [complicationIdentifier isEqualToString:MDComplicationIdentifierSwapped];
    BOOL const isDateOnly = [complicationIdentifier isEqualToString:MDComplicationIdentifierDateOnly];
    
    NSString *shortStyle = [_shortStyleFormatter stringFromDate:date];
    NSString *dayMonth = [_dayMonthFormatter stringFromDate:date];
    
    CLKTextProvider *numericalProvider = [CLKSimpleTextProvider textProviderWithText:shortStyle shortText:dayMonth];
    CLKTextProvider *weekdayProvider =  [CLKDateTextProvider textProviderWithDate:date units:NSCalendarUnitWeekday];
    
    CLKTextProvider *line1TextProvider = isSwapped ? numericalProvider : weekdayProvider;
    CLKTextProvider *line2TextProvider = isSwapped ? weekdayProvider : numericalProvider;
    
    CLKTextProvider *combinedProvider = [CLKTextProvider textProviderWithFormat:@"%@ · %@", line1TextProvider, line2TextProvider];
    
    CLKComplicationTemplate *ret = nil;
    switch (family) {
        case CLKComplicationFamilyModularSmall: {
            CLKComplicationTemplateModularSmallStackText *tmp = [CLKComplicationTemplateModularSmallStackText new];
            tmp.line1TextProvider = line1TextProvider;
            tmp.line2TextProvider = line2TextProvider;
            ret = tmp;
        } break;
        case CLKComplicationFamilyModularLarge: {
            CLKComplicationTemplateModularLargeTallBody *tmp = [CLKComplicationTemplateModularLargeTallBody new];
            tmp.headerTextProvider = line1TextProvider;
            tmp.bodyTextProvider = line2TextProvider;
            ret = tmp;
        } break;
        case CLKComplicationFamilyUtilitarianSmall:
        case CLKComplicationFamilyUtilitarianSmallFlat: {
            CLKComplicationTemplateUtilitarianSmallFlat *tmp =  [CLKComplicationTemplateUtilitarianSmallFlat new];
            tmp.textProvider = isDateOnly ? numericalProvider : combinedProvider;
            ret = tmp;
        } break;
        case CLKComplicationFamilyUtilitarianLarge: {
            CLKComplicationTemplateUtilitarianLargeFlat *tmp =  [CLKComplicationTemplateUtilitarianLargeFlat new];
            tmp.textProvider = isDateOnly ? numericalProvider : combinedProvider;
            ret = tmp;
        } break;
        case CLKComplicationFamilyCircularSmall: {
            if (isDateOnly) {
                CLKComplicationTemplateCircularSmallSimpleText *tmp = [CLKComplicationTemplateCircularSmallSimpleText new];
                tmp.textProvider = numericalProvider;
                ret = tmp;
            } else {
                CLKComplicationTemplateCircularSmallStackText *tmp = [CLKComplicationTemplateCircularSmallStackText new];
                tmp.line1TextProvider = line1TextProvider;
                tmp.line2TextProvider = line2TextProvider;
                ret = tmp;
            }
        } break;
        case CLKComplicationFamilyExtraLarge: {
            if (isDateOnly) {
                CLKComplicationTemplateExtraLargeSimpleText *tmp = [CLKComplicationTemplateExtraLargeSimpleText new];
                tmp.textProvider = numericalProvider;
                ret = tmp;
            } else {
                CLKComplicationTemplateExtraLargeStackText *tmp = [CLKComplicationTemplateExtraLargeStackText new];
                tmp.line1TextProvider = line1TextProvider;
                tmp.line2TextProvider = line2TextProvider;
                ret = tmp;
            }
        } break;
        case CLKComplicationFamilyGraphicCorner: {
            CLKComplicationTemplateGraphicCornerStackText *tmp = [CLKComplicationTemplateGraphicCornerStackText new];
            tmp.innerTextProvider = isSwapped ? numericalProvider : weekdayProvider;
            tmp.outerTextProvider = isSwapped ? weekdayProvider : numericalProvider;
            ret = tmp;
        } break;
        case CLKComplicationFamilyGraphicCircular: {
            CLKComplicationTemplateGraphicCircularStackText *tmp = [CLKComplicationTemplateGraphicCircularStackText new];
            tmp.line1TextProvider = line1TextProvider;
            tmp.line2TextProvider = line2TextProvider;
            ret = tmp;
        } break;
        case CLKComplicationFamilyGraphicExtraLarge: {
            if (@available(watchOS 7.0, *)) {
                CLKComplicationTemplateGraphicExtraLargeCircularStackText *tmp = [CLKComplicationTemplateGraphicExtraLargeCircularStackText new];
                tmp.line1TextProvider = line1TextProvider;
                tmp.line2TextProvider = line2TextProvider;
                ret = tmp;
            }
        } break;
        case CLKComplicationFamilyGraphicBezel:
        case CLKComplicationFamilyGraphicRectangular:
            NSLog(@"Unsupported case: %ld", (long)family);
            break;
        default:
            NSLog(@"Unknown case: %ld", (long)family);
            break;
    }
    return ret;
}

- (CLKComplicationTimelineEntry *)_timelineEntryForDate:(NSDate *)date complication:(CLKComplication *)complication {
    NSDate *start = [_calendar startOfDayForDate:date];
    return [CLKComplicationTimelineEntry entryWithDate:start complicationTemplate:[self _templateForDate:date complication:complication]];
}

- (void)getComplicationDescriptorsWithHandler:(void(^)(NSArray<CLKComplicationDescriptor *> *))handler API_AVAILABLE(watchos(7.0)) {
    handler(@[
        [[CLKComplicationDescriptor alloc] initWithIdentifier:CLKDefaultComplicationIdentifier displayName:@"Default" supportedFamilies:@[
            @(CLKComplicationFamilyModularSmall),
            @(CLKComplicationFamilyModularLarge),
            @(CLKComplicationFamilyUtilitarianSmall),
            @(CLKComplicationFamilyUtilitarianSmallFlat),
            @(CLKComplicationFamilyUtilitarianLarge),
            @(CLKComplicationFamilyCircularSmall),
            @(CLKComplicationFamilyExtraLarge),
            @(CLKComplicationFamilyGraphicCorner),
            @(CLKComplicationFamilyGraphicCircular),
            @(CLKComplicationFamilyGraphicExtraLarge)
        ]],
        
        [[CLKComplicationDescriptor alloc] initWithIdentifier:MDComplicationIdentifierSwapped displayName:@"Swapped" supportedFamilies:@[
            @(CLKComplicationFamilyModularSmall),
            @(CLKComplicationFamilyModularLarge),
            @(CLKComplicationFamilyUtilitarianSmall),
            @(CLKComplicationFamilyUtilitarianSmallFlat),
            @(CLKComplicationFamilyUtilitarianLarge),
            @(CLKComplicationFamilyCircularSmall),
            @(CLKComplicationFamilyExtraLarge),
            @(CLKComplicationFamilyGraphicCorner),
            @(CLKComplicationFamilyGraphicCircular),
            @(CLKComplicationFamilyGraphicExtraLarge)
        ]],
        
        [[CLKComplicationDescriptor alloc] initWithIdentifier:MDComplicationIdentifierDateOnly displayName:@"Date Only" supportedFamilies:@[
            @(CLKComplicationFamilyUtilitarianSmall),
            @(CLKComplicationFamilyUtilitarianSmallFlat),
            @(CLKComplicationFamilyUtilitarianLarge),
            @(CLKComplicationFamilyCircularSmall),
            @(CLKComplicationFamilyExtraLarge),
        ]],
    ]);
}

// MARK: - Timeline Configuration

- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication
                                            withHandler:(void(^)(CLKComplicationTimeTravelDirections directions))handler {
    handler(CLKComplicationTimeTravelDirectionForward | CLKComplicationTimeTravelDirectionBackward);
}

- (void)getTimelineStartDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate *date))handler {
    handler(NSDate.distantPast);
}

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate *date))handler {
    handler(NSDate.distantFuture);
}

- (void)getPrivacyBehaviorForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationPrivacyBehavior privacyBehavior))handler {
    handler(CLKComplicationPrivacyBehaviorShowOnLockScreen);
}

// MARK: - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication
                                   withHandler:(void(^)(CLKComplicationTimelineEntry *entry))handler {
    handler([self _timelineEntryForDate:[NSDate date] complication:complication]);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication beforeDate:(NSDate *)date limit:(NSUInteger)limit
                              withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> *entries))handler {
    NSMutableArray<CLKComplicationTimelineEntry *> *entries = [NSMutableArray arrayWithCapacity:limit];
    // assuming that date is not exactly between days, so add the given day to the timeline as well
    for (__typeof(limit) intern = 0; intern < limit; intern++) {
        NSDate *entryDate = [_calendar dateByAddingUnit:NSCalendarUnitDay value:(-intern) toDate:date options:0];
        [entries addObject:[self _timelineEntryForDate:entryDate complication:complication]];
    }
    handler([entries copy]);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit
                              withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> *entries))handler {
    NSMutableArray<CLKComplicationTimelineEntry *> *entries = [NSMutableArray arrayWithCapacity:limit];
    // assuming that date is not exactly between days, so add the given day to the timeline as well
    for (__typeof(limit) intern = 0; intern < limit; intern++) {
        NSDate *entryDate = [_calendar dateByAddingUnit:NSCalendarUnitDay value:(+intern) toDate:date options:0];
        [entries addObject:[self _timelineEntryForDate:entryDate complication:complication]];
    }
    handler([entries copy]);
}

// MARK: - Placeholder Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication
                                        withHandler:(void(^)(CLKComplicationTemplate *complicationTemplate))handler {
    // from https://gist.github.com/leptos-null/21837fe407d8d2620698b1530e56abd8
    static NSDateComponents *comps;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        comps = [NSDateComponents new];
        comps.calendar = NSCalendar.autoupdatingCurrentCalendar;
        comps.timeZone = NSTimeZone.localTimeZone;
        comps.year = 2014;
        comps.month = 9;
        comps.day = 9;
        comps.hour = 10;
        comps.minute = 9;
        comps.second = 30;
    });
    handler([self _templateForDate:comps.date complication:complication]);
}

@end
