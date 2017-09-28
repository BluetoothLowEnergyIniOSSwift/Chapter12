//
//  EchoServer.swift
//  sketch
//
//  Created by Adonis Gaitatzis on 1/9/17.
//  Copyright © 2017 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth


class EchoServerPeripheral : NSObject, CBPeripheralManagerDelegate {
    
    // MARK: Peripheral properties
    
    // Advertized name
    let advertisingName = "EchoServer"
    
    // Device identifier
    let peripheralIdentifier = "8f68d89b-448c-4b14-aa9a-f8de6d8a4753"
    
    
    // MARK: GATT Profile
    
    // Service UUID
    let serviceUuid = CBUUID(string: "0000180c-0000-1000-8000-00805f9b34fb")
    
    // Characteristic UUIDs
    let readCharacteristicUuid = CBUUID(string: "00002a56-0000-1000-8000-00805f9b34fb")
    let writeCharacteristicUuid = CBUUID(string: "00002a57-0000-1000-8000-00805f9b34fb")
    
    // Read Characteristic
    var readCharacteristic:CBMutableCharacteristic!
    
    // Write Characteristic
    var writeCharacteristic:CBMutableCharacteristic!
    
    // the size of a Characteristic
    let readCharacteristicLength = 20
    let writeCharacteristicLength = 20
    
    
    
    // MARK: Peripheral State
    
    // Peripheral Manager
    var peripheralManager:CBPeripheralManager!
    
    // Connected Central
    var central:CBCentral!
    
    // delegate
    var delegate:EchoServerPeripheralDelegate!
    
    /**
     Initialize BlePeripheral with a corresponding Peripheral
     
     - Parameters:
     - delegate: The BlePeripheralDelegate
     - peripheral: The discovered Peripheral
     */
    init(delegate: EchoServerPeripheralDelegate?) {
        super.init()
        
        // empty dispatch queue
        let dispatchQueue:DispatchQueue! = nil
        
        // Build Advertising options
        let options:[String : Any] = [
            //
            CBPeripheralManagerOptionShowPowerAlertKey: true,
            // Peripheral unique identifier
            CBPeripheralManagerOptionRestoreIdentifierKey: peripheralIdentifier
        ]
        peripheralManager = CBPeripheralManager(delegate: self, queue: dispatchQueue, options: options)
        self.delegate = delegate
    }

    /**
     Stop advertising, shut down the Peripheral
     */
    func stop() {
        peripheralManager.stopAdvertising()
    }
    
    /**
     Start Bluetooth Advertising.  This must be after building the GATT profile
     */
    func startAdvertising() {
        let serviceUuids = [serviceUuid]
        let advertisementData:[String: Any] = [
            CBAdvertisementDataLocalNameKey: advertisingName,
            CBAdvertisementDataServiceUUIDsKey: serviceUuids
        ]
        peripheralManager.startAdvertising(advertisementData)
    }
    
    /**
     Build Gatt Profile.  This must be done after Bluetooth Radio has turned on
     */
    func buildGattProfile() {
        let service = CBMutableService(type: serviceUuid, primary: true)
        
        var rProperties = CBCharacteristicProperties.read
        rProperties.formUnion(CBCharacteristicProperties.notify)
        var rPermissions = CBAttributePermissions.writeable
        rPermissions.formUnion(CBAttributePermissions.readable)
        readCharacteristic = CBMutableCharacteristic(type: readCharacteristicUuid, properties: rProperties, value: nil, permissions: rPermissions)
        
        let wProperties = CBCharacteristicProperties.write
        let wPermissions = CBAttributePermissions.writeable
        writeCharacteristic = CBMutableCharacteristic(type: writeCharacteristicUuid, properties: wProperties, value: nil, permissions: wPermissions)
        
        service.characteristics = [ readCharacteristic, writeCharacteristic ]
        peripheralManager.add(service)
    }
    
    
    
    
    // MARK: CBPeripheralManagerDelegate
    
    /**
     Peripheral will become active
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("restoring peripheral state")
    }
    
    /**
     Peripheral added a new Service
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("added service to peripheral")
        if error != nil {
            print(error.debugDescription)
        }
    }
    
    /**
     Peripheral started advertising
     */
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error != nil {
            print ("Error advertising peripheral")
            print(error.debugDescription)
        }
        self.peripheralManager = peripheral
        
        delegate?.echoServerPeripheral?(startedAdvertising: error)
    }
    
    
    /**
     Connected Central requested to read from a Characteristic
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        //if request.characteristic.UUID.isEqual(characteristic.UUID) {
        // Respond to the request
        
        //}
        
        let characteristic = request.characteristic
        if (characteristic.uuid == readCharacteristic.uuid) {
            if let value = characteristic.value {
                //let stringValue = String(data: value, encoding: .utf8)!
                if request.offset > value.count {
                    peripheralManager.respond(to: request, withResult: CBATTError.invalidOffset)
                    return
                }
                
                let range = Range(uncheckedBounds: (lower: request.offset, upper: value.count - request.offset))
                request.value = value.subdata(in: range)
                
                peripheral.respond(to: request, withResult: CBATTError.success)
            }
        }
        
    }
    
    /**
     Connected Central requested to write to a Characteristic
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            peripheral.respond(to: request, withResult: CBATTError.success)
            print("new request")
            if let value = request.value {
                print("notifying delegate")
                delegate?.echoServerPeripheral?(valueWritten: value, toCharacteristic: request.characteristic)
                
                // update readCharacteristic
                print("updating characteristic")
                readCharacteristic.value = value
                // notify subscribers
                print("notifying characteristic")
                peripheralManager.updateValue(
                    value,
                    for: readCharacteristic,
                    onSubscribedCentrals: [central])
            }
        }
    }
    
    /**
     Connected Central subscribed to a Characteristic
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.central = central
    }
    
    /**
     Connected Central unsubscribed from a Characteristic
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        self.central = central
    }
    
    /**
     Peripheral is about to notify subscribers of changes to a Characteristic
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("Peripheral about to update subscribers")
    }
    
    /**
     Bluetooth Radio state changed
     */
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        peripheralManager = peripheral
        switch peripheral.state {
        case CBManagerState.poweredOn:
            buildGattProfile()
            startAdvertising()
        default: break
        }
        delegate?.echoServerPeripheral?(stateChanged: peripheral.state)
        
    }
}
