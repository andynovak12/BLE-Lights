//
//  PeripheralManager.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/19/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import Foundation
import CoreBluetooth

class PeripheralManager: NSObject {
	var peripheral: CBPeripheral
	let serviceUUID = CBUUID(string: "12345678") // defined in lights_main.py

	init(with peripheral: CBPeripheral) {
		self.peripheral = peripheral
		super.init()

		self.peripheral.delegate = self
	}

	func discoverServices() {
		self.peripheral.discoverServices([self.serviceUUID])
	}
}

extension PeripheralManager: CBPeripheralDelegate {
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print("did discover services: \(peripheral.services)")
		if let services = peripheral.services {
			for service in services {
				self.peripheral.discoverCharacteristics(nil, for: service)
			}
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
		print("did discover included services")
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		if let error = error {
			print("ERROR discovering characteristics: \(error.localizedDescription)")
		}
		if let characteristics = service.characteristics {
			for characteristic in characteristics {
				print("Characteristic: \(characteristic)")
			}
		}
	}

}
