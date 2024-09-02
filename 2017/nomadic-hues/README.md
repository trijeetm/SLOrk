TODOs:
- [ ] update README
    - [ ] re-write keymap
    - [ ] add documentation on Xmitter.ck
- [ ] cleanup references to NUM_IN_FRONT, etc
- [ ] add additional notes to score
- [ ] document MIDI controller commands


## To run the piece

**To run server:**

```
chuck run-nameless-server.ck:(local)
`processing-java --sketch=`pwd`/world --run
```

dependencies: `oscP5` and `Ani` (move folders to processing's sketchbook)
if local is not specified, initializes clients as listed in the source.

**To run locally (for testing purposes):**

```
chuck run-nameless-go.ck:(name of server)
```
if name of server is not specified, assumed to be `localhost`.


## Controls

### CLIENT KEYMAP
```
 - <SPACE>             to begin / enter world
 - arrow keys          to navigate world
 - d                   to rearticulate drone (on your current position)
 - 1-0                 to 'tinkle' (clocked by server)
 - j                   to 'jump' (clocked by server)
```

### SERVER KEYMAP

**Color selector**
_This changes the color of the performer dots. It also sets the timbre of the performers._
```
 - g                   to slew to random g
 - b                   to slew to random b
 - r                   to slew to random r
```


**Scale selector**
```
 - p                   to use pentatonic scale
 - h                   to use hirajoshi scale
 - a                   to use aminor scale
 - d                   to use dminor scale
 - z                   to use ascending scale
 - y                   to use "yo" scale
```

 **Envelope selector**
 ```
 - 1, 2, 3, 4           to set ADSR presets on all clients in the "front" section
 - 7, 8, 9, 0           to set ADSR presets on all clients in the to "back" section
```

## Musical gestures
_See score for details, and how it fits into the piece_
 - RAIN:     everyone drift downwards
 - ARP:      everyone drift to the right
 - TINKLE:   numbers 1-0 control number of tinkles (can strike successively)
 - JUMP:     percussive effect
 - DRIFT:    find a place sonically pleasing

## Performance notes for SLOrk setup 
nameless Trijeet.local
motu -25
