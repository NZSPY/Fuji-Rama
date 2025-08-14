package main

import (
	"math/rand"
	"net/http"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

type GameState struct {
	Table    GameTable
	Playing  bool
	Maindeck Deck
	NumCards int
	Discard  Card
	Players  Player
}

var gameStates = make([]GameState, 7)

type GameTable struct {
	Table      string `json:"t"`
	Name       string `json:"n"`
	CurPlayers int    `json:"p"` // human players
	MaxPlayers int    `json:"m"` // human players
}

var tables = []GameTable{
	{Table: "ai1", Name: "AI Room - 1 bots", CurPlayers: 0, MaxPlayers: 5},
	{Table: "ai2", Name: "AI Room - 2 bots", CurPlayers: 0, MaxPlayers: 4},
	{Table: "ai3", Name: "AI Room - 3 bots", CurPlayers: 0, MaxPlayers: 3},
	{Table: "ai4", Name: "AI Room - 4 bots", CurPlayers: 0, MaxPlayers: 2},
	{Table: "ai5", Name: "AI Room - 5 bots", CurPlayers: 0, MaxPlayers: 1},
	{Table: "river", Name: "The River", CurPlayers: 0, MaxPlayers: 6},
	{Table: "cave", Name: "Cave of Caerbannog", CurPlayers: 0, MaxPlayers: 6},
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

func main() {
	// Initialize the tables and game states
	for i := 0; i < len(gameStates); i++ {
		gameStates[i] = GameState{Table: tables[i], Playing: false, Maindeck: Deck{}, NumCards: 0, Discard: Card{}, Players: Player{}}
		SetupTable(i) // Initialize each table with a new deck and shuffle it
	}

	router := gin.Default()
	router.Use(cors.Default())         // All origins allowed by default (added this for testing via java script as it wouldn't work with it)
	router.GET("/tables", getTables)   // Get the list of tables
	router.GET("/view", viewGameState) // View the game state for a specific table
	router.GET("/state", getGameState)
	router.GET("/draw", drawCard)

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
	gameStates[tableIndex].Maindeck = NewDeck()
	shuffleDeck(gameStates[tableIndex].Maindeck)
	gameStates[tableIndex].Discard = gameStates[tableIndex].Maindeck[55] // Set the discard to the last card in the deck
	gameStates[tableIndex].NumCards = 55                                 // 55 cards left in the deck after dealing one to discard
}

// shuffleDeck shuffles the deck using the Fisher-Yates algorithm.
func shuffleDeck(deck []Card) {
	for i := len(deck) - 1; i > 0; i-- {
		j := rand.Intn(i + 1)
		deck[i], deck[j] = deck[j], deck[i]
	}
}

// drawCard handles the drawing of a card from the deck.
func drawCard(c *gin.Context) {
	ok := false
	tableIndex := -1
	tableIndex, ok = getTableIndex(c)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid table index"})
		return
	}

	if gameStates[tableIndex].NumCards == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No cards left in the deck"})
		return
	}
	gameStates[tableIndex].Discard = gameStates[tableIndex].Maindeck[gameStates[tableIndex].NumCards] // Set the discard to the last card in the deck
	gameStates[tableIndex].NumCards--
	c.JSON(http.StatusOK, gameStates[tableIndex].Discard)
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
