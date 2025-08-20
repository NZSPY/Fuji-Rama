package main

import (
	"fmt"
	"math/rand"
	"net/http"
	"strings"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

type GameState struct {
	Table          GameTable
	NumCards       int
	Discard        Card
	Players        Players
	Maindeck       Deck
	LastMovePlayed string // Last move made by the active player (e.g., "play", "fold", "draw")
	WaitingTimer   int    // Timer for waiting for players to make a move
}

var gameStates = make([]GameState, 7)

type GameTable struct {
	Table      string `json:"t"`
	Name       string `json:"n"`
	CurPlayers int    `json:"p"` // human players
	MaxPlayers int    `json:"m"` // human players
	maxBots    int    // max bots allowed (internal use)
	Status     string `json:"s"` // status of the table, e.g. "waiting", "playing"
}

var tables = []GameTable{
	{Table: "ai1", Name: "AI Room - 1 bots", CurPlayers: 0, MaxPlayers: 5, maxBots: 1, Status: "empty"},
	{Table: "ai2", Name: "AI Room - 2 bots", CurPlayers: 0, MaxPlayers: 4, maxBots: 2, Status: "empty"},
	{Table: "ai3", Name: "AI Room - 3 bots", CurPlayers: 0, MaxPlayers: 3, maxBots: 3, Status: "empty"},
	{Table: "ai4", Name: "AI Room - 4 bots", CurPlayers: 0, MaxPlayers: 2, maxBots: 4, Status: "empty"},
	{Table: "ai5", Name: "AI Room - 5 bots", CurPlayers: 0, MaxPlayers: 1, maxBots: 5, Status: "empty"},
	{Table: "river", Name: "The River", CurPlayers: 0, MaxPlayers: 6, maxBots: 6, Status: "empty"},
	{Table: "cave", Name: "Cave of Caerbannog", CurPlayers: 0, MaxPlayers: 6, maxBots: 6, Status: "empty"},
}

type Status int

const (
	STATUS_WAITING Status = 0
	STATUS_PLAYING Status = 1
	STATUS_FOLDED  Status = 2
	STATUS_WON     Status = 3 // Player has won the round
)

// Deck represents a collection of cards.
type Deck []Card

// card represents a playing card with it's name and value
type Card struct {
	Cardvalue int
	Cardname  string
}

type Player struct {
	Name             string
	Human            bool
	Status           Status
	Whitecounters    int
	Blackcounters    int
	Score            int
	Hand             Deck
	NumCards         int    // Number of cards in hand
	ValidMove        string // List of valid moves for the player (e.g., "play", "fold", "draw")
	Playorder        int
	LastPlayerToFold bool // Indicates if this player was the last to play or fold (used to determine the first player for next round)

}

// Players represents a the players at a table
type Players []Player

func main() {
	// Initialize the tables and game states
	for i := 0; i < len(gameStates); i++ {
		gameStates[i] = GameState{Table: tables[i], Maindeck: Deck{}, NumCards: 0, Discard: Card{}, Players: Players{}, LastMovePlayed: "Waiting for players to join"}
		SetupTable(i) // Initialize each table with a new deck and shuffle it
	}

	router := gin.Default()
	router.Use(cors.Default())            // All origins allowed by default (added this for testing via java script as it wouldn't work with it)
	router.GET("/tables", getTables)      // Get the list of tables
	router.GET("/devview", viewGameState) // View the game state for a specific table (IE Cheats view)
	router.GET("/state", getGameState)    // Get the game state for a specific table and player
	router.GET("/join", joinTable)        // Join a table
	router.GET("/start", StartNewGame)    // start a new game on a table (this also happens when the table is filled with players), if the table is not fill it will fill the emplty slots with AI Players
	router.GET("/move", doVaildMoveURL)   // Make a move on the table (play, fold, draw)

	// Set up router and start server
	router.SetTrustedProxies(nil) // Disable trusted proxies because Gin told me to do it.. (neeed to investigate this further)
	//router.Run("localhost:8080")
	router.Run("192.168.68.100:8080") // put your server address here
}

// getTables responds with the list of all tables  as JSON.
func getTables(c *gin.Context) {
	c.JSON(http.StatusOK, tables)
}

// View the State retrieves the game state for a specific table or all if none specified (cheating view).
func viewGameState(c *gin.Context) {
	tableIndex := -1
	ok := false
	tableIndex, ok = getTableIndex(c)
	if ok {
		c.IndentedJSON(http.StatusOK, gameStates[tableIndex]) // Return the game state for the specified table
	} else {
		c.IndentedJSON(http.StatusOK, gameStates) // Return all game states if no specific table is requested
	}
}

// NewDeck creates a new Llama 56-card deck.
func NewDeck() []Card {
	deck := make([]Card, 56)

	cardNames := []string{"One", "Two", "Three", "Four", "Five", "Six", "Llama"}

	currentCard := 0
	for value := 1; value <= 7; value++ {
		for i := 0; i < 8; i++ {
			deck[currentCard] = Card{Cardvalue: value, Cardname: cardNames[value-1]}
			currentCard++
		}
	}
	return deck
}

func SetupTable(tableIndex int) {
	if tableIndex < 0 || tableIndex >= len(gameStates) {
		return // Invalid table index
	}
	gameStates[tableIndex].Maindeck = NewDeck()              // Create a new deck for the table
	shuffleDeck(gameStates[tableIndex].Maindeck, tableIndex) // Shuffle the deck and set the discard pile
}

// shuffleDeck shuffles the deck using the Fisher-Yates algorithm.
// And deal out the first card to the discard pile.
func shuffleDeck(deck []Card, tableIndex int) {
	for i := len(deck) - 1; i > 0; i-- {
		j := rand.Intn(i + 1)
		deck[i], deck[j] = deck[j], deck[i]
	}
	gameStates[tableIndex].Discard = gameStates[tableIndex].Maindeck[55] // Set the discard to the last card in the deck
	gameStates[tableIndex].NumCards = 55
}

// find the table index from the query parameter
// Returns the table index and a boolean indicating a vaild table was found
func getTableIndex(c *gin.Context) (int, bool) {
	tableIndex := -1
	ok := false
	if tableStr := c.Query("table"); tableStr != "" {
		// Find the table index by matching the table name
		for i, t := range tables {
			if t.Table == tableStr {
				tableIndex = i
				ok = true
				break
			}
		}
	}
	return tableIndex, ok
}

// joinTable allows a player to join a table.
func joinTable(c *gin.Context) {
	tableIndex := -1
	ok := false
	tableIndex, ok = getTableIndex(c)
	newplayerName := c.Query("player")
	newplayer := Player{
		Name:             newplayerName,
		Human:            true,
		Status:           STATUS_WAITING,
		Whitecounters:    0,
		Blackcounters:    0,
		Score:            0,
		Hand:             Deck{},
		NumCards:         0,     // Initially, the player has no cards in hand
		ValidMove:        "",    // Initially, the player has not made a valid move
		Playorder:        0,     // Set the play order to the current number of players
		LastPlayerToFold: false, // Initially, the player is not the last to play or fold
	}
	// Add the new player to the game state if a valid condtions are met

	switch {
	case !ok:
		c.JSON(http.StatusPartialContent, "ERR(1)You need to specify a valid table and player name to join") // Notify the player to specify a table and player name
		return
	case newplayerName == "":
		c.JSON(http.StatusPartialContent, "ERR(2)You need to supply a player name to join a table")
		return
	case checkPlayerName(tableIndex, newplayerName):
		c.JSON(http.StatusConflict, "ERR(3) Sorry: "+newplayerName+" someone is already at table with that name ,please try a different table and or name") // Notify the player name is already taken
		return
	case gameStates[tableIndex].Table.Status == "playing":
		c.JSON(http.StatusConflict, "ERR(4) Sorry: "+newplayerName+" table "+tables[tableIndex].Table+" has a game in progress, please try a different table") // Notify the player that the table is busy
		return
	case gameStates[tableIndex].Table.Status == "full":
		gameStates[tableIndex].Table.Status = "full"
		c.JSON(http.StatusConflict, "ERR(5) Sorry: "+newplayerName+" table "+tables[tableIndex].Table+" is full, please try a different table") // Notify the player that the table is full
		return

	default:
		c.JSON(http.StatusOK, newplayerName+" joined table "+tables[tableIndex].Table) // Notify the player that they have successfully joined the table
		gameStates[tableIndex].Table.Status = "waiting"                                // set status to waiting
		gameStates[tableIndex].Players = append(gameStates[tableIndex].Players, newplayer)
		gameStates[tableIndex].Table.CurPlayers++ // Increment the current players count
		if gameStates[tableIndex].Table.CurPlayers >= gameStates[tableIndex].Table.MaxPlayers {
			gameStates[tableIndex].Table.Status = "full" // Set the status to full if max players reached
			StartNewGame(c)                              // Automatically start a new game if the table is full
		}
		tables[tableIndex].CurPlayers = gameStates[tableIndex].Table.CurPlayers // update the quick table view players count
		tables[tableIndex].Status = gameStates[tableIndex].Table.Status         // update the quick table view status
		gameStates[tableIndex].WaitingTimer = 30                                // Reset the waiting timer for the game state
	}
}

// Check if player name is already taken
func checkPlayerName(tableIndex int, newplayerName string) bool {
	ok := false
	for _, player := range gameStates[tableIndex].Players {
		if player.Name == newplayerName {
			ok = true
		}
	}
	return ok
}

// start a new game on the table
func StartNewGame(c *gin.Context) {
	tableIndex := -1
	ok := false
	surpress := false
	if c.Param("sup") == "1" {
		surpress = true
	}

	tableIndex, ok = getTableIndex(c)
	switch {
	case !ok || tableIndex < 0 || tableIndex >= len(gameStates):
		// If no table is specified or invalid table index, return an error
		if !surpress {
			c.JSON(http.StatusPartialContent, "You need to specify a valid table to start a new game EG: /start?table=ai1")
		}
		return
	case gameStates[tableIndex].Table.CurPlayers == 0:
		if !surpress {
			c.JSON(http.StatusConflict, "Sorry: table "+tables[tableIndex].Table+" has no human players, please join the table before starting a game")
		}
		return
	case gameStates[tableIndex].Table.Status == "playing":
		if !surpress {
			c.JSON(http.StatusConflict, "Sorry: table "+tables[tableIndex].Table+" has a game in progress, please try a different table")
		}
		return
	default:
		// Start the game state for the table
		if !surpress {
			c.JSON(http.StatusOK, "New game started on table "+tables[tableIndex].Table)
		}
		// fill up the empty slots with AI players if there are less than 6 players up to the maxiumum  bots allowed at that table
		for i := 0; i < gameStates[tableIndex].Table.maxBots; i++ {
			if gameStates[tableIndex].Table.CurPlayers >= (gameStates[tableIndex].Table.MaxPlayers + gameStates[tableIndex].Table.maxBots) {
				break // Stop adding AI players if the maximum number of players is reached
			}
			// Create a new AI player
			newAIPlayer := Player{
				Name:             fmt.Sprintf("AI-%d", i+1),
				Human:            false,
				Status:           STATUS_WAITING,
				Whitecounters:    0,
				Blackcounters:    0,
				Score:            0,
				Hand:             Deck{},
				Playorder:        i + 1, // Set the play order based on the current number of players
				LastPlayerToFold: false, // Initially, the AI player is not the last to play or fold
			}
			gameStates[tableIndex].Players = append(gameStates[tableIndex].Players, newAIPlayer)
			gameStates[tableIndex].Table.CurPlayers++
		}
		gameStates[tableIndex].Table.Status = "playing"                                                                                   // Set the table status to playing
		tables[tableIndex].CurPlayers = gameStates[tableIndex].Table.CurPlayers                                                           // Update the quick table view players count
		tables[tableIndex].Status = gameStates[tableIndex].Table.Status                                                                   // Update the quick table view status
		gameStates[tableIndex].Players[0].Status = STATUS_PLAYING                                                                         // make the first player status to playing
		gameStates[tableIndex].LastMovePlayed = "Game Started, Waiting for " + gameStates[tableIndex].Players[0].Name + " to make a move" // Update the last move played to indicate the game has started
		// deal cards to all players
		for i := 0; i < gameStates[tableIndex].Table.CurPlayers; i++ {
			player := &gameStates[tableIndex].Players[i]

			for j := 0; j < 6; j++ {
				player.Hand = append(player.Hand, gameStates[tableIndex].Maindeck[gameStates[tableIndex].NumCards]) // draw the last card from the deck
				gameStates[tableIndex].NumCards--                                                                   // Decrement the number of cards in the deck
				player.NumCards++                                                                                   // Increment the number of cards in the player's hand
			}
		}

	}
}

// getGameState retrieves the game state for a specific player at a specific table
func getGameState(c *gin.Context) {
	tableIndex, ok := getTableIndex(c)
	playerName := c.Query("player")

	if !ok || playerName == "" {
		c.JSON(http.StatusBadRequest, "Must specify both table and player name")
		return
	}

	// Create player state info for all players at table
	playerStates := make([]struct {
		Name          string `json:"n"`
		Status        Status `json:"s"`
		NumCards      int    `json:"nc"`
		WhiteCounters int    `json:"wc"`
		BlackCounters int    `json:"bc"`
	}, len(gameStates[tableIndex].Players))

	// Find active player's hand and valid moves
	// Initialize Requesting  player variables so can be loaded from the game state
	var reqestingPlayerHand Deck
	reqestingPlayerName := ""
	reqestingPlayerStatus := STATUS_WAITING
	reqestingPlayerWC := 0
	reqestingPlayerBC := 0
	reqestingPlayerValidMove := ""
	index := 0
	for _, player := range gameStates[tableIndex].Players {

		if player.Name == playerName {
			reqestingPlayerName = player.Name
			reqestingPlayerStatus = player.Status
			if player.Status == STATUS_PLAYING {
				player.ValidMove = setValidmoves(tableIndex, player) // Get valid moves for the player
			}
			reqestingPlayerWC = player.Whitecounters
			reqestingPlayerBC = player.Blackcounters
			reqestingPlayerHand = player.Hand
			reqestingPlayerValidMove = player.ValidMove
			gameStates[tableIndex].Players[index] = player // Update the player in the game state
			break
		}
		index++

	}
	if gameStates[tableIndex].Table.CurPlayers > 0 { // If there are players at the table, decrement the waiting timer
		gameStates[tableIndex].WaitingTimer-- // decrement the waiting timer for the game state
	}

	for i, player := range gameStates[tableIndex].Players {
		playerStates[i] = struct {
			Name          string `json:"n"`
			Status        Status `json:"s"`
			NumCards      int    `json:"nc"`
			WhiteCounters int    `json:"wc"`
			BlackCounters int    `json:"bc"`
		}{
			Name:          player.Name,
			Status:        player.Status,
			NumCards:      player.NumCards,
			WhiteCounters: player.Whitecounters,
			BlackCounters: player.Blackcounters,
		}
	}

	// Create simplified game state response with player's hand
	response := struct {
		DrawDeck        int         `json:"dd"`
		DiscardPile     Card        `json:"dp"`
		LastMovePlayed  string      `json:"lmp"` // Last move played
		PlayerName      string      `json:"pn"`
		PlayerStatus    Status      `json:"ps"`
		PlayerWC        int         `json:"pwc"`
		PlayerBC        int         `json:"pbc"`
		PlayerValidMove string      `json:"pvm"`
		PlayerHand      Deck        `json:"ph"`
		Players         interface{} `json:"pls"`
		//WaitingTimer    int         `json:"wt"` // Timer for waiting for players to make a move
	}{

		DrawDeck:       gameStates[tableIndex].NumCards,
		DiscardPile:    gameStates[tableIndex].Discard,
		LastMovePlayed: gameStates[tableIndex].LastMovePlayed,
		//WaitingTimer:    gameStates[tableIndex].WaitingTimer,
		PlayerName:      reqestingPlayerName,
		PlayerStatus:    reqestingPlayerStatus,
		PlayerWC:        reqestingPlayerWC,
		PlayerBC:        reqestingPlayerBC,
		PlayerValidMove: reqestingPlayerValidMove,
		PlayerHand:      reqestingPlayerHand,
		Players:         playerStates,
	}

	c.JSON(http.StatusOK, response)

	if gameStates[tableIndex].WaitingTimer <= 10 && gameStates[tableIndex].Table.Status == "waiting" {
		gameStates[tableIndex].WaitingTimer = 30 // Reset the waiting timer
		fmt.Println("Waiting timer exceeded 20 seconds, starting new game")
		c.Params = []gin.Param{{Key: "sup", Value: "1"}}
		StartNewGame(c)
	}
	if gameStates[tableIndex].WaitingTimer <= 25 && gameStates[tableIndex].Table.Status == "playing" {
		for i := 0; i < len(gameStates[tableIndex].Players); i++ {
			if gameStates[tableIndex].Players[i].Status == STATUS_PLAYING && !gameStates[tableIndex].Players[i].Human {
				move := aiMove(tableIndex, i)    // AI move function to determine the AI's move)
				doVaildMove(tableIndex, i, move) // Perform the AI's move
				break                            // Exit the loop after the AI makes a move
			}
		}
	}

	if gameStates[tableIndex].WaitingTimer <= 0 && gameStates[tableIndex].Table.Status == "playing" {
		gameStates[tableIndex].WaitingTimer = 30 // Reset the waiting timer
		for i := 0; i < len(gameStates[tableIndex].Players); i++ {
			if gameStates[tableIndex].Players[i].Status == STATUS_PLAYING {
				doVaildMove(tableIndex, i, "F") // If the player has not made a move in 30 seconds, fold them
				fmt.Println("Waiting timer exceeded 30 seconds, folding", gameStates[tableIndex].Players[i].Name)
				break // Exit the loop after folding the first player who is still playing
			}
		}
	}

	// Check if the round has ended and handle the end of the round logic
	if checkRoundEndCondtions(tableIndex) {
		//endRound(tableIndex) // Call the end round function to handle the end of the round logic
		fmt.Println("Round ended for table", tables[tableIndex].Table)
	}

}

// checks the player's hand and returns a string of valid moves possible for that player
func setValidmoves(tableIndex int, player Player) string {

	validMoves := ""
	if player.Status == STATUS_PLAYING {
		// Check if any card in hand matches or is higher than discard pile
		for _, card := range player.Hand {
			if card.Cardvalue == gameStates[tableIndex].Discard.Cardvalue {
				validMoves = "Cc" // Player can play a matching card
				break
			}
		}
		for _, card := range player.Hand {
			nextValue := gameStates[tableIndex].Discard.Cardvalue + 1
			if nextValue > 7 {
				nextValue = 1
			}
			if card.Cardvalue == nextValue {
				validMoves = validMoves + "Nn" // Player can play a matching card
				break
			}
		}
		if gameStates[tableIndex].NumCards > 0 {
			validMoves = validMoves + "Dd" // Player can draw
		}
		if player.Status == STATUS_PLAYING {
			validMoves = validMoves + "Ff" // Player can fold
		}
	}

	return validMoves
}

func doVaildMoveURL(c *gin.Context) {

	tableIndex, ok := getTableIndex(c)
	if !ok { // If no table is specified or invalid table index, return an error

		c.JSON(http.StatusBadRequest, "Must specify a valid table")

		return
	}

	// Find the player and check their status
	playerName := c.Query("player")
	var playerFound bool
	var validMoves string
	playerIndex := -1
	i := -1
	for _, player := range gameStates[tableIndex].Players {
		i++
		if player.Name == playerName {
			playerFound = true
			playerIndex = i // Store the index of the player
			validMoves = player.ValidMove
			if player.Status != STATUS_PLAYING {

				c.JSON(http.StatusBadRequest, "It's not your turn to play")

				return
			}
		}
	}
	if !playerFound {

		c.JSON(http.StatusBadRequest, "Player not found at this table")

		return
	}

	move := c.Query("VM") // Valid Move (e.g., "C", "N", "D", "F")
	if playerName == "" || move == "" {

		c.JSON(http.StatusBadRequest, "Must specify both player name and move")

		return
	}
	if !strings.Contains(validMoves, move) {

		c.JSON(http.StatusBadRequest, "Thats not a valid move, please try again")

		return
	}

	doVaildMove(tableIndex, playerIndex, move) // Call the doVaildMove function with the player and move
	c.JSON(http.StatusOK, gameStates[tableIndex].LastMovePlayed)

}

// Perform the valid move for the player at the specified table
func doVaildMove(tableIndex int, playerIndex int, move string) {
	gameStates[tableIndex].WaitingTimer = 30 // Reset the waiting timer
	switch move {
	case "C", "c": // Current
		gameStates[tableIndex].LastMovePlayed = gameStates[tableIndex].Players[playerIndex].Name + " played a " + gameStates[tableIndex].Discard.Cardname + " onto the discard pile"
		removeCardFromHand(tableIndex, playerIndex, gameStates[tableIndex].Discard) // Remove the played card from the player's hand
	case "N", "n": // Next
		var nextCard Card
		cardNames := []string{"One", "Two", "Three", "Four", "Five", "Six", "Llama"}
		if gameStates[tableIndex].Discard.Cardvalue < 7 {
			nextCard.Cardvalue = gameStates[tableIndex].Discard.Cardvalue + 1
		} else {
			nextCard.Cardvalue = 1
		}
		nextCard.Cardname = cardNames[nextCard.Cardvalue-1]
		removeCardFromHand(tableIndex, playerIndex, nextCard) // Remove the played card from the player's hand
		gameStates[tableIndex].LastMovePlayed = gameStates[tableIndex].Players[playerIndex].Name + " played a " + nextCard.Cardname + " onto the discard pile"
		gameStates[tableIndex].Discard = nextCard // Update the discard pile with the played card
	case "D", "d": // Draw
		gameStates[tableIndex].LastMovePlayed = gameStates[tableIndex].Players[playerIndex].Name + " drew a card from the deck"
		addCardtohand(tableIndex, playerIndex) // Add a card to the player's hand
	case "F", "f": // Fold
		gameStates[tableIndex].LastMovePlayed = gameStates[tableIndex].Players[playerIndex].Name + " folded"
		gameStates[tableIndex].Players[playerIndex].Status = STATUS_FOLDED
		for i := 0; i < len(gameStates[tableIndex].Players); i++ {
			gameStates[tableIndex].Players[i].LastPlayerToFold = false // Reset last player status
		}
		gameStates[tableIndex].Players[playerIndex].LastPlayerToFold = true

	}

	// Update the player's  status
	gameStates[tableIndex].Players[playerIndex].ValidMove = "" // Clear the valid moves after the player has made a move
	if gameStates[tableIndex].Players[playerIndex].Status == STATUS_PLAYING {
		gameStates[tableIndex].Players[playerIndex].Status = STATUS_WAITING // Set the current player's status to waiting if they didn't fold
	}

	// check idf the round end conditions have been met and if not find the next player to play
	if checkRoundEndCondtions(tableIndex) {
		fmt.Println("Round ended for table", tables[tableIndex].Table)
	} else {
		// If there are still players playing, find the next player to play
		nextPlayerIndex := playerIndex + 1
		if nextPlayerIndex >= len(gameStates[tableIndex].Players) {
			nextPlayerIndex = 0 // Wrap around to the first player if we reach the end
		}
		for i := 0; i < len(gameStates[tableIndex].Players); i++ {
			if gameStates[tableIndex].Players[nextPlayerIndex].Status == STATUS_FOLDED {
				// skip folded players
			} else {
				gameStates[tableIndex].Players[nextPlayerIndex].Status = STATUS_PLAYING // Set the next player to playing status
				gameStates[tableIndex].LastMovePlayed += ", Waiting for " + gameStates[tableIndex].Players[nextPlayerIndex].Name + " to make a move"
				gameStates[tableIndex].Players[nextPlayerIndex].ValidMove = setValidmoves(tableIndex, gameStates[tableIndex].Players[nextPlayerIndex]) // Set valid moves for the next player
				break
			}
			nextPlayerIndex++
			if nextPlayerIndex >= len(gameStates[tableIndex].Players) {
				nextPlayerIndex = 0 // Wrap around to the first player if we reach the end
			}
		}
	}
}

func removeCardFromHand(tableIndex int, playerIndex int, card Card) {
	for i, c := range gameStates[tableIndex].Players[playerIndex].Hand {
		if c.Cardvalue == card.Cardvalue {
			gameStates[tableIndex].Players[playerIndex].Hand = append(gameStates[tableIndex].Players[playerIndex].Hand[:i], gameStates[tableIndex].Players[playerIndex].Hand[i+1:]...) // Remove the card from the player's hand
			gameStates[tableIndex].Players[playerIndex].NumCards--                                                                                                                     // Decrement the number of cards in hand
			if gameStates[tableIndex].Players[playerIndex].NumCards <= 0 {
				gameStates[tableIndex].Players[playerIndex].Status = STATUS_WON // If the player has no cards left, set their status to won
				fmt.Println(gameStates[tableIndex].Players[playerIndex].Name, "has won the round!")
			}
			return
		}
	}
}

func addCardtohand(tableIndex int, playerIndex int) {

	gameStates[tableIndex].Players[playerIndex].Hand = append(gameStates[tableIndex].Players[playerIndex].Hand, gameStates[tableIndex].Maindeck[gameStates[tableIndex].NumCards]) // draw the last card from the deck
	gameStates[tableIndex].NumCards--                                                                                                                                             // Decrement the number of cards in the deck
	gameStates[tableIndex].Players[playerIndex].NumCards++                                                                                                                        // Increment the number of cards in hand
}

// aiMove simulates an player's just dumb move by returning the first valid move from the AI player's valid moves.
// This is a placeholder for a more sophisticated AI logic that could be implemented later.
func aiMove(tableIndex int, playerIndex int) string {
	move := string(gameStates[tableIndex].Players[playerIndex].ValidMove[0]) // Get the first valid move for the AI player
	return move                                                              // Return the move
}

func checkRoundEndCondtions(tableIndex int) bool {
	// Check if all players have folded or if the deck is empty
	foldedCount := 0
	wonCount := 0
	for _, player := range gameStates[tableIndex].Players {
		if player.Status == STATUS_FOLDED {
			foldedCount++
		}
		if player.Status == STATUS_WON {
			wonCount++
		}
	}
	if foldedCount >= gameStates[tableIndex].Table.CurPlayers || gameStates[tableIndex].NumCards <= 0 || wonCount >= 1 {
		gameStates[tableIndex].LastMovePlayed = "(RO) Round over, adding up the scores"
		return true // Round ends if all players have folded or no cards left in the deck
	}
	return false // Round continues if there are still players playing and cards available
}
