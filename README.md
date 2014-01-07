# How To set this up

If you want to play with this game, please follow the following instruction carefully.
Otherwise the game might lead to unpredictable behavior.

Below are instructions to set it up on Mac OSX. This game has been developed and
tested on an **Mac OSX** system, but should just as well work on a Linux or
Windows machine. Please file an [Issue](issues/new) when run into problems.

## Prerequisites

* A Web Camera (High Definition preferrably)
* Ruby 1.9+ installed
* [Bundler](http://bundler.io)

## Camera

This project uses **libusbx** in order to send instructions to the camera through USB,
please make sure you install it:

    brew install libusbx

then run `bundle` to update the dependencies.

## OpenCV

This project also depends on OpenCV 2.4.5. If you have homebrew
installed on your Mac, it's a simple matter of running:

    brew tap homebrew/science
    cd /usr/local/Library/Taps/homebrew-science
    git checkout ae74fe9 opencv.rb
    brew install opencv --with-tbb

## Download the source code:

To get a fresh check out, run:

    git clone git@github.com:quintel/theia.git
    cd theia
    bundle install

If you're just updating the code:

    git up
    bundle install

## Calibrate

Since your lighting conditions may be different, you will probably have to calibrate the game before you start.

Assuming you've followed the steps above (installed OpenCV, ran `bundle` and copied the example pieces file), all you have to do is:

    ./bin/theia calibrate

and follow the instructions in the terminal.

## Start the Game!

    ./bin/theia game
    
## Connect to the Energy Transition Model

You probably want to see the results of the game displayed in the
[Energy Game](http://etflex.et-model.com) of the Energy Transition Model.

To accomplish this, please first run in a Terminal window:

    ./bin/theia websocket

Then fire up your 

    cd ..
    git clone git@github.com:quintel/etflex.git
    git checkout theia-frontend
    bundle install
    bundle exec rails server
    
Then visit [localhost:3000](http://localhost:3000) in your webbrowser
(Chrome is recommended).

## "Do's" and "dont's"

* **Don't** break the map contour. If it gets broken, Theia stops updating the board. This is in place to prevent erroneous updates
(ie shadows, arms, etc) from contaminating the background model.
* **Don't** place pieces too close together. A good "rule of thumb" is to see if a finger fits between them (see what I did there?)
* **Don't** place too many pieces at once. Try to place a maximum of two or at a time. Too many pieces will be considered a "flakey" update, and
treated as such.
* And most importantly, **do** have lots of fun with this game.
