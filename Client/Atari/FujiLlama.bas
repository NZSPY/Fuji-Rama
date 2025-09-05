' Fuji-Llama Title Page
' Written in Atari FastBasic
' @author  Simon Young (with lots of help from Eric Carr and Thomas Cherryhomes)
' @version September 2025
' This is a client for the Fuji-Llama game server



' Disable BASIC on XL/XE to make more memory available. (found in Erics 5card code don't know if I need it or not)
if dpeek(741)-$BC00<0
  ' Disable BASIC
  pause: poke $D301, peek($D301) ! 2: poke $3F8, 1
  ' Set memtop to 48K
  dpoke 741, $BC00
endif

Dim  TableID$(6),TableName$(6),TableCurrentPlayers$(6),TableMaxPlayers$(6),TableStatus$(6)
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
  TableID$(j)="":TableName$(j)="":TableCurrentPlayers$(j)=""
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
TableID$(j)="":TableName$(j)="":TableCurrentPlayers$(j)=""

' Now charBuffer will be aligned to a 1K boundary
dim charBuffer(1023) BYTE

' *************** END IMPORTANT NOTE ***************
' **************************************************
DIM Screen
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

' Fuji-Net Setup Variblies 
UNIT=1
JSON_MODE=1
URL$=""
BaseURL$="N:HTTP://192.168.68.100:8080"
QUERY$=""$9B
JSON$="/tables"
dummy$=""
' Initialize strings - this reserves their space in memory so NInput can write to them
for i=0 to 6
 TableID$(i)=""
 TableName$(i)=""
 TableCurrentPlayers$(i)=""
 TableMaxPlayers$(i)=""
 TableStatus$(i)=""
next i
ok=0
' Player and table selection variables
_TN=0
_name$=""
gameover=0
shown=0

' Game state variables
Dim PlayerName$(6),PlayerStatus(6),PlayerHandCount(6),PlayerWhiteCounters(6),PlayerBlackCounters(6),PlayerScore(6),PlayerHand$(6),PlayerValidMoves$(6),PlayerMessage1$(6),PlayerMessage2$(6),PlayerRoundScore(6)
Drawdeck=0
DiscardTop=0
LastMovePlayed$=""
PreviousLastMovePlayed$=""
for i=0 to 6
 playerName$(i)=""
 PlayerStatus(i)=0
 PlayerHandCount(i)=0
 PlayerWhiteCounters(i)=0
 PlayerBlackCounters(i)=0
 PlayerScore(i)=0
 PlayerHand$(i)=""
 PlayerValidMoves$(i)=""
  PlayerMessage1$(i)=""
  PlayerMessage2$(i)=""
  PlayerRoundScore(i)=0
next i
moves$=""
PlayerIndex=0

' Game Result variables
MessageLine1$=""
MessageLine2$=""
MessageLine3$=""
' Error variable
_ERR=0    
' Index variable for reading FujiNet JSON data
INDEX=0
' Variables for NInput helper code
__NI_unit=0
__NI_index=0
__NI_bufferEnd=0
__NI_indexStop=0
__NI_resultLen=0

' Silence the loud SIO noise
poke 65,0




' --------- Main program -----------------------------
@TitleScreen
' Loop until the player has successfully joined a table
Repeat
do 
  ' Draw the welcome screen and display the tables available to join
  @tableSelection

  ' Check if the player has joined a table, if not then exit
  @checkErrors

  ' If the player has joined a table, then exit the loop
  if ok=1 then exit
  GET K
loop
  
  ? "You have joined table "
 ? TableName$(_TN-1)
  ? "as player ";_name$

REPEAT
 @readGameState
 if LastMovePlayed$[1,4]="(RE)"
  if shown=0 
    @ShowResults
    shown=1
  endif
  if gameover=1 then exit
 elif LastMovePlayed$<>PreviousLastMovePlayed$
  @DrawGameState
  PreviousLastMovePlayed$=LastMovePlayed$
 endif
 K=0
 if PlayerStatus(PlayerIndex)=1 or LastMovePlayed$[1,4]="Wait" then GET K  
 if K=68 or K=67 or K=78 or K=70 
  moves$=CHR$(K)
  @playMove 
 endif
 if K=83 then @StartGame
 if k=32 then PreviousLastMovePlayed$=""
UNTIL K=27

UNTIL K=27
' all done for now exit the program
NCLOSE UNIT ' Close encase it's still open
' Exit the program
END

' --------- End of Main program ----------------------

proc TitleScreen
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
  

  @PrintCard 5,13,1
  @PrintCard 9,13,2
  @PrintCard 13,13,3
  @PrintCard 17,13,4
  @PrintCard 21,13,5
  @PrintCard 25,13,6
  @PrintCard 29,13,7
  @PrintCard 33,13,8

Repeat
@CycleColorTheme
Get K
UNTIL K=27
Endproc




proc tableSelection
' This procedure draws the welcome screen and displays the tables available to join
' Draw the opening screen 
@EnableDoubleBuffer
@ResetScreen
@DrawTheWelcomeScreen
@DrawBufferEnd
@ShowScreen


JSON$="/tables"
@CallFujiNet

' Initialize reading the api response
 @NInputInit UNIT, &responseBuffer

'Convert table JSON into strings for display and slection use 
INDEX=0
do
  ' If the first read is empty, we reached the end
  @NInput &dummy$ : if len(dummy$) = 0 then exit
  @NInput &TableID$(INDEX)
  @NInput &dummy$ : @NInput &TableName$(INDEX)
  @NInput &dummy$ : @NInput &TableCurrentPlayers$(INDEX)
  @NInput &dummy$ : @NInput &TableMaxPlayers$(INDEX)
  @NInput &dummy$ : @NInput &TableStatus$(INDEX)

  INC INDEX
loop 
@EnableDoubleBuffer
@ResetScreen
@DrawTheWelcomeScreen

'now display the data on the welcome page 
X=5:Y=7
for a=0 to 6

@POS X,Y:@Print &STR$(A+1)
@Print & ","
@PrintUpper & TableName$(a)
@POS 30,Y:@PrintUpper &TableStatus$(a)[1,1]
@POS 32,Y:@PrintUpper &TableCurrentPlayers$(a)
@POS 33,Y:@PrintUpper &"/"
@POS 34,Y:@PrintUpper &TableMaxPlayers$(a)
y=y+2
next a

@DrawBufferEnd
@ShowScreen
@POS 5,22: @Print &  "ENTER YOUR NAME"

GET K 

@POS 5,22: @Print & "ENTER THE TABLE NUMBER TO JOIN"
GET K 

_name$="SIMON" ' for testing only
_TN =1 ' for testing only

JSON$="/join?table="
JSON$=+TableID$(_TN-1) ' Join the table based on the name selected
JSON$=+"&player="
JSON$=+_name$


@POS X,Y+1: @Print &    "CONNECTING TO TABLE...                  "

@POS X,Y+2: @Print &    "PLEASE WAIT THIS MAY TAKE A MOMENT... "


@CallFujiNet ' Call the FujiNet API to join the table
@NInputInit UNIT, &responseBuffer ' Initialize reading the api response
@NInput &dummy$ ' Read the response from the FujiNet API

endproc


' Read the game state from the FujiNet API
proc readGameState
' ? "getting game state from FujiNet"
JSON$="/state?table="
JSON$=+TableID$(_TN-1) 
JSON$=+"&player="
JSON$=+_name$
' JSON$="/state?table=ai1&player=SIMON"
@CallFujiNet ' Call the FujiNet API to join the table
@NInputInit UNIT, &responseBuffer ' Initialize reading the api response
@NInput &dummy$ ' Read the response from the FujiNet API
@checkErrors
if ok <>1 then Exit
@NInput &dummy$
Drawdeck=VAL(dummy$)
key$="" : value$=""
do ' Loop reading key/value pairs until we reach the Start of the Player Array
  ' Get the next line of text from the api response as the key
  @NInput &key$
 
  ' An empty key means we reached the end of the response
  if len(key$) = 0 then exit
  ' Get the next line of text from the api response as the value
  @NInput &value$
  
  ' Depending on key, set appropriate variable to the value
  if key$="dp" then DiscardTop=VAL(value$)
  if key$="lmp" 
  LastMovePlayed$=value$
  EXIT
  ENDIF
loop 
@NInput &dummy$ ' Read the Start of the Player Array
INDEX=0
do ' Loop reading key/value pairs until we reach the Start of the Player Array
  ' Get the next line of text from the api response as the key
  @NInput &key$
  
  ' An empty key means we reached the end of the response
  if len(key$) = 0 then exit

  ' Get the next line of text from the api response as the value
  @NInput &value$
 
  ' Depending on key, set appropriate variable to the value
  if key$="n" then PlayerName$(INDEX)=value$
  if key$="s" then PlayerStatus(INDEX)=VAL(value$)
  if key$="nc" then PlayerHandCount(INDEX)=VAL(value$)
  if key$="wc" then PlayerWhiteCounters(INDEX)=VAL(value$)
  if key$="bc" then PlayerBlackCounters(INDEX)=VAL(value$)
  if key$="ph" then PlayerHand$(INDEX)=value$   
  if key$="pvm" 
  PlayerValidMoves$(INDEX)=value$
  PlayerScore(INDEX)=(PlayerBlackCounters(INDEX)*10)+PlayerWhiteCounters(INDEX)
  INC INDEX  ' If read last field of a Player Array, increment index and read next player
ENDIF
loop 
' find the player index for the current player
for a=0 to 6
 if PlayerName$(a)=_name$
 PlayerIndex=a
 endif
Next a
endproc


' This procedure draws the welcome screen and blank table grid
Proc DrawTheWelcomeScreen

@POS 10,2: @Print &"WELCOME TO FUJI-LLAMA"
@PrintCard 2,3,7:@PrintCard 35,3,8
@POS 5,4: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
@POS 5,5: @Print &"TABLE NAME":@POS 28,5: @Print &"PLAYERS"
@POS 5,6: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
for y=7 to 19
@POS 3,y: @PrintINV &"?":@POS 36,y: @PrintINV &"?"
next y
for y=8 to 20 step 2
@POS 4,y: @Print &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
next y
@PrintCard 2,20,8:@PrintCard 35,20,7
@POS 5,21: @PrintINV &"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
endproc


PROC DrawGameState ' Draw the current game state on the screen
GRAPHICS 0
SETCOLOR 2,0,0
SETCOLOR 1,14,6
POKE 82,0 'set margin to zero 
? "****************************************";
? "        *** Fuji-Llama ***            "
? "****************************************";
? "  ";tableName$(_TN-1);" - Player: ";_name$
if LastMovePlayed$="Waiting for players to join"
for a=0 to 6
  if PlayerName$(a)<>"" 
  ? "Player ";(A+1);":";PlayerName$(a)
  endif
Next a
? "      Waiting for players to join"
? "   <Space to refresh or (S) to Start>"
? "****************************************";
exit
ENDIF

? LastMovePlayed$
? "****************************************";
for a=0 to 6
 if PlayerName$(a)<>"" and PlayerName$(a)<>_name$
  ? PlayerName$(a);" has ";PlayerHandCount(a);" cards";
? ":";PlayerStatus(a);":";
   ? "BC:";PlayerBlackCounters(a);
  ? " WC:";PlayerWhiteCounters(a);
  ? " Score:";PlayerScore(a)
  
 endif
 Next a
 ? "****************************************";
 ? "Cards in Draw Deck:";Drawdeck
 ? "Top card on Discard Pile:";DiscardTop
 ? "****************************************";
  ? "BC:";PlayerBlackCounters(PlayerIndex);
  ? " WC:";PlayerWhiteCounters(PlayerIndex);
  ? " Score:";PlayerScore(PlayerIndex)
? "Your Hand:";PlayerHand$(PlayerIndex)
if len(PlayerValidMoves$(PlayerIndex))=0
 ? "Please wait for others to play"
else
? "Your Valid Moves:"
 for a=1 to len(PlayerValidMoves$(PlayerIndex))
  moves$=PlayerValidMoves$(PlayerIndex)[a,1]
if moves$="D" then ?"D (Draw) ";
if moves$="C" then ?"C (Play Current) ";
if moves$="N" then ?"N (Play Next) ";
if moves$="F" then ? "F (Fold) "
 next a
endif
? "****************************************";
endproc


proc playMove
shown=0
JSON$="/move?table="
JSON$=+TableID$(_TN-1)
JSON$=+"&player="
JSON$=+_name$
JSON$=+"&VM="
JSON$=+moves$
@CallFujiNet
endproc

proc StartGame
JSON$="/start?table="
JSON$=+TableID$(_TN-1)
@CallFujiNet
endproc

proc ShowResults
JSON$="/results?table="
JSON$=+TableID$(_TN-1)
JSON$=+"&player="
JSON$=+_name$
@CallFujiNet
@NInputInit UNIT, &responseBuffer
@NInput &dummy$
@checkErrors
if ok <>1 then Exit
@NInput &dummy$
MessageLine1$=dummy$
key$="" : value$=""
do ' Loop reading key/value pairs until we reach the Start of the Player Array
  ' Get the next line of text from the api response as the key
  @NInput &key$
  ' An empty key means we reached the end of the response
  if len(key$) = 0 then exit
  ' Get the next line of text from the api response as the value
  @NInput &value$
  ' Depending on key, set appropriate variable to the value
  if key$="msg2" then MessageLine2$=value$
  if key$="msg3" 
  MessageLine3$=value$
  EXIT
  ENDIF
loop 
@NInput &dummy$ ' Read the Start of the Player Array
INDEX=0
do ' Loop reading key/value pairs until we reach the Start of the Player Array
  ' Get the next line of text from the api response as the key
  @NInput &key$
  
  ' An empty key means we reached the end of the response
  if len(key$) = 0 then exit

  ' Get the next line of text from the api response as the value
  @NInput &value$
 
  ' Depending on key, set appropriate variable to the value
  if key$="n" then PlayerName$(INDEX)=value$
  if key$="ph" then PlayerHand$(INDEX)=value$   
  if key$="m1" then PlayerMessage1$(INDEX)=value$
  if key$="m2" then PlayerMessage2$(INDEX)=value$
  if key$="rs" then PlayerRoundScore(INDEX)=VAL(value$)
  if key$="s" 
  PlayerScore(INDEX)=VAL(value$)
  INC INDEX  ' If read last field of a Player Array, increment index and read next player
ENDIF
loop 
' find the player index for the current player
for a=0 to 6
 if PlayerName$(a)=_name$
 PlayerIndex=a
 endif
Next a
? "****************************************";
? "        *** Fuji-Llama ***            "
? "****************************************";
? "  ";tableName$(_TN-1);" - Player: ";_name$

? MessageLine1$
if MessageLine2$<>"" then ? MessageLine2$
if MessageLine3$<>"" 
? MessageLine3$
gameover=1
ENDIF
?  "****************************************";
for a=0 to 6
 if PlayerName$(a)<>""
  ? PlayerName$(a);"'s cards are ";PlayerHand$(a)
  ? PlayerMessage1$(a)
  ? PlayerMessage2$(a)
  ? "----------------------------------------";
endif
 Next a
? "****************************************";
? "<press space see the Leaderboard>"
GET K
? "Name                         Round Score";
for a=0 to 6
 if PlayerName$(a)<>""
  ? PlayerName$(a);"          ";PlayerRoundScore(a);" ";PlayerScore(a)
endif
 Next a
? "****************************************";
? "<press space to start new round>"
GET K
endproc


' Check data returned from FujiNet to see if it was successful or not
' and display appropriate message
Proc checkErrors
ok = 1
if len(dummy$) > 0 then
_ERR=VAL(dummy$[5,1])
  if _ERR=1 
    ok = 0
    ? " You need to specify a valid table"
  elif _ERR=2 
    ok = 0
    ? " You need to supply a player name"
    ? " to join a table"
  elif _ERR=3 
    ok = 0
    ? "Sorry: ";_name$;" someone is already"
    ? "at table ";TableName$(_TN-1);"with that name,"
    ? "please try a different"
    ? "table and or name"
  
  elif _ERR=4 
    ok = 0
    ? "Sorry: ";_name$;" table ";TableName$(_TN-1)
    ? " has a game in progress,"
    ? "please try a different table"
  elif _ERR=5 
    ok = 0
    ? "Sorry: ";_name$;" table ";TableName$(_TN-1);
    ? " is full, please try a different table"
  elif _ERR=6 
    ok = 0
    ? "Must specify both table and player name"
 elif _ERR=7 
    ok = 0
    ? "Player not found at this table"
  elif _ERR=8 
    ok = 0
    ? "Round is not over yet, no results available"
  elif _ERR=9 
    ok = 0
    ? "No human players at this table"
else
  ok = 1
endif

endproc



'-------------------------------------------------------------
' PROCEDURES to get Json data and load into the Var Result
'open the API connect and setup for Read JSON file
'Code lifted from the Introduction to Fuji-net for Atari Users
'by Thomas Cherryhomes
'(MASTODON Example)
'--------------------------------------------------------------
PROC CallFujiNet
dummy$=""
URL$=BaseURL$
URL$=+JSON$
URL$=+""$9B
@openconnection
@nsetchannelmode 
@nparsejson
IF SErr()<>1
PRINT "Could not parse JSON."
@nprinterror
GET K
ENDIF
@doJSON
ENDPROC


PROC openconnection ' Open the connection, or throw error and end program
NOPEN UNIT, 12, 0, URL$
' If not successful, then exit.
IF SERR()<>1
PRINT "Could not open connection."
@nprinterror
EXIT
ENDIF
ENDPROC

PROC nsetchannelmode ' Set the channel mode to the JSON_mode
SIO $71, UNIT, $FC, $00, 0, $1F, 0, 12, JSON_MODE
ENDPROC

PROC nparsejson ' send Parse to the FujiNet, so it parses the JSON value set by the URL$
SIO $71, UNIT, $50, $00, 0, $1f, 0, 12, 0
ENDPROC

PROC njsonquery ' Query the JSON data that has been parsesed base on the attributes in $query
SIO $71, UNIT, $51, $80, &query$+1, $1f, 256, 12, 0
ENDPROC

PROC nprinterror ' get the current eror and display on screen 
NSTATUS UNIT
PRINT "ERROR- "; PEEK($02ED)
ENDPROC

PROC DoJSON 
@njsonquery
NSTATUS UNIT
IF PEEK($02ED) > 128
PRINT "Could not fetch query:"
PRINT QUERY$
PRINT "ERROR- "; PEEK($02ED)
EXIT
ENDIF
ENDPROC



' ============================================================================
' Helper code from  Eric Carr
' (N Helper) Gets the entire response from the specified unit into the provided buffer index for NInput to read from.
' WARNING! No check is made if buffer length is long enough to hold the FujiNet payload.
' ============================================================================

PROC NInputInit __NI_unit __NI_index
NSTATUS __NI_unit
  __NI_bufferEnd = __NI_index + DPEEK($02EA)
  NGET __NI_unit, __NI_index, __NI_bufferEnd - __NI_index
  NCLOSE __NI_unit ' Close since we are done reading
ENDPROC

' ============================================================================
' (N Helper) Reads a line of text into the specified string - Similar to Atari BASIC: INPUT #N, MyString$
PROC NInput __NI_stringPointer

  ' Start the indexStop at the current index position
  __NI_indexStop = __NI_index
  
  ' Seek the end of this line (or buffer)
  while peek(__NI_indexStop) <> $9B and __NI_indexStop < __NI_bufferEnd
    inc __NI_indexStop
  wend

  ' Calculate the length of this result
  __NI_resultLen = __NI_indexStop - __NI_index
  
  ' Update the length in the output string 
  poke __NI_stringPointer, __NI_resultLen

  ' If we successfully read a value, copy from the buffer to the string that was passed in and increment the index
  if __NI_indexStop < __NI_bufferEnd
    move __NI_index, __NI_stringPointer+1, __NI_resultLen

    ' Move the buffer index for the next input
    __NI_index = __NI_indexStop + 1
  endif
ENDPROC

' ============================================================================
' Screen code from  Eric Carr lifted from 5 card stud
' ============================================================================

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

' Call to show the screen, or occasionally to stop Atari attract/screensaver color mode from occuring
PROC ShowScreen
  poke 77,0:pause:poke 559,46+16
ENDPROC


' Call to clear the screen to an empty table
PROC ResetScreen
  mset screen,40*26,0
  
  ' Draw the four black corners of the screen
poke screen, 88:poke screen+39,89
  poke screen+40*24, 90:poke screen+40*25-1,91
ENDPROC

' Reset the screen in a double buffered manner
PROC ResetScreenBuffered
  @EnableDoubleBuffer
  @ResetScreen
  @DrawBufferEnd
endproc

PROC DrawBuffer
  pause
  move &screenBuffer+1040,&screenBuffer, 1040
ENDPROC

Proc DrawBufferEnd
  @DrawBuffer
  @DisableDoubleBuffer
endproc

PROC EnableDoubleBuffer
  screen = &screenBuffer + 1040
ENDPROC

PROC DisableDoubleBuffer
  screen = &screenbuffer
ENDPROC

PROC ClearStatusBar
  PMHPOS 2,0
  mset &screenBuffer+1040+40*25, 40,0
  mset &screenBuffer+40*25, 40,0
ENDPROC

PROC ClearKeyQueue
  ' Clear out any queued key presses
  while key() : get k:wend
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

' ============================================================================
' CARD PRINTING ROUTINES
' These routines print cards to the screen at the specified location

Proc PrintCard _col _row _card
IF _card=0  
    @POS _col,_row:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS _col,_row+1:@PrintByte 63:@PrintByte 62:@PrintByte 64
    @POS _col,_row+1:@PrintByte 63:@PrintByte 62:@PrintByte 64
    @POS _col,_row+1:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF _card=1 
    @POS _col,_row:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS _col,_row+1:@PrintByte 63:@PrintByte 66:@PrintByte 64
    @POS _col,_row+1:@PrintByte 63:@PrintByte 67:@PrintByte 64
    @POS _col,_row+1:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF _card=2 
    @POS _col,_row:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS _col,_row+1:@PrintByte 63:@PrintByte 196:@PrintByte 64
    @POS _col,_row+1:@PrintByte 63:@PrintByte 197:@PrintByte 64
    @POS _col,_row+1:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF _card=3 
    @POS _col,_row:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS _col,_row+1:@PrintByte 63:@PrintByte 68:@PrintByte 64
    @POS _col,_row+1:@PrintByte 63:@PrintByte 70:@PrintByte 64
    @POS _col,_row+1:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF _card=4 
    @POS _col,_row:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS _col,_row+1:@PrintByte 63:@PrintByte 199:@PrintByte 64
    @POS _col,_row+1:@PrintByte 63:@PrintByte 200:@PrintByte 64
    @POS _col,_row+1:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF _card=5 
    @POS _col,_row:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS _col,_row+1:@PrintByte 63:@PrintByte 73:@PrintByte 64
    @POS _col,_row+1:@PrintByte 63:@PrintByte 70:@PrintByte 64
    @POS _col,_row+1:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF _card=6 
    @POS _col,_row:@PrintByte 28:@PrintByte 29:@PrintByte 30
    @POS _col,_row+1:@PrintByte 63:@PrintByte 202:@PrintByte 64
    @POS _col,_row+1:@PrintByte 63:@PrintByte 203:@PrintByte 64
    @POS _col,_row+1:@PrintByte 59:@PrintByte 60:@PrintByte 61
ElIF _card=7 
    @POS _col,_row:@PrintByte 204:@PrintByte 205:@PrintByte 206
    @POS _col,_row+1:@PrintByte 207:@PrintByte 208:@PrintByte 209
    @POS _col,_row+1:@PrintByte 210:@PrintByte 211:@PrintByte 212
    @POS _col,_row+1:@PrintByte 213:@PrintByte 214:@PrintByte 215
ElIF _card=8 
    @POS _col,_row:@Print &"abc"
    @POS _col,_row+1:@Print &"def"
    @POS _col,_row+1:@Print &"ghi"
    @POS _col,_row+1:@Print &"jkl"
endif
ENDPROC
