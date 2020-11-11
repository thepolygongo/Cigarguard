//
//  HistoryView.m
//  CigarGuard
//
//  Created by admin on 4/29/16.
//  Copyright © 2016 GP. All rights reserved.
//

#import "HistoryView.h"
#import "Checkpoint.h"
#import "SettingVC.h"
#import "DVSwitch.h"
@import Charts;

@interface HistoryView()
{
    __weak IBOutlet UILabel *_dateLabel;
    __weak IBOutlet UILabel *_deviceNameLabel;
    __weak IBOutlet LineChartView *_chartView;
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
}
@end

@implementation HistoryView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
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
		switcher.frame = CGRectMake(superViewTemperLabel.bounds.size.width * 0.75 - 40.0, superViewTemperLabel.bounds.size.height - 30.0, 80.0, 30);
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

#define RECORD_PER_SECONDS  6

- (void)loadCheckpoints:(History *)history
{
    
    if (history && history.checkpoints && history.checkpoints.count > 0) {
        NSMutableArray *values = [[NSMutableArray alloc] init];
        
        int countRemove = 0;
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
