# Fuji-Llama Development in Google Cloud Shell

Welcome to the Fuji-Llama project! This tutorial will help you get started with developing and deploying the Llama card game server.

## Project Overview

Fuji-Llama is a card game server written in Go with multiple clients:
- **Server**: Go-based REST API server
- **Web Client**: HTML/JavaScript client
- **Atari Client**: Atari 8-bit computer client

## Getting Started

### 1. Explore the Project Structure

```bash
ls -la
```

Key directories:
- `server/` - Go server code and deployment scripts
- `Client/Web/` - Web-based client
- `Client/Atari/` - Atari 8-bit client
- `Llama/` - Standalone terminal game

### 2. Run the Server Locally

```bash
cd server
go run .
```

The server will start on port 8080. You can test it by accessing the web client.

### 3. Test the Web Client

Open the web client in Cloud Shell's web preview:
```bash
cd Client/Web
python3 -m http.server 8000
```

Then use Cloud Shell's web preview feature to view it on port 8000.

### 4. Deploy to Google Cloud Run

First, make sure you're authenticated and have a project set:
```bash
gcloud auth list
gcloud config list project
```

If you need to set a project:
```bash
gcloud config set project YOUR_PROJECT_ID
```

Then deploy:
```bash
cd server
./deploy.sh
```

## Available Endpoints

Once running, the server provides these endpoints:
- `GET /tables` - List available game tables
- `GET /join?table=TABLE&player=NAME` - Join a game table
- `GET /state?table=TABLE&player=NAME` - Get game state
- `GET /devview?table=TABLE` - Developer view of game state

## Development Tips

1. **Live Development**: Use `go run .` for quick testing
2. **Build for Production**: Use `go build` to create a binary
3. **Testing**: The web client can connect to `localhost:8080` for local testing

## Next Steps

- Explore the game logic in `server/main.go`
- Try the web client at `Client/Web/index.html`
- Check out the standalone version in `Llama/`

Happy coding! 🦙