//
//  SettingVC.m
//  CigarGuard
//
//  Created by admin on 4/26/16.
//  Copyright © 2016 GP. All rights reserved.
//

#import <MagicalRecord/MagicalRecord.h>
#import "SettingVC.h"
#import "SVProgressHUD.h"
#import "History.h"
#import "Checkpoint.h"
#import "HistoryView.h"
@import Charts;

@interface SettingVC () <UIGestureRecognizerDelegate>
{
    NSDateFormatter *dateFormat;
    
    __weak IBOutlet UILabel *_dateLabel;
    __weak IBOutlet UILabel *_deviceLabel;
    __weak IBOutlet UILabel *_humidityLabel;
    __weak IBOutlet UILabel *_temperatureLabel;
    __weak IBOutlet UILabel *_temperatureUnitLabel;
    __weak IBOutlet UILabel *_averageLabel;
    __weak IBOutlet UILabel *_currentSettingLabel;
    __weak IBOutlet UILabel *_maxLabel;
    __weak IBOutlet UILabel *_minLabel;
    __weak IBOutlet UIImageView *_dot1ImageView;
    __weak IBOutlet UIImageView *_dot2ImageView;
    __weak IBOutlet UIImageView *_dot3ImageView;
    __weak IBOutlet UIButton *_selButton;
    __weak IBOutlet LineChartView *_chartView;
            
    NSMutableString *dataString;
    
    NSTimer *timer;
    
    BOOL isInOperation;
    int countRemove;
    BOOL isFirst;
}

@property (strong, nonatomic) CBCharacteristic *readCharacteristic;
@property (strong, nonatomic) CBCharacteristic *writeCharacteristic;

@property int HUM;
@property int TEMP;
@property int AVG;
@property int SET;
@property int MAX;
@property int MIN;
@property int STATE;
@property int dotSTATE;

@property History *last;

@end

@implementation SettingVC

//- (BOOL)prefersStatusBarHidden
//{
//    return YES;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    countRemove = 0;
    isFirst = true;
    if (!self.currPeripheral) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
//    [SVProgressHUD showInfoWithStatus:@"Preparing..."];
    
    [self initialize];
    
    [self babyDelegate];
    
    [self loadData];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerTask) userInfo:nil repeats:YES];
	
	[self connect];
}

- (void)connect
{
	//[baby cancelAllPeripheralsConnection];
	
	baby.having(self.currPeripheral).and.channel(channelOnPeropheralView).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	if ([timer isValid]) {
		[timer invalidate];
	}
	timer = nil;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_last != nil) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            History *history = [localContext existingObjectWithID:_last.objectID error:nil];
            
            Checkpoint *record = [Checkpoint MR_createEntityInContext:localContext];
            record.date = [NSDate date];
            record.humidity = @(_HUM);
            record.temperature = @(_TEMP);
            record.average = @(_AVG);
            record.current_setting = @(_SET);
            record.max_val = @(_MAX);
            record.min_val = @(_MIN);
            record.state = @(_STATE);
            record.history = history;
        }];
    }
    NSLog(@"closed------");
    
}

- (void)initialize
{
	[_deviceLabel setHidden:NO];		
	[_dateLabel setHidden:NO];
	    
    dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd hh:mm:ss aa";
    _dateLabel.text = [dateFormat stringFromDate:[NSDate date]];
    _deviceLabel.text = self.DeviceNumber;
    
    // chartView
    _chartView.multipleTouchEnabled = false;
    _chartView.dragEnabled = false;
    
    _chartView.rightAxis.enabled = false;
    _chartView.leftAxis.axisMinimum = 10;
    _chartView.leftAxis.axisMaximum = 90;
    [_chartView.leftAxis setLabelCount:5 force:true];
    _chartView.leftAxis.labelTextColor = UIColor.darkGrayColor;
    _chartView.legend.textColor = UIColor.darkGrayColor;

    _chartView.xAxis.axisMinimum = 0;
    _chartView.xAxis.axisMaximum = 9;
    _chartView.xAxis.labelPosition = XAxisLabelPositionBottom;
    _chartView.xAxis.labelCount = 3;
    _chartView.xAxis.labelTextColor = UIColor.darkGrayColor;
    
    NSNumberFormatter *leftAxisFormatter = [[NSNumberFormatter alloc] init];
    leftAxisFormatter.minimumFractionDigits = 0;
    leftAxisFormatter.maximumFractionDigits = 1;
    leftAxisFormatter.negativeSuffix = @"%";
    leftAxisFormatter.positiveSuffix = @"%";
    _chartView.leftAxis.valueFormatter = [[ChartDefaultAxisValueFormatter alloc] initWithFormatter:leftAxisFormatter];
    _chartView.chartDescription.text = @"Minutes";
    _chartView.chartDescription.textColor = UIColor.darkGrayColor;
}

- (void)timerTask
{
    _dateLabel.text = [dateFormat stringFromDate:[NSDate date]];
}

- (void)notifyOnCharacteristic:(CBCharacteristic *)c
{
    [baby notify:self.currPeripheral characteristic:c block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        if (peripheral == self.currPeripheral && characteristics && characteristics.UUID && [characteristics.UUID.UUIDString isEqualToString:ReadValueCharacteristicUUID] && !error) {
            [self prepareParsing:characteristics.value];
        }
    }];
}

- (void)prepareParsing:(NSData *)data
{
    if (data) {
        if (!dataString)
            dataString = [NSMutableString string];
        [dataString appendString:NSDataToHex(data)];
        
        CGFloat prefixLoc = [dataString rangeOfString:ReadValuePrefix].location;
        while (prefixLoc != NSNotFound) {
            [dataString deleteCharactersInRange:NSMakeRange(0, prefixLoc + ReadValuePrefix.length)];
            prefixLoc = [dataString rangeOfString:ReadValuePrefix].location;
        }
        
        CGFloat suffixLoc = [dataString rangeOfString:ReadValueSuffix].location;
        if (suffixLoc != NSNotFound) {
            [self parseCharacteristicValue:[dataString substringWithRange:NSMakeRange(0, suffixLoc)]];
            
            // cancel notify
            [baby cancelNotify:self.currPeripheral characteristic:self.readCharacteristic];
            
            [self notifyOnCharacteristic:self.readCharacteristic];
        }
    }
}


#define RECORD_PER_SECONDS  6

- (void)parseCharacteristicValue:(NSString *)value
{
    _HUM = [self convertHexToInt:[value substringWithRange:NSMakeRange(4, 2)]];
    _TEMP = [self convertHexToInt:[value substringWithRange:NSMakeRange(6, 2)]];
    _AVG = [self convertHexToInt:[value substringWithRange:NSMakeRange(8, 2)]];
    _SET = [self convertHexToInt:[value substringWithRange:NSMakeRange(10, 2)]];
    _MAX = [self convertHexToInt:[value substringWithRange:NSMakeRange(12, 2)]];
    _MIN = [self convertHexToInt:[value substringWithRange:NSMakeRange(14, 2)]];
    _STATE = [self convertHexToInt:[value substringWithRange:NSMakeRange(16, 2)]];
	_dotSTATE = [self convertHexToInt:[value substringWithRange:NSMakeRange(17, 1)]];
	
    _humidityLabel.text = [self getValString:_HUM];
    _temperatureLabel.text = [self getValString:_TEMP];
    _averageLabel.text = [self getValString:_AVG];
    _currentSettingLabel.text = [self getValString:_SET];
    _maxLabel.text = [NSString stringWithFormat:@"Max Humidity %2d %%", _MAX];
    _minLabel.text = [NSString stringWithFormat:@"Min Humidity %2d %%", _MIN];
	
	_dot1ImageView.hidden = YES;
	_dot2ImageView.hidden = YES;
	_dot3ImageView.hidden = YES;
	
	switch (_dotSTATE) {
		case 1:
			_dot1ImageView.hidden = NO;
			_dot2ImageView.hidden = NO;
			_dot3ImageView.hidden = NO;
			break;
		case 2:
			_dot1ImageView.hidden = NO;
			_dot2ImageView.hidden = NO;
		case 4:
			_dot1ImageView.hidden = NO;
		default:
			break;
	}
    if (_STATE & CGStatePropertyFahrenheit) {
        _temperatureUnitLabel.text = @"   Temperature (°F) ";
    } else if (_STATE & CGStatePropertyCelsius) {
        _temperatureUnitLabel.text = @"   Temperature (°C) ";
    } else {
        _temperatureUnitLabel.text = @"Temperature";
        _temperatureLabel.text = @"--";
    }
    
    if (_HUM <= 0 || _HUM >= 100)
        return;
    
    if (isInOperation)
        return;
    
    isInOperation = YES;
    
    // Get Last
    _last = nil;
    NSArray *list = [History MR_findAllSortedBy:@"date" ascending:NO];
    if (list && list.count > 0) {
        _last = list[0];
    }
    
    // Save Record
    if (isFirst || !_last || ![_last.device_name isEqualToString:self.DeviceNumber]) {
        isFirst = false;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            History *newHistory = [History MR_createEntityInContext:localContext];
            newHistory.date = [NSDate date];
            newHistory.device_name = self.DeviceNumber;
            newHistory.device_uuid = self.currPeripheral.identifier.UUIDString;
            
            Checkpoint *record = [Checkpoint MR_createEntityInContext:localContext];
            record.date = [NSDate date];
            record.humidity = @(_HUM);
            record.temperature = @(_TEMP);
            record.average = @(_AVG);
            record.current_setting = @(_SET);
            record.max_val = @(_MAX);
            record.min_val = @(_MIN);
            record.state = @(_STATE);
            record.history = newHistory;
            
        } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
            [self loadData];
            isInOperation = NO;
        }];
    } else {
        BOOL needAdd = NO;
        if (_last.checkpoints && _last.checkpoints.count > 0) {
			
            Checkpoint *lastCheckpoint = _last.checkpoints[_last.checkpoints.count - 1];
			
			if ([lastCheckpoint.date timeIntervalSinceNow] < -RECORD_PER_SECONDS) {

				NSLog(@"%@ - %f", lastCheckpoint.date, [lastCheckpoint.date timeIntervalSinceNow]);
				needAdd = YES;
			}
		} else {
            needAdd = YES;
        }
        
        if (needAdd) {
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
                
                History *history = [localContext existingObjectWithID:_last.objectID error:nil];
                
                Checkpoint *record = [Checkpoint MR_createEntityInContext:localContext];
                record.date = [NSDate date];
                record.humidity = @(_HUM);
                record.temperature = @(_TEMP);
                record.average = @(_AVG);
                record.current_setting = @(_SET);
                record.max_val = @(_MAX);
                record.min_val = @(_MIN);
                record.state = @(_STATE);
                record.history = history;
                
            } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
				[self loadData];
                isInOperation = NO;
            }];
        } else {
            isInOperation = NO;
        }
    }
}

- (NSString *)getValString:(int)val
{
    if (val == 170) {
        return @"--";
    } else if (val == 177) {
        return @"HI";
    } else if (val == 205) {
        return @"LOW";
    } else if (val == 255) {
        return @"";
    } else {
        return [NSString stringWithFormat:@"%2d", val];
    }
}

- (unsigned int)convertHexToInt:(NSString *)valueString
{
    if (valueString && valueString.length > 0) {
        NSScanner *pScanner = [NSScanner scannerWithString:valueString];
        unsigned int value;
        [pScanner scanHexInt:&value];
        return value;
    } else {
        return 0;
    }
}

#pragma mark - IBAction

- (IBAction)selTouchDown:(id)sender
{
    if (self.writeCharacteristic) {
        NSData *data = HexToNSData(WriteValueSetTouchDown);
        [self.currPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (IBAction)selTouchUp:(id)sender
{
    if (self.writeCharacteristic) {
			NSData *data = HexToNSData(WriteValueSetTouchUp);
			[self.currPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];	
    }
}

- (IBAction)upTouchDown:(id)sender
{
    if (self.writeCharacteristic) {
        NSData *data = HexToNSData(WriteValueUpTouchDown);
        [self.currPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (IBAction)upTouchUp:(id)sender
{
    if (self.writeCharacteristic) {
		NSData *data = HexToNSData(WriteValueUpTouchUp);
        [self.currPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (IBAction)downTouchDown:(id)sender
{
    if (self.writeCharacteristic) {
        NSData *data = HexToNSData(WriteValueDownTouchDown);
        [self.currPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (IBAction)downTouchUp:(id)sender
{
    if (self.writeCharacteristic) {
		NSData *data = HexToNSData(WriteValueDownTouchUp);
        [self.currPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - BabyBluetooth Delegate

- (void)babyDelegate
{
    __weak typeof(self) weakSelf = self;
    BabyRhythm *rhythm = [[BabyRhythm alloc] init];
    
    [baby setBlockOnConnectedAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral) {
//        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"Connected: %@", peripheral.name]];
    }];
    
    [baby setBlockOnFailToConnectAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"Connect Failed: %@", peripheral.name]];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
    
    [baby setBlockOnDisconnectAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"Disconnected: %@", peripheral.name]];
		if (_last != nil) {
			[MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
				History *history = [localContext existingObjectWithID:_last.objectID error:nil];
				
				Checkpoint *record = [Checkpoint MR_createEntityInContext:localContext];
				record.date = [NSDate date];
				record.humidity = @(_HUM);
				record.temperature = @(_TEMP);
				record.average = @(_AVG);
				record.current_setting = @(_SET);
				record.max_val = @(_MAX);
				record.min_val = @(_MIN);
				record.state = @(_STATE);
				record.history = history;
			}];
		}
		[weakSelf.navigationController popViewControllerAnimated:YES];
//        [weakSelf connect];
    }];
	
    [baby setBlockOnDiscoverServicesAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, NSError *error) {
        [rhythm beats];
    }];
    
    [baby setBlockOnDiscoverCharacteristicsAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        if (peripheral && service && service.UUID && [service.UUID.UUIDString isEqualToString:ReadValueServiceUUID]) {
            for (int row=0; row<service.characteristics.count; row++) {
                CBCharacteristic *c = service.characteristics[row];
                if (c.UUID) {
                    if ([c.UUID.UUIDString isEqualToString:ReadValueCharacteristicUUID]) {
                        weakSelf.readCharacteristic = c;
                        [weakSelf notifyOnCharacteristic:c];
                    } else if ([c.UUID.UUIDString isEqualToString:WriteValueCharacteristicUUID]) {
                        weakSelf.writeCharacteristic = c;
                    }
                }
            }
        }
    }];
    
    [baby setBlockOnReadValueForCharacteristicAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        if (peripheral == self.currPeripheral && characteristics && characteristics.UUID && [characteristics.UUID.UUIDString isEqualToString:ReadValueCharacteristicUUID] && !error) {
            [weakSelf prepareParsing:characteristics.value];
        }
    }];
    
    [baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
    
    [baby setBabyOptionsAtChannel:channelOnPeropheralView
    scanForPeripheralsWithOptions:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}
     connectPeripheralWithOptions:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                    CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                    CBConnectPeripheralOptionNotifyOnNotificationKey:@YES}
   scanForPeripheralsWithServices:nil
             discoverWithServices:nil
      discoverWithCharacteristics:nil];
}

#pragma mark - CoreData

#define MAX_PAGE_COUNT  10

- (void)loadData
{
    NSArray *list = [History MR_findAllSortedBy:@"date" ascending:NO];
    if (list && list.count > 0) {
        		
		History *history = list[0];
		if ([self.currPeripheral.identifier.UUIDString isEqualToString:history.device_uuid]) {
            
            if (history && history.checkpoints && history.checkpoints.count > 0) {
                NSMutableArray *values = [[NSMutableArray alloc] init];
                        
                while(history.checkpoints.count > 9 * 60.0 / RECORD_PER_SECONDS){
                    [history removeCheckpointsAtIndexes:[NSIndexSet indexSetWithIndex:0]];
                    countRemove++;
                }
                
                for (int i=0; i<history.checkpoints.count; i++) {
                    double val = history.checkpoints[i].humidity.floatValue;
                    double x = (countRemove  + i) * RECORD_PER_SECONDS / 60.0;
                    [values addObject:[[ChartDataEntry alloc] initWithX:x  y:val]];
                }
                        
                LineChartDataSet *humidityDataSet = nil;
                humidityDataSet = [[LineChartDataSet alloc] initWithEntries:values label:@"Humidity"];
                humidityDataSet.drawValuesEnabled = false;
                humidityDataSet.drawCirclesEnabled = false;
                [humidityDataSet setColor:UIColor.blueColor];
                
                NSMutableArray *dataSets = [[NSMutableArray alloc] init];
                [dataSets addObject:humidityDataSet];
                
                LineChartData *data = [[LineChartData alloc] initWithDataSets:dataSets];
                
                if(countRemove > 0){
                    _chartView.xAxis.axisMinimum = countRemove * RECORD_PER_SECONDS / 60.0;
                    _chartView.xAxis.axisMaximum = countRemove * RECORD_PER_SECONDS / 60.0 + 9;
                }
                _chartView.data = data;
            }
		}
    }
}

#pragma mark - Hex & NSData Conversion

static inline char itoh(int i)
{
    if (i > 9) return 'A' + (i - 10);
    return '0' + i;
}

// NSData -> NSString
NSString * NSDataToHex(NSData *data)
{
    NSUInteger i, len;
    unsigned char *buf, *bytes;
    
    len = data.length;
    bytes = (unsigned char*)data.bytes;
    buf = malloc(len*2);
    
    for (i=0; i<len; i++) {
        buf[i*2] = itoh((bytes[i] >> 4) & 0xF);
        buf[i*2+1] = itoh(bytes[i] & 0xF);
    }
    
    return [[NSString alloc] initWithBytesNoCopy:buf
                                          length:len*2
                                        encoding:NSASCIIStringEncoding
                                    freeWhenDone:YES];
}

// NSString -> NSData
NSData * HexToNSData(NSString *hex)
{
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [hex length]/2; i++) {
        byte_chars[0] = [hex characterAtIndex:i*2];
        byte_chars[1] = [hex characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return commandToSend;
}

@end
