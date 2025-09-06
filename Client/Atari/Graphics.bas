
' use custom Font for FujiLlama
' By Simon Young 2025

dim player_name$(7), player_status(7), player_bet(7), player_move$(7), player_purse(7), player_hand$(7)
' **************************************************
' ***************** IMPORTANT NOTE *****************

' ** These variables are dimensioned in a specific order to reduce wasted
' space when aligning certain arrays to 4K and 1K boundaries

' Receive buffer
dim responseBuffer(1023) BYTE

' Align screenBuffer at 4096 boundary (and charBuffer at 1024 boundary afterward)
i = (&responseBuffer+1023)/4096*4096 - &responseBuffer + 3071

' If space is available until the next 4096 boundary,
' initialize some player array strings to use this available space
j=0
while i > 768
  player_name$(j)="":player_hand$(j)="":player_move$(j)=""
  i=i-768
  inc j
wend

' Any remaining space is assigned to a filler array
if i>0 then dim filler(i) BYTE

' The screenbuffer holds the Playfield screen (40*26=1040), followed by an offscreen buffer of the same size.
' It only needs 2080 bytes.
' The charBuffer that is dimensioned immediately following the playfield needs to be 1024 byte aligned.
' This gives us 992 bytes (1024*3-2080) extra space to do something with.
' We use 768 of that to allocate another set of player strings
' 1024*3=3072 bytes, - 768 = 2304 bytes we are allocating below
dim screenBuffer(2303) BYTE

' Allocate 3 more strings, taking up 768 bytes 
player_name$(j)="":player_hand$(j)="":player_move$(j)=""

' Now charBuffer will be aligned to a 1K boundary
dim charBuffer(1023) BYTE

' *************** END IMPORTANT NOTE ***************
' **************************************************

DIM Screen


' ==========================================================
' DATA - Character Fonts
' Custom character set for FujiLlama - 128 characters, 8 bytes each
' Size: 1024 bytes
data font() byte = 0,0,0,0,0,0,0,0,
data byte = 64,64,64,64,64,64,64,85,
data byte = 0,0,0,0,0,0,0,85,
data byte = 1,1,1,1,1,1,1,85,
data byte = 64,64,64,64,64,64,76,85,
data byte = 64,64,64,64,76,64,76,85,
data byte = 64,64,76,64,76,64,76,85,
data byte = 0,0,0,0,0,0,32,85,
data byte = 0,0,0,0,32,0,32,85,
data byte = 0,0,32,0,32,0,32,85,
data byte = 32,0,32,0,32,0,32,85,
data byte = 1,1,1,1,1,1,33,85,
data byte = 1,1,1,1,33,1,33,85,
data byte = 10,47,191,181,183,183,183,181,
data byte = 128,224,248,120,248,248,248,248,
data byte = 183,183,183,183,183,191,47,10,
data byte = 0,32,136,136,136,136,136,32,
data byte = 0,32,160,32,32,32,32,168,
data byte = 0,32,136,136,8,32,128,168,
data byte = 0,32,136,8,32,8,136,32,
data byte = 0,8,136,136,168,8,8,8,
data byte = 0,168,128,160,8,8,8,160,
data byte = 0,40,128,160,136,136,136,32,
data byte = 0,168,136,8,32,32,32,32,
data byte = 0,32,136,136,32,136,136,32,
data byte = 0,32,136,136,136,40,8,160,
data byte = 0,0,32,32,0,0,32,32,
data byte = 248,248,248,248,248,248,224,128,
data byte = 5,21,26,26,106,106,106,106,
data byte = 85,85,170,170,170,170,170,170,
data byte = 64,80,144,148,164,164,164,164,
data byte = 12,12,12,12,12,12,12,12,
data byte = 0,0,0,0,255,255,0,0,
data byte = 0,32,168,136,136,168,136,136,
data byte = 0,160,136,136,160,136,136,160,
data byte = 0,40,128,128,128,128,128,40,
data byte = 0,160,136,136,136,136,136,160,
data byte = 0,168,136,128,160,128,128,168,
data byte = 0,168,136,128,160,128,128,128,
data byte = 0,40,136,128,152,136,136,40,
data byte = 0,136,136,136,168,136,136,136,
data byte = 0,168,32,32,32,32,32,168,
data byte = 0,40,8,8,8,8,136,32,
data byte = 0,136,136,160,160,136,136,136,
data byte = 0,128,128,128,128,128,128,168,
data byte = 0,136,168,168,136,136,136,136,
data byte = 0,136,136,168,168,168,136,136,
data byte = 0,32,136,136,136,136,136,32,
data byte = 0,160,136,136,136,160,128,128,
data byte = 0,32,136,136,136,136,32,8,
data byte = 0,160,136,136,136,160,136,136,
data byte = 0,40,136,128,32,8,136,160,
data byte = 0,168,32,32,32,32,32,32,
data byte = 0,136,136,136,136,136,136,168,
data byte = 0,136,136,136,136,168,32,32,
data byte = 0,136,136,136,136,168,168,136,
data byte = 0,136,136,32,32,136,136,136,
data byte = 0,136,136,136,168,32,32,32,
data byte = 0,168,8,32,32,128,128,168,
data byte = 106,106,106,106,26,26,21,5,
data byte = 170,170,170,170,170,170,85,85,
data byte = 164,164,164,164,148,144,80,64,
data byte = 170,170,170,170,170,170,170,170,
data byte = 106,106,106,106,106,106,106,106,
data byte = 164,164,164,164,164,164,164,164,
data byte = 165,149,154,154,106,106,106,106,
data byte = 170,254,254,254,190,190,190,190,
data byte = 190,190,190,190,190,255,255,170,
data byte = 255,255,171,171,171,171,171,255,
data byte = 255,234,234,234,234,234,255,255,
data byte = 255,171,171,171,171,171,255,255,
data byte = 171,171,235,235,235,235,235,255,
data byte = 255,171,171,171,171,171,171,171,
data byte = 170,170,255,255,234,234,234,234,
data byte = 170,255,255,235,235,234,234,234,
data byte = 255,235,235,235,235,235,235,255,
data byte = 5,21,26,26,104,99,99,98,
data byte = 85,85,170,170,168,35,35,2,
data byte = 64,80,144,148,164,36,36,36,
data byte = 98,104,98,98,98,98,98,98,
data byte = 170,168,170,238,238,170,186,186,
data byte = 36,164,36,36,36,36,36,36,
data byte = 98,98,104,106,104,104,104,104,
data byte = 254,186,168,18,18,68,100,168,
data byte = 36,36,164,164,164,164,164,164,
data byte = 96,96,97,97,17,19,23,5,
data byte = 100,100,85,17,17,19,87,85,
data byte = 36,36,36,36,20,16,80,64,
data byte = 255,252,240,240,192,192,192,0,
data byte = 255,63,15,15,3,3,3,0,
data byte = 0,192,192,192,240,240,252,255,
data byte = 0,3,3,3,15,15,63,255,
data byte = 255,252,240,240,192,192,192,0,
data byte = 0,0,0,0,0,0,0,0,
data byte = 0,0,0,0,0,0,0,0,
data byte = 0,0,0,0,0,0,0,0,
data byte = 0,48,116,220,220,220,116,48,
data byte = 5,21,31,31,126,126,126,126,
data byte = 85,85,255,239,238,238,238,238,
data byte = 64,80,208,212,244,244,244,244,
data byte = 126,126,126,126,122,122,122,123,
data byte = 238,238,238,238,238,238,238,239,
data byte = 244,244,244,244,180,180,180,180,
data byte = 123,123,127,127,125,125,125,125,
data byte = 239,239,255,255,119,247,247,119,
data byte = 180,180,244,244,244,244,244,244,
data byte = 125,125,125,125,31,31,21,5,
data byte = 247,247,247,245,255,255,85,85,
data byte = 244,244,244,244,212,208,80,64,
data byte = 16,16,16,85,16,16,16,16,
data byte = 16,16,16,85,16,16,16,0,
data byte = 0,0,16,21,16,16,0,0,
data byte = 16,32,168,169,168,168,32,16,
data byte = 16,48,184,236,236,236,184,48,
data byte = 0,40,170,170,174,174,40,0,
data byte = 0,40,170,170,186,186,40,0,
data byte = 0,0,0,0,0,32,32,128,
data byte = 0,32,236,184,184,184,236,32,
data byte = 0,0,0,80,0,0,0,0,
data byte = 0,148,164,164,164,164,164,148,
data byte = 0,124,92,92,92,92,92,124,
data byte = 0,0,0,32,24,20,28,48,
data byte = 0,0,0,32,144,80,208,48,
data byte = 0,40,138,138,130,170,170,40,
data byte = 0,8,8,32,32,32,128,128,
data byte = 0,0,0,0,168,0,0,0,
data byte = 0,0,0,0,0,0,0,0,
data byte = 0,0,0,0,0,0,0,0

' DLI Colors 
data background_color()B.=$0,0,0
data text_color()B.=$0E,$0E,0

' Color Themes: (Background & card border)
' Themes: Green, Blue, Brown, Gray
DATA colorThemeMap()      =  $B4,$88,  $84,$08, $22,$28, $04,$08,' NTSC
DATA                      =  $A4,$78,  $74,$08, $12,$18, $04,$08 ' PAL 
colorTheme=-1



' --------- Main program -----------------------------
@InitScreen
@ShowScreen

 N=13
  @POS N,1: @Print &"      m"
  @POS n,2: @Print &"     mpm"
  @POS n,3: @Print &"FUJIopqpvNET"
  @POS n,4: @Print &"     nmpv"
  @POS n,5: @Print &"      nmm"
  @POS n+3,7:@Print &"PRESENTS"
  @POS n+2,8:@Print &"FUJI-LLAMA"
  @POS n-8,10:@Print &"A CARD GAME FOR UP TO 6 PLAYERS"

  @PrintCard 0,13,0
  @PrintCard 4,13,1
  @PrintCard 8,13,2
  @PrintCard 12,13,3
  @PrintCard 16,13,4
  @PrintCard 20,13,5
  @PrintCard 24,13,6
  @PrintCard 28,13,7
  @PrintCard 32,13,8

@PrintPH 0,0,1

@PrintPH 0,22,5

@printPlayerScore 0,4,0,0
@printPlayerScore 0,6,1,0
@printPlayerScore 0,8,2,0
@printPlayerScore 0,10,2,0

@printPlayerScore 10,4,0,0
@printPlayerScore 10,6,1,1
@printPlayerScore 10,8,2,2
@printPlayerScore 10,10,3,3
@printPlayerScore 10,12,2,4
@printPlayerScore 10,14,0,5


@printPlayerScore 20,6,1,6
@printPlayerScore 20,8,2,7
@printPlayerScore 20,10,3,8
@printPlayerScore 20,12,2,9
@printPlayerScore 20,14,0,10



Repeat
@CycleColorTheme
Get K
UNTIL K=27

END

Proc PrintCard _col _row _card
x=_col:y=_row:card=_card
IF card=0  
    @POS x,y:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS x,y+1:@PrintByte 63:@PrintByte 62:@PrintByte 64
    @POS x,y+2:@PrintByte 63:@PrintByte 62:@PrintByte 64
    @POS x,y+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF card=1 
    @POS x,y:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS x,y+1:@PrintByte 63:@PrintByte 66:@PrintByte 64
    @POS x,y+2:@PrintByte 63:@PrintByte 67:@PrintByte 64
    @POS x,y+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF card=2 
    @POS x,y:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS x,y+1:@PrintByte 63:@PrintByte 196:@PrintByte 64
    @POS x,y+2:@PrintByte 63:@PrintByte 197:@PrintByte 64
    @POS x,y+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF card=3 
    @POS x,y:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS x,y+1:@PrintByte 63:@PrintByte 68:@PrintByte 64
    @POS x,y+2:@PrintByte 63:@PrintByte 70:@PrintByte 64
    @POS x,y+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF card=4 
    @POS x,y:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS x,y+1:@PrintByte 63:@PrintByte 199:@PrintByte 64
    @POS x,y+2:@PrintByte 63:@PrintByte 200:@PrintByte 64
    @POS x,y+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF card=5 
    @POS x,y:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS x,y+1:@PrintByte 63:@PrintByte 73:@PrintByte 64
    @POS x,y+2:@PrintByte 63:@PrintByte 70:@PrintByte 64
    @POS x,y+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF card=6 
    @POS x,y:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS x,y+1:@PrintByte 63:@PrintByte 202:@PrintByte 64
    @POS x,y+2:@PrintByte 63:@PrintByte 203:@PrintByte 64
    @POS x,y+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF card=7 
    @POS x,y:@PrintByte 204:@PrintByte 205:@PrintByte 206
    @POS x,y+1:@PrintByte 207:@PrintByte 208:@PrintByte 209
    @POS x,y+2:@PrintByte 210:@PrintByte 211:@PrintByte 212
    @POS x,y+3:@PrintByte 213:@PrintByte 214:@PrintByte 215
ElIF card=8 
   @POS x,y:@PrintByte 97:@PrintByte 98:@PrintByte 99
    @POS x,y+1:@PrintByte 100:@PrintByte 101:@PrintByte 102
    @POS x,y+2:@PrintByte 103:@PrintByte 104:@PrintByte 105
    @POS x,y+3:@PrintByte 106:@PrintByte 107:@PrintByte 108
endif
ENDPROC

proc printPh _col _row _numCards 
x=_col:y=_row
for i=1 to _numCards
@POS (x+i)-1,y:@PrintByte 13:@PrintByte 14
@POS (x+i)-1,y+1:@PrintByte 15:@PrintByte 27
next i
ENDPROC

proc printPlayerScore _col _row _BlackCounters _WhiteCounters
x=_col:y=_row:bc=_BlackCounters:wc=_WhiteCounters
IF BC=0
@POS x,y:@PrintByte 1:@PrintByte 2:@PrintByte 2:@PrintByte 3
ELIF BC=1
@POS x,y:@PrintByte 4:@PrintByte 2:@PrintByte 2:@PrintByte 3
ELIF BC=2   
@POS x,y:@PrintByte 5:@PrintByte 2:@PrintByte 2:@PrintByte 3
ELIF BC=3                                               
@POS x,y:@PrintByte 6:@PrintByte 2:@PrintByte 2:@PrintByte 3
ENDIF

IF WC=0
@POS x+1,y:@PrintByte 2:@PrintByte 2:@PrintByte 3
ELIF WC=1
@POS x+1,y:@PrintByte 2:@PrintByte 2:@PrintByte 11
ELIF WC=2   
@POS x+1,y:@PrintByte 2:@PrintByte 7:@PrintByte 11
ELIF WC=3                                               
@POS x+1,y:@PrintByte 7:@PrintByte 7:@PrintByte 11
ELIF WC=4
@POS x+1,y:@PrintByte 7:@PrintByte 8:@PrintByte 11
ELIF WC=5   
@POS x+1,y:@PrintByte 8:@PrintByte 8:@PrintByte 11
ELIF WC=6                                               
@POS x+1,y:@PrintByte 8:@PrintByte 8:@PrintByte 12
ELIF WC=7
@POS x+1,y:@PrintByte 9:@PrintByte 8:@PrintByte 12
ELIF WC=8   
@POS x+1,y:@PrintByte 9:@PrintByte 9:@PrintByte 12
ELIF WC=9                                               
@POS x+1,y:@PrintByte 9:@PrintByte 10:@PrintByte 12
ELIF WC=10                                               
@POS x+1,y:@PrintByte 10:@PrintByte 10:@PrintByte 12
ENDIF
ENDPROC


' ============================================================================
' Init screen/graphics - leaves screen blank. ShowScreen must be called afer
PROC InitScreen

  ' ============= PLAYER MISSLE GRAPHICS =============

  ' Use player missle graphics as follows:
  ' Player 0 and 3 - Left and Right black bars to cover up the background to render a nice round table
  ' Player 1 - Darken player's secret card
  ' Player 2 - Move selection/active player indicator
  pmgraphics 1

  ' Keeping here in case I need it again - Set player missle priority: Players 0-1, playfield, players 2-3, background
   P.623,2

  ' Hide screen for faster startup
  poke 559,0
    
  ' Clear player data, then set sidebars
  mset pm.0,1024,0
  mset pm.0,255,255
  mset pm.3,255,255

  ' Make the sidebar and selection cursor 4x wide to block as much of the screen as possible, and the secret card 1x wide
  mset 53256,4,3: poke 53257, 0
  
  ' Set side par positions to left and right edge of screen
  PMHPOS 0,16:PMHPOS 3,208
  
  ' ============= COLORS =============

  ' Order: Players 0,1,2,3, Playfield 0,1,2,3, Background
  
  if PEEK(53268)=1 ' Check if we are running PAL on GTIA machines
    ' PAL colors
    move &""$00$0a$fa$00$78$0E$00$24$00+1, 704, 9
    move_color = $EE
  else
    ' NTSC colors
    move &""$00$0a$fa$00$88$0E$00$34$00+1, 704, 9
    move_color = $FE
  endif

  text_color(2) = move_color

  @CycleColorTheme  

  ' ============= PLAYFIELD =============
  @DisableDoubleBuffer
  
  ' Copy the custom character set data to the location
  move &font,&charBuffer,8*128

  ' Tell Atari to use the new location
  P.756,&charBuffer/256

  ' Custom Display List to give us 2 more rows (40x26) with DLI for coloring
  DL$ = ""$20$F0$44$00$00$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$04$84$84$20$04$41$00$00
  
  ' Copy the display list from the string to memory.
  displayList = &DL$+1
  dpoke displayList+len(DL$)-2,displayList

  ' Tell the display list the new location of the screen buffer
  dpoke displayList+3,&screenBuffer

  ' Use DLI to change the text/background colors of the bottom status rows
  DLISET dli_colors = background_color INTO $D01A, text_color INTO $D017
  DLI dli_colors

  ' Enable the new Display list
  dpoke 560, displayList

  ' Reset the screen
  @ResetScreen

  ' Disable accidental break key press
  poke 16,64:poke 53774,64

ENDPROC

PROC CycleColorTheme
  
  if colorTheme = -1
    colorTheme = 0
  else
    ' Otheriwse, just cycle theme
    sound 0, 220,10,5
    pause 4
    sound 0, 200,10,5
    
    colorTheme = (colorTheme + 1) mod 4 
  endif

  ' Set new theme colors (NTSC/PAL + theme index)
  i = (PEEK(53268)=1)*2*4 + 2*colorTheme
  h=colorThemeMap(i)
  j=colorThemeMap(i+1)

  pause 2
  background_color(0)= colorThemeMap(i)
  background_color(1)= colorThemeMap(i)
  POKE 708, colorThemeMap(i+1)
'poke 712,background_color(0)

  sound
ENDPROC

PROC DisableDoubleBuffer
  screen = &screenbuffer
ENDPROC

' Call to clear the screen to an empty table
PROC ResetScreen
  mset screen,40*26,0
  
  ' Draw the four black corners of the screen
  poke screen, 88:poke screen+39,89
  poke screen+40*24, 90:poke screen+40*25-1,91
ENDPROC

' Call to show the screen, or occasionally to stop Atari attract/screensaver color mode from occuring
PROC ShowScreen
  poke 77,0:pause:poke 559,46+16
ENDPROC


' ============================================================================
' (Utility Functions) Convert string to upper case, replace character in string
PROC ToUpper text
  for __i=text+1 to text + peek(text)
    if peek(__i) >$60 and peek(__i)<$7B then poke __i, peek(__i)-32
  next
ENDPROC

' ============================================================================
' Print #6 Replacement
' Since there is a custom screen location for 26 rows, print #6 will not work out of the box, 
' I use POKE routines to PRINT. These were written over time as needed, so not as organized or optimized as they could be.
' I wrote these before switching to a double buffered approach. A speed/size optimization could be done
' revert to PRINT #6, but would still need some trickery for the last 2 rows. 

PROC PrintUpper text
  temp$=$(text)
  @ToUpper &temp$
  @Print &temp$
ENDPROC

PROC PrintAt _col _row text
  @Pos _col, _row
  @Print text
ENDPROC

PROC POS _col _row
  __loc = screen + 40*_row +_col
ENDPROC

' Inverse is the analog to COLOR(128)
PROC PrintInv text
  __print_inverse=128
  @Print text
  __print_inverse=0
ENDPROC

' Reverse prints right aligned, starting at the current location
PROC PrintReverse
  __print_reverse = 1
ENDPROC

PROC PrintVal text
  @Print &str$(text)
ENDPROC

' Prints text, followed by space up the specified character length.
' Useful for printing "100" in one moment, then "1  " next, without building the string manually
PROC PrintValSpace text __len
  @PrintSpace &str$(text), __len
ENDPROC

' Prints space for the rest of this line - used for bottom status bar
PROC PrintSpaceRest
  __charsLeft = 40 - (__loc-screen-40*_row)
  if  __charsLeft>0 then mset __loc, __charsLeft, 0
ENDPROC

PROC PrintSpace text __len
  if __print_reverse 
    temp$=""
    while peek(text)+len(temp$)<__len: temp$ =+" ": wend
    temp$ =+ $(text)    
  else 
    temp$ = $(text)
    while len(temp$)<__len: temp$ =+" ": wend
  endif

  @print &temp$
ENDPROC

' ============================================================================
' Core Printing routine. Converts from ATASCII to INTERNAL, handling inverted, alphanumeric and a few other supported characters
PROC Print text
  if __print_reverse then __loc = __loc - peek(text)+1
  ' Go through each character and convert from ATASCII to INTERNAL, then poke to memory to draw it
  FOR __i=text+1 to text+peek(text)
    _code = peek(__i)
    
    if _code<32
      _code= _code + 64
    elif _code< 95
      _code= _code - 32
      if _code = 12 : _code=116 ' Handle comma
      elif _code = 13 : _code=125  ' Handle hyphen
      elif _code = 14 : _code=115  ' Handle period
      elif _code = 15 : _code=124  ' Handle /
      endif
    elif _code<128
    elif _code<160
      _code= _code + 64
    elif _code<223
      _code= _code - 32
    endif

    poke __loc,_code+__print_inverse
    inc __loc
  next

  ' Reset print reverse
  __print_reverse = 0
  
ENDPROC

' Print a byte directly (INTERNAL, not ATASCII)
PROC PrintByte _byte
  poke __loc,_byte
  inc __loc
ENDPROC