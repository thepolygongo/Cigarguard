//
//  SettingVC.h
//  CigarGuard
//
//  Created by admin on 4/26/16.
//  Copyright © 2016 GP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import "lelib.h"

#define channelOnPeropheralView         @"peripheralView"
#define ReadValueServiceUUID            @"18F0"
#define ReadValueCharacteristicUUID     @"2AF0"
#define ReadValuePrefix                 @"AAAAAAAA"
#define ReadValueSuffix                 @"FFFFFFFF"
#define WriteValueCharacteristicUUID    @"2AF1"

#define WriteValueUpTouchDown           @"AAAAAAAA0001A1FFFFFFFF"
#define WriteValueUpTouchUp             @"AAAAAAAA0001A4FFFFFFFF"
#define WriteValueDownTouchDown         @"AAAAAAAA0001A2FFFFFFFF"
#define WriteValueDownTouchUp           @"AAAAAAAA0001A5FFFFFFFF"
#define WriteValueSetTouchDown          @"AAAAAAAA0001A3FFFFFFFF"
#define WriteValueSetTouchUp            @"AAAAAAAA0001A6FFFFFFFF"


typedef NS_OPTIONS(NSUInteger, CGStateProperties)
{
    CGStatePropertyFahrenheit   = 0x20,
    CGStatePropertyCelsius      = 0x10,
    CGStateProperty1Dot         = 0x04,
    CGStateProperty2Dot         = 0x02,
    CGStateProperty3Dot         = 0x01
};

@interface SettingVC : UIViewController
{
@public
    BabyBluetooth *baby;
}

@property (strong, nonatomic) CBPeripheral *currPeripheral;
@property NSString *DeviceNumber;

@end
