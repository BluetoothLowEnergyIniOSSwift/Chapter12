//
//  ViewController.swift
//  sketch
//
//  Created by Adonis Gaitatzis on 1/9/17.
//  Copyright © 2017 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 This view displays the state of a BlePeripheral
 */
class ViewController: UIViewController, EchoServerPeripheralDelegate {
    
    // MARK: UI Elements
    @IBOutlet weak var advertisingLabel: UILabel!
    @IBOutlet weak var advertisingSwitch: UISwitch!
    @IBOutlet weak var characteristicLogText: UITextView!

    
    // MARK: BlePeripheral
    
    // BlePeripheral
    var echoServer:EchoServerPeripheral!
    
    
    
    /**
     UIView loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()        
    }
    
    /**
     View appeared.  Start the Peripheral
     */
    override func viewDidAppear(_ animated: Bool) {
        echoServer = EchoServerPeripheral(delegate: self)
        
        advertisingLabel.text = echoServer.advertisingName
    }
    
    /**
     View will appear.  Stop transmitting random data
     */
    override func viewWillDisappear(_ animated: Bool) {
        echoServer.stop()
    }
    
    /**
     View disappeared.  Stop advertising
     */
    override func viewDidDisappear(_ animated: Bool) {
        advertisingSwitch.setOn(false, animated: true)
    }

    // MARK: BlePeripheralDelegate
    
    
    /**
     Echo Server state changed
     
     - Parameters:
     - state: the CBManagerState representing the new state
     */
    func echoServerPeripheral(stateChanged state: CBManagerState) {
        switch (state) {
        case CBManagerState.poweredOn:
            print("Bluetooth on")
        case CBManagerState.poweredOff:
            print("Bluetooth off")
        default:
            print("Bluetooth not ready yet...")
        }
    }
    
    
    /**
     EchoServerPeripheral statrted adertising
     
     - Parameters:
     - error: the error message, if any
     */
    func echoServerPeripheral(startedAdvertising error: Error?) {
        if error != nil {
            print("Problem starting advertising: " + error.debugDescription)
        } else {
            print("adertising started")
            advertisingSwitch.setOn(true, animated: true)
        }
    }
    
    
    /**
     Value written to Characteristic
     
     - Parameters:
     - stringValue: the value read from the Charactersitic
     - characteristic: the Characteristic that was written to
     */
    func echoServerPeripheral(valueWritten value: Data, toCharacteristic: CBCharacteristic) {
        print("converting data to String")
        let stringValue = String(data: value, encoding: .utf8)
        if let stringValue = stringValue {
            print("writing to textview")
            characteristicLogText.text = characteristicLogText.text + "\n" + stringValue
            
            if !characteristicLogText.text.isEmpty {
                characteristicLogText.scrollRangeToVisible(NSMakeRange(0, 1))
            }
        }
    }
    
}

