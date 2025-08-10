package main

import (
	"fmt"
	"math/rand"
	"sort"
	"strings"
	"time"
)

var numberplayers = 6
var player [6]players
var topofdiscardpile card
var decksize int          // Tracks the size of the current deck
var activePlayerCount int // Tracks the number of inactive players
var move string
var valid bool
var roundactive = true
var gameactive = true
var currentdeck deck

// card represents a playing card with it's name and value
type card struct {
	cardvalue int
	cardname  string
	// use these to get erics code going
	value int
	suit  int
}

// Deck represents a collection of cards.
type deck []card

type players struct {
	name          string
	human         bool
	playing       bool
	whitecounters int
	blackcounters int
	score         int
	hand          deck
	playorder     int
	lastplayer    bool // Indicates if this player was the last to play or fold
}

// Added the following in from Erics code to try and get is server running with my game logic etc

// Drop players who do not make a move in 5 minutes
const PLAYER_PING_TIMEOUT = time.Minute * time.Duration(-5)
const WAITING_MESSAGE = "Waiting for more players"
const STARTING_PURSE = 200

var botNames = []string{"SPY1", "SPY2", "SPY3", "SPY4", "SPY5", "SPY6", "SPY7", "SPY8"}

type GameTable struct {
	Table      string `json:"t"`
	Name       string `json:"n"`
	CurPlayers int    `json:"p"`
	MaxPlayers int    `json:"m"`
}

type GameState struct {
	// External (JSON)
	LastResult   string      `json:"l"`
	Round        int         `json:"r"`
	Pot          int         `json:"p"`
	ActivePlayer int         `json:"a"`
	MoveTime     int         `json:"m"`
	Viewing      int         `json:"v"`
	ValidMoves   []validMove `json:"vm"`
	Players      []Player    `json:"pl"`

	// Internal
	deck          []card
	deckIndex     int
	currentBet    int
	gameOver      bool
	clientPlayer  int
	table         string
	wonByFolds    bool
	moveExpires   time.Time
	serverName    string
	raiseCount    int
	raiseAmount   int
	registerLobby bool
	hash          string //   `json:"z"` // external later
}

type Player struct {
	Name   string `json:"n"`
	Status Status `json:"s"`
	Bet    int    `json:"b"`
	Move   string `json:"m"`
	Purse  int    `json:"p"`
	Hand   string `json:"h"`

	// Internal
	isBot    bool
	cards    []card
	lastPing time.Time
}

type validMove struct {
	Move string `json:"m"`
	Name string `json:"n"`
}

type Status int64

const (
	STATUS_WAITING Status = 0
	STATUS_PLAYING Status = 1
	STATUS_FOLDED  Status = 2
	STATUS_LEFT    Status = 3
)

func initializeGameServer() {

	// Append BOT to botNames array
	for i := 0; i < len(botNames); i++ {
		botNames[i] = botNames[i] + " BOT"
	}

}

func (state *GameState) performMove(move string, internalCall ...bool) bool {
	/*
		if len(internalCall) == 0 || !internalCall[0] {
			state.playerPing()
		}

		// Get pointer to player
		player := &state.Players[state.ActivePlayer]

		// Sanity check if player is still in the game. Unless there is a bug, they should never be active if their status is != PLAYING
		if player.Status != STATUS_PLAYING {
			return false
		}

		// Only perform move if it is a valid move for this player
		if !slices.ContainsFunc(state.getValidMoves(), func(m validMove) bool { return m.Move == move }) {
			return false
		}

		if move == "FO" { // FOLD
			player.Status = STATUS_FOLDED
		} else if move != "CH" { // Not Checking

			// Default raise to 0 (effectively a CALL)
			raise := 0

			if move == "RA" {
				raise = state.raiseAmount
				state.raiseCount++
			} else if move == "BH" {
				raise = HIGH
				state.raiseAmount = HIGH
			} else if move == "BL" {
				raise = LOW
				state.raiseAmount = LOW

				// If betting LOW the very first time and the pot is BRINGIN
				// just make their bet enough to make the total bet LOW
				if state.currentBet == BRINGIN {
					raise -= BRINGIN
				}
			} else if move == "BB" {
				raise = BRINGIN
			}

			// Place the bet
			delta := state.currentBet + raise - player.Bet
			state.currentBet += raise
			player.Bet += delta
			player.Purse -= delta
		}

		player.Move = moveLookup[move]
		state.nextValidPlayer()
	*/
	return true

}

// Creates a copy of the state and modifies it to be from the
// perspective of this client (e.g. player array, visible cards)
func (state *GameState) createClientState() *GameState {

	stateCopy := *state
	/*
		setActivePlayer := false

		// Check if:
		// 1. The game is over,
		// 2. Only one player is left (waiting for another player to join)
		// 3. We are at the end of a round, where the active player has moved
		// This lets the client perform end of round/game tasks/animation
		if state.gameOver ||
			len(stateCopy.Players) < 2 ||
			(stateCopy.ActivePlayer > -1 && ((state.currentBet > 0 && state.Players[state.ActivePlayer].Bet == state.currentBet) ||
				(state.currentBet == 0 && state.Players[state.ActivePlayer].Move != ""))) {
			stateCopy.ActivePlayer = -1
			setActivePlayer = true
		}

		// Now, store a copy of state players, then loop
		// through and add to the state copy, starting
		// with this player first

		statePlayers := stateCopy.Players
		stateCopy.Players = []Player{}

		// When on observer is viewing the game, the clientPlayer will be -1, so just start at 0
		// Also, set flag to let client know they are not actively part of the game
		start := state.clientPlayer
		if start < 0 {
			start = 0
			stateCopy.Viewing = 1
		} else {
			stateCopy.Viewing = 0
		}

		// Loop through each player and create the hand, starting at this player, so all clients see the same order regardless of starting player
		for i := start; i < start+len(statePlayers); i++ {

			// Wrap around to beginning of playar array when needed
			playerIndex := i % len(statePlayers)

			// Update the ActivePlayer to be client relative
			if !setActivePlayer && playerIndex == stateCopy.ActivePlayer {
				setActivePlayer = true
				stateCopy.ActivePlayer = i - start
			}

			player := statePlayers[playerIndex]
			player.Hand = ""

			switch player.Status {
			case STATUS_PLAYING:
				// Loop through and build hand string, taking
				// care to not disclose the first card of a hand to other players
				for cardIndex, card := range player.cards {
					if cardIndex > 0 || playerIndex == state.clientPlayer || (state.Round == 5 && !state.wonByFolds) {
						player.Hand += valueLookup[card.value] + suitLookup[card.suit]
					} else {
						player.Hand += "??"
					}
				}
			case STATUS_FOLDED:
				player.Hand = "??"
			}

			// Add this player to the copy of the state going out
			stateCopy.Players = append(stateCopy.Players, player)
		}

		// Determine valid moves for this player (if their turn)
		if stateCopy.ActivePlayer == 0 {
			stateCopy.ValidMoves = state.getValidMoves()
		}

		// Determine the move time left. Reduce the number by the grace period, to allow for plenty of time for a response to be sent back and accepted
		stateCopy.MoveTime = int(time.Until(stateCopy.moveExpires).Seconds())

		if stateCopy.ActivePlayer > -1 {
			stateCopy.MoveTime -= MOVE_TIME_GRACE_SECONDS
		}

		// No need to send move time if the calling player isn't the active player
		if stateCopy.MoveTime < 0 || stateCopy.ActivePlayer != 0 {
			stateCopy.MoveTime = 0
		}

		// Compute hash - this will be compared with an incoming hash. If the same, the entire state does not
		// need to be sent back. This speeds up checks for change in state
		stateCopy.hash = "0"
		hash, _ := hashstructure.Hash(stateCopy, hashstructure.FormatV2, nil)
		stateCopy.hash = fmt.Sprintf("%d", hash)
	*/
	return &stateCopy
}

// Emulates simplified player/logic for 5 card stud
func (state *GameState) runGameLogic() {
	/*
		state.playerPing()

		// We can't play a game until there are at least 2 players
		if len(state.Players) < 2 {
			// Reset the round to 0 so the client knows there is no active game being run
			state.Round = 0
			state.Pot = 0
			state.ActivePlayer = -1
			return
		}

		// Very first call of state? Initialize first round but do not play for any BOTs
		if state.Round == 0 {
			state.newRound()
			return
		}

		//isHumanPlayer := state.ActivePlayer == state.clientPlayer

		if state.gameOver {

			// Create a new game if the end game delay is past
			if int(time.Until(state.moveExpires).Seconds()) < 0 {
				state.dropInactivePlayers(false, false)
				state.Round = 0
				state.Pot = 0
				state.gameOver = false
				state.newRound()
			}
			return
		}

		// Check if only one player is left
		playersLeft := 0
		for _, player := range state.Players {
			if player.Status == STATUS_PLAYING {
				playersLeft++
			}
		}

		// If only one player is left, just end the game now
		if playersLeft == 1 {
			state.endGame(false)
			return
		}

		// Check if we should start the next round. One of the following must be true
		// 1. We got back to the player who made the most recent bet/raise
		// 2. There were checks/folds around the table
		if state.ActivePlayer > -1 {
			if (state.currentBet > 0 && state.Players[state.ActivePlayer].Bet == state.currentBet) ||
				(state.currentBet == 0 && state.Players[state.ActivePlayer].Move != "") {
				if state.Round == 4 {
					state.endGame(false)
				} else {
					state.newRound()
				}
				return
			}
		}

		// Return if the move timer has not expired
		// Check timer if no active player, or the active player hasn't already left
		if state.ActivePlayer == -1 || state.Players[state.ActivePlayer].Status != STATUS_LEFT {
			moveTimeRemaining := int(time.Until(state.moveExpires).Seconds())
			if moveTimeRemaining > 0 {
				return
			}
		}

		// If there is no active player, we are done
		if state.ActivePlayer < 0 {
			return
		}

		// Edge cases
		// - player leaves when it is their move - skip over them
		// - player's turn but they are waiting (out of this hand)
		if state.Players[state.ActivePlayer].Status == STATUS_LEFT ||
			state.Players[state.ActivePlayer].Status == STATUS_WAITING {
			state.nextValidPlayer()
			return
		}

		// Force a move for this player or BOT if they are in the game and have not folded
		if state.Players[state.ActivePlayer].Status == STATUS_PLAYING {
			cards := state.Players[state.ActivePlayer].cards
			moves := state.getValidMoves()

			// Default to FOLD
			choice := 0

			// Never fold if CHECK is an option. This applies to forced player moves as well as bots
			if len(moves) > 1 && moves[1].Move == "CH" {
				choice = 1
			}

			// If this is a bot, pick the best move using some simple logic (sometimes random)
			if state.Players[state.ActivePlayer].isBot {

				// Potential TODO: If on round 5 and check is not an option, fold if there is a visible hand that beats the bot's hand.
				//if len(cards) == 5 && len(moves) > 1 && moves[1].Move == "CH" {}

				// Hardly ever fold early if a BOT has an jack or higher.
				if state.Round < 3 && len(moves) > 1 && rand.Intn(3) > 0 && slices.ContainsFunc(cards, func(c card) bool { return c.value > 10 }) {
					choice = 1
				}

				// Likely don't fold if BOT has a pair or better
				rank := getRank(cards)
				if rank[0] < 300 && rand.Intn(20) > 0 {
					choice = 1
				}

				// Don't fold if BOT has a 2 pair or better
				if rank[0] < 200 {
					choice = 1
				}

				// Raise the bet if three of a kind or better
				if len(moves) > 2 && rank[0] < 312 && state.currentBet < LOW {
					choice = 2
				} else if len(moves) > 2 && state.getPlayerWithBestVisibleHand(true) == state.ActivePlayer && state.currentBet < HIGH && (rank[0] < 306) {
					choice = len(moves) - 1
				} else {

					// Consider bet/call/raise most of the time
					if len(moves) > 1 && rand.Intn(3) > 0 && (len(cards) > 2 ||
						cards[0].value == cards[1].value ||
						math.Abs(float64(cards[1].value-cards[0].value)) < 3 ||
						cards[0].value > 8 ||
						cards[1].value > 5) {

						// Avoid endless raises
						if state.currentBet >= 20 || rand.Intn(3) > 0 {
							choice = 1
						} else {
							choice = rand.Intn(len(moves)-1) + 1
						}

					}
				}
			}

			// Bounds check - clamp the move to the end of the array if a higher move is desired.
			// This may occur if a bot wants to call, but cannot, due to limited funds.
			if choice > len(moves)-1 {
				choice = len(moves) - 1
			}

			move := moves[choice]

			state.performMove(move.Move, true)
		}
	*/
}

func (state *GameState) clientLeave() {
	/*

		if state.clientPlayer < 0 {
			return
		}
		player := &state.Players[state.clientPlayer]

		player.Status = STATUS_LEFT
		player.Move = "LEFT"

		// Check if no human players are playing. If so, end the game
		playersLeft := 0
		for _, player := range state.Players {
			if player.Status == STATUS_PLAYING && !player.isBot {
				playersLeft++
			}
		}

		// If the last player dropped, stop the game and update the lobby
		if playersLeft == 0 {
			state.endGame(true)
			state.dropInactivePlayers(false, false)
			return
		}
	*/
}

func (state *GameState) updateLobby() {

	if !state.registerLobby {
		return
	}

	humanPlayerSlots, humanPlayerCount := state.getHumanPlayerCountInfo()

	// Send the total human slots / players to the Lobby
	sendStateToLobby(humanPlayerSlots, humanPlayerCount, true, state.serverName, "?table="+state.table)

}

// Return number of active human players in the table, for the lobby
func (state *GameState) getHumanPlayerCountInfo() (int, int) {
	humanAvailSlots := 6
	humanPlayerCount := 0

	cutoff := time.Now().Add(PLAYER_PING_TIMEOUT)

	for _, player := range state.Players {
		if player.isBot {
			humanAvailSlots--
		} else if player.Status != STATUS_LEFT && player.lastPing.Compare(cutoff) > 0 {
			humanPlayerCount++
		}
	}

	return humanAvailSlots, humanPlayerCount
}

func (state *GameState) setClientPlayerByName(playerName string) {
	/*

		// If no player name was passed, simply return. This is an anonymous viewer.
		if len(playerName) == 0 {
			state.clientPlayer = -1
			return
		}
		state.clientPlayer = slices.IndexFunc(state.Players, func(p Player) bool { return strings.EqualFold(p.Name, playerName) })

		// If a new player is joining, remove any old players that timed out to make space
		if state.clientPlayer < 0 {
			// Drop any players that left to make space
			state.dropInactivePlayers(false, true)
		}

		// Add new player if there is room
		if state.clientPlayer < 0 && len(state.Players) < 8 {
			state.addPlayer(playerName, false)
			state.clientPlayer = len(state.Players) - 1

			// Set the ping for this player so they are counted as active when updating the lobby
			state.playerPing()

			// Update the lobby with the new state (new player joined)
			state.updateLobby()
		}

		// Extra logic if a player is requesting
		if state.clientPlayer > 0 {

			// In case a player returns while they are still in the "LEFT" status (before the current game ended), add them back in as waiting
			if state.Players[state.clientPlayer].Status == STATUS_LEFT {
				state.Players[state.clientPlayer].Status = STATUS_WAITING
			}
		}
	*/
}

func createGameState(playerCount int, registerLobby bool) *GameState {

	// My Deck creation code replacing Eric's
	cardNames := []string{"One", "Two", "Three", "Four", "Five", "Six", "Llama"}
	deck := make(deck, 0, 56) // Pre-allocate slice with capacity for 56 cards

	for i := 0; i < 8; i++ { // Repeat the cards 8 times to create a full deck
		for value, name := range cardNames {
			deck = append(deck, card{cardvalue: value + 1, cardname: name})
		}
	}
	/* Eric's Create deck code
	deck := []card{}

	// Create deck of 52 cards
	for suit := 0; suit < 4; suit++ {
		for value := 2; value < 15; value++ {
			card := card{value: value, suit: suit}
			deck = append(deck, card)
		}
	}
	*/

	state := GameState{}

	state.deck = deck
	state.Round = 0
	state.ActivePlayer = -1
	state.registerLobby = registerLobby

	// Pre-populate player pool with bots
	for i := 0; i < playerCount; i++ {
		state.addPlayer(botNames[i], true)
	}

	if playerCount < 2 {
		state.LastResult = WAITING_MESSAGE
	}

	return &state
}

func (state *GameState) addPlayer(playerName string, isBot bool) {

	newPlayer := Player{
		Name:   playerName,
		Status: 0,
		Purse:  STARTING_PURSE,
		cards:  []card{},
		isBot:  isBot,
	}

	state.Players = append(state.Players, newPlayer)
}

// my code from here the old main loop ...

func oldmain() { // this was the main loop in the stand alone game now seeing what i need to make it work here
	fmt.Println("Welcome to Fuji-Llama!")
	// get the number of AI players with validate
	for !valid {
		fmt.Print("How many AI Bot's ? (1-5)")
		_, err := fmt.Scan(&numberplayers)
		if err != nil {
			fmt.Println("enter a number only, please try again")
		} else {
			valid = true
		}
		if numberplayers >= 1 && numberplayers <= 5 {
			valid = true
		} else {
			valid = false
			fmt.Println("1 to 5 only, please try again")
		}
	}
	numberplayers++ // add in the human player

	// Create the player array
	for i := 0; i < 6; i++ {
		player[i] = NewPlayer(i)
	}

	player[0].human = true // set the first player as human

	for gameactive {

		currentdeck = NewDeck()
		decksize = len(currentdeck)

		fmt.Println("Now Shuffling the cards:")
		currentdeck.Shuffle()
		fmt.Println("Now Dealing the cards:")
		// clear out players hands first and reset their state
		for i := 0; i < numberplayers; i++ {
			player[i].hand = []card{}
			player[i].playing = true
		}
		activePlayerCount = numberplayers // Reset active player count at the start of a round
		// deal the 6 cards to each player
		for j := 0; j < 6; j++ {
			for i := 0; i < numberplayers; i++ {
				player[i].hand = append(player[i].hand, currentdeck.DealCard())
			}
		}

		// turn over top card onto the discard pile
		topofdiscardpile = currentdeck.DealCard()

		// playing a round the main loop
		for roundactive {

			for i := 0; i < numberplayers; i++ {
				if player[i].playing {
					Display() // display the round status
					DoVaildMoves(i, CheckVaildMoves(i))

					hand := player[i].hand // Get the current player's hand
					if len(hand) == 0 {    // If the player has no cards left, they have won the round, end the round
						fmt.Println(player[i].name, "is all out, and has won the round")
						roundactive = false
						player[i].lastplayer = true // Mark this player as the last player to play
						break
					}
					if activePlayerCount == 0 { // If no active players left, end the round
						roundactive = false
						player[i].lastplayer = true // Mark this player as the last player to play
						break
					}
				}
			}
		}
		fmt.Println("----------------------------------------------------")
		fmt.Println("Round Over")
		EndofRoundScore()
		fmt.Println("----------------------------------------------------")

		if CheckGameEnd() {
			ReorderPlayers() // Reorder players for the next round
			fmt.Println("Press return to play the next round")
			waitkey := ""
			fmt.Scanln(&waitkey)
			roundactive = true
		}
		gameactive = CheckGameEnd()
	}
	DisplayGameEnd()
	fmt.Println("Thanks for playing Fuji-Llama!")
}

// create a new player with a name and default values
func NewPlayer(index int) players {
	playernames := []string{"Simon", "Lorenzo", "Jeff", "John", "Terry", "Eric", "Graham"}
	newPlayer := players{
		name:          playernames[index],
		human:         false,
		playing:       false,
		whitecounters: 0,
		blackcounters: 0,
		score:         0,
		playorder:     index,
	}
	return newPlayer
}

// NewDeck creates a new Llama 56-card deck.

func NewDeck() deck {
	cardNames := []string{"One", "Two", "Three", "Four", "Five", "Six", "Llama"}
	newDeck := make(deck, 0, 56) // Pre-allocate slice with capacity for 56 cards

	for i := 0; i < 8; i++ { // Repeat the cards 8 times to create a full deck
		for value, name := range cardNames {
			newDeck = append(newDeck, card{cardvalue: value + 1, cardname: name})
		}
	}
	return newDeck
}

// Shuffle shuffles the deck using the Fisher-Yates algorithm.
func (d *deck) Shuffle() {
	for i := len(*d) - 1; i > 0; i-- {
		j := rand.Intn(i + 1)
		(*d)[i], (*d)[j] = (*d)[j], (*d)[i]
	}
}

// DealCard deals a single card from the top of the deck.
func (d *deck) DealCard() card {
	card := (*d)[0]
	*d = (*d)[1:]
	return card
}

// display the current status
func Display() {
	fmt.Println("Current round status:")
	fmt.Println("----------------------------------------------------")

	for i := 0; i < numberplayers; i++ {
		var statetext string
		if player[i].playing {
			statetext = "playing"
		} else {
			statetext = "folded"
		}

		fmt.Println(player[i].name, "has", len(player[i].hand), "Cards\t:", statetext,
			":", player[i].whitecounters, "white counters and",
			player[i].blackcounters, "black counters and a score of",
			player[i].score)
		// fmt.Println(DisplayHand(i)) // Display the player's hand for debugging

	}
	fmt.Println("----------------------------------------------------")

}

// DisplayHand displays the cards in a player's hand.
// It returns a string representation of the hand.
// If the player index is invalid, it returns an error message.
// If the player has no cards in hand, it returns a message indicating that.
func DisplayHand(playerIndex int) string {
	if playerIndex < 0 || playerIndex >= numberplayers {
		return "Invalid player index"
	}

	hand := player[playerIndex].hand
	if len(hand) == 0 {
		return "No cards in hand"
	}

	handDisplay := "[ "
	for _, card := range hand {
		handDisplay += card.cardname + " "
	}
	handDisplay += "]"
	return handDisplay
}

// CheckVaildMoves checks the player's hand for valid moves
// The valid moves are determined based on them holding a card that matches the top card of the discard pile or next card in the sequence.
// then checks they can draw a card and if not they must or fold (they can fold if they don't want to fold).
// It returns a string indicating the valid moves available.
func CheckVaildMoves(index int) string {
	validmove := ""
	nextcard := 0
	currentcardcount := 0
	nextcardcount := 0
	decksize = len(currentdeck)
	if topofdiscardpile.cardvalue == 7 {
		nextcard = 1
	} else {
		nextcard = topofdiscardpile.cardvalue + 1
	}

	for _, s := range player[index].hand { // check each card in the players hand for valid cards
		if s.cardvalue == topofdiscardpile.cardvalue {
			currentcardcount++ // Count how many of the current card the player has
		}
		if s.cardvalue == nextcard {
			nextcardcount++ // Count how many of the current card the player has
		}
	}
	switch {
	case currentcardcount > 0 && nextcardcount > 0 && activePlayerCount > 1 && decksize > 0: // If they have both current and next card
		validmove = "CNcnDFdf" // Can play current or next card, draw a card or fold
	case currentcardcount > 0 && activePlayerCount > 1 && decksize > 0: // If they have just the current card
		validmove = "CcDFdf" // Can play current card, draw a card or fold
	case nextcardcount > 0 && activePlayerCount > 1 && decksize > 0: // If they have just the next card, draw a card or fold
		validmove = "NnDFdf"
	case currentcardcount > 0 && nextcardcount > 0 && (activePlayerCount == 1 || decksize < 1): // If they have both current and next card but your the only player left or deck is depleted
		validmove = "CNcnFf" // Can play current or next card or fold
	case currentcardcount > 0 && (activePlayerCount == 1 || decksize < 1): // If they have just the current but your the only player left or deck is depleted
		validmove = "CcFf" // Can play current card  or fold
	case nextcardcount > 0 && (activePlayerCount == 1 || decksize < 1): // If they have just the next card but your the only player left or deck is depleted
		validmove = "NnFf" // Can play next card or fold
	case decksize > 0 && activePlayerCount > 1: // if there are cards left in the deck you can draw or fold
		validmove = "DFdf"
	default: // fold is then only option left
		validmove = "Ff"
	}
	return validmove
}

// DoVaildMoves asks the play what moves they want to make and checks they are valid, also current does simple AI player moves.
func DoVaildMoves(index int, validmove string) {

	validcheck := false
	if player[index].human {
		fmt.Println("The top card showing is:", topofdiscardpile.cardname, "and there are", len(currentdeck), "cards remaining")
		fmt.Println("your hand is:", DisplayHand(index)) // Display the player's hand
		for !validcheck {
			fmt.Println(player[index].name, "your play options are:")
			switch {
			case validmove == "CNcnDFdf":
				fmt.Println("Play current card (C), Play next card (N), Draw card (D) or Fold (F)")
			case validmove == "CcDFdf":
				fmt.Println("Play current card (C), Draw card (D) or Fold (F)")
			case validmove == "NnDFdf":
				fmt.Println("Play next card (N), Draw card (D) or Fold (F)")
			case validmove == "CNcnFf":
				fmt.Println("Play current card (C), Play next card (N), or Fold (F)")
			case validmove == "CcFf":
				fmt.Println("Play current card (C) or Fold (F)")
			case validmove == "NnFf":
				fmt.Println("Play Next card (N) or Fold (F)")
			case validmove == "DFdf":
				fmt.Println("Draw card (D) or Fold (F)")
			default:
				fmt.Println("Fold (F)")
			}
			fmt.Scan(&move)
			if strings.Contains(validmove, move) {
				validcheck = true
			} else {
				fmt.Println("not a valid move, please try again")
				validcheck = false
			}
		}
	} else {
		// do AI stuff just do either randomly pick a valid move or play the first valid move
		rt := rand.Intn(10) // Randomly decide whether to play a card or draw a card or fold
		if rt < 3 {
			rm := rand.Intn(len(validmove)) // Randomly select a valid move
			move = string(validmove[rm])    // Get the move from the valid moves string
		} else {
			move = validmove[0:1]
		}
	}

	switch move {
	case "c", "C":
		fmt.Println(player[index].name, "played a", topofdiscardpile.cardname, "on to the discard pile")
		RemoveCard(index, topofdiscardpile.cardvalue)

	case "n", "N":
		// need to set card to 1 if current card is Llama (Im sure there is a better way to do this )
		if topofdiscardpile.cardvalue == 7 {
			topofdiscardpile.cardvalue = 1
			topofdiscardpile.cardname = "One"
		} else {
			topofdiscardpile.cardvalue = topofdiscardpile.cardvalue + 1
			cardNames := []string{"One", "Two", "Three", "Four", "Five", "Six", "Llama"}
			topofdiscardpile.cardname = cardNames[topofdiscardpile.cardvalue-1]
		}
		fmt.Println(player[index].name, "played a", topofdiscardpile.cardname, "on to the discard pile")
		RemoveCard(index, topofdiscardpile.cardvalue)

	case "d", "D":
		fmt.Println(player[index].name, "drew a new card from the deck")
		player[index].hand = append(player[index].hand, currentdeck.DealCard())
	case "f", "F":
		fmt.Println(player[index].name, "folded")
		player[index].playing = false
		activePlayerCount-- // decrement active player count
	}
}

// Remove the played card from players hand
func RemoveCard(index, cardvalue int) {

	for i, s := range player[index].hand { // find the card in the player's hand and then remove it
		if s.cardvalue == cardvalue {
			// Remove the card by slicing out the matched card
			player[index].hand = append(player[index].hand[:i], player[index].hand[i+1:]...)
			break // Exit the loop after removing the first matching card
		}
	}
}

// End of round scoreing
func EndofRoundScore() {
	fmt.Println("------------- End of round summary ------------------")
	for i := 0; i < numberplayers; i++ {
		a := 0
		b := 0
		c := 0
		for ii := 0; ii < len(player[i].hand); ii++ {
			switch {
			case player[i].hand[ii].cardvalue == 0:
				// do nothing
			case player[i].hand[ii].cardvalue == 7:
				b++ // Llama is worth 1 black counter (10 points)
			default:
				a = a + player[i].hand[ii].cardvalue
			}
		}

		c = a / 10
		b = b + c
		a = a - (c * 10)
		if (a + (b * 10)) == 0 {
			switch {
			case player[i].blackcounters > 0:
				fmt.Println(player[i].name, "finshed with no cards, so scores zero points and is returning one black token")
				player[1].blackcounters = player[i].blackcounters - 1
			case player[i].whitecounters > 0:
				fmt.Println(player[i].name, "finshed with no cards, so scores zero points and is returning one white token")
				player[i].whitecounters = player[i].whitecounters - 1
			default:
				fmt.Println(player[i].name, "finshed with no cards, so scores zero points")
			}
		} else {
			fmt.Println(player[i].name, "cards are", DisplayHand(i), "and gains", a, "white counters and", b, "black counters, scoring", a+(b*10), "points")
			player[i].whitecounters = player[i].whitecounters + a
			player[i].blackcounters = player[i].blackcounters + b
			player[i].score = player[i].score + a + (b * 10)
		}

	}

	// Sort by score, usign dummy slice to avoid modifying the original player array
	// This is useful for displaying the scores without stuffign up the player Array which craps out the code if I try to use a slice :-(
	var dummyplayerSlice []players
	for i := 0; i < numberplayers; i++ {
		if player[i].name != "" {
			dummyplayerSlice = append(dummyplayerSlice, player[i])
		}
	}

	sort.SliceStable(dummyplayerSlice[:], func(i, j int) bool {
		return dummyplayerSlice[i].score < dummyplayerSlice[j].score
	})

	fmt.Println("------------- End of round totals  ------------------")
	for i := 0; i < numberplayers; i++ {
		fmt.Println(dummyplayerSlice[i].name, "has", dummyplayerSlice[i].whitecounters, "white counters and",
			dummyplayerSlice[i].blackcounters, "black counters and a total score of",
			dummyplayerSlice[i].score)
	}
	// work out who was last to quit or emptied their hand
	//fmt.Println("The last player to quit or empty their hand was:", player[numberplayers-1].name, "with a score of", player[numberplayers-1].score)

	// Reset the playorder for the next round
	/*

			for i := 0; i < numberplayers; i++ {
				player[i].playorder = i // Reset playorder to the original order
			}
			 Change the playorder of players
			player[0].playorder = 6
			player[1].playorder = 5
			player[2].playorder = 2
			player[3].playorder = 1
			player[4].playorder = 3
			player[5].playorder = 0

		// Sort by playorder based on the playorder field
		// This will ensure that the players are sorted in the order they played in the last round
		// This is useful for determining the order of play in the next round.
		sort.SliceStable(player[:], func(i, j int) bool {
			return player[i].playorder < player[j].playorder
		})
	*/
}

// Check for game end
func CheckGameEnd() bool {
	var scorenotmax = true
	for i := 0; i < numberplayers; i++ {
		if player[i].score >= 40 {
			scorenotmax = false
		}
	}
	return scorenotmax
}

// show game over summary and the winner etc
func DisplayGameEnd() {
	fmt.Println("The Game is Over")
	// Sort by score, usign dummy slice to avoid modifying the original player array
	// This is useful for displaying the scores without stuffign up the player Array which craps out the code if I try to use a slice :-(
	var dummyplayerSlice []players
	for i := 0; i < numberplayers; i++ {
		if player[i].name != "" {
			dummyplayerSlice = append(dummyplayerSlice, player[i])
		}
	}

	sort.SliceStable(dummyplayerSlice[:], func(i, j int) bool {
		return dummyplayerSlice[i].score < dummyplayerSlice[j].score
	})

	// Sort by score with the dummy slice
	sort.SliceStable(dummyplayerSlice[:], func(i, j int) bool {
		return dummyplayerSlice[i].score < dummyplayerSlice[j].score
	})
	fmt.Println("------------- Final scores  ------------------")
	for i := 0; i < numberplayers; i++ {
		fmt.Println(dummyplayerSlice[i].name, "has", dummyplayerSlice[i].whitecounters, "white counters and",
			dummyplayerSlice[i].blackcounters, "black counters and a total score of",
			dummyplayerSlice[i].score)
	}
	fmt.Println("The Winner is:", dummyplayerSlice[0].name, "with a score of", dummyplayerSlice[0].score)
}

// Figure out who starts the next round and reorder the players
func ReorderPlayers() {
	var lastplayer int // Variable to hold the index of the last player who played or folded
	for i := 0; i < numberplayers; i++ {
		if player[i].lastplayer {
			lastplayer = i
			player[i].lastplayer = false // Reset last player flag for the next round
			break
		}
	}
	if lastplayer == 0 {
		return // If the last player is the first player, no need to change anything
	}
	// Reorder the players based on who one the last round, or who folded last
	// I couldn't figure out how to do this with a loop so I have hard coded it for now
	switch {
	case numberplayers == 6:
		switch {
		case lastplayer == 1:
			player[0].playorder = 5
			player[1].playorder = 0
			player[2].playorder = 1
			player[3].playorder = 2
			player[4].playorder = 3
			player[5].playorder = 4
		case lastplayer == 2:
			player[0].playorder = 4
			player[1].playorder = 5
			player[2].playorder = 0
			player[3].playorder = 1
			player[4].playorder = 2
			player[5].playorder = 3
		case lastplayer == 3:
			player[0].playorder = 3
			player[1].playorder = 4
			player[2].playorder = 5
			player[3].playorder = 0
			player[4].playorder = 1
			player[5].playorder = 2
		case lastplayer == 4:
			player[0].playorder = 2
			player[1].playorder = 3
			player[2].playorder = 4
			player[3].playorder = 5
			player[4].playorder = 0
			player[5].playorder = 1
		case lastplayer == 5:
			player[0].playorder = 1
			player[1].playorder = 2
			player[2].playorder = 3
			player[3].playorder = 4
			player[4].playorder = 5
			player[5].playorder = 0
		}
	case numberplayers == 5:
		switch {
		case lastplayer == 1:
			player[0].playorder = 4
			player[1].playorder = 0
			player[2].playorder = 1
			player[3].playorder = 2
			player[4].playorder = 3
		case lastplayer == 2:
			player[0].playorder = 3
			player[1].playorder = 4
			player[2].playorder = 0
			player[3].playorder = 1
			player[4].playorder = 2
		case lastplayer == 3:
			player[0].playorder = 2
			player[1].playorder = 3
			player[2].playorder = 4
			player[3].playorder = 0
			player[4].playorder = 1
		case lastplayer == 4:
			player[0].playorder = 1
			player[1].playorder = 2
			player[2].playorder = 3
			player[3].playorder = 4
			player[4].playorder = 0
		}
	case numberplayers == 4:
		switch {
		case lastplayer == 1:
			player[0].playorder = 3
			player[1].playorder = 0
			player[2].playorder = 1
			player[3].playorder = 2
		case lastplayer == 2:
			player[0].playorder = 2
			player[1].playorder = 3
			player[2].playorder = 0
			player[3].playorder = 1
		case lastplayer == 3:
			player[0].playorder = 1
			player[1].playorder = 2
			player[2].playorder = 3
			player[3].playorder = 0
		}
	case numberplayers == 3:
		switch {
		case lastplayer == 1:
			player[0].playorder = 2
			player[1].playorder = 0
			player[2].playorder = 1

		case lastplayer == 2:
			player[0].playorder = 1
			player[1].playorder = 2
			player[2].playorder = 0
		}
	case numberplayers == 2:
		player[0].playorder = 1
		player[1].playorder = 0
	}
	// Sort players by playorder by the new play order values
	sort.SliceStable(player[:], func(i, j int) bool {
		return player[i].playorder < player[j].playorder
	})
}
