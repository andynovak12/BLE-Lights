//
//  IntentHandler.swift
//  BluetoothLEDStripIntentionsTarget
//
//  Created by Andy Novak on 3/30/17.
//  Copyright © 2017 Andy Novak. All rights reserved.
//

import Intents

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

class IntentHandler: INExtension, INSendMessageIntentHandling {

	var alarmTime: (Int, Int)? = nil

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    // MARK: - INSendMessageIntentHandling
    
    // Implement resolution methods to provide additional information about your intent (optional).
    func resolveRecipients(forSendMessage intent: INSendMessageIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
//		guard let content = intent.content else {
//			// TODO: handle no content
//			print("No Content")
//			return
//		}
		if let content = intent.content {
			let times = extractNumbers(from: content)
			if times.count == 1 || times.count == 2 {
				print("got a number \(times.first!) \(String(describing: times.get(index: 1)))")
				var time = self.getTime(from: times.first!, secondNumber: times.get(index: 1))
				if intent.content?.contains("PM") ?? false {
					time.0 += 12
				}
				guard self.isValidated(hour: time.0, minute: time.1) else {
					// TODO: request better message
					print("Error: unformatted time")
					return
				}
				print("got a time! \(time)")
				self.alarmTime = time
			} else if times.isEmpty {
				// TODO: "which time do you want to set the alarm for"
				print("Couldn't get a time")
			} else {
				// TODO: "select which time do you want to set your alarm"
				print("there were too many times \(times)")
			}
		}
		let dummyRecipient = INPerson(personHandle: INPersonHandle(value: "Person value", type: .unknown), nameComponents: nil, displayName: nil, image: nil, contactIdentifier: nil, customIdentifier: nil)
		completion([INPersonResolutionResult.success(with: dummyRecipient)])
/*
        if let recipients = intent.recipients {
            
              // If no recipients were provided we'll need to prompt for a value.
            if recipients.count == 0 {
                completion([INPersonResolutionResult.needsValue()])
                return
            }
            
            var resolutionResults = [INPersonResolutionResult]()
            for recipient in recipients {
                let matchingContacts = [recipient] // Implement your contact matching logic here to create an array of matching contacts
                switch matchingContacts.count {
                case 2  ... Int.max:
                    // We need Siri's help to ask user to pick one from the matches.
                    resolutionResults += [INPersonResolutionResult.disambiguation(with: matchingContacts)]
                    
                case 1:
                    // We have exactly one matching contact
                    resolutionResults += [INPersonResolutionResult.success(with: recipient)]
                    
                case 0:
                    // We have no contacts matching the description provided
                    resolutionResults += [INPersonResolutionResult.unsupported()]
                    
                default:
                    break
                    
                }
            }
            completion(resolutionResults)
        }
*/
    }
    
    func resolveContent(forSendMessage intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let text = intent.content, !text.isEmpty {
			guard let alarmTime = self.alarmTime else {
				completion(INStringResolutionResult.success(with: "Sorry, I was unable to understand your alarm time."))
				return
			}
			BluetoothManager.sharedInstance.scanForPeripherals()
			var responseText = "Setting Alarm to \(alarmTime.0)"
			if alarmTime.1 > 0 {
				responseText += ":\(alarmTime.1)"
			}
			completion(INStringResolutionResult.success(with: responseText))
//			completion(INStringResolutionResult.success(with: text))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }
    
    // Once resolution is completed, perform validation on the intent and provide confirmation (optional).
    
    func confirm(sendMessage intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        // Verify user is authenticated and your app is ready to send a message.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSendMessageIntent.self))
        let response = INSendMessageIntentResponse(code: .ready, userActivity: userActivity)
        completion(response)
    }
    
    // Handle the completed intent (required).
    
    func handle(sendMessage intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        // Implement your application logic to send a message here.
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSendMessageIntent.self))
        let response = INSendMessageIntentResponse(code: .success, userActivity: userActivity)
		// HERE IS WHERE WE SEND THE COMMAND TO THE LIGHTS
		BluetoothManager.sharedInstance.isDeviceReady.producer.startWithValues { isReady in
			if isReady {
				if let hour = self.alarmTime?.0, let minute = self.alarmTime?.1 {
					BluetoothManager.sharedInstance.setAlarmTime(to: hour, minute: minute)
					BluetoothManager.sharedInstance.setColor(red: 50, green: 50, blue: 50)
					BluetoothManager.sharedInstance.setBrightness(value: 100)
					completion(response)
				} else {
					let response = INSendMessageIntentResponse(code: INSendMessageIntentResponseCode.failureRequiringAppLaunch, userActivity: userActivity)
					completion(response)
				}
			} else {
				print("Bluetooth device is not ready yet")
			}
		}
    }
    
    // Implement handlers for each intent you wish to handle.  As an example for messages, you may wish to also handle searchForMessages and setMessageAttributes.

	// MARK: Helper functions
	func extractNumbers(from string: String) -> [Int] {
		var extractedNumbers: [Int] = []
		// check if string contains digits (i.e. "set alarm to 8")
		let component = string.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
		extractedNumbers.append(contentsOf: component.filter({ $0 != "" }).flatMap { Int($0) })

		// check if string contains numbers as words (i.e. "set alarm to eight")
		for (index, numberWord) in numbersArray.enumerated() {
			if string.range(of: numberWord) != nil {
				extractedNumbers.append(index)
			}
		}
		return extractedNumbers
	}

	func getTime(from firstNumber: Int, secondNumber: Int?) -> (Int, Int) {
		// eight twenty could be [8, 20] or [820]
		let hour: Int
		let minute: Int
		if firstNumber > 24 {
			hour = firstNumber / 100
			minute = firstNumber % 100
		} else {
			hour = firstNumber
			minute = secondNumber ?? 0
		}
		return (hour, minute)
	}

	func isValidated(hour: Int, minute: Int) -> Bool {
		guard hour < 24, hour > 0, minute < 60, minute >= 0 else {
			return false
		}
		return true
	}
}

// from: http://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings
extension Array {
	// Safely lookup an index that might be out of bounds,
	// returning nil if it does not exist
	func get(index: Int) -> Element? {
		if 0 <= index && index < count {
			return self[index]
		} else {
			return nil
		}
	}
}
