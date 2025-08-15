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
QUERY$=""
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
do 
  ' Draw the welcome screen and display the tables available to join
  @welcome

  ' Check if the player has joined a table, if not then exit
  @checkJoined

  ' If the player has joined a table, then exit the loop
  if ok=1 then exit
loop



' all done for now exit the program
NCLOSE UNIT ' Close encase it's still open
? "          Coming soon !!" 
? "  - rest of game not yet implemented"
? "    Press any key to exit"
GET K
' Exit the program
END





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

_T$=""
if _TN=1
_T$="ai1"
elif _TN=2
_T$="ai2"
elif _TN=3
_T$="ai3"
elif _TN=4
_T$="ai4"
elif _TN=5
_T$="ai5"
elif _TN=6
_T$="river"
elif _TN=7
_T$="Cave"
Endif


JSON$="/join?table="
JSON$=+_T$
JSON$=+"&player="
JSON$=+_name$


? "Connecting to FujiNet at "

? "Please wait, this may take a few seconds"
? "          ..."

@CallFujiNet ' Call the FujiNet API to join the table
@NInputInit UNIT, &responseBuffer ' Initialize reading the api response
@NInput &dummy$ ' Read the response from the FujiNet API

endproc



Proc checkJoined
' Check if the player has joined a table, if not then exit
ok = 1

if len(dummy$) > 0 then
_ERR=VAL(dummy$[5,1])
  if _ERR=1 
    ok = 0
    ? "You need to specify a valid table and player name to join"
  elif _ERR=2 
    ok = 0
    ? "You need to supply a player name to join a table"
  elif _ERR=3 
    ok = 0
    ? "Sorry: ";_name$;" someone is already at table with that name, please try a different table and or name"
  elif _ERR=4 
    ok = 0
    ? "Sorry: ";_name$;" table ";_T$;" has a game in progress, please try a different table"
  elif _ERR=5 
    ok = 0
    ? "Sorry: ";_name$;" table ";_T$;" is full, please try a different table"
else
  ? "You have joined table ";_T$;" as player ";_name$
  ok = 1
endif
get K
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