# How To set this up

If you want to play with this game, please follow the following instruction carefully. Otherwise the game
might lead to unpredictable behavior.

## Camera

You'll need a decent WebCam. We use the [Logitech C920](http://www.logitech.com/en-us/product/hd-pro-webcam-c920)
and we can advise it.

Make sure to install
[Webcam Settings](https://itunes.apple.com/us/app/webcam-settings/id533696630?mt=12)
to adjust the settings as described below. If you do not do this, your webcam will try
to auto-focus and auto-balance colors, which leads to a significant drop in stability.

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
    bundle
    ./bin/theia

If you're just updating the code:

    git up
    bundle
    ./bin/theia

# How to calibrate

Assuming you've followed the steps above (installed OpenCV, ran `bundle` and copied the example pieces file), all you have to do is:

    ./bin/theia calibrate

or shorter:

    ./bin/theia c

and follow instructions

# "Do's" and "dont's"

* **Don't** break the map contour. If it gets broken, Theia stops updating the board. This is in place to prevent erroneous updates
(ie shadows, arms, etc) from contaminating the background model.
* **Don't** place pieces too close together. A good "rule of thumb" is to see if a finger fits between them (see what I did there?)
* **Don't** place too many pieces at once. Try to place a maximum of two or at a time. Too many pieces will be considered a "flakey" update, and
treated as such.
* And most importantly, **do** have lots of fun with this game.
