Theia
=====

# Installing the Camera

Make sure you have [Webcam Settings](https://itunes.apple.com/us/app/webcam-settings/id533696630?mt=12) installed.

**Warning:** make sure that Webcam Settings is **not running**. (Quit it).

Then run the following commands to update the settings to the general Theia settings:

    mkdir -p ~/Library/Containers/com.mactaris.Webcam-Settings/Data/Library/Preferences/
    cp data/com.mactaris.Webcam-Settings.plist ~/Library/Containers/com.mactaris.Webcam-Settings/Data/Library/Preferences/

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
