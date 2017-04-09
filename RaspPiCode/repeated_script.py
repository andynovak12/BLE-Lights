import LEDController, time, datetime

if __name__ == '__main__':
    now = datetime.datetime.now()
    print('running now',now)
    LEDController.setColorAndBrightnessRepeated()
