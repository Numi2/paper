# Simplified Test Suite

This test suite has been drastically simplified to focus on essential functionality.

## Test Files

- **websocket-connectivity.test.js** - Basic WebSocket connection test
- **concurrent-connections.test.js** - Simple concurrent connections test  
- **multiplayer-protocol.test.js** - Basic protocol communication test
- **unit/game.test.js** - Simple game class creation test

## Running Tests

```bash
# Run the main connectivity test
node test-runner.js

# Or run individual tests
node tests/websocket-connectivity.test.js
node tests/concurrent-connections.test.js
node tests/multiplayer-protocol.test.js
```

Each test file contains exactly **one test function** that covers the most essential functionality without complexity.