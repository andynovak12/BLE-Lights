//
//  PeripheralConstants.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/19/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK -- Services

let lightsAdvertisedServiceIdentifierUUID = CBUUID(string: "1234")				// defined in advertisment of lights_ble_base.py
let lightsServiceIdentifierUUID = CBUUID(string: "12345678")										// defined in lights_main.py

let alarmAdvertisedServiceIdentifierUUID = CBUUID(string: "2345")				// defined in advertisment of lights_ble_base.py
let alarmServiceIdentifierUUID = CBUUID(string: "23456781")											// defined in lights_main.py

// MARK -- Characteristics

let brightnessCharacteristicUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef1")			// defined in lights_main.py
let colorCharacteristicUUID = CBUUID(string: "12345678-1234-5678-1234-56789abcdef3")				// defined in lights_main.py

let setAlarmCharacteristicUUID = CBUUID(string: "a2345678-1234-5678-1234-56789abcdef1")				// defined in lights_main.py
let disableAlarmCharacteristicUUID = CBUUID(string: "a2345678-1234-5678-1234-56789abcdef3")			// defined in lights_main.py
let snoozeCharacteristicUUID = CBUUID(string: "a2345678-1234-5678-1234-56789abcdef5")				// defined in lights_main.py
let setSnoozeDurationCharacteristicUUID = CBUUID(string: "a2345678-1234-5678-1234-56789abcdef7")	// defined in lights_main.py


struct PeripheralCharacteristics {
	var brightnessCharacteristic: CBCharacteristic?
	var colorCharacteristic: CBCharacteristic?
	var setAlarmCharacteristic: CBCharacteristic?
	var disableAlarmCharacteristic: CBCharacteristic?
	var snoozeCharacteristic: CBCharacteristic?
	var setSnoozeDurationCharacteristic: CBCharacteristic?

	func allCharacteristics() -> [CBCharacteristic?] {
		return [brightnessCharacteristic,
		        colorCharacteristic,
		        setAlarmCharacteristic,
		        disableAlarmCharacteristic,
		        snoozeCharacteristic,
		        setSnoozeDurationCharacteristic]
	}
}
