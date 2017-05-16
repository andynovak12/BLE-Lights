//
//  FirstViewController.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/19/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

class FirstViewController: UIViewController {

	@IBOutlet weak var powerSwitch: UISwitch!
	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var redSlider: UISlider!
	@IBOutlet weak var greenSlider: UISlider!
	@IBOutlet weak var blueSlider: UISlider!

	private var brightnessValue =	MutableProperty(0)
	private var redValue =			MutableProperty(0)
	private var greenValue =		MutableProperty(0)
	private var blueValue =			MutableProperty(0)
	private var previousBrightnessValue =	0
	private var previousRedValue =			0
	private var previousGreenValue =		0
	private var previousBlueValue =			0

	private let sliderThreshold =	5
	private let brightnessOnValue = 50
	private let colorsOnValue =		50

	override func viewDidLoad() {
		super.viewDidLoad()

		self.powerSwitch.addTarget(self, action: #selector(powerSwitchTappedHandler(notification:)), for: UIControlEvents.touchUpInside)
		self.brightnessSlider.addTarget(self, action: #selector(brightnessSliderHandler(notification:)), for: UIControlEvents.touchDragInside)
		self.redSlider.addTarget(self, action: #selector(redSliderHandler(notification:)), for: UIControlEvents.touchDragInside)
		self.greenSlider.addTarget(self, action: #selector(greenSliderHandler(notification:)), for: UIControlEvents.touchDragInside)
		self.blueSlider.addTarget(self, action: #selector(blueSliderHandler(notification:)), for: UIControlEvents.touchDragInside)

		self.brightnessValue.signal.observeValues { brightnessValue in
			self.powerSwitch.isOn = brightnessValue > 0
			self.brightnessSlider.value = Float(brightnessValue)
			if brightnessValue == 0 {
				BluetoothManager.sharedInstance.setBrightness(value: 0)
				self.previousBrightnessValue = brightnessValue
			} else if abs(self.previousBrightnessValue - brightnessValue) > self.sliderThreshold {
				BluetoothManager.sharedInstance.setBrightness(value: brightnessValue)
				if self.redValue.value == 0, self.greenValue.value == 0, self.blueValue.value == 0 {
					self.redValue.value = self.colorsOnValue
					self.greenValue.value = self.colorsOnValue
					self.blueValue.value = self.colorsOnValue
					self.previousRedValue = self.redValue.value
					self.previousGreenValue = self.greenValue.value
					self.previousBlueValue = self.blueValue.value

					BluetoothManager.sharedInstance.setColor(red: self.previousRedValue, green: self.previousGreenValue, blue: self.previousBlueValue)
				}
				self.previousBrightnessValue = brightnessValue
			}
		}

		let colorChangedSignal = Signal.combineLatest(self.redValue.signal, self.greenValue.signal, self.blueValue.signal)
		colorChangedSignal.observeValues { red, green, blue in
			self.redSlider.value = Float(red)
			self.greenSlider.value = Float(green)
			self.blueSlider.value = Float(blue)

			var sendNewColorValue = false

			if abs(red - self.previousRedValue) > self.sliderThreshold {
				self.previousRedValue = red
				sendNewColorValue = true
			}
			if abs(green - self.previousGreenValue) > self.sliderThreshold {
				self.previousGreenValue = green
				sendNewColorValue = true
			}
			if abs(blue - self.previousBlueValue) > self.sliderThreshold {
				self.previousBlueValue = blue
				sendNewColorValue = true
			}
			if sendNewColorValue {
				BluetoothManager.sharedInstance.setColor(red: self.previousRedValue, green: self.previousGreenValue, blue: self.previousBlueValue)
			}
		}

	}

	func powerSwitchTappedHandler(notification: UISwitch) {
		if !self.powerSwitch.isOn {
			self.brightnessValue.value = 0
		} else {
			self.brightnessValue.value = self.brightnessOnValue
		}
	}

	func brightnessSliderHandler(notification: UISlider) {
		self.brightnessValue.value = Int(notification.value)
	}
	func redSliderHandler(notification: UISlider) {
		self.redValue.value = Int(notification.value)
	}
	func greenSliderHandler(notification: UISlider) {
		self.greenValue.value = Int(notification.value)
	}
	func blueSliderHandler(notification: UISlider) {
		self.blueValue.value = Int(notification.value)
	}
}

