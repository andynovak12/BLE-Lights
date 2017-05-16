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

	private var brightnessValue = MutableProperty(0)
	private var previousBrightnessValue = 0
	private var redValue: Int = 0
	private var greenValue: Int = 0
	private var blueValue: Int = 0

	private let sliderThreshold = 5

	override func viewDidLoad() {
		super.viewDidLoad()

		self.powerSwitch.addTarget(self, action: #selector(powerSwitchTappedHandler(notification:)), for: UIControlEvents.touchUpInside)
		self.brightnessSlider.addTarget(self, action: #selector(brightnessSliderHandler(notification:)), for: UIControlEvents.touchDragInside)
		self.brightnessValue.signal.observeValues { brightnessValue in
			self.powerSwitch.isOn = brightnessValue > 0
			self.brightnessSlider.value = Float(brightnessValue)
			if brightnessValue == 0 {
				BluetoothManager.sharedInstance.setBrightness(value: 0)
				self.previousBrightnessValue = brightnessValue
			} else if abs(self.previousBrightnessValue - brightnessValue) > self.sliderThreshold {
				BluetoothManager.sharedInstance.setBrightness(value: brightnessValue)
				if self.redValue == 0, self.greenValue == 0, self.blueValue == 0 {
					BluetoothManager.sharedInstance.setColor(red: 50, green: 50, blue: 50)
				}
				self.previousBrightnessValue = brightnessValue
			}
		}
	}

	func powerSwitchTappedHandler(notification: UISwitch) {
		if !self.powerSwitch.isOn {
			self.brightnessValue.value = 0
		} else {
			self.brightnessValue.value = 50
		}
	}

	func brightnessSliderHandler(notification: UISlider) {
		self.brightnessValue.value = Int(notification.value)
	}

	@IBAction func redSlider(_ sender: UISlider) {
		if abs(Int(sender.value) - self.redValue) > self.sliderThreshold {
			self.redValue = Int(sender.value)
			BluetoothManager.sharedInstance.setColor(red: self.redValue, green: self.greenValue, blue: self.blueValue)
		}
	}
	@IBAction func greenSlider(_ sender: UISlider) {
		if abs(Int(sender.value) - self.greenValue) > self.sliderThreshold {
			self.greenValue = Int(sender.value)
			BluetoothManager.sharedInstance.setColor(red: self.redValue, green: self.greenValue, blue: self.blueValue)
		}
	}
	@IBAction func blueSlider(_ sender: UISlider) {
		if abs(Int(sender.value) - self.blueValue) > self.sliderThreshold {
			self.blueValue = Int(sender.value)
			BluetoothManager.sharedInstance.setColor(red: self.redValue, green: self.greenValue, blue: self.blueValue)
		}
	}
}

