#!/bin/bash

# Fuji-Llama Cloud Shell Setup Script
# This script sets up the environment when opening in Google Cloud Shell

echo "🦙 Welcome to Fuji-Llama development environment!"
echo ""
echo "This is a Llama Card game server written in Go with multiple clients."
echo ""
echo "Quick Start:"
echo "1. To run the server locally:"
echo "   cd server && go run ."
echo ""
echo "2. To deploy to Google Cloud Run:"
echo "   cd server && chmod +x deploy.sh && ./deploy.sh"
echo ""
echo "3. To test the web client:"
echo "   Open Client/Web/index.html in a web browser"
echo ""
echo "📚 Check README.md for more detailed instructions."
echo ""

# Set up Go environment if needed
if ! command -v go &> /dev/null; then
    echo "Setting up Go environment..."
    # Cloud Shell usually has Go pre-installed, but just in case
    export PATH=$PATH:/usr/local/go/bin
fi

# Navigate to the project directory
echo "Environment setup complete! 🚀"
echo "Current directory: $(pwd)"