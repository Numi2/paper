# Multiplayer Server Tests

This directory contains comprehensive tests for the Paper Airplane multiplayer server.

## Test Structure

```
tests/
├── unit/                          # Unit tests (Jest)
│   └── game.test.js              # Game class unit tests
├── integration/                   # Integration tests
│   └── run-all.js                # Test orchestrator
├── websocket-connectivity.test.js # WebSocket connection tests
├── multiplayer-protocol.test.js   # Game protocol tests
├── concurrent-connections.test.js # Load and concurrency tests
└── README.md                     # This file
```

## Running Tests

### All Tests (via GitHub Actions)
Tests run automatically on push/PR to verify multiplayer functionality.

### Manual Testing

1. **Start the server:**
   ```bash
   cd multiplayer-server
   npm start
   ```

2. **Run unit tests:**
   ```bash
   npm test
   ```

3. **Run integration tests:**
   ```bash
   npm run test:integration
   ```

4. **Run individual test suites:**
   ```bash
   node tests/websocket-connectivity.test.js
   node tests/multiplayer-protocol.test.js
   node tests/concurrent-connections.test.js
   ```

## Test Coverage

### ✅ Unit Tests
- Game class functionality
- Player management
- Game state management
- Message broadcasting
- Event handling

### ✅ Connectivity Tests
- WebSocket connection establishment
- Ping/pong functionality
- Multiple simultaneous connections
- Connection cleanup

### ✅ Protocol Tests
- Game creation and joining
- Player movement synchronization
- Game event handling
- Player leaving/disconnection

### ✅ Concurrency Tests
- Multiple game creation
- 4-player game scenarios
- Server load testing (20+ connections)
- Movement synchronization under load

## Test Requirements

- **Node.js 14+**
- **Server running on port 8080**
- **Available network connections**

## Expected Output

```
🚀 Starting Multiplayer Integration Tests
==================================================

📋 Running: WebSocket Connectivity
✅ PASSED: WebSocket Connectivity

📋 Running: Game Creation
✅ PASSED: Game Creation

...

==================================================
📊 Test Results:
   ✅ Passed: 11
   ❌ Failed: 0
   ⏱️  Duration: 8.45s

🎉 All integration tests passed!
```

## Troubleshooting

### Common Issues

**Server Not Running**
```
💥 Integration tests failed: Server not responding
❗ Make sure the multiplayer server is running on port 8080
```
- Solution: Start server with `npm start`

**Port Already in Use**
```
Error: listen EADDRINUSE :::8080
```
- Solution: Kill process using port 8080 or change server port

**Connection Timeouts**
- Check firewall settings
- Verify server is accessible on localhost:8080
- Increase timeout values in test files if needed

### Debug Mode

Enable detailed logging:
```bash
DEBUG=* npm start
```

For test debugging, modify timeout values in test files:
- `TEST_TIMEOUT` in websocket-connectivity.test.js
- Function-specific timeouts in other test files