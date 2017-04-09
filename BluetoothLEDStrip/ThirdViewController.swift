//
//  ThirdViewController.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/25/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import UIKit
import ReactiveSwift

class ThirdViewController: UIViewController {
	var isListeningToCompass = MutableProperty(false)
	var isListeningToAttitude = MutableProperty(false)
	@IBOutlet weak var magneticHeadingLabel: UILabel!

	@IBOutlet weak var startColorButton: UIButton!
	@IBOutlet weak var rgbLabel: UILabel!
	var lastHeading = 0.0
	var lastRed = 0.0
	var lastGreen = 0.0
	var lastBlue = 0.0

	let headingChangeThreshold = 5.0
	let colorChangeThreshold = 5.0

	@IBOutlet weak var startBrightnessButton: UIButton!

	override func viewDidLoad() {
        super.viewDidLoad()

		self.setupBrightnessListener()
		self.setupColorListener()
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		self.isListeningToCompass.value = false
		self.isListeningToAttitude.value = false
	}

	private func setupBrightnessListener() {
		let combinedProducer = SignalProducer.combineLatest(self.isListeningToCompass.producer,
		                                                    Compass.shared.magneticHeading.producer)
		combinedProducer.startWithValues { (isListening, heading) in
			if isListening {
				self.startBrightnessButton.setTitle("Stop Brightness", for: .normal)
				if abs(self.lastHeading - heading) > self.headingChangeThreshold {
					self.lastHeading = heading
					BluetoothManager.sharedInstance.setBrightness(value: Int((heading * 255)/360))
				}
				self.magneticHeadingLabel.text = "\(Int(self.lastHeading)) Degrees"
			} else {
				self.startBrightnessButton.setTitle("Start Brightness", for: .normal)
				self.magneticHeadingLabel.text = "North is off"
			}
		}
	}

	private func setupColorListener() {
		let combinedColorProducer = SignalProducer.combineLatest(self.isListeningToAttitude.producer,
		                                                         Motion.shared.attitude.producer)
		combinedColorProducer.startWithValues { (isListening, attitude) in
			if isListening {
				guard let attitude = attitude else { return }
				self.startColorButton.setTitle("Stop Color", for: .normal)
				let red = abs(attitude.pitch) * 255.0 / 180.0
				let blue = abs(attitude.yaw) * 255.0 / 180.0
				let green = abs(attitude.roll) * 255.0 / 180.0

				if (abs(red - self.lastRed) > self.colorChangeThreshold) ||
					(abs(blue - self.lastBlue) > self.colorChangeThreshold) ||
					(abs(green - self.lastGreen) > self.colorChangeThreshold) {
					self.lastGreen = green
					self.lastRed = red
					self.lastBlue = blue
					self.rgbLabel.text = "Red: \(Int(red)) | Green: \(Int(green)) | Blue: \(Int(blue)) "

					BluetoothManager.sharedInstance.setColor(red: Int(red), green: Int(green), blue: Int(blue))
				}
			} else {
				self.startColorButton.setTitle("Start Color", for: .normal)
			}
		}
	}

	@IBAction func startBrightnessButtonTapped(_ sender: UIButton) {
		self.isListeningToCompass.value = !self.isListeningToCompass.value
	}
	@IBAction func startColorButtonTapped(_ sender: Any) {
		self.isListeningToAttitude.value = !self.isListeningToAttitude.value
	}
}
