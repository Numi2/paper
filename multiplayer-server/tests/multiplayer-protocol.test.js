const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const SERVER_URL = 'ws://localhost:8080';
const TEST_TIMEOUT = 15000;

function createTestPlayer(name, onMessage = null) {
    return new Promise((resolve, reject) => {
        const playerId = uuidv4();
        const ws = new WebSocket(SERVER_URL);
        
        const player = {
            id: playerId,
            name: name,
            ws: ws,
            gameId: null,
            messages: []
        };
        
        ws.on('open', () => {
            resolve(player);
        });
        
        ws.on('message', (data) => {
            const message = JSON.parse(data.toString());
            player.messages.push(message);
            
            if (onMessage) {
                onMessage(message, player);
            }
        });
        
        ws.on('error', reject);
        
        setTimeout(() => reject(new Error('Player connection timeout')), 5000);
    });
}

function sendMessage(player, type, data = null) {
    const message = {
        type: type,
        gameId: player.gameId,
        playerId: player.id,
        playerName: player.name,
        timestamp: Date.now(),
        data: data
    };
    
    player.ws.send(JSON.stringify(message));
}

async function testGameCreation() {
    console.log('🎮 Testing Game Creation...');
    
    const player1 = await createTestPlayer('Player1');
    
    try {
        // Create a game
        sendMessage(player1, 'create_game');
        
        // Wait for game created response
        await waitForMessage(player1, 'game_created', 5000);
        
        const gameCreatedMsg = player1.messages.find(m => m.type === 'game_created');
        if (!gameCreatedMsg || !gameCreatedMsg.gameId) {
            throw new Error('Game creation failed - no game ID received');
        }
        
        player1.gameId = gameCreatedMsg.gameId;
        console.log(`✅ Game created successfully: ${player1.gameId}`);
        
        player1.ws.close();
        
    } catch (error) {
        player1.ws.close();
        throw error;
    }
}

async function testGameJoining() {
    console.log('👥 Testing Game Joining...');
    
    const player1 = await createTestPlayer('Host');
    const player2 = await createTestPlayer('Guest');
    
    try {
        // Player 1 creates a game
        sendMessage(player1, 'create_game');
        await waitForMessage(player1, 'game_created', 5000);
        
        const gameCreatedMsg = player1.messages.find(m => m.type === 'game_created');
        player1.gameId = gameCreatedMsg.gameId;
        
        // Player 2 joins the game
        player2.gameId = player1.gameId;
        sendMessage(player2, 'join_game');
        
        // Wait for join confirmation
        await waitForMessage(player2, 'game_joined', 5000);
        
        // Player 1 should receive player_joined notification
        await waitForMessage(player1, 'player_joined', 5000);
        
        console.log('✅ Game joining successful');
        
        player1.ws.close();
        player2.ws.close();
        
    } catch (error) {
        player1.ws.close();
        player2.ws.close();
        throw error;
    }
}

async function testPlayerMovement() {
    console.log('🏃 Testing Player Movement...');
    
    const player1 = await createTestPlayer('Mover');
    const player2 = await createTestPlayer('Observer');
    
    try {
        // Create and join game
        sendMessage(player1, 'create_game');
        await waitForMessage(player1, 'game_created', 5000);
        
        const gameCreatedMsg = player1.messages.find(m => m.type === 'game_created');
        player1.gameId = gameCreatedMsg.gameId;
        
        player2.gameId = player1.gameId;
        sendMessage(player2, 'join_game');
        await waitForMessage(player2, 'game_joined', 5000);
        
        // Clear messages to focus on movement
        player1.messages = [];
        player2.messages = [];
        
        // Player 1 sends movement data
        const movementData = {
            position: { x: 100, y: 200 },
            velocity: { dx: 10, dy: 20 },
            rotation: 1.5,
            timestamp: Date.now()
        };
        
        sendMessage(player1, 'player_move', movementData);
        
        // Player 2 should receive the movement update
        await waitForMessage(player2, 'player_move', 5000);
        
        const movementMsg = player2.messages.find(m => m.type === 'player_move');
        if (!movementMsg || !movementMsg.data) {
            throw new Error('Movement data not received');
        }
        
        console.log('✅ Player movement synchronization successful');
        
        player1.ws.close();
        player2.ws.close();
        
    } catch (error) {
        player1.ws.close();
        player2.ws.close();
        throw error;
    }
}

async function testGameEvents() {
    console.log('💥 Testing Game Events...');
    
    const player1 = await createTestPlayer('EventSender');
    const player2 = await createTestPlayer('EventReceiver');
    
    try {
        // Setup game
        sendMessage(player1, 'create_game');
        await waitForMessage(player1, 'game_created', 5000);
        
        const gameCreatedMsg = player1.messages.find(m => m.type === 'game_created');
        player1.gameId = gameCreatedMsg.gameId;
        
        player2.gameId = player1.gameId;
        sendMessage(player2, 'join_game');
        await waitForMessage(player2, 'game_joined', 5000);
        
        // Clear messages
        player1.messages = [];
        player2.messages = [];
        
        // Send game event
        const eventData = {
            eventType: 'collectible_gathered',
            position: { x: 50, y: 75 },
            value: 100,
            timestamp: Date.now()
        };
        
        sendMessage(player1, 'game_event', eventData);
        
        // Player 2 should receive the event
        await waitForMessage(player2, 'game_event', 5000);
        
        const eventMsg = player2.messages.find(m => m.type === 'game_event');
        if (!eventMsg || !eventMsg.data || eventMsg.data.eventType !== 'collectible_gathered') {
            throw new Error('Game event not properly received');
        }
        
        console.log('✅ Game events working correctly');
        
        player1.ws.close();
        player2.ws.close();
        
    } catch (error) {
        player1.ws.close();
        player2.ws.close();
        throw error;
    }
}

async function testPlayerLeaving() {
    console.log('🚪 Testing Player Leaving...');
    
    const player1 = await createTestPlayer('Stayer');
    const player2 = await createTestPlayer('Leaver');
    
    try {
        // Setup game
        sendMessage(player1, 'create_game');
        await waitForMessage(player1, 'game_created', 5000);
        
        const gameCreatedMsg = player1.messages.find(m => m.type === 'game_created');
        player1.gameId = gameCreatedMsg.gameId;
        
        player2.gameId = player1.gameId;
        sendMessage(player2, 'join_game');
        await waitForMessage(player2, 'game_joined', 5000);
        
        // Clear messages
        player1.messages = [];
        
        // Player 2 leaves
        sendMessage(player2, 'leave_game');
        player2.ws.close();
        
        // Player 1 should receive player_left notification
        await waitForMessage(player1, 'player_left', 5000);
        
        console.log('✅ Player leaving handled correctly');
        
        player1.ws.close();
        
    } catch (error) {
        player1.ws.close();
        if (player2.ws.readyState === WebSocket.OPEN) {
            player2.ws.close();
        }
        throw error;
    }
}

function waitForMessage(player, messageType, timeout = 5000) {
    return new Promise((resolve, reject) => {
        const timeoutId = setTimeout(() => {
            reject(new Error(`Timeout waiting for message type: ${messageType}`));
        }, timeout);
        
        const checkMessages = () => {
            const message = player.messages.find(m => m.type === messageType);
            if (message) {
                clearTimeout(timeoutId);
                resolve(message);
            } else {
                setTimeout(checkMessages, 100);
            }
        };
        
        checkMessages();
    });
}

async function runAllTests() {
    try {
        await testGameCreation();
        await testGameJoining();
        await testPlayerMovement();
        await testGameEvents();
        await testPlayerLeaving();
        
        console.log('🎉 All multiplayer protocol tests passed!');
        process.exit(0);
    } catch (error) {
        console.error('💥 Protocol test failed:', error.message);
        process.exit(1);
    }
}

// Run tests if this file is executed directly
if (require.main === module) {
    runAllTests();
}

module.exports = {
    testGameCreation,
    testGameJoining,
    testPlayerMovement,
    testGameEvents,
    testPlayerLeaving
};