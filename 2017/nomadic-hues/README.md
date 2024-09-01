TODOs:
[] update README
    - re-write keymap
    - add documentation on Xmitter.ck
[] cleanup references to NUM_IN_FRONT, etc
[] add additional notes to score

--------------------------------------------------------------------------------

## To run the piece

**To run server:**

chuck run-nameless-server.ck:(local)
processing-java --sketch=`pwd`/world --run

dependencies: oscP5 and Ani (move folders to processing's sketchbook)
if local is not specified, initializes clients as listed in the source.

**To run locally (for testing purposes):**

chuck run-nameless-go.ck:(name of server)

if name of server is not specified, assumed to be localhost.

--------------------------------------------------------------------------------

### CLIENT KEYMAP
 - <SPACE>             to begin / enter world
 - ^v<> keys           to navigate world
 - d                   to rearticulate drone (on your current position)
 - 1-0                 to 'tinkle' (clocked by server)
 - j                   to 'jump' (clocked by server)

### SERVER KEYMAP

**Color selector**
_This changes the color of the performer dots. It also sets the timbre of the performers._
 - g                   to slew to random g
 - b                   to slew to random b
 - r                   to slew to random r
 - y                   <not implemented>

**Scale selector**
 - p                   to use pentatonic scale
 - h                   to use hirajoshi scale
 - a                   to use aminor scale
 - d                   to use dminor scale
 - z                   to use ascending scale

 **Envelope selector**
 - 1234                to set ADSR presets on all clients
                       corresponds to sections of the piece
   
 - x                   to fork bass on clients who have subs

 GESTURES
 - RAIN:     everyone drift downwards
 - ARP:      everyone drift to the right
 - TINKLE:   numbers 1-0 control number of tinkles (can strike successively)
 - JUMP:     percussive effect
 - DRIFT:    find a place sonically pleasing

--------------------------------------------------------------------------------

### Performance notes for SLOrk setup 
nameless Trijeet.local
motu -25
