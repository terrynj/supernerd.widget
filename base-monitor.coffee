commands =
  volume : "osascript -e 'output volume of (get volume settings)'"
  ismuted : "osascript -e 'output muted of (get volume settings)'"
  battery : "pmset -g batt | egrep '([0-9]+\%).*' -o --colour=auto | cut -f1 -d';'"
  ischarging : "sh ./supernerd.widget/scripts/ischarging.sh"
  wifi: "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed -e \"s/^ *SSID: //p\" -e d"
  isconnected: "echo true"
  focus : "/usr/local/bin/chunkc tiling::query --window name"
  playing: "osascript -e 'tell application \"iTunes\" to if player state is playing then artist of current track & \" - \" & name of current track'"
  time: "date +\"%H:%M\""


command: "echo " +
         "$(#{ commands.volume }):::" +
         "$(#{ commands.ismuted }):::" +
         "$(#{ commands.battery }):::" +
         "$(#{ commands.ischarging }):::" +
         "$(#{ commands.wifi }):::" +
         "$(#{ commands.isconnected }):::" +
         "$(#{ commands.time }):::"

refreshFrequency: '10s'

render: ( ) ->
  """
    <div class="container">
    <span id="valueHolder" value="10"></span>

      <div class="widg" id="volume">
        <div class="icon-container" id='volume-icon-container'>
          <i id="volume-icon"></i>
        </div>
        <!-- <span class='output'>
          <div class="bar-output" id="volume-bar-output">
            <div class="bar-output" id="volume-bar-color-output"></div>
          </div>
        </span> -->
        <span class="output" id='volume-output'></span>
      </div>

      <div class="widg" id="wifi">
        <div class="icon-container" id='wifi-icon-container'>
          <i class="fa fa-wifi"></i>
        </div>
        <span class="output" id='wifi-output'></span>
      </div>

      <div class="widg pinned" id="battery">
        <div class="icon-container" id='battery-icon-container'>
        <i class="battery-icon"></i>
        </div>
        <span class="output" id='battery-output'></span>
      </div>

      <div class="widg pinned red" id="time">
        <span class="output pinned" id="time-output"></span>
      </div>

    </div>

  """

update: ( output, domEl ) ->
  output = output.split( /:::/g )

  values = []

  values.volume   = output[ 0 ]
  values.ismuted  = output[ 1 ]
  values.battery = output[ 2 ]
  values.ischarging  = output[ 3 ]
  values.wifi = output[ 4 ]
  values.isconnected = output[ 5 ]
  values.time = output[ 6 ]


  controls = ['battery','volume','wifi','time']
  for control in controls
    outputId = "#"+control+"-output"
    currentValue = $("#{outputId}").value
    updatedValue = values[control]

    if updatedValue != currentValue
      $("#{ outputId }").text("#{ updatedValue }")

      if control is 'battery'
         @handleBattery( domEl, Number( values["battery"].replace( /%/g, "" ) ), values["ischarging"] )
      else if control is 'wifi' then @handleWifi( domEl, values["wifi"] )
      else if control is  'volume' then @handleVolume( domEl, Number( values["volume"]), values["ismuted"] )
      else if control is 'brightness' then @handleBrightness( domEl, values["brightness"] )

#
# ─── HANDLE BRIGHTNESS ─────────────────────────────────────────────────────────
handleBrightness: (domEl, brightness ) ->
  brightness = Math.round(100*brightness) + 2
  $("#brightness-output").text("#{brightness}")
  $( "#brightness-bar-color-output" ).width( "#{brightness}%" )

#
#
# ─── HANDLE VOLUME ─────────────────────────────────────────────────────────
#

handleVolume: ( domEl, volume, ismuted ) ->
  div = $( domEl )

  volumeIcon = switch
    when volume ==   0 then "fa-volume-off"
    when volume <=  50 then "fa-volume-down"
    when volume <= 100 then "fa-volume-up"

  #
  # div.find("#volume").removeClass('blue')
  # div.find("#volume").removeClass('red')
  #
  # if ismuted != 'true'
  #   div.find( "#volume-output").text("#{ volume }")
  #   div.find('#volume').addClass('blue')
  #   div.find('#volume-icon-container').addClass('blue')
  # else
  #   div.find( "#volume-output").text("Muted")
  #   volumeIcon = "fa-volume-off"
  #   div.find('#volume').addClass('red')
  #   div.find('#volume-icon-container').addClass('red')

  $("#volume-output").text("#{volume}")
  $( "#volume-icon" ).html( "<i class=\"fa #{ volumeIcon }\"></i>" )
  $( "#volume-bar-color-output" ).width( "#{volume}%" )


#
# ─── HANDLE BATTERY ─────────────────────────────────────────────────────────
#

handleBattery: ( domEl, percentage, ischarging ) ->
  div = $( domEl )

  batteryIcon = switch
    when percentage <=  12 then "fa-battery-empty"
    when percentage <=  25 then "fa-battery-quarter"
    when percentage <=  50 then "fa-battery-half"
    when percentage <=  75 then "fa-battery-three-quarters"
    when percentage <= 100 then "fa-battery-full"


  div.find("#battery").removeClass('green')
  div.find("#battery").removeClass('yellow')
  div.find("#battery").removeClass('red')

  if percentage >= 35
    div.find('#battery').addClass('green')
    div.find('#battery-icon-container').addClass('green')
  else if percentage >= 15
    div.find('#battery').addClass('yellow')
    div.find('#battery-icon-container').addClass('yellow')
  else
    div.find('#battery').addClass('red')
    div.find('#battery-icon-container').addClass('red')

  if ischarging == "true"
    batteryIcon = "fas fa-bolt"
  $( ".battery-icon" ).html( "<i class=\"fa #{ batteryIcon }\"></i>" )



#
# ─── HANDLE WIFI ─────────────────────────────────────────────────────────
#

handleWifi: (domEl, wifi ) ->
  $( "#wifi-output").text("#{ wifi }")

  if wifi == ''
    wifiIcon = 'fas fa-exclamation-circle'
  else
    wifiIcon = 'fa fa-wifi'
  $(domEl).find( ".wifi-icon" ).html( "<i class=\"fa #{ wifiIcon }\"></i>" )


#
# ─── ANIMATION  ─────────────────────────────────────────────────────────
#
afterRender: (domEl) ->
  $(domEl).on 'mouseover', ".widg", (e) => $(domEl).find( $($(e.target))).addClass('open')

  $(domEl).on 'mouseout', ".widg", (e) => $(domEl).find( $($(e.target))).removeClass('open')

  $(domEl).on 'click', ".widg", (e) => if $(domEl).find( $($(e.target))).attr('id') != "time" then $(domEl).find( $($(e.target))).toggleClass('pinned')
