//
//  MyTabBarViewController.swift
//  BluetoothLEDStrip
//
//  Created by Andy Novak on 3/25/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import UIKit
import APESuperHUD

class MyTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

		BluetoothManager.sharedInstance.scanForPeripherals()
		BluetoothManager.sharedInstance.isConnecting.producer.startWithValues { isConnecting in
			if isConnecting {
				APESuperHUD.showOrUpdateHUD(loadingIndicator: .standard,
				                            message: "Connecting to Bluetooth",
				                            presentingView: self.view)
			} else {
				APESuperHUD.showOrUpdateHUD(icon: UIImage(named: "bluetooth-logo")!, message: "Connected Successfully", duration: 1.0, presentingView: self.view, completion: {
					APESuperHUD.removeHUD(animated: true, presentingView: self.view, completion: nil)
				})
			}
		}

	}
}
