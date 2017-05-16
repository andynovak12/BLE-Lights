//
//  Motion.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/25/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import Foundation
import CoreMotion
import ReactiveSwift

struct DegreeAttitude {
	var roll: Double
	var pitch: Double
	var yaw: Double
}

class Motion: NSObject {
	static let shared = Motion()
	var motionManager: CMMotionManager!
	var attitude: MutableProperty<DegreeAttitude?> = MutableProperty(nil)
	let updateInterval = 0.5

	override init() {
		super.init()
		self.motionManager = CMMotionManager()
		self.motionManager.deviceMotionUpdateInterval = self.updateInterval

		self.startReadingMotion()
	}

	func startReadingMotion() {
		self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (motionData, error) in
			if(error == nil) {
				self.handleDeviceMotionUpdate(motionData!)
			} else {
				print("Error: \(String(describing: error))")
			}
		}
	}

	func stopReadingMotion() {
		self.motionManager.stopDeviceMotionUpdates()
	}

	// MARK - Helpers 
	func handleDeviceMotionUpdate(_ deviceMotion:CMDeviceMotion) {
		let attitude = deviceMotion.attitude
		let roll = degrees(attitude.roll)
		let pitch = degrees(attitude.pitch)
		let yaw = degrees(attitude.yaw)
		self.attitude.value = DegreeAttitude(roll: roll, pitch: pitch, yaw: yaw)
	}

	func degrees(_ radians:Double) -> Double {
		return 180 / .pi * radians
	}
}

