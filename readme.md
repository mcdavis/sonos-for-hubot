# Sonos for Hubot

![screenshot](http://cl.ly/image/3S2m2j451W3b/Image%202013.08.22%204%3A54%3A04%20PM.png)

## Requirements

- Hubot
- HUBOT_SONOS_HOST - an export set to an IP for a single sonos speaker.  If grouped, it needs to be the main speaker in the group.
- The bot has to be running somewhere where it can access your sonos speakers.

## Installation

- Drop this into your scripts folder in your hubot

## Notes

This is pretty brittle in that Sonos discovery is not great.  So, if the Sonos ip changes or someone changes the group order, this breaks.  Ideally, you'd have it try and discover the Sonos components and work with those directly.  Maybe something like [Sonos for Ruby](https://github.com/soffes/sonos) would be a good inspiration.

I've also thought about having it know about multiple sonos components and groups so that a person could tell it something like 'hubot play for devs' or something.  That's a ways off from here as I haven't found the time, but it would be cool.

The code could also probably use a rewrite.  I've gone through and done some quick cleanup, but it could probably be optimized as it was something I quickly wrote in some free time one time.

## Credits

I wrote a bunch of the interactivity, but the base was created by [berg](https://github.com/github/hubot-scripts/blob/master/src/scripts/sonos.coffee) and I modified it from there.

I also figured out some of the needed data formats from [SoCo](https://github.com/rahims/SoCo).
