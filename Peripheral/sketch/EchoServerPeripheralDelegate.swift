//
//  EchoServerDelegate.swift
//  sketch
//
//  Created by Adonis Gaitatzis on 1/9/17.
//  Copyright © 2017 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth


/**
 Relays important status changes from BlePeripheral
 */
@objc protocol EchoServerPeripheralDelegate : class {
    
    /**
     Echo Server State Changed
     
     - Parameters:
     - rssi: the RSSI
     - blePeripheral: the BlePeripheral
     */
    @objc optional func echoServerPeripheral(stateChanged state: CBManagerState)
    
    /**
     Echo Server statrted advertising
     
     - Parameters:
     - error: the error message, if any
     */
    @objc optional func echoServerPeripheral(startedAdvertising error: Error?)
    
    /**
     Value written to Characteristic
     
     - Parameters:
     - value: the Data value written to the Charactersitic
     - characteristic: the Characteristic that was written to
     */
    @objc optional func echoServerPeripheral(valueWritten value: Data, toCharacteristic: CBCharacteristic)
}
