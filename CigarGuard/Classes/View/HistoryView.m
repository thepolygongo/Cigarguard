//
//  HistoryView.m
//  CigarGuard
//
//  Created by admin on 4/29/16.
//  Copyright © 2016 GP. All rights reserved.
//

#import "HistoryView.h"
#import "PNChart.h"
#import "Checkpoint.h"
#import "SettingVC.h"
#import "DVSwitch.h"

@interface HistoryView()
{
    __weak IBOutlet UILabel *_dateLabel;
    __weak IBOutlet UILabel *_deviceNameLabel;
    __weak IBOutlet UIView *_chartView;
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
	
	NSInteger celTemperatureValue;
    PNLineChart *lineChart;
}
@end

@implementation HistoryView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
	CGRect chartBounds = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, _chartView.bounds.size.height);
	lineChart = [[PNLineChart alloc] initWithFrame:chartBounds];
    [lineChart setShowCoordinateAxis:YES];
    [lineChart setXUnit:@"H"];
    [lineChart setYUnit:@"%"];
    [lineChart setXLabelFont:[UIFont systemFontOfSize:6]];
    [lineChart setYValueMax:100];
    [lineChart setYValueMin:0];
    [lineChart setYLabels:@[@"", @"10", @"", @"30", @"", @"50", @"", @"70", @"", @"90", @""]];
    [lineChart setXLabels:@[@"",
                            @"", @"", @"", @"", @"",
                            @"", @"", @"", @"", @"",
                            @"", @"", @"", @"", @"3",
                            @"", @"", @"", @"", @"",
                            @"", @"", @"", @"", @"",
                            @"", @"", @"", @"", @"6",
                            @"", @"", @"", @"", @"",
                            @"", @"", @"", @"", @"",
                            @"", @"", @"", @"", @"9",
                            ]];
    
    [_chartView addSubview:lineChart];
}

- (void)loadData:(History *)history
{
    if (!history)
        return;
	
	[_deviceNameLabel setHidden:NO];
	[_dateLabel setHidden:NO];
	
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd hh:mm:ss aa";
    
    _deviceNameLabel.text = history.device_name;
    
    if (history.checkpoints && history.checkpoints.count > 0) {
        
        Checkpoint *checkpoint = history.checkpoints[history.checkpoints.count - 1];
        
        _dateLabel.text = [dateFormat stringFromDate:checkpoint.date];
        
        _humidityLabel.text = [self getValString:checkpoint.humidity.intValue];
        _temperatureLabel.text = [self getValString:checkpoint.temperature.intValue];
        _averageLabel.text = [self getValString:checkpoint.average.intValue];
        _currentSettingLabel.text = [self getValString:checkpoint.current_setting.intValue];
        _maxLabel.text = [NSString stringWithFormat:@"Max Humidity %2d %%", checkpoint.max_val.intValue];
        _minLabel.text = [NSString stringWithFormat:@"Min Humidity %2d %%", checkpoint.min_val.intValue];
     
        int STATE = checkpoint.state.intValue;
        
        _dot1ImageView.hidden = STATE & CGStateProperty1Dot ? NO : YES;
        _dot2ImageView.hidden = STATE & CGStateProperty2Dot ? NO : YES;
        _dot3ImageView.hidden = STATE & CGStateProperty3Dot ? NO : YES;
		
		UIView *superViewTemperLabel = [[[[_temperatureLabel superview] superview] superview] superview];
		
		DVSwitch *switcher = [[DVSwitch alloc] initWithStringsArray:@[@"°C", @"°F"]];
		switcher.frame = CGRectMake(superViewTemperLabel.bounds.size.width * 0.75 - 40.0, superViewTemperLabel.bounds.size.height, 80.0, 30);
		[superViewTemperLabel addSubview:switcher];
		
		[switcher setPressedHandler:^(NSUInteger index) {
			
			NSLog(@"Did press position on first switch at index: %lu", (unsigned long)index);
			if (switcher.selectedIndex == 0) {
				_temperatureLabel.text = [self getValString:celTemperatureValue];
				_temperatureUnitLabel.text = @"   Temperature (°C) ";
			} else {
				_temperatureLabel.text = [self getValString:celTemperatureValue * 1.8 + 32];
				 _temperatureUnitLabel.text = @"   Temperature (°F) ";
			}
		}];

        if (STATE & CGStatePropertyFahrenheit) {
            _temperatureUnitLabel.text = @"   Temperature (°F) ";
			celTemperatureValue = (_temperatureLabel.text.integerValue - 32) / 1.8;
			[switcher setSelectedIndex:1];
        } else if (STATE & CGStatePropertyCelsius) {
            _temperatureUnitLabel.text = @"   Temperature (°C) ";
			celTemperatureValue = _temperatureLabel.text.integerValue;
			[switcher setSelectedIndex:0];
        } else {
            _temperatureUnitLabel.text = @"Temperature";
            _temperatureLabel.text = @"--";
        }
		
        [self loadCheckpoints:history];
    }
}

- (void)loadCheckpoints:(History *)history
{
    if (history && history.checkpoints && history.checkpoints.count > 0) {
        
        NSMutableArray *dataList = [NSMutableArray array];
        for (int i=history.checkpoints.count - 1; i>=0; i--) {
			
			[dataList addObject:history.checkpoints[i]];
			if (dataList.count >= lineChart.xLabels.count) {
				break;
			}
        }
        
        PNLineChartData *data01 = [PNLineChartData new];
        data01.color = PNBlack;
        data01.itemCount = lineChart.xLabels.count;
        data01.inflexionPointStyle = PNLineChartPointStyleCircle;
        data01.inflexionPointWidth = 2;
        data01.getData = ^(NSUInteger index) {
            if (dataList.count > index) {
                Checkpoint *checkpoint = dataList[index];
				NSLog(@"%f", checkpoint.humidity.floatValue);
                return [PNLineChartDataItem dataItemWithY:checkpoint.humidity.floatValue];
            } else {
                return [PNLineChartDataItem dataItemWithY:0];
            }
        };
        
        lineChart.chartData = @[data01];
        [lineChart strokeChart];
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

@end
