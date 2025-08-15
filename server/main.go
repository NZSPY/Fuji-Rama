package main

import (
	"fmt"
	"math/rand"
	"net/http"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

type GameState struct {
	Table    GameTable
	NumCards int
	Discard  Card
	Players  Players
	Maindeck Deck
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
	STATUS_LEFT    Status = 3
)

// Deck represents a collection of cards.
type Deck []Card

// card represents a playing card with it's name and value
type Card struct {
	Cardvalue int
	Cardname  string
}

type Player struct {
	Name          string
	Human         bool
	Status        Status
	Whitecounters int
	Blackcounters int
	Score         int
	Hand          Deck
	Playorder     int
	Lastplayer    bool // Indicates if this player was the last to play or fold
}

// Players represents a the players at a table
type Players []Player

func main() {
	// Initialize the tables and game states
	for i := 0; i < len(gameStates); i++ {
		gameStates[i] = GameState{Table: tables[i], Maindeck: Deck{}, NumCards: 0, Discard: Card{}, Players: Players{}}
		SetupTable(i) // Initialize each table with a new deck and shuffle it
	}

	router := gin.Default()
	router.Use(cors.Default())         // All origins allowed by default (added this for testing via java script as it wouldn't work with it)
	router.GET("/tables", getTables)   // Get the list of tables
	router.GET("/view", viewGameState) // View the game state for a specific table
	router.GET("/state", getGameState) // Get the game state for a specific table (not yet implemented)
	router.GET("/join", joinTable)     // Join a table
	router.GET("/start", StartNewGame) // Join a table

	// Set up router and start server

	router.SetTrustedProxies(nil) // Disable trusted proxies because Gin told me to do it.. (neeed to investigate this further)
	//router.Run("localhost:8080")
	router.Run("192.168.68.100:8080") // put your server address here
}

// getTables responds with the list of all tables  as JSON.
func getTables(c *gin.Context) {
	c.JSON(http.StatusOK, tables)
}

// getGameState retrieves the game state for a specific table.
// This function is a placeholder for future implementation.
func getGameState(c *gin.Context) {
	c.JSON(http.StatusOK, "Commign soon - game state retrieval not yet implemented")
}

// View the State retrieves the game state for a specific table or all if none specified.
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
		Name:          newplayerName,
		Human:         true,
		Status:        STATUS_WAITING,
		Whitecounters: 0,
		Blackcounters: 0,
		Score:         0,
		Hand:          Deck{},
		Playorder:     0,     // Set the play order to the current number of players
		Lastplayer:    false, // Initially, the player is not the last to play or fold
	}
	// Add the new player to the game state if a valid condtions are met

	switch {
	case !ok:
		c.JSON(http.StatusPartialContent, "You need to specify a valid table and player name to join") // Notify the player to specify a table and player name
		return
	case newplayerName == "":
		c.JSON(http.StatusPartialContent, "You need to supply a player name to join a table")
		return
	case checkPlayerName(tableIndex, newplayerName):
		c.JSON(http.StatusConflict, "Sorry: "+newplayerName+" someone is already at table with that name ,please try a diffrent table and or name") // Notify the player name is already taken
		return
	case gameStates[tableIndex].Table.Status == "playing":
		c.JSON(http.StatusConflict, "Sorry: "+newplayerName+" table "+tables[tableIndex].Table+" has a game in progress, please try a diffrent table") // Notify the player that the table is busy
		return
	case gameStates[tableIndex].Table.Status == "full":
		gameStates[tableIndex].Table.Status = "full"
		c.JSON(http.StatusConflict, "Sorry: "+newplayerName+" table "+tables[tableIndex].Table+" is full, please try a diffrent table") // Notify the player that the table is full
		return

	default:
		gameStates[tableIndex].Table.Status = "waiting" // set status to waiting
		gameStates[tableIndex].Players = append(gameStates[tableIndex].Players, newplayer)
		gameStates[tableIndex].Table.CurPlayers++ // Increment the current players count
		if gameStates[tableIndex].Table.CurPlayers >= gameStates[tableIndex].Table.MaxPlayers {
			gameStates[tableIndex].Table.Status = "full" // Set the status to full if max players reached
		}
		tables[tableIndex].CurPlayers = gameStates[tableIndex].Table.CurPlayers // update the quick table view players count
		tables[tableIndex].Status = gameStates[tableIndex].Table.Status         // update the quick table view status
		c.JSON(http.StatusCreated, newplayerName+" joined table "+tables[tableIndex].Table)
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
	tableIndex, ok = getTableIndex(c)
	switch {
	case !ok || tableIndex < 0 || tableIndex >= len(gameStates):
		// If no table is specified or invalid table index, return an error
		c.JSON(http.StatusPartialContent, "You need to specify a valid table to start a new game EG: /start?table=ai1")
		return
	case gameStates[tableIndex].Table.CurPlayers == 0:
		c.JSON(http.StatusConflict, "Sorry: table "+tables[tableIndex].Table+" has no human players, please join the table before starting a game")
		return
	case gameStates[tableIndex].Table.Status == "playing":
		c.JSON(http.StatusConflict, "Sorry: table "+tables[tableIndex].Table+" has a game in progress, please try a diffrent table")
		return
	default:
		// Start the game state for the table
		c.JSON(http.StatusOK, "New game started on table "+tables[tableIndex].Table)
		// fill up the empty slots with AI players if there are less than 6 players up to the maxiumum  bots allowed at that table
		for i := 0; i < gameStates[tableIndex].Table.maxBots; i++ {
			if gameStates[tableIndex].Table.CurPlayers >= gameStates[tableIndex].Table.MaxPlayers {
				break // Stop adding AI players if the maximum number of players is reached
			}
			// Create a new AI player
			newAIPlayer := Player{
				Name:          fmt.Sprintf("AI-%d", i+1),
				Human:         false,
				Status:        STATUS_WAITING,
				Whitecounters: 0,
				Blackcounters: 0,
				Score:         0,
				Hand:          Deck{},
				Playorder:     i + 1, // Set the play order based on the current number of players
				Lastplayer:    false, // Initially, the AI player is not the last to play or fold
			}
			gameStates[tableIndex].Players = append(gameStates[tableIndex].Players, newAIPlayer)
			gameStates[tableIndex].Table.CurPlayers++
		}
		gameStates[tableIndex].Table.Status = "playing"                         // Set the table status to playing
		tables[tableIndex].CurPlayers = gameStates[tableIndex].Table.CurPlayers // Update the quick table view players count
		tables[tableIndex].Status = gameStates[tableIndex].Table.Status         // Update the quick table view status
		// deal cards to all players
		for i := 0; i < gameStates[tableIndex].Table.CurPlayers; i++ {
			player := &gameStates[tableIndex].Players[i]

			for j := 0; j < 6; j++ {
				player.Hand = append(player.Hand, gameStates[tableIndex].Maindeck[gameStates[tableIndex].NumCards]) // draw the last card from the deck
				gameStates[tableIndex].NumCards--                                                                   // Decrement the number of cards in the deck
			}
		}

	}
}
