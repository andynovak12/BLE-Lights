# BLE-Lights

##Explanation of Files in RaspPiCode:

#### LEDController.py
Contains the functions to control the LED strip

#### alarm_settings.txt
Acts as a datastore where:
1st line: Alarm time (empty for no alarm)
2nd line: Rise time - how many minutes it takes the lights to reach 100% brightness
3rd line: On length - how many minutes the lights stay on after reaching 100% brightness
4th line: Snooze length - how many minutes a snooze will delay the alarm
Note: The lights will be at 50% brightness at the alarm time

#### example_advertisement_gatt_server.py
A combination of https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/test/example-advertisement and https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/test/example-gatt-server
into one file

#### lights_ble_base.py
The necessary parts from example_advertisement_gatt_server.py that do not need to be changed

#### lights_main.py
The customized Bluetooth functions. This script will run at startup and perform Bluetooth related tasks

#### repeated_script.py
This script runs every minute and adjust the lights based on the alarm time
