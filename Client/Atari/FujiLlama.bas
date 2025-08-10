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
DIM RESULT(1024) BYTE
'RESULT$=""
JSON_MODE=1
URL$="N:HTTP://192.168.68.100:8080/tables"
QUERY$=""
O$=""

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
'open the API connect and setup for Read JSON file
' commenting this all out to see if I can get just the string sliceing working
'@openconnection
'@nsetchannelmode 
'@nparsejson
'IF SErr()<>1
'PRINT "Could not parse JSON."
'@nprinterror
'GET K
'ENDIF

'display a table of the available rooms 

Dim TableName$(5),TableCurrentPlayers$(5),TableMaxPlayers$(5) 'String arrays to load with the values from the table Query
' @getresult
' simulate data reurned from Query for now so I can test my string slicing
O$ ="t"$9B"ai6"$9B"n"$9B"AI Room - 6 bots"$9B"p"$9B"0"$9B"m"$9B"2"$9B 
O$ =+"t"$9B"ai4"$9B"n"$9B"AI Room - 4 bots"$9B"p"$9B"0"$9B"m"$9B"4"$9B
O$ =+"t"$9B"ai2"$9B"n"$9B"AI Room - 2 bots"$9B"p"$9B"0"$9B"m"$9B"6"$9B
O$ =+"t"$9B"den"$9B"n"$9B"The Den"$9B"p"$9B"0"$9B"m"$9B"8"$9B
O$ =+"t"$9B"basement"$9B"n"$9B"The Basement"$9B"p"$9B"0"$9B"m"$9B"8"$9B



STARTCHR=1
LENGTH=-2
INDEX=0
SKIP=0
FOR a=0 TO LEN(O$)
INC LENGTH
IF PEEK(&O$+a)=$9B
    IF SKIP=3 THEN TableName$(INDEX)=O$[STARTCHR,LENGTH]
    IF SKIP=5 THEN TableCurrentPlayers$(INDEX)=O$[STARTCHR,LENGTH]
    IF SKIP=7 
        TableMaxPlayers$(INDEX)=O$[STARTCHR,LENGTH]
        SKIP=-1
        INC INDEX
    ENDIF
INC SKIP
LENGTH=-1
STARTCHR=a+1
ENDIF
Next a

X=35:Y=7
for a=0 to 4
? " *";TableName$(a);
Position X,Y: ? TableCurrentPlayers$(a);"/";TableMaxPlayers$(a);"*"
inc y
next a
? " **************************************"

? "done"
GET K
'NCLOSE UNIT




' PROCEDURES to get Json data and load into the Var Result

PROC openconnection ' Open the connection, or throw error and end program
NOPEN UNIT, 12, 0, URL$
' If not successful, then exit.
IF SERR()<>1
PRINT "Could not open connection."
@nprinterror
EXIT
'ELSE
'PRINT "Horray"
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
BW=DPEEK($02EA)
NGET UNIT, &RESULT+1, BW
'BPUT #0,  &RESULT, BW (leaving this as might need it for debuging at a later date )
POKE &RESULT,BW-1
O$=$(ADR(RESULT))
ENDPROC

