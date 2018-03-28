#!/usr/bin/python

import dbus
import dbus.exceptions
import dbus.mainloop.glib
import dbus.service
import time

from lights_ble_base import *
import LEDController

mainloop = None

class Application(dbus.service.Object):
    """
    org.bluez.GattApplication1 interface implementation
    """
    def __init__(self, bus):
        self.path = '/'
        self.services = []
        dbus.service.Object.__init__(self, bus, self.path)
        self.add_service(LightService(bus, 0))
        self.add_service(AlarmService(bus, 1))

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_service(self, service):
        self.services.append(service)

    @dbus.service.method(DBUS_OM_IFACE, out_signature='a{oa{sa{sv}}}')
    def GetManagedObjects(self):
        response = {}
        print('GetManagedObjects')

        for service in self.services:
            response[service.get_path()] = service.get_properties()
            chrcs = service.get_characteristics()
            for chrc in chrcs:
                response[chrc.get_path()] = chrc.get_properties()
                descs = chrc.get_descriptors()
                for desc in descs:
                    response[desc.get_path()] = desc.get_properties()

        return response


class LightService(Service):
    """
    Service for controlling the lights

    """
    TEST_SVC_UUID = '12345678'

    def __init__(self, bus, index):
        Service.__init__(self, bus, index, self.TEST_SVC_UUID, True)
        self.add_characteristic(LEDBrightnessCharacteristic(bus, 0, self))
        self.add_characteristic(LEDColorCharacteristic(bus, 1, self))


class LEDBrightnessCharacteristic(Characteristic):
    """
    Characteristic to control brightness of LED strip.
    Values from 0-255
    """
    TEST_CHRC_UUID = '12345678-1234-5678-1234-56789abcdef1'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TEST_CHRC_UUID,
                ['read', 'write', 'writable-auxiliaries'],
                service)
        self.value = []
        self.add_descriptor(TestDescriptor(bus, 0, self))
        self.add_descriptor(
                CharacteristicUserDescriptionDescriptor(bus, 1, self, 'LED Strip Brightness 0-255'))

    def ReadValue(self, options):
        print('LEDBrightnessCharacteristic Read: ' + repr(self.value))
        return self.value

    def WriteValue(self, value, options):
        print('LEDBrightnessCharacteristic Write: ' + repr(value))
        self.value = value
        LEDController.setBrightnessOfStrip(int(value[0]))

class LEDColorCharacteristic(Characteristic):
    """
    Characteristic to control color of LED strip.
    Values RRGGBB where RR is hex value for red, GG is hex value for green, and BB is hex value for blue
    """
    TEST_CHRC_UUID = '12345678-1234-5678-1234-56789abcdef3'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TEST_CHRC_UUID,
                ['read', 'write', 'writable-auxiliaries'],
                service)
        self.value = []
        self.add_descriptor(TestDescriptor(bus, 0, self))
        self.add_descriptor(
                CharacteristicUserDescriptionDescriptor(bus, 1, self, 'LED Strip Color In Hex'))

    def ReadValue(self, options):
        print('LEDColorCharacteristic Read: ' + repr(self.value))
        return self.value

    def WriteValue(self, value, options):
        print('LEDColorCharacteristic Write: ' + repr(value))
        self.value = value
        LEDController.colorAllPixels(int(value[0]), int(value[1]), int(value[2]))

class AlarmService(Service):
    """
    Service for controlling the lights

    """
    TEST_SVC_UUID = '23456781'

    def __init__(self, bus, index):
        Service.__init__(self, bus, index, self.TEST_SVC_UUID, True)
        self.add_characteristic(SetAlarmCharacteristic(bus, 0, self))
        self.add_characteristic(DisableAlarmCharacteristic(bus, 1, self))
        self.add_characteristic(SnoozeCharacteristic(bus, 2, self))
        self.add_characteristic(SetSnoozeDurationCharacteristic(bus, 3, self))

class SetAlarmCharacteristic(Characteristic):
    """
    Characteristic to set time of alarm.
    Values = (hour (in 24hour), minute)
    """
    TEST_CHRC_UUID = 'a2345678-1234-5678-1234-56789abcdef1'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TEST_CHRC_UUID,
                ['read', 'write', 'writable-auxiliaries', 'notify'],
                service)
        self.value = []
        self.notifying = False
        self.add_descriptor(TestDescriptor(bus, 0, self))
        self.add_descriptor(
                CharacteristicUserDescriptionDescriptor(bus, 1, self, 'Set Alarm (hour, minute)'))

    def ReadValue(self, options):
        print('SetAlarmCharacteristic Read: ' + repr(self.value))
        return self.value

    def WriteValue(self, value, options):
        print('SetAlarmCharacteristic Write: ' + repr(value))
        self.value = value
        LEDController.setAlarm(int(value[0]), int(value[1]))
        self.notify_alarm_time()

    def notify_alarm_time(self):
        if not self.notifying:
            return
        self.PropertiesChanged(GATT_CHRC_IFACE, { 'Value': self.value }, [])

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_alarm_time()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False
        self.notify_alarm_time()

class DisableAlarmCharacteristic(Characteristic):
    """
    Characteristic to turn off alarm.
    Send any value to turn off alarm
    """
    TEST_CHRC_UUID = 'a2345678-1234-5678-1234-56789abcdef3'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TEST_CHRC_UUID,
                ['read', 'write', 'writable-auxiliaries', 'notify'],
                service)
        self.value = []
        self.notifying = False
        self.add_descriptor(TestDescriptor(bus, 0, self))
        self.add_descriptor(
                CharacteristicUserDescriptionDescriptor(bus, 1, self, 'Turn off alarm'))

    def ReadValue(self, options):
        print('DisableAlarmCharacteristic Read: ' + repr(self.value))
        return self.value

    def WriteValue(self, value, options):
        print('DisableAlarmCharacteristic Write: ' + repr(value))
        self.value = value
        LEDController.disableAlarm()
        self.notify_alarm_off()

    def notify_alarm_off(self):
        if not self.notifying:
            return
        self.PropertiesChanged(GATT_CHRC_IFACE, { 'Value': self.value }, [])

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_alarm_off()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False
        self.notify_alarm_off()

class SnoozeCharacteristic(Characteristic):
    """
    Characteristic to snooze the alarm.
    Any value will snooze the alarm.
    """
    TEST_CHRC_UUID = 'a2345678-1234-5678-1234-56789abcdef5'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TEST_CHRC_UUID,
                ['read', 'write', 'writable-auxiliaries'],
                service)
        self.value = []
        self.add_descriptor(TestDescriptor(bus, 0, self))
        self.add_descriptor(
                CharacteristicUserDescriptionDescriptor(bus, 1, self, 'Snooze the alarm'))

    def ReadValue(self, options):
        print('SnoozeCharacteristic Read: ' + repr(self.value))
        return self.value

    def WriteValue(self, value, options):
        print('SnoozeCharacteristic Write: ' + repr(value))
        self.value = value
        LEDController.snooze()

class SetSnoozeDurationCharacteristic(Characteristic):
    """
    Characteristic to set snooze duration of the alarm.
    Value in minutes.
    """
    TEST_CHRC_UUID = 'a2345678-1234-5678-1234-56789abcdef7'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TEST_CHRC_UUID,
                ['read', 'write', 'writable-auxiliaries'],
                service)
        self.value = []
        self.add_descriptor(TestDescriptor(bus, 0, self))
        self.add_descriptor(
                CharacteristicUserDescriptionDescriptor(bus, 1, self, 'Set the snooze duration'))

    def ReadValue(self, options):
        print('SetSnoozeDurationCharacteristic Read: ' + repr(self.value))
        return self.value

    def WriteValue(self, value, options):
        print('SetSnoozeDurationCharacteristic Write: ' + repr(value))
        self.value = value
        LEDController.changeSnoozeDuration(int(value[0]))


def register_app_error_cb(error):
    print('Failed to register application: ' + str(error))
    mainloop.quit()

def main():
    global mainloop

	time.sleep(5)

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()

    adapter = find_adapter(bus)
    if not adapter:
        print 'LEAdvertisingManager1 interface not found'
        return

    # ADVERTISE

    adapter_props = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                   "org.freedesktop.DBus.Properties");

    adapter_props.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(1))

    ad_manager = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                LE_ADVERTISING_MANAGER_IFACE)

    test_advertisement = TestAdvertisement(bus, 0)


    # Service
    service_manager = dbus.Interface(
            bus.get_object(BLUEZ_SERVICE_NAME, adapter),
            GATT_MANAGER_IFACE)

    app = Application(bus)

    mainloop = gobject.MainLoop()

    ad_manager.RegisterAdvertisement(test_advertisement.get_path(), {},
                                     reply_handler=register_ad_cb,
                                     error_handler=register_ad_error_cb)

    print('Registering GATT application...')

    service_manager.RegisterApplication(app.get_path(), {},
                                reply_handler=register_app_cb,
                                error_handler=register_app_error_cb)


    print('Starting LED Strip Initialization')
    LEDController.initializeStrip()

    mainloop.run()

if __name__ == '__main__':
    main()
