//
//  BluetoothManager.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/19/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import Foundation
import CoreBluetooth
import ReactiveSwift

struct AlarmComponents {
	var hour: Int
	var minute: Int

	init(hour: Int, minute: Int) {
		self.hour = hour
		self.minute = minute
	}
}

class BluetoothManager: NSObject {
	static let sharedInstance = BluetoothManager()

	var manager: CBCentralManager!
	var peripheral: CBPeripheral?
	var isConnecting = MutableProperty(false)
	var isDeviceReady = MutableProperty(false)
	var setAlarmTime: MutableProperty<AlarmComponents?> = MutableProperty(nil)

	var peripheralCharacteristics = PeripheralCharacteristics()

	var isBluetoothReady = false
	fileprivate var onBluetoothReady: (() -> Void)?

	override init() {
		super.init()
		self.manager = CBCentralManager(delegate: self, queue: nil, options: nil)
	}

	func scanForPeripherals() {
		self.isConnecting.value = true
		if isBluetoothReady {
			self.manager.scanForPeripherals(withServices: [lightsAdvertisedServiceIdentifierUUID], options: nil)
		} else {
			self.onBluetoothReady = {
				self.manager.scanForPeripherals(withServices: [lightsAdvertisedServiceIdentifierUUID], options: nil)
			}
			
		}
	}

	// Set brightness from 0-255
	func setBrightness(value: Int) {
		var byteValue = value
		let data = Data(buffer: UnsafeBufferPointer(start: &byteValue, count: 1))
		print("Brightness " + data.hex())
		self.peripheral?.writeValue(data, for: (self.peripheralCharacteristics.brightnessCharacteristic)!, type: .withResponse)
	}

	// RGB values from 0-255
	func setColor(red: Int, green: Int, blue: Int) {
		print("red: \(red) green: \(green) blue: \(blue)")
		var decimalTotal = (blue * 65536) + (green * 256) + red
		let data = Data(buffer: UnsafeBufferPointer(start: &decimalTotal, count: 1))
		print("Color " + data.hex())
		self.peripheral?.writeValue(data, for: (self.peripheralCharacteristics.colorCharacteristic)!, type: .withResponse)
	}

	func setAlarmTime(to hour: Int, minute: Int) {
		if hour > 23 || hour < 0 {
			print("Error! Hour is outside of range")
			return
		}
		if minute > 59 || minute < 0 {
			print("Error! Minute is outside of range")
			return
		}
		var decimalTotal = (minute * 256) + hour
		let data = Data(buffer: UnsafeBufferPointer(start: &decimalTotal, count: 1))
		self.peripheral?.writeValue(data, for: (self.peripheralCharacteristics.setAlarmCharacteristic)!, type: .withResponse)
	}

	func disableAlarm() {
		var anyValue = 0
		let data = Data(buffer: UnsafeBufferPointer(start: &anyValue, count: 1))
		self.peripheral?.writeValue(data, for: (self.peripheralCharacteristics.disableAlarmCharacteristic)!, type: .withResponse)
	}

	func performSnooze() {
		var anyValue = 0
		let data = Data(buffer: UnsafeBufferPointer(start: &anyValue, count: 1))
		self.peripheral?.writeValue(data, for: (self.peripheralCharacteristics.snoozeCharacteristic)!, type: .withResponse)
	}

	func setSnoozeDuration(in minutes: Int) {
		var byteValue = Int(String(minutes), radix: 16)!
		let data = Data(buffer: UnsafeBufferPointer(start: &byteValue, count: 1))
		self.peripheral?.writeValue(data, for: (self.peripheralCharacteristics.setSnoozeDurationCharacteristic)!, type: .withResponse)
	}

}

extension BluetoothManager: CBCentralManagerDelegate {
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
		case .poweredOff:
			print("CoreBluetooth BLE hardware is powered off")
			self.isBluetoothReady = false
		case .poweredOn:
			print("CoreBluetooth BLE hardware is powered on and ready")
			self.isBluetoothReady = true
			self.onBluetoothReady?()
		case .resetting:
			print("CoreBluetooth BLE hardware is resetting")
		case .unauthorized:
			print("CoreBluetooth BLE state is unauthorized")
		case .unknown:
			print("CoreBluetooth BLE state is unknown")
		case .unsupported:
			print("CoreBluetooth BLE hardware is unsupported on this platform")
		}
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		print("Discovered: \(String(describing: peripheral.name)) / RSSI: \(RSSI)")
		self.peripheral = peripheral
		self.manager.stopScan()
		self.manager.connect(peripheral, options: nil)
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print("Connected: \(peripheral)")
		self.manager.stopScan()
		self.peripheral = peripheral
		self.peripheral?.delegate = self
		self.peripheral?.discoverServices([lightsServiceIdentifierUUID, alarmServiceIdentifierUUID])
	}

	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		print("Connection Failed: \(peripheral)")
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		print("Disconnected: \(peripheral)")
	}
}

extension BluetoothManager: CBPeripheralDelegate {
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print("did discover services: \(String(describing: peripheral.services))")
		if let services = peripheral.services {
			for service in services {
				self.peripheral!.discoverCharacteristics(nil, for: service)
			}
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		if let error = error {
			print("ERROR discovering characteristics: \(error.localizedDescription)")
		}
		if let characteristics = service.characteristics {
			for characteristic in characteristics {
				self.peripheral!.setNotifyValue(true, for: characteristic)
				if characteristic.uuid == brightnessCharacteristicUUID {
					self.peripheralCharacteristics.brightnessCharacteristic = characteristic
				} else if characteristic.uuid == colorCharacteristicUUID {
					self.peripheralCharacteristics.colorCharacteristic = characteristic
				} else if characteristic.uuid == setAlarmCharacteristicUUID {
					self.peripheralCharacteristics.setAlarmCharacteristic = characteristic
				} else if characteristic.uuid == disableAlarmCharacteristicUUID {
					self.peripheralCharacteristics.disableAlarmCharacteristic = characteristic
				} else if characteristic.uuid == snoozeCharacteristicUUID {
					self.peripheralCharacteristics.snoozeCharacteristic = characteristic
				} else if characteristic.uuid == setSnoozeDurationCharacteristicUUID {
					self.peripheralCharacteristics.setSnoozeDurationCharacteristic = characteristic
				}
			}

		}
		let allCharacteristicsSet = !self.peripheralCharacteristics.allCharacteristics().contains{$0 == nil}
		if allCharacteristicsSet {
			self.isConnecting.value = false
			self.isDeviceReady.value = true
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		if characteristic.uuid == setAlarmCharacteristicUUID {
			let dataString = characteristic.value!.hex()
			print("set alarm: \(dataString)")
			let hourIndex = dataString.index(dataString.startIndex, offsetBy: 2)
			let hourHexString = dataString.substring(to: hourIndex)

			let range = dataString.range(of: dataString)
			let lo = dataString.index(range!.lowerBound, offsetBy: 2)
			let hi = dataString.index(range!.lowerBound, offsetBy: 4)
			let subRange = lo ..< hi
			let minuteHexString = dataString[subRange]

			// convert hex string to int
			let hour = Int(UInt8(hourHexString, radix: 16)!)
			let minute = Int(UInt8(minuteHexString, radix: 16)!)
			print("alarm set  \(hour) + \(minute)")
			self.setAlarmTime.value = AlarmComponents(hour: hour, minute: minute)

		} else if characteristic.uuid == disableAlarmCharacteristicUUID {
			print("Alarm disabled")
			self.setAlarmTime.value = nil
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		if characteristic.uuid == setAlarmCharacteristicUUID {
			print("Notification updated for \(characteristic)")
		}
//		print("Notification state changed for characteristic: \(characteristic)")
	}

}

extension Data {
	func hex() -> String {
		return map { String(format: "%02hhx", $0) }.joined()
	}
}
