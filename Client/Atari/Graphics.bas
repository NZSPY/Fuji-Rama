
' use custom Font for FujiLlama
' By Simon Young 2025

' --------- DIM all the string Arrays -------------------
Dim TableID$(6),TableName$(6),PlayerName$(5),PlayerHand$(5),PlayerValidMoves$(5)

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
  TableID$(j)="":TableName$(j)="":PlayerName$(j)=""
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
TableID$(j)="":TableName$(j)="":PlayerName$(j)=""

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
data byte = 0,0,64,64,64,64,64,85,
data byte = 0,0,0,0,0,0,0,85,
data byte = 0,0,1,1,1,1,1,85,
data byte = 0,0,64,64,64,64,76,85,
data byte = 0,0,64,64,76,64,76,85,
data byte = 0,0,76,64,76,64,76,85,
data byte = 0,0,0,0,0,0,32,85,
data byte = 0,0,0,0,32,0,32,85,
data byte = 0,0,32,0,32,0,32,85,
data byte = 32,0,32,0,32,0,32,85,
data byte = 0,0,1,1,1,1,33,85,
data byte = 0,0,1,1,33,1,33,85,
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
data byte = 106,106,106,106,106,106,106,106,
data byte = 170,170,170,170,170,170,170,170,
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
data byte = 10,47,191,181,183,183,183,183,
data byte = 12,12,12,12,252,252,12,12,
data byte = 12,12,12,12,15,15,12,12,
data byte = 0,0,0,0,255,255,12,12,
data byte = 128,224,248,248,120,120,120,120,
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
data byte = 106,106,106,106,255,255,0,0,
data byte = 170,170,170,170,255,255,0,0,
data byte = 0,0,0,0,0,32,32,128,
data byte = 183,183,183,183,181,191,47,10,
data byte = 0,0,0,80,0,0,0,0,
data byte = 0,0,0,0,15,15,12,12,
data byte = 0,0,0,0,252,252,12,12,
data byte = 12,12,12,12,15,15,0,0,
data byte = 12,12,12,12,252,252,0,0,
data byte = 164,164,164,164,255,255,0,0,
data byte = 0,8,8,32,32,32,128,128,
data byte = 0,0,0,0,168,0,0,0,
data byte = 12,12,12,12,255,255,0,0,
data byte = 120,120,120,120,248,248,224,128

' DLI Colors 
data background_color()B.=$0,0,0
data text_color()B.=$0E,$0E,0

' Color Themes: (Background & card border)
' Themes: Green, Blue, Brown, Gray
DATA colorThemeMap()      =  $B4,$88,  $84,$08, $22,$28, $04,$08,' NTSC
DATA                      =  $A4,$78,  $74,$08, $12,$18, $04,$08 ' PAL 
colorTheme=-1

' Initialize strings and Arrays - this reserves their space in memory so NInput can write to them
Dim TableCurrentPlayers(6),TableMaxPlayers(6),TableStatus(6),PlayerStatus(5),PlayerHandCount(5),PlayerWhiteTokens(5),PlayerBlackTokens(5),PlayerScore(5),PlayerRoundScore(5),GameStatus(5)
for i=0 to 6
 TableID$(i)=""
 TableName$(i)=""
 TableCurrentPlayers(i)=0
 TableMaxPlayers(i)=0
 TableStatus(i)=0
next i
ok=0
' Player and table selection variables
TableNumber=0
myName$="TESTER" ' Default name will get this from App key when I learn how to do that

' Game state variables
Drawdeck=56
DiscardTop=7
LastMovePlayed$=""
PreviousLastMovePlayed$=""
for i=0 to 5
 playerName$(i)=""
 PlayerStatus(i)=0
 PlayerHandCount(i)=6
 PlayerWhiteTokens(i)=0
 PlayerBlackTokens(i)=0
 PlayerScore(i)=0
 PlayerHand$(i)="123456"
 PlayerValidMoves$(i)=""
 PlayerRoundScore(i)=0
 GameStatus(i)=0
next i
move$=""
PlayerIndex=0

playerName$(1)=""
playerName$(2)="BOB"
playerName$(3)=""
playerName$(4)="DAVID"
playerName$(5)=""

' --------- Main program -----------------------------


' SIO command to $70 command 'S', DSTATS $40, DBYT $04, DBUF 
POKE 731,255 ' Turn off keyclick


@InitScreen
@ShowScreen
LastMovePlayed$="Waiting for players to join"
dealt=0
playerName$(0)=myName$
Repeat
@DrawGameState
Get K
if K<85
  @GoodBeep
Else  
  @BadBeep
endif

LastMovePlayed$=""

UNTIL K=27

END

Proc DealCards
  data yend()=19,14,8,3,8,14
  data xend0()=8,12,16,20,24,28
  data xend1()=1,3,5,7,9,11
  data xend2()=1,3,5,7,9,11
  data xend3()=14,16,18,20,22,24
  data xend4()=38,36,34,32,30,28
  data xend5()=38,36,34,32,30,28
  for cardnumber=1 to 6
    for player=0 to 5
      if player=0 and playerName$(player)<>"" then @DrawCardFromDeck xend0(cardnumber-1),yend(player),VAL(PlayerHand$(player)[cardnumber,1])
      if player=1 and playerName$(player)<>"" then @DrawCardFromDeck xend1(cardnumber-1),yend(player),9
      if player=2 and playerName$(player)<>"" then @DrawCardFromDeck xend2(cardnumber-1),yend(player),9
      if player=3 and playerName$(player)<>"" then @DrawCardFromDeck xend3(cardnumber-1),yend(player),9
      if player=4 and playerName$(player)<>"" then @DrawCardFromDeck xend4(cardnumber-1),yend(player),9
      if player=5 and playerName$(player)<>"" then @DrawCardFromDeck xend5(cardnumber-1),yend(player),9
    next player
  next cardnumber
  @DrawCardFromDeck 20,9,DiscardTop
  dealt=1
ENDPROC


Proc DrawCardFromDeck _endX _endY _card
  SOUND 0,121,1,8
  dx=18:dy=10: endX=_endX : endY=_endY : card=_card
  xchange=-1:ychange=-1
  if endX>dx then xchange=1 
  if endy>dy then ychange=1 
  repeat
    @DrawBuffer 
    if dx<>endx then DX=DX+xchange
    if dy<>endy then DY=DY+ychange
    if card=9 
      @POS dx,dy:@PrintByte 13:@PrintByte 14
      @POS dx,dy+1:@PrintByte 15:@PrintByte 27
      else
      @DrawCard dx,dy,card
    endif
  until dx=endx and dy=endy
  dec Drawdeck
  @POS 19,13: @PrintVal Drawdeck
  @UpdateScreenBuffer
  sound
ENDPROC

Proc UpdateScreenBuffer
  move &screenBuffer,&screenBuffer+1040, 1040
  @DrawBuffer
ENDPROC

PROC DrawBorder _col _row _sizeX _sizeY _colour
  X=_col:Y=_row:Xsize=_sizex:Ysize=_sizey:colour=_colour
  @POS X,Y:@PrintByte 114+colour
  For Xstep=X+1 to X+Xsize
  @POS Xstep,Y:@PrintByte 32+colour
  Next Xstep
  @POS Xstep,Y:@PrintByte 115+colour
  
  For Ystep=Y+1 to Y+15
  @POS X,Ystep:@PrintByte 31+colour
  For Xstep=X+1 to X+Xsize
  @POS Xstep,Ystep:@PrintByte 0
  Next Xstep
  @POS Xstep,Ystep:@PrintByte 31+colour
  Next Ystep

  @POS X,Ystep:@PrintByte 117+colour
  For Xstep=X+1 to X+Xsize
  @POS Xstep,Ystep:@PrintByte 32+colour
  Next Xstep
  @POS Xstep,Ystep:@PrintByte 123+colour
ENDPROC

PROC GoodBeep
  SOUND 0,121,10,8
  pause 4
  SOUND 
ENDPROC

PROC BadBeep
  SOUND 0,255,10,8
  pause 4
  SOUND 
ENDPROC

PROC DrawGameState 
  ' Draw the current game state on the screen
  @EnableDoubleBuffer
  @ResetScreen
  @POS 0,5: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  @POS 0,10: @PrintINV &"@@@@@@@@@@@@@@@@"
  @POS 24,10: @PrintINV &"@@@@@@@@@@@@@@@@"
  @POS 0,16: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" 
  @POS 15,5: @PrintByte 223:@POS 23,5: @PrintByte 223 
  for Y=6 to 15  
  @POS 15,Y: @PrintByte 159:@POS 23,Y: @PrintByte 159
  next Y
  @POS 15,10: @PrintByte 221:@POS 23,10: @PrintByte 222  
  @POS 15,16: @PrintByte 254:@POS 23,16: @PrintByte 254                 
  @DrawPlayers
  if LastMovePlayed$="Waiting for players to join"
  @POS 2,3: @Print &"PLEASE WAIT FOR OTHER PLAYERS TO JOIN"
  @POS 3,4: @Print &"OR PRESS S TO START WITH AI PLAYERS" 
  @DrawCard 17,9,8 ' Draw Deck
  @DrawCard 20,9,0 ' Discard Pile
  @DrawBufferEnd
  @ShowScreen
  exit
  ENDIF
  if Drawdeck>0 
  @DrawCard 17,9,8 ' Draw Deck
  @POS 19,13: @PrintVal Drawdeck
  else
  @DrawCard 17,9,0 ' Empty Draw Deck
  endif
  @DrawCard 20,9,DiscardTop ' Discard Pile
  @POS 1,24: @PrintUpper & LastMovePlayed$[1,38]
  @POS 5,25:@Print &"H-HELP C-COLOR E-EXIT Q-QUIT"
  if PlayerStatus(PlayerIndex)=1 
  @POS 1,24: @PrintUpper & LastMovePlayed$[1,23]
  @Print &", YOUR TURN NOW"
  @DrawDrawButton 2,20
  @DrawFoldButton 37,20
  ENDIF
  @DrawBufferEnd
  @ShowScreen
ENDPROC

PROC DrawMainPlayerHand _Index
  DisplayIndex=_Index:YY=19
  if PlayerHandCount(DisplayIndex)<9
  XX=((36-(PlayerHandCount(DisplayIndex)*4))/2)+2
  for a=1 to len(PlayerHand$(DisplayIndex))
    card=VAL(PlayerHand$(DisplayIndex)[a,1])
    if playerStatus(DisplayIndex)=2 then card=8 ' if folded show back of card
    @DrawCard XX,YY,card
    XX=XX+4
  next a
  elif PlayerHandCount(DisplayIndex)<10 ' more than 8 cards so print cards closer together
  XX=((36-(PlayerHandCount(DisplayIndex)*3))/2)+2
  for a=1 to len(PlayerHand$(DisplayIndex))
    card=VAL(PlayerHand$(DisplayIndex)[a,1])
    if playerStatus(DisplayIndex)=2 then card=8 ' if folded show back of card
    @DrawCard XX,YY,card
    XX=XX+3
 next a
 else ' more than 10 cards so print even closer together
  XX=((36-(PlayerHandCount(DisplayIndex)*2)+1)/2)+2
  for a=1 to len(PlayerHand$(DisplayIndex))
    card=VAL(PlayerHand$(DisplayIndex)[a,1])
    if playerStatus(DisplayIndex)=2 then card=8 ' if folded show back of card
    @DrawCard XX,YY,card
    XX=XX+2
 next a
  Endif
ENDPROC

PROC DrawCard _col _row _card
  XXX=_col:YYY=_row:card=_card
  IF card=0  
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 63:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 63:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF card=1 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 66:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 67:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
    ElIF card=2 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 196:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 197:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF card=3 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS XXX,YYY+1:@PrintByte 62:@PrintByte 68:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 70:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF card=4 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 199:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 200:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF card=5 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS XXX,YYY+1:@PrintByte 62:@PrintByte 73:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 70:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF card=6 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 202:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 203:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 59:@PrintByte 60:@PrintByte 61
  ElIF card=7 
    @POS XXX,YYY:@PrintByte 204:@PrintByte 205:@PrintByte 206
    @POS XXX,YYY+1:@PrintByte 207:@PrintByte 208:@PrintByte 209
    @POS XXX,YYY+2:@PrintByte 210:@PrintByte 211:@PrintByte 212
    @POS XXX,YYY+3:@PrintByte 213:@PrintByte 214:@PrintByte 215
  ElIF card=8 
   @POS XXX,YYY:@PrintByte 97:@PrintByte 98:@PrintByte 99
    @POS XXX,YYY+1:@PrintByte 100:@PrintByte 101:@PrintByte 102
    @POS XXX,YYY+2:@PrintByte 103:@PrintByte 104:@PrintByte 105
    @POS XXX,YYY+3:@PrintByte 106:@PrintByte 107:@PrintByte 108
  endif
ENDPROC

PROC DrawCardLine _col _row _card
  XXX=_col:YYY=_row:card=_card
  IF card=0  
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 63:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 63:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=1 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 66:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 67:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
    ElIF card=2 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 196:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 197:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=3 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS XXX,YYY+1:@PrintByte 62:@PrintByte 68:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 70:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=4 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 199:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 200:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=5 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
   @POS XXX,YYY+1:@PrintByte 62:@PrintByte 73:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 70:@PrintByte 64
   @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=6 
    @POS XXX,YYY:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS XXX,YYY+1:@PrintByte 62:@PrintByte 202:@PrintByte 64
    @POS XXX,YYY+2:@PrintByte 62:@PrintByte 203:@PrintByte 64
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=7 
    @POS XXX,YYY:@PrintByte 204:@PrintByte 205:@PrintByte 206
    @POS XXX,YYY+1:@PrintByte 207:@PrintByte 208:@PrintByte 209
    @POS XXX,YYY+2:@PrintByte 210:@PrintByte 211:@PrintByte 212
    @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  ElIF card=8 
   @POS XXX,YYY:@PrintByte 97:@PrintByte 98:@PrintByte 99
    @POS XXX,YYY+1:@PrintByte 100:@PrintByte 101:@PrintByte 102
    @POS XXX,YYY+2:@PrintByte 103:@PrintByte 104:@PrintByte 105
   @POS XXX,YYY+3:@PrintByte 114:@PrintByte 115:@PrintByte 123
  endif
ENDPROC

PROC DrawPlayerScore _col _row _BlackTokens _WhiteTokens
  xx=_col:yy=_row:bt=_BlackTokens:wt=_WhiteTokens
  IF BT=0
  @POS xx,yy:@PrintByte 1:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ELIF BT=1
  @POS xx,yy:@PrintByte 4:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ELIF BT=2   
  @POS xx,yy:@PrintByte 5:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ELIF BT>=3                                               
  @POS xx,yy:@PrintByte 6:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ENDIF

  IF WT=0
    @POS xx+1,yy:@PrintByte 2:@PrintByte 2:@PrintByte 3
  ELIF WT=1
    @POS xx+1,yy:@PrintByte 2:@PrintByte 2:@PrintByte 11
  ELIF WT=2   
    @POS xx+1,yy:@PrintByte 2:@PrintByte 7:@PrintByte 11
  ELIF WT=3                                               
    @POS xx+1,yy:@PrintByte 7:@PrintByte 7:@PrintByte 11
  ELIF WT=4
    @POS xx+1,yy:@PrintByte 7:@PrintByte 8:@PrintByte 11
  ELIF WT=5   
    @POS xx+1,yy:@PrintByte 8:@PrintByte 8:@PrintByte 11
  ELIF WT=6                                               
    @POS xx+1,yy:@PrintByte 8:@PrintByte 8:@PrintByte 12  
  ELIF WT=7
    @POS xx+1,yy:@PrintByte 9:@PrintByte 8:@PrintByte 12
  ELIF WT=8   
    @POS xx+1,yy:@PrintByte 9:@PrintByte 9:@PrintByte 12
  ELIF WT=9                                               
    @POS xx+1,yy:@PrintByte 9:@PrintByte 10:@PrintByte 12
  ELIF WT>=10                                               
    @POS xx+1,yy:@PrintByte 10:@PrintByte 10:@PrintByte 12
  ENDIF
ENDPROC

PROC DrawDrawButton _col _row 
  XXX=_col:YYY=_row
  @POS XXX,YYY:@PrintByte 220:@PrintByte 224
  @POS XXX,YYY+1:@PrintByte 245:@PrintByte 255
ENDPROC

PROC DrawFoldButton _col _row 
  XXX=_col:YYY=_row
  @POS XXX,YYY:@PrintByte 141:@PrintByte 142
  @POS XXX,YYY+1:@PrintByte 143:@PrintByte 155
ENDPROC

PROC DrawPlayers 
  ' Draw the players around the table
  Xoffset=LEN(PlayerName$(PlayerIndex))
  if Xoffset>12 then Xoffset=12
  X=((36-(Xoffset+6))/2)+2
  Y=17
  @POS X,Y: @PrintUpper &PlayerName$(PlayerIndex)[1,Xoffset]
  @POS X+Xoffset,Y: @Print &":"
  @POS X+Xoffset+1,Y: @PrintVal PlayerStatus(PlayerIndex)
  @DrawPlayerScore X+Xoffset+2,17,PlayerBlackTokens(PlayerIndex),PlayerWhiteTokens(PlayerIndex)
  if PlayerHandCount(playerIndex)>0 and dealt=1 then @DrawMainPlayerHand Playerindex
  DATA XPOS()=1,1,0,25,25
  DATA HPOS()=1,1,13,26,26
  DATA YPOS()=12,6,1,6,12
  slot=0
  For a=0 to 5
      if  a<>PlayerIndex
        if PlayerName$(a)<>""
          Xoffset=len(PlayerName$(a))
          if Xoffset>8 and slot<>2 then Xoffset=8
          if Xoffset>12 and slot=2 then Xoffset=12
          X=(14-(Xoffset+6))/2
          if slot=2 then X=((36-(Xoffset+6))/2)+2
          X=X+XPOS(SLOT)
          @POS X,YPOS(SLOT): @PrintUpper &PlayerName$(a)[1,Xoffset]
          @POS X+Xoffset,YPOS(SLOT): @Print &":"
          @POS X+Xoffset+1,YPOS(SLOT): @PrintVal PlayerStatus(a)
          @DrawPlayerScore X+Xoffset+2,YPOS(SLOT),PlayerBlackTokens(a),PlayerWhiteTokens(a)
          folded=0
          if playerStatus(a)=2 then folded=128
          if dealt=1
            if slot=2 
              @DrawPlayerHand XPOS(SLOT)+((38-(PlayerHandCount(a)+2))/2),YPOS(SLOT)+2,PlayerHandCount(a),folded
              else
              @DrawPlayerHand XPOS(SLOT)+((14-(PlayerHandCount(a)+2))/2),YPOS(SLOT)+2,PlayerHandCount(a),folded
              ENDIF
          endif
          inc SLOT
        Endif
      Endif
  Next a
ENDPROC

PROC DrawPlayerHand _col _row _numCards _folded
  if _numCards=0 then exit
  XXX=_col:YYY=_row:folded=_folded
  if _numCards>12 then _numCards=12
  for i=1 to _numCards
  @POS (XXX+i)-1,YYY:@PrintByte 13+folded:@PrintByte 14+folded
  @POS (XXX+i)-1,YYY+1:@PrintByte 15+folded:@PrintByte 27+folded
  next i
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

PROC DisableDoubleBuffer
  screen = &screenbuffer
ENDPROC

PROC EnableDoubleBuffer
  screen = &screenBuffer + 1040
ENDPROC

Proc DrawBufferEnd
  @DrawBuffer
  @DisableDoubleBuffer
endproc

PROC DrawBuffer
  pause
  move &screenBuffer+1040,&screenBuffer, 1040
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