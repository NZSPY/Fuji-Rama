' Fuji-Llama Title Page
' Written in Atari FastBasic
' @author  Simon Young


' Disable BASIC on XL/XE to make more memory available. (found in Erics code  don't know if I need it or not)
if dpeek(741)-$BC00<0
  ' Disable BASIC
  pause: poke $D301, peek($D301) ! 2: poke $3F8, 1
  ' Set memtop to 48K
  dpoke 741, $BC00
endif

' Fuji-Net Setup Variblies 
UNIT=1
dim responseBuffer(1023) BYTE
'RESULT$=""
JSON_MODE=1
URL$="N:HTTP://192.168.68.100:8080/tables"
QUERY$=""

' Initialize strings - this reserves their space in memory so NInput can write to them
Dim  TableID$(6),TableName$(6),TableCurrentPlayers$(6),TableMaxPlayers$(6)

dummy$=""
for i=0 to 6
 TableID$(i)=""
 TableName$(i)=""
 TableCurrentPlayers$(i)=""
 TableMaxPlayers$(i)=""
next i

' Draw the opening screen 
GRAPHICS 0
SETCOLOR 2,0,0
SETCOLOR 1,14,6
POKE 82,0 'set margin to zero
?
? "      *** Welcome to Fuji-Llama ***    "
?
? " Choose a table to join"
? " **************************************"
? " *Table Name                   Players*"
? " **************************************"


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

  INC INDEX
loop 


'now display the data on the welcome page 
X=35:Y=7
for a=0 to 5
? " *";TableName$(a);
Position X,Y: ? TableCurrentPlayers$(a);"/";TableMaxPlayers$(a);"*"
inc y
next a
? " **************************************"


' all done for now exit the program
? "done"
GET K
NCLOSE UNIT


'-------------------------------------------------------------
' PROCEDURES to get Json data and load into the Var Result
'open the API connect and setup for Read JSON file
'--------------------------------------------------------------
PROC CallFujiNet
@openconnection
@nsetchannelmode 
@nparsejson
IF SErr()<>1
PRINT "Could not parse JSON."
@nprinterror
GET K
ENDIF
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

PROC nparsejson ' send Parse to the FujiNet, so it parses the JSON value set by teh URL$
SIO $71, UNIT, $50, $00, 0, $1f, 0, 12, 0
ENDPROC

PROC njsonquery ' Querey the JSON data that has been parsesed base on the attributes in $query
SIO $71, UNIT, $51, $80, &query$+1, $1f, 256, 12, 0
ENDPROC

PROC nprinterror ' get the current eror and display on screen 
NSTATUS UNIT
PRINT "ERROR- "; PEEK($02ED)
ENDPROC

PROC getresult 
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
' From Eric Carr
' (N Helper) Gets the entire response from the specified unit into the provided buffer index for NInput to read from.
' WARNING! No check is made if buffer length is long enough to hold the FujiNet payload.
PROC NInputInit __NI_unit __NI_index
  __NI_bufferEnd = __NI_index + DPEEK($02EA)
  NGET __NI_unit, __NI_index, __NI_bufferEnd - __NI_index
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