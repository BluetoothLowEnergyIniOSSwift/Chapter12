//
//  CharacteristicViewController.swift
//  ReadCharacteristic
//
//  Created by Adonis Gaitatzis on 11/22/16.
//  Copyright © 2016 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 This view talks to a Bluetooth Echo Server
 */
class CharacteristicViewController: UIViewController, CBCentralManagerDelegate, EchoServerDelegate {
    
    // MARK: UI Elements
    @IBOutlet weak var characteristicValueText: UITextView!
    @IBOutlet weak var writeCharacteristicButton: UIButton!
    @IBOutlet weak var writeCharacteristicText: UITextField!
    
    
    // MARK: Bluetooth stuff
    
    // Bluetooth features
    var centralManager:CBCentralManager!
    
    // the EchoServer
    var echoServer:EchoServer!

    
    /**
     View loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    /**
     Write button pressed
     */
    @IBAction func onWriteCharacteristicButtonTouchUp(_ sender: UIButton) {
        print("write button pressed")
        
        if let string = writeCharacteristicText.text {
            //let value = string.data(using: .utf8)
            
            print(string)
            
            echoServer.writeValue(value: string)
            //, peripheral: connectedPeripheral, characteristic: connectedCharacteristic)

            writeCharacteristicText.text = ""
        }
    }
    
    
    // MARK: EchoServerDelegate
    
    
    /**
     Message received from EchoServer.  Update UI
     */
    func echoServer(messageReceived stringValue: String) {
        characteristicValueText.insertText(stringValue)
        
        let stringLength = characteristicValueText.text.characters.count
        characteristicValueText.scrollRangeToVisible(NSMakeRange(stringLength-1, 0))    }
    
    
    /**
     Characteristic was connected on the EchoServer. Update UI
     */
    func echoServer(connectedToCharacteristics characteristics: [CBCharacteristic]) {
        for characteristic in characteristics {
            print(" characteristic: -> \(characteristic.uuid.uuidString): \(characteristic.properties.rawValue)")
        
            if EchoServer.isCharacteristic(isWriteable: characteristic) {
                writeCharacteristicText.isEnabled = true
                writeCharacteristicButton.isEnabled = true
            }
        }
    }
    
    
    // MARK: CBCentralManagerDelegate
    
    /**
     centralManager is called each time a new Peripheral is discovered
     
     - parameters
     - central: the CentralManager for this UIView
     - peripheral: A discovered Peripheral
     - advertisementData: The Bluetooth advertisement data discevered with the Peripheral
     - rssi: the radio signal strength indicator for this Peripheral
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("Discovered \(peripheral.name)")
        print("Discovered \(peripheral.identifier.uuidString) (\(peripheral.name))")
        
        echoServer = EchoServer(delegate: self, peripheral: peripheral)
        
        // find the advertised name
        if let advertisedName = EchoServer.getNameFromAdvertisementData(advertisementData: advertisementData) {
            if advertisedName == EchoServer.advertisedName {
                print("connecting to peripheral...")
                centralManager.connect(peripheral, options: nil)
            }
        }
        
    }
    
    
    /**
     Peripheral connected.
     
     - Parameters:
     - central: the reference to the central
     - peripheral: the connected Peripheral
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected Peripheral: \(peripheral.name)")
        
        // Do any additional setup after loading the view.
        echoServer.connected(peripheral: peripheral)
        
    }

    
    /**
     Peripheral disconnected
     
     - Parameters:
     - central: the reference to the central
     - peripheral: the connected Peripheral
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // disconnected.  Leave
        print("disconnected")
        writeCharacteristicButton.isEnabled = false
    }
    
    
    /**
     Bluetooth radio state changed
     
     - Parameters:
     - central: the reference to the central
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager updated: checking state")
        
        switch (central.state) {
        case .poweredOn:
            print("bluetooth on")
            central.scanForPeripherals(withServices: [EchoServer.serviceUuid], options: nil)
        default:
            print("bluetooth unavailable")
        }
    }
    
    

}
