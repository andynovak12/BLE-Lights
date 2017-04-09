import time, datetime, re
import os, sys
import psutil, math
from neopixel import *

# LED strip configuration:
LED_COUNT      = 150      # Number of LED pixels.
LED_PIN        = 18      # GPIO pin connected to the pixels (must support PWM!).
LED_FREQ_HZ    = 800000  # LED signal frequency in hertz (usually 800khz)
LED_DMA        = 5       # DMA channel to use for generating signal (try 5)
LED_BRIGHTNESS = 100     # Set to 0 for darkest and 255 for brightest
LED_INVERT     = False   # True to invert the signal (when using NPN transistor level shift)

globalStrip = None

# Alarm configuration:
globalAlarmTime = None
riseTimeInMinutes = 15
onTimeAfterMaxInMinutes = 20
globalSnoozeDuration = 10


# Interacting with data store file
def readAlarmSettings():
    dataStore = open('/home/pi/alarm_settings.txt', 'r')
    alarmSettingsStringLines = dataStore.readlines()
    alarmTimeString = alarmSettingsStringLines[0]
    global globalAlarmTime
    if alarmTimeString.isspace():
        globalAlarmTime = None
    else:
        hourMinuteArray = [x.strip() for x in alarmTimeString.split(',')]
        hour = int(hourMinuteArray[0])
        minute = int(hourMinuteArray[1])
        global globalAlarmTime
        globalAlarmTime = datetime.datetime(2008, 1, 1, hour, minute, 0) # date doesn't matter

    riseTimeString = alarmSettingsStringLines[1]
    global riseTimeInMinutes
    riseTimeInMinutes = int(riseTimeString)

    onTimeString = alarmSettingsStringLines[2]
    global onTimeAfterMaxInMinutes
    onTimeAfterMaxInMinutes = int(onTimeString)

    snoozeDurationString = alarmSettingsStringLines[3]
    global globalSnoozeDuration
    globalSnoozeDuration = int(snoozeDurationString)
    print(globalAlarmTime, riseTimeInMinutes, onTimeAfterMaxInMinutes, globalSnoozeDuration)

def writeAlarmTimeToFile(hour, minute):
    newString = str(hour)+ ' , ' + str(minute)
    replaceLineWithString(1, newString)

def writeEmptyToAlarmTimeToFile():
    replaceLineWithString(1, ' ')

def writeSnoozeDurationToFile(newDuration):
    replaceLineWithString(4, str(newDuration))

def replaceLineWithString(lineNumber, newString):
    f = open('/home/pi/alarm_settings.txt', 'r')    # pass an appropriate path of the required file
    lines = f.readlines()
    lines[lineNumber-1] = newString + '\n'    # n is the line number you want to edit; subtract 1 as indexing of list starts from 0
    f.close()   # close the file and reopen in write mode to enable writing to file; you can also open in append mode and use "seek", but you will have some unwanted old data if the new data is shorter in length.

    f = open('/home/pi/alarm_settings.txt', 'w')
    f.writelines(lines)
    f.close()

#interacting with LED Strip
def turnOffLEDs():
        globalStrip.begin()
        print('Turning off leds')
        globalStrip.setBrightness(0)
        globalStrip.show()

def colorAllPixelsOff(color):
        globalStrip.begin()
        for i in range(globalStrip.numPixels()):
                globalStrip.setPixelColor(i, color)
        globalStrip.setBrightness(0)
        globalStrip.show()

def colorAllPixels(red, green, blue):
        globalStrip.begin()
        print('Coloring all pixels to red: ',red, 'green ',green, 'blue ',blue)
        for i in range(globalStrip.numPixels()):
                globalStrip.setPixelColor(i, Color(green, red, blue))
        globalStrip.show()

def colorAllPixelsWithBrightness(red, green, blue, brightness):
        globalStrip.begin()
        redInt = int(red)
        greenInt = int(green)
        blueInt = int(blue)
        print('Coloring all pixels to red: ',redInt, 'green ',greenInt, 'blue ',blueInt, 'brightness', brightness)
        for i in range(globalStrip.numPixels()):
                globalStrip.setPixelColor(i, Color(greenInt, redInt, blueInt))
        globalStrip.setBrightness(int(brightness))
        globalStrip.show()

def setBrightnessOfStrip(value):
        print('setting brightness to ', value)
        globalStrip.setBrightness(int(value))
        globalStrip.show()

def getColors(hours, minutes):
# convert time to temp (k). 7am = 2000K. 12am = 5500K

  # only allow time to be within range
  if hours < 7:
        hours = 7

  temp_k = 2000 + (3500 * (60*(hours-7)+minutes)/ ((12-7)*60))
  # convert temp (k) to RGB
  mid_temp = temp_k / 100
  red = 255

  green = 99.4708025861 * math.log(mid_temp) - 161.1195681661
  if green < 0 :
    green = 0
  elif green > 255 :
    green = 255

  blue = 0
  if mid_temp <= 19:
    blue = 0
  else:
    blue = mid_temp - 10
    blue = 138.5177312231 * math.log(blue) - 305.0447927307
    if blue < 0:
      blue = 0
    elif blue > 255:
      blue = 255

  return (red, green, blue)

def minutesBetweenDates(firstDate, secondDate):
    firstRounded = firstDate.replace(second = 0, microsecond = 0)
    secondRounded = secondDate.replace(second = 0, microsecond = 0)
    d = firstRounded - secondRounded
    minutes = d.seconds / 60
    if minutes > 12*60: # half day
        minutes = minutes - 24*60
    return minutes

def getBrightness():
    if globalAlarmTime is None:
        print("globalAlarmTime is not set")
        return
    else:
        now = datetime.datetime.now()
        timeAfterAlarmInMinutes = minutesBetweenDates(now, globalAlarmTime)
        halfRiseTime = (0.5)*riseTimeInMinutes
        if timeAfterAlarmInMinutes < (-1)*halfRiseTime:
            return
        elif timeAfterAlarmInMinutes >= (-1)*halfRiseTime and timeAfterAlarmInMinutes <= halfRiseTime:
            return ((timeAfterAlarmInMinutes + halfRiseTime)/riseTimeInMinutes) * 255
        elif timeAfterAlarmInMinutes > halfRiseTime and timeAfterAlarmInMinutes <= (halfRiseTime + onTimeAfterMaxInMinutes):
            return 255
        elif timeAfterAlarmInMinutes < (halfRiseTime + onTimeAfterMaxInMinutes + 2):
            return 0
        else:
            return

def setBrightnessAndColorForTime():
    brightness = getBrightness()
    now = datetime.datetime.now()
    (my_red, my_green, my_blue) = getColors(now.hour, now.minute)

    if brightness is None:
        print("No Brightness to set")
    else:
        global globalStrip
        globalStrip = Adafruit_NeoPixel(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS)
        colorAllPixelsWithBrightness(my_red, my_green, my_blue, brightness)

# Interacting with alarm
def setAlarm(hour, minute):
    global globalAlarmTime
    globalAlarmTime = datetime.datetime(2008, 1, 1, hour, minute, 0) # date doesn't matter
    writeAlarmTimeToFile(hour, minute)

def disableAlarm():
    global globalAlarmTime
    globalAlarmTime = None
    turnOffLEDs()
    writeEmptyToAlarmTimeToFile()

def changeSnoozeDuration(newDuration):
    global globalSnoozeDuration
    globalSnoozeDuration = newDuration
    writeSnoozeDurationToFile(newDuration)

def snooze():
    readAlarmSettings()
    global globalAlarmTime
    if globalAlarmTime is None:
        print ('Cannot snooze. Alarm not set')
        return
    globalAlarmTime = globalAlarmTime + (datetime.timedelta(seconds=60 * globalSnoozeDuration))
    writeAlarmTimeToFile(globalAlarmTime.hour, globalAlarmTime.minute)
    turnOffLEDs()

def initializeStrip():
    # Create NeoPixel object with appropriate configuration.
    global globalStrip
    globalStrip = Adafruit_NeoPixel(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS)
    # Intialize the library (must be called once before other functions).
    globalStrip.begin()
    #colorAllPixelsOff(Color(243, 255, 234))

    now = datetime.datetime.now()
    print (now.strftime("Current time: %a %d-%m-%Y @ %H:%M:%S"))

def setColorAndBrightnessRepeated():
    print('repeated function executing')
    readAlarmSettings()
    setBrightnessAndColorForTime()
    # add stuff here based on conditions
