//
//  CBPeripheral+Extensions.m
//  BLE Central Cordova Plugin
//
//  (c) 2104 Don Coleman
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "CBPeripheral+Extensions.h"

static char ADVERTISING_IDENTIFER;
static char ADVERTISEMENT_RSSI_IDENTIFER;

@implementation CBPeripheral(com_megster_ble_extension)

-(NSString *)uuidAsString {
    if (self.identifier.UUIDString) {
        return self.identifier.UUIDString;
    } else {
        return @"";
    }
}


-(NSDictionary *)asDictionary {
    NSString *uuidString = NULL;
    if (self.identifier.UUIDString) {
        uuidString = self.identifier.UUIDString;
    } else {
        uuidString = @"";
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: uuidString forKey: @"id"];

    if ([self name]) {
        [dictionary setObject: [self name] forKey: @"name"];
    }

    if ([self RSSI]) {
        [dictionary setObject: [self RSSI] forKey: @"rssi"];
    } else if ([self advertisementRSSI]) {
        [dictionary setObject: [self advertisementRSSI] forKey: @"rssi"];
    }

    if ([self advertising]) {
        [dictionary setObject: [self advertising] forKey: @"advertising"];
    }

    if([[self services] count] > 0) {
        [self serviceAndCharacteristicInfo: dictionary];
    }

    return dictionary;

}

// Put the service, characteristic, and descriptor data in a format that will serialize through JSON
// sending a list of services and a list of characteristics
- (void) serviceAndCharacteristicInfo: (NSMutableDictionary *) info {

    NSMutableArray *serviceList = [NSMutableArray new];
    NSMutableArray *characteristicList = [NSMutableArray new];

    @try {
        // This can move into the CBPeripherial Extension
        for (CBService *service in [self services]) {
            [serviceList addObject:[[service UUID] UUIDString]]; // Can crash for some BT peripherials
            for (CBCharacteristic *characteristic in service.characteristics) {
                NSMutableDictionary *characteristicDictionary = [NSMutableDictionary new];
                [characteristicDictionary setObject:[[service UUID] UUIDString] forKey:@"service"];
                [characteristicDictionary setObject:[[characteristic UUID] UUIDString] forKey:@"characteristic"];

                if ([characteristic value]) {
                    [characteristicDictionary setObject:dataToArrayBuffer([characteristic value]) forKey:@"value"];
                }
                if ([characteristic properties]) {
                    //[characteristicDictionary setObject:[NSNumber numberWithInt:[characteristic properties]] forKey:@"propertiesValue"];
                    [characteristicDictionary setObject:[self decodeCharacteristicProperties:characteristic] forKey:@"properties"];
                }
                // permissions only exist on CBMutableCharacteristics
                [characteristicDictionary setObject:[NSNumber numberWithBool:[characteristic isNotifying]] forKey:@"isNotifying"];
                [characteristicList addObject:characteristicDictionary];

                // descriptors always seem to be nil, probably a bug here
                NSMutableArray *descriptorList = [NSMutableArray new];
                for (CBDescriptor *descriptor in characteristic.descriptors) {
                    NSMutableDictionary *descriptorDictionary = [NSMutableDictionary new];
                    [descriptorDictionary setObject:[[descriptor UUID] UUIDString] forKey:@"descriptor"];
                    if ([descriptor value]) { // should always have a value?
                        [descriptorDictionary setObject:[descriptor value] forKey:@"value"];
                    }
                    [descriptorList addObject:descriptorDictionary];
                }
                if ([descriptorList count] > 0) {
                    [characteristicDictionary setObject:descriptorList forKey:@"descriptors"];
                }

            }
        }
    }

    @catch (NSException *e) {

    }

    [info setObject:serviceList forKey:@"services"];
    [info setObject:characteristicList forKey:@"characteristics"];

}

-(NSArray *) decodeCharacteristicProperties: (CBCharacteristic *) characteristic {
    NSMutableArray *props = [NSMutableArray new];

    CBCharacteristicProperties p = [characteristic properties];

    // NOTE: props strings need to be consistent across iOS and Android
    if ((p & CBCharacteristicPropertyBroadcast) != 0x0) {
        [props addObject:@"Broadcast"];
    }

    if ((p & CBCharacteristicPropertyRead) != 0x0) {
        [props addObject:@"Read"];
    }

    if ((p & CBCharacteristicPropertyWriteWithoutResponse) != 0x0) {
        [props addObject:@"WriteWithoutResponse"];
    }

    if ((p & CBCharacteristicPropertyWrite) != 0x0) {
        [props addObject:@"Write"];
    }

    if ((p & CBCharacteristicPropertyNotify) != 0x0) {
        [props addObject:@"Notify"];
    }

    if ((p & CBCharacteristicPropertyIndicate) != 0x0) {
        [props addObject:@"Indicate"];
    }

    if ((p & CBCharacteristicPropertyAuthenticatedSignedWrites) != 0x0) {
        [props addObject:@"AutheticateSignedWrites"];
    }

    if ((p & CBCharacteristicPropertyExtendedProperties) != 0x0) {
        [props addObject:@"ExtendedProperties"];
    }

    if ((p & CBCharacteristicPropertyNotifyEncryptionRequired) != 0x0) {
        [props addObject:@"NotifyEncryptionRequired"];
    }

    if ((p & CBCharacteristicPropertyIndicateEncryptionRequired) != 0x0) {
        [props addObject:@"IndicateEncryptionRequired"];
    }

    return props;
}

// Borrowed from Cordova messageFromArrayBuffer since Cordova doesn't handle NSData in NSDictionary
id dataToArrayBuffer(NSData* data)
{
    return @{
             @"CDVType" : @"ArrayBuffer",
             @"data" :[data base64EncodedStringWithOptions:0]
             };
}

-(NSString*)advertising{
    return objc_getAssociatedObject(self, &ADVERTISING_IDENTIFER);
}

-(NSString*)advertisementRSSI{
    return objc_getAssociatedObject(self, &ADVERTISEMENT_RSSI_IDENTIFER);
}

@end
