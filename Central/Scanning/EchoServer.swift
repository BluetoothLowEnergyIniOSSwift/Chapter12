//
//  EchoServer.swift
//  EchoClient
//
//  Created by Adonis Gaitatzis on 11/26/16.
//  Copyright © 2016 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 EchoServer talks to a connected Bluetooth device
 */
class EchoServer:NSObject, CBPeripheralDelegate {
    
    // MARK: Peripheral properties
    
    // The Broadcast name of the Perihperal
    static let advertisedName = "EchoServer"
    
    // the Service UUID
    static let serviceUuid = CBUUID(string: "180C")
    
    // The Characteristic UUID used to write text to the Peripheral
    static let readCharacteristicUuid = CBUUID(string: "2A56")
    
    // the Characteristic UUID used to read echoes from the Peripheral
    static let writeCharacteristicUuid = CBUUID(string: "2A57")
    
    // the size of the characteristic
    let characteristicLength = 20
    
    
    // MARK: Flow control
    
    // FLow control response
    let flowControlMessage = "ready"
    
    // outbound value to be sent to the Characteristic
    var outboundByteArray:[UInt8]!
    
    // packet offset in multi-packet value
    var packetOffset = 0
    
    
    
    // MARK: connected device

    // EchoServerDelegate
    var delegate:EchoServerDelegate!
    
    // connected Peripheral
    var connectedPeripheral:CBPeripheral!
    
    // connected Characteristic
    var readCharacteristic:CBCharacteristic!
    
    
    var writeCharacteristic:CBCharacteristic!
    
    
    
    
    /**
     Initialize EchoServer with a corresponding Peripheral
     
     - Parameters:
        - delegate: The EchoServerDelegate
        - peripheral: The discovered Peripheral
     */
    init(delegate: EchoServerDelegate, peripheral: CBPeripheral) {
        super.init()
        connectedPeripheral = peripheral
        connectedPeripheral.delegate = self
        self.delegate = delegate
        
    }
    
    
    /**
     Notify the EchoServer that the peripheral has been connected
     */
    func connected(peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedPeripheral.delegate = self
        connectedPeripheral.discoverServices([EchoServer.serviceUuid])
    }
    
    
    /**
     Get a advertised name from an advertisementData packet.  This may be different than the actual Peripheral name
     */
    static func getNameFromAdvertisementData(advertisementData: [String : Any]) -> String? {
        // grab thekCBAdvDataLocalName from the advertisementData to see if there's an alternate broadcast name
        if advertisementData["kCBAdvDataLocalName"] != nil {
            return (advertisementData["kCBAdvDataLocalName"] as! String)
        }
        return nil
    }    
    
    
    /**
     Write a text value to the EchoServer
     
     - Parameters:
        - value: the value to write to the connected Characteristic
     */
    func writeValue(value: String) {
        // get the characteristic length
        let writeableValue = value + "\n\0"
        packetOffset = 0
        
        // get the data for the current offset
        outboundByteArray = Array(writeableValue.utf8)
        //outboundByteArray = Array<Any>(writeableValue.withCString) as [UInt8]
        
        writePartialValue(value: outboundByteArray, offset: packetOffset)
    }
    
    
    /**
     Write a partial value to the EchoServer
     
     - Parameters:
        - value: the full value to write to the connected Characteristic
        - offset: the packet offset
     
     */
    func writePartialValue(value: [UInt8], offset: Int) {
        // don't go past the total value size
        var end =  offset + characteristicLength
        
        if end > outboundByteArray.count {
            end = outboundByteArray.count
        }
        
        
        let transmissableValue = Data(Array(outboundByteArray[offset..<end]))
        
        print("writing partial value:  \(offset)-\(end)")
        print(transmissableValue)
        
        var writeType = CBCharacteristicWriteType.withResponse
        if EchoServer.isCharacteristic(isWriteableWithoutResponse: writeCharacteristic) {
            writeType = CBCharacteristicWriteType.withoutResponse
        }
        
        connectedPeripheral.writeValue(transmissableValue, for: writeCharacteristic, type: writeType)
        print("write request sent")
        
    }
    
    
    
    /**
     Check if Characteristic is readable
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is readable
     */
    static func isCharacteristic(isReadable characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            print("readable")
            return true
        }
        return false
    }
    
    
    /**
     Check if Characteristic is writeable
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is writeable
     */
    static func isCharacteristic(isWriteable characteristic: CBCharacteristic) -> Bool {
        print("testing if characteristic is writeable")
        if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 ||
            (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            print("characteristic is writeable")
            return true
        }
        print("characteristic is not writeable")
        return false
    }
    
    
    /**
     Check if Characteristic is writeable with response
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is writeable with response
     */
    static func isCharacteristic(isWriteableWithResponse characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 {
            return true
        }
        return false
    }
    
    
    /**
     Check if Characteristic is writeable without response
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is writeable without response
     */
    static func isCharacteristic(isWriteableWithoutResponse characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            return true
        }
        return false
    }
    
    
    /**
     Check if Characteristic is notifiable
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is notifiable
     */
    static func isCharacteristic(isNotifiable characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0 {
            print("characteristic is notifiable")
            return true
        }
        return false
    }
    
    
    // MARK: CBPeripheralDelegate
    
    
    /**
     Characteristic has been subscribed to or unsubscribed from
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        connectedPeripheral = peripheral
        connectedPeripheral.delegate = self
        
        print("Notification state updated for: \(characteristic.uuid.uuidString)")
        print("New state: \(characteristic.isNotifying)")
        
        
        if let errorValue = error {
            print("error subscribing to notification: ")
            print(errorValue.localizedDescription)
        }
    }
    
    
    /**
     Value was written to the Characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("data written")
    }
    
    
    
    /**
     Value downloaded from Characteristic on connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("characteristic updated")
        if let value = characteristic.value {
            
            print(value.debugDescription)
            print(value.description)
            
            let byteArray = [UInt8](value)
            
            if let stringValue = String(data: value, encoding: .ascii) {
            
                print(stringValue)
        
                packetOffset += characteristicLength
                //let byteArray:[UInt8] = Array(outboundValue.withCString)
                print("new packet offset: \(packetOffset)")
                print("new packet offset: \(packetOffset)")
                if packetOffset < outboundByteArray.count {
                    print("sending new packet: \(packetOffset)-\(byteArray.count)")
                    writePartialValue(value: outboundByteArray, offset: packetOffset)
                }
                
                if delegate != nil {
                    delegate.echoServer(messageReceived: stringValue)
                }
            }
        }
    }
    
    
    /**
     Servicess were discovered on the connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("services discovered")
        
        connectedPeripheral = peripheral
        connectedPeripheral.delegate = self
        
        if error != nil {
            print("Discover service Error: \(error)")
        } else {
            print("Discovered Service")
            for service in peripheral.services!{
                if service.uuid == EchoServer.serviceUuid {
                    connectedPeripheral.discoverCharacteristics([EchoServer.readCharacteristicUuid, EchoServer.writeCharacteristicUuid], for: service)
                }
            }
            print(peripheral.services!)
            print("DONE")
        }
        
    }
    
    
    /**
     Characteristics were discovered for a Service on the connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("characteristics discovered")
        connectedPeripheral = peripheral
        connectedPeripheral.delegate = self
        // grab the service
        let serviceIdentifier = service.uuid.uuidString
        
        
        print("service: \(serviceIdentifier)")
        
        
        if let characteristics = service.characteristics {

            print("characteristics found: \(characteristics.count)")
            for characteristic in characteristics {
                print("-> \(characteristic.uuid.uuidString)")
                //if characteristic.uuid.isEqual(EchoServer.characteristicUuid) {
                if characteristic.uuid.uuidString == EchoServer.writeCharacteristicUuid.uuidString {
                    print("matching uuid found for characteristic")
                    writeCharacteristic = characteristic
                    
                } else if characteristic.uuid.uuidString == EchoServer.readCharacteristicUuid.uuidString {
                    readCharacteristic = characteristic
                    
                    
                    if EchoServer.isCharacteristic(isNotifiable: characteristic) {
                        connectedPeripheral.setNotifyValue(true, for: characteristic)
                    }
                    
                }
                

                
            }
            // notify the delegate
            if readCharacteristic != nil && writeCharacteristic != nil {
                if delegate != nil {
                    delegate.echoServer(connectedToCharacteristics: [readCharacteristic, writeCharacteristic])
                }

            }
            
        }
        
    }
    
    
}
