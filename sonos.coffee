# Description:
#   Control Sonos using Hubot
#
# Dependencies:
#   "xml2js": "0.1.14"
#
# Configuration:
#   HUBOT_SONOS_HOST
#
# Commands:
#   hubot what's playing? - Returns the current song
#   hubot next - Plays the next song
#   hubot previous - Plays the previous song
#   hubot pause - Pauses the current song
#   hubot play - Starts Sonos
#   hubot volume <amount> - Adjusts the Sonos volume to the amount passed
#
# Author:
#   mcdavis (modified from berg - https://github.com/github/hubot-scripts/blob/master/src/scripts/sonos.coffee)

xml2js = require 'xml2js'
util = require 'util'

wrapInEnvelope = (body) ->
    """
    <?xml version="1.0" encoding="utf-8"?>
    <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
      <s:Body>#{body}</s:Body>
    </s:Envelope>
    """

getURL = (path) ->
    # this needs to be the ip for a sonos speaker
    # and if grouped, it needs to be
    # the owner of the group
    host = process.env.HUBOT_SONOS_HOST
    "http://#{host}:1400#{path}"

makeRequest = (msg, path, action, body, response, cb) ->
    wrappedBody = wrapInEnvelope body

    msg.http(getURL path).header('SOAPAction', action).header('Content-type', 'text/xml; charset=utf8')
        .post(wrappedBody) (err, resp, body) ->
            unless err?
                (new xml2js.Parser()).parseString body, (err, json) ->
                    unless err?
                        body = json['s:Envelope']['s:Body'][0]
                        if body?
                            response_body = body[response]
                            cb(response_body) if response_body?

volume = (msg,loudness) ->
    if loudness?
        body = """
        <u:SetVolume xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1">
            <InstanceID>0</InstanceID>
            <Channel>Master</Channel>
            <DesiredVolume>#{loudness}</DesiredVolume>
        </u:SetVolume>
        """

        action = '"urn:schemas-upnp-org:service:RenderingControl:1#SetVolume"'
        path = '/MediaRenderer/RenderingControl/Control'

        makeRequest msg, path, action, body, 'u:SetVolumeResponse', (obj) ->
            msg.send "Cranking this thing to #{loudness}"

previous = (msg) ->
    body = """
    <u:Previous xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        <Speed>1</Speed>
    </u:Previous>
    """

    action = '"urn:schemas-upnp-org:service:AVTransport:1#Previous"'
    path = '/MediaRenderer/AVTransport/Control'

    makeRequest msg, path, action, body, 'u:PreviousResponse', (obj) ->
        msg.send 'Let\'s hear it again, Sonos'

        # show what's playing after firing the last command
        # timeout because sometimes sonos doesn't update fast enough
        setTimeout (->
          nowPlaying msg
        ), 1500

next = (msg) ->
    body = """
    <u:Next xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        <Speed>1</Speed>
    </u:Next>
    """

    action = '"urn:schemas-upnp-org:service:AVTransport:1#Next"'
    path = '/MediaRenderer/AVTransport/Control'

    makeRequest msg, path, action, body, 'u:NextResponse', (obj) ->
        msg.send 'On to the next one'

        # show what's playing after firing the last command
        # timeout because sometimes sonos doesn't update fast enough
        setTimeout (->
          nowPlaying msg
        ), 1500

play = (msg) ->
    body = """
    <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        <Speed>1</Speed>
    </u:Play>
    """

    action = '"urn:schemas-upnp-org:service:AVTransport:1#Play"'
    path = '/MediaRenderer/AVTransport/Control'

    makeRequest msg, path, action, body, 'u:PlayResponse', (obj) ->
        msg.send 'Spin that shit, Sonos'

pause = (msg) ->
    body = """
    <u:Pause xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        <Speed>1</Speed>
    </u:Pause>
    """

    action = '"urn:schemas-upnp-org:service:AVTransport:1#Pause"'
    path = '/MediaRenderer/AVTransport/Control'

    makeRequest msg, path, action, body, 'u:PauseResponse', (obj) ->
        msg.send 'It\'s getting quiet in here...'

nowPlaying = (msg) ->
    body = """
    <u:GetPositionInfo xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      <InstanceID>0</InstanceID>
      <Channel>Master</Channel>
    </u:GetPositionInfo>
    """

    action = 'urn:schemas-upnp-org:service:AVTransport:1#GetPositionInfo'
    path = '/MediaRenderer/AVTransport/Control'

    makeRequest msg, path, action, body, 'u:GetPositionInfoResponse', (obj) ->
        metadata = obj[0].TrackMetaData

        if metadata?
            (new xml2js.Parser()).parseString metadata, (err, obj) ->
                unless err?
                    item = obj["DIDL-Lite"].item[0]

                    if item?
                        title = item['dc:title'] ? '(no title)'
                        artist = item['dc:creator'] ? '(no artist)'
                        album = item['upnp:album'] ? '(no album)'
                        artURI = item['upnp:albumArtURI']

                        if item['res'][0]['$'].protocolInfo is 'sonos.com-spotify:*:audio/x-spotify:*'
                            artURI = getURL artURI + '#.png'
                            source = 'Spotify'
                        else
                            source = 'Pandora'

                        msg.send "Now playing: \"#{title}\" by #{artist} from #{source}"
                        msg.send artURI

module.exports = (robot) ->
    robot.respond /what'?s playing\??/i, (msg) ->
        nowPlaying msg
    robot.respond /pause/i, (msg) ->
        pause msg
    robot.respond /play(.*)/i, (msg) ->
        play msg
    robot.respond /spin that shit (.*)/i, (msg) ->
        play msg
    robot.respond /next(.*)/i, (msg) ->
        next msg
    robot.respond /back(.*)/i, (msg) ->
        previous msg
    robot.respond /previous/i, (msg) ->
        previous msg
    robot.respond /volume (.*)/i, (msg) ->
        loudness = msg.match[1]
        volume msg,loudness
