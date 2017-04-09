//
//  SecondViewController.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/19/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import UIKit

struct AlarmComponents {
	var hour: Int
	var minute: Int

	init(hour: Int, minute: Int) {
		self.hour = hour
		self.minute = minute
	}
}

class SecondViewController: UIViewController {
	@IBOutlet weak var alarmPicker: UIDatePicker!
	@IBOutlet weak var snoozeButton: UIButton!
	@IBOutlet weak var snoozeDurationTextField: UITextField!
	@IBOutlet weak var alarmTimeLabel: UILabel!
	var snoozeDuration: Int?
	var alarmTime: AlarmComponents?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.snoozeDurationTextField.delegate = self
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		self.view.addGestureRecognizer(tap)

		BluetoothManager.sharedInstance.setAlarmTime.producer.startWithValues { alarm in
			if let alarm = alarm {
				self.alarmTimeLabel.text = "Alarm time: \(String(format: "%02d", alarm.hour)):\(String(format: "%02d", alarm.minute))"
			} else {
				self.alarmTimeLabel.text = "Alarm time: ---"
			}
		}
	}

	func dismissKeyboard() {
		view.endEditing(true)
	}

	@IBAction func setAlarmTapped(_ sender: Any) {
		let date = self.alarmPicker.date
		let calendar = Calendar.current
		let hour = calendar.component(.hour, from: date)
		let minutes = calendar.component(.minute, from: date)
		BluetoothManager.sharedInstance.setAlarmTime(to: hour, minute: minutes)
		self.alarmTimeLabel.text = "Setting Alarm..."
	}

	@IBAction func disableAlarmTapped(_ sender: UIButton) {
		BluetoothManager.sharedInstance.disableAlarm()
		self.alarmTimeLabel.text = "Disabling Alarm..."
	}

	@IBAction func snoozeTapped(_ sender: Any) {
		BluetoothManager.sharedInstance.performSnooze()
	}

}

extension SecondViewController: UITextFieldDelegate {
	func textFieldDidEndEditing(_ textField: UITextField) {
		guard let inputtedText = textField.text, let inputtedAmount = Int(inputtedText) else {
			return
		}
		if self.snoozeDuration == nil || inputtedAmount != snoozeDuration {
			self.snoozeDuration = inputtedAmount
			BluetoothManager.sharedInstance.setSnoozeDuration(in: inputtedAmount)
		}
	}
}
