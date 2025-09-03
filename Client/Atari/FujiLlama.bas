' Fuji-Llama Title Page
' Written in Atari FastBasic
' @author  Simon Young


' Disable BASIC on XL/XE to make more memory available. (found in Erics 5card code don't know if I need it or not)
if dpeek(741)-$BC00<0
  ' Disable BASIC
  pause: poke $D301, peek($D301) ! 2: poke $3F8, 1
  ' Set memtop to 48K
  dpoke 741, $BC00
endif

' Fuji-Net Setup Variblies 
UNIT=1
dim responseBuffer(1023) BYTE
JSON_MODE=1
URL$=""
BaseURL$="N:HTTP://192.168.68.100:8080"
QUERY$=""$9B
JSON$="/tables"
dummy$=""
' Initialize strings - this reserves their space in memory so NInput can write to them
Dim  TableID$(6),TableName$(6),TableCurrentPlayers$(6),TableMaxPlayers$(6),TableStatus$(6)
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
dealt=0
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



' --------- Main program -----------------------------
' Loop until the player has successfully joined a table
Repeat
do 
  ' Draw the welcome screen and display the tables available to join
  @welcome

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
  if dealt=1 then PreviousLastMovePlayed$="Cards Dealt"
 endif
 K=0
 if PlayerStatus(PlayerIndex)=1 or LastMovePlayed$[1,4]="Wait" then GET K  
 if K=68 or K=67 or K=78 or K=70 
  moves$=CHR$(K)
  @playMove 
 endif
 if K=83 then @StartGame
UNTIL K=27

UNTIL K=27
' all done for now exit the program
NCLOSE UNIT ' Close encase it's still open
' Exit the program
END

' --------- End of Main program ----------------------

proc welcome
' This procedure draws the welcome screen and displays the tables available to join
' Draw the opening screen 
GRAPHICS 0
SETCOLOR 2,0,0
SETCOLOR 1,14,6
POKE 82,0 'set margin to zero
?
? "      *** Welcome to Fuji-Llama ***    "
?

? " **************************************"
? " *Table Name                   Players*"
? " **************************************"


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


'now display the data on the welcome page 
X=33:Y=6
for a=0 to 6
? " *";(A+1);",";TableName$(a);
Position X,Y: ? TableStatus$(a)[1,1];" ";TableCurrentPlayers$(a);"/";TableMaxPlayers$(a);"*"
inc y
next a
? " **************************************"

input " Enter your name ?";_name$
? " **************************************"




input " Enter the table number to join it ?";_TN
? " **************************************"




JSON$="/join?table="
JSON$=+TableID$(_TN-1) ' Join the table based on the name selected
JSON$=+"&player="
JSON$=+_name$


? "Connecting to FujiNet at "

? "Please wait, this may take a few seconds"
? "          ..."

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
  if key$="c" then PlayerBlackCounters(INDEX)=VAL(value$)
  if key$="ph" then PlayerHand$(INDEX)=value$   
  if key$="pvm" 
  PlayerValidMoves$(INDEX)=value$
INC INDEX  ' If read last field of a Player Array, increment index and read next player
PlayerScore(INDEX)=(PlayerBlackCounters(INDEX)*10)+PlayerWhiteCounters(INDEX)
ENDIF
loop 
' find the player index for the current player
for a=0 to 6
 if PlayerName$(a)=_name$
 PlayerIndex=a
 endif
Next a
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
? "Status: ";LastMovePlayed$
? "<or press (S) to Start>"
exit
ENDIF
if LastMovePlayed$[1,12]="Game Started" and dealt=0
dealt=1
? "Game has started, good luck"
? "Dealing the cards to ..."
for a=0 to 6
 if PlayerName$(a)<>"" 
  ? "Player ";(A+1);":";PlayerName$(a)
 endif
Next a
? "<press space to start>"
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

' /move?table=ai3&player=Bob&VM=F
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
? "Round Over - Scores are"
? MessageLine1$
if MessageLine2$<>"" then ? MessageLine2$
if MessageLine3$<>"" 
? MessageLine3$
gameover=1
ENDIF
? "****************************************";
for a=0 to 6
 if PlayerName$(a)<>""
  ? PlayerName$(a);"'s cards are ";PlayerHand$(a);",";
  ? PlayerMessage1$(a);
  ? PlayerMessage2$(a);
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