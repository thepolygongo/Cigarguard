//
//  HomeVC.m
//  CigarGuard
//
//  Created by admin on 4/26/16.
//  Copyright © 2016 GP. All rights reserved.
//

#import "HomeVC.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import "SVProgressHUD.h"
#import "SettingVC.h"
#import "NSData+Conversion.h"

#define LOGO_NAME   @"Le Veil"

@interface HomeVC ()
{
    NSMutableArray *peripherals;
    NSMutableArray *peripheralsAD;
    
    BabyBluetooth *baby;
}

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation HomeVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [SVProgressHUD showInfoWithStatus:@"Preparing..."];
    
    [self initialize];
}

- (void)viewDidAppear:(BOOL)animated
{
    [baby cancelAllPeripheralsConnection];
    
    peripherals = [NSMutableArray array];
    peripheralsAD = [NSMutableArray array];
	
	[_tableView reloadData];
	
    baby.scanForPeripherals().begin();
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    self.navigationController.navigationBarHidden = NO;
}

- (void)initialize
{
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    peripherals = [NSMutableArray array];
    peripheralsAD = [NSMutableArray array];
    
    baby = [BabyBluetooth shareBabyBluetooth];
    [self babyDelegate];
    
    UIImageView *logo = [[UIImageView alloc] initWithFrame:self.navigationController.navigationBar.bounds];
    logo.image = [UIImage imageNamed:@"logo"];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    [self.navigationController.navigationBar addSubview:logo];
}

- (IBAction)connect:(id)sender
{
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CBPeripheral *peripheral = [peripherals objectAtIndex:indexPath.row];
    NSDictionary *ad = [peripheralsAD objectAtIndex:indexPath.row];
    
    // Name
    NSString *localName;
    if ([ad objectForKey:@"kCBAdvDataLocalName"]) {
        localName = [NSString stringWithFormat:@"%@", [ad objectForKey:@"kCBAdvDataLocalName"]];
    } else {
        localName = peripheral.name;
    }
	
	if ([ad objectForKey:@"kCBAdvDataManufacturerData"]) {
		
		NSData *data = [ad objectForKey:@"kCBAdvDataManufacturerData"];
		NSString *hexString = [data hexadecimalString];
		NSString *hexCode = [hexString substringFromIndex: [hexString length] - 6];
		
		unsigned deviceNumber = 0;
		NSScanner *scanner = [NSScanner scannerWithString:hexCode];
		
		[scanner setScanLocation:0]; // bypass '#' character
		[scanner scanHexInt:&deviceNumber];
		NSLog(@"%u", deviceNumber);
		localName = [NSString stringWithFormat:@"%@%@%u", localName, @" ", deviceNumber];
	}
	
	cell.textLabel.text = localName;
	
    // Status
    cell.detailTextLabel.text = @"Reading...";
    NSArray *serviceUUIDs = [ad objectForKey:@"kCBAdvDataServiceUUIDs"];
    if (serviceUUIDs) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu services", (unsigned long)serviceUUIDs.count];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"0 service"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
    if (peripherals.count > indexPath.row) {
        [baby cancelScan];
        
        SettingVC *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingVC"];
        vc.currPeripheral = [peripherals objectAtIndex:indexPath.row];
		vc.DeviceNumber = cell.textLabel.text;
		
        vc->baby = self->baby;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)insertTableView:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData
{
    if (![peripherals containsObject:peripheral]) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:peripherals.count inSection:0];
        [indexPaths addObject:indexPath];
        [peripherals addObject:peripheral];
        [peripheralsAD addObject:advertisementData];
//        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadData];
    }
}

#pragma mark - BabyBluetooth Delegate

- (void)babyDelegate
{
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
            [SVProgressHUD showInfoWithStatus:@"Scan Started!"];
        }
    }];
    
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        [weakSelf insertTableView:peripheral advertisementData:advertisementData];
    }];
    
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
//        for (CBService *service in peripheral.services) {
//            NSLog(@"Service:%@", service.UUID.UUIDString);
//        }
        for (int i=0; i<peripherals.count; i++) {
            UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if ([cell.textLabel.text isEqualToString:peripheral.name]) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu services", (unsigned long)peripheral.services.count];
            }
        }
    }];

//    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
//        NSLog(@"===service name:%@", service.UUID);
//        for (CBCharacteristic *c in service.characteristics) {
//            NSLog(@"charateristic name is :%@", c.UUID);
//        }
//    }];
    
//    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
//        NSLog(@"characteristic name:%@ value is:%@", characteristics.UUID, characteristics.value);
//    }];
    
//    [baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
//        NSLog(@"===characteristic name:%@", characteristic.service.UUID);
//        for (CBDescriptor *d in characteristic.descriptors) {
//            NSLog(@"CBDescriptor name is :%@", d.UUID);
//        }
//    }];
    
//    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
//        NSLog(@"Descriptor name:%@ value is:%@", descriptor.characteristic.UUID, descriptor.value);
//    }];
//    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
//        NSLog(@"setBlockOnCancelAllPeripheralsConnectionBlock");
//    }];
//
//    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
//        NSLog(@"setBlockOnCancelScanBlock");
//    }];
    
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (peripheralName.length > 0 && [peripheralName containsString:LOGO_NAME]) {
            return YES;
        }
        return NO;
    }];
    
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}
                             connectPeripheralWithOptions:nil
                           scanForPeripheralsWithServices:nil
                                     discoverWithServices:nil
                              discoverWithCharacteristics:nil];
}

@end