//
//  Compass.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/19/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift

class Compass: NSObject, CLLocationManagerDelegate {

	static let shared = Compass()
	var magneticHeading: MutableProperty<CLLocationDirection> = MutableProperty(0.0)
	var lm: CLLocationManager!

	override init() {
		super.init()

		lm = CLLocationManager()
		lm.delegate = self

		lm.startUpdatingHeading()
	}

	func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		self.magneticHeading.value = newHeading.magneticHeading
	}

}
