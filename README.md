Theia
=====

# Installing the Camera

Make sure you have [Webcam Settings](https://itunes.apple.com/us/app/webcam-settings/id533696630?mt=12) installed.

## Adapt settings:

#### Basic:

* Auto exposure: manual
* Exposure time: 100
* Gain: 0
* Brightness, constract, saturation and sharpness: 128 (in the middle)
* White balance temperature: 4250

#### Advances:

* Power line frequency: disabled
* backlight compensation: off
* Focus: Turn off auto: 0
* Zoom: minimum (100)
* Pan: 0
* Tilt: 0

#### Preferences:

* Read auto settings: disabled
* Write every settings to webcam: every 0.5 seconds

# How to run

This project depends on OpenCV. If you have homebrew installed on your mac, it's a simple matter of running

    brew tap homebrew/science
    brew install opencv --with-tbb

To get a fresh check out, here's how you do it:

    git clone git@github.com:quintel/theia.git
    cd theia
	bundle
    ./bin/theia
    
Before running, make sure you copy `data/pieces.yml.example` to `data/pieces.yml`.

If you're just updating the code:

    git pull
    ./bin/theia

# How to calibrate

Assuming you've followed the steps above (installed OpenCV, ran `bundle` and copied the example pieces file), all you have to do is:

    ./bin/theia calibrate
