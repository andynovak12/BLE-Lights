//
//  FirstViewController.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/19/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

	var brightnessValue: Int = 0
	var redValue: Int = 0
	var greenValue: Int = 0
	var blueValue: Int = 0

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	@IBAction func brightnessSliderValueChanged(_ sender: UISlider) {
		if abs(Int(sender.value) - self.brightnessValue) > 10 {
			self.brightnessValue = Int(sender.value)
			BluetoothManager.sharedInstance.setBrightness(value: self.brightnessValue)
		}

	}

	@IBAction func redSlider(_ sender: UISlider) {
		if abs(Int(sender.value) - self.redValue) > 10 {
			self.redValue = Int(sender.value)
			BluetoothManager.sharedInstance.setColor(red: self.redValue, green: self.greenValue, blue: self.blueValue)
		}
	}
	@IBAction func greenSlider(_ sender: UISlider) {
		if abs(Int(sender.value) - self.greenValue) > 10 {
			self.greenValue = Int(sender.value)
			BluetoothManager.sharedInstance.setColor(red: self.redValue, green: self.greenValue, blue: self.blueValue)
		}
	}
	@IBAction func blueSlider(_ sender: UISlider) {
		if abs(Int(sender.value) - self.blueValue) > 10 {
			self.blueValue = Int(sender.value)
			BluetoothManager.sharedInstance.setColor(red: self.redValue, green: self.greenValue, blue: self.blueValue)
		}
	}
}

