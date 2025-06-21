# Paper Airplane - Multiplayer Implementation

This document explains the multiplayer functionality implemented for the Paper Airplane iOS game using WebSocket for real-time communication.

## Overview

The multiplayer system allows up to 4 players to compete in real-time, controlling their paper airplanes while avoiding obstacles and collecting stars. Players can see each other's movements, scores, and compete for the highest score.

## Architecture

### Client (iOS)
- **WebSocketManager**: Handles WebSocket connections and message routing
- **MultiplayerMessage**: Protocol definitions for network communication
- **MenuScene**: Main menu with single/multiplayer options
- **MultiplayerLobbyScene**: Lobby for creating/joining games
- **MultiplayerGameScene**: Real-time multiplayer game scene

### Server (Node.js)
- **WebSocket Server**: Handles client connections and game logic
- **Game State Management**: Manages multiple game rooms and player states
- **Real-time Synchronization**: Broadcasts player movements and events

## Features

### ✅ Implemented Features
- Real-time player movement synchronization (30 FPS)
- Game lobby system (create/join games)
- Up to 4 players per game
- Individual player colors and names
- Live leaderboard with scores
- Game events (crashes, collectibles)
- Smooth interpolation for remote players
- Automatic game cleanup
- Connection status monitoring

### 🚧 Future Enhancements
- Voice chat integration
- Spectator mode
- Tournament system
- Power-ups and special abilities
- Custom game modes
- Player statistics and rankings

## Setup Instructions

### 1. Server Setup

Navigate to the multiplayer server directory:
```bash
cd multiplayer-server
```

Install dependencies:
```bash
npm install
```

Start the server:
```bash
npm start
```

The server will start on `ws://localhost:8080`

For development with auto-restart:
```bash
npm run dev
```

### 2. iOS Client Configuration

The iOS client is already configured to connect to `ws://localhost:8080`. To change the server URL:

1. Open `Paper/WebSocketManager.swift`
2. Update the `serverURL` constant:

```swift
private let serverURL = "ws://your-server-url:8080"
```

### 3. Building and Running

1. Open the Xcode project
2. Build and run on your iOS device/simulator
3. Choose "Multiplayer" from the main menu
4. Create a game or join with game ID "demo_game_123"

## File Structure

```
Paper/
├── WebSocketManager.swift          # WebSocket connection management
├── MultiplayerMessage.swift        # Network protocol definitions
├── MenuScene.swift                 # Main menu scene
├── MultiplayerLobbyScene.swift     # Multiplayer lobby
├── MultiplayerGameScene.swift      # Real-time multiplayer game
├── GameScene.swift                 # Original single-player game
└── GameViewController.swift        # Updated to show menu

multiplayer-server/
├── server.js                       # Node.js WebSocket server
├── package.json                    # Server dependencies
└── README.md                       # Server documentation
```

## Network Protocol

### Message Types

| Type | Description |
|------|-------------|
| `create_game` | Create a new game room |
| `join_game` | Join an existing game |
| `player_move` | Player position/rotation update |
| `game_event` | Game events (crash, collectible) |
| `game_start` | Game starts with all players |
| `player_left` | Player disconnected |

### Message Format

```json
{
  "type": "player_move",
  "gameId": "uuid-string",
  "playerId": "uuid-string",
  "playerName": "Player Name",
  "timestamp": 1234567890,
  "data": {
    "position": { "x": 100, "y": 200 },
    "velocity": { "dx": 50, "dy": 25 },
    "rotation": 0.5
  }
}
```

## Deployment

### Development Server
The included Node.js server is suitable for development and testing.

### Production Deployment
For production, consider:

1. **Cloud Hosting**: Deploy to AWS, Google Cloud, or Heroku
2. **Load Balancing**: Use multiple server instances
3. **Database**: Store game statistics and player data
4. **SSL/TLS**: Use secure WebSocket connections (WSS)
5. **Rate Limiting**: Prevent spam and abuse
6. **Monitoring**: Add logging and error tracking

### Example Heroku Deployment

1. Create a `Procfile`:
```
web: node multiplayer-server/server.js
```

2. Update port configuration in `server.js`:
```javascript
const port = process.env.PORT || 8080;
const wss = new WebSocket.Server({ port });
```

3. Deploy to Heroku:
```bash
git add .
git commit -m "Add multiplayer server"
heroku create your-app-name
git push heroku main
```

## Testing

### Local Testing
1. Start the server: `cd multiplayer-server && npm start`
2. Run the iOS app on multiple simulators
3. Create/join games and test real-time synchronization

### Network Testing
- Test with different network conditions
- Verify reconnection handling
- Check performance with multiple players

## Troubleshooting

### Common Issues

**Connection Failed**
- Ensure server is running on correct port
- Check firewall settings
- Verify WebSocket URL in iOS app

**Players Not Syncing**
- Check server logs for errors
- Verify message format matches protocol
- Test with single connection first

**High Latency**
- Reduce position update frequency
- Implement client-side prediction
- Optimize server performance

### Debug Tools

**Server Logs**
```bash
# View server logs
npm start

# Enable debug mode
DEBUG=* npm start
```

**iOS Debug**
- Enable network logging in WebSocketManager
- Use Xcode's Network debugging tools
- Check device console logs

## Performance Considerations

### Client (iOS)
- Position updates: 30 FPS (configurable)
- Smooth interpolation for remote players
- Efficient message parsing and handling
- Memory management for disconnected players

### Server (Node.js)
- Handles 100+ concurrent connections
- Automatic game cleanup
- Efficient message broadcasting
- Memory-optimized player state storage

## Security Notes

⚠️ **Important**: This implementation is for development/demonstration purposes.

For production use, implement:
- Player authentication
- Input validation and sanitization
- Rate limiting and anti-cheat measures
- Secure WebSocket connections (WSS)
- Player data encryption

## Contributing

To add new features:

1. **Client**: Extend message types in `MultiplayerMessage.swift`
2. **Server**: Add handlers in `server.js`
3. **UI**: Update lobby and game scenes as needed
4. **Testing**: Verify with multiple clients

## License

This multiplayer implementation is part of the Paper Airplane game project and follows the same license terms.

---

## Quick Start Guide

1. **Start Server**: `cd multiplayer-server && npm install && npm start`
2. **Open iOS Project**: Launch in Xcode
3. **Run Game**: Choose "Multiplayer" → "Create Game"
4. **Test**: Run on multiple devices/simulators and join the same game

Enjoy flying with friends! ✈️