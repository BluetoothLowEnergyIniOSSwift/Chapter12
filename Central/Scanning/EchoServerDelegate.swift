//
//  EchoServerDelegate.swift
//  EchoClient
//
//  Created by Adonis Gaitatzis on 11/29/16.
//  Copyright © 2016 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 EchoServerDelegate relays important status changes from EchoServer
 */
protocol EchoServerDelegate {
    
    /**
     Message received from Echo Server
     
     - Parameters:
     - stringValue: the value read from the Charactersitic
     */
    func echoServer(messageReceived stringValue: String)
    
    /**
     Connection to characteristics was successful
     
     - Parameters:
     - characteristic: the Characteristic that was subscribed or unsubscribed from
     */
    func echoServer(connectedToCharacteristics characteristics: [CBCharacteristic])
}
