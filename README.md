Theia
=====

# Dependencies

## Camera

Make sure you have [Webcam Settings](https://itunes.apple.com/us/app/webcam-settings/id533696630?mt=12) installed.

## Adapt settings for Webcam Settings(c)

Please make sure you have the following settings applied:

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

## OpenCV

This project also depends on OpenCV 2.4.5. If you have homebrew
installed on your mac, it's a simple matter of running:

    brew tap homebrew/science
    cd /usr/local/Library/Taps/homebrew-science
    git checkout ae74fe9 opencv.rb
    brew install opencv --with-tbb

## Hit it!

To get a fresh check out, and get the pieces information run:

    git clone git@github.com:quintel/theia.git
    cd theia
    cp data/pieces.yml.example data/pieces.yml
    bundle
    ./bin/theia
    
If you're just updating the code:

    git up
    bundle
    ./bin/theia

# How to calibrate

Assuming you've followed the steps above (installed OpenCV, ran `bundle` and copied the example pieces file), all you have to do is:

    ./bin/theia calibrate
