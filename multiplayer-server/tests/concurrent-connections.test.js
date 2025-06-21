const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const SERVER_URL = 'ws://localhost:8080';

async function testConcurrentGameCreation() {
    console.log('🎮 Testing Concurrent Game Creation...');
    
    const NUM_GAMES = 5;
    const connections = [];
    
    try {
        // Create multiple players simultaneously
        const players = await Promise.all(
            Array.from({ length: NUM_GAMES }, (_, i) => 
                createTestPlayer(`GameCreator${i}`)
            )
        );
        
        connections.push(...players.map(p => p.ws));
        
        // All players create games simultaneously
        await Promise.all(players.map(player => {
            sendMessage(player, 'create_game');
            return waitForMessage(player, 'game_created', 5000);
        }));
        
        // Verify all games were created with unique IDs
        const gameIds = players.map(player => {
            const msg = player.messages.find(m => m.type === 'game_created');
            return msg ? msg.gameId : null;
        });
        
        const uniqueGameIds = new Set(gameIds);
        if (uniqueGameIds.size !== NUM_GAMES || uniqueGameIds.has(null)) {
            throw new Error('Not all games were created with unique IDs');
        }
        
        console.log(`✅ Successfully created ${NUM_GAMES} concurrent games`);
        
        // Clean up
        players.forEach(player => player.ws.close());
        
    } catch (error) {
        connections.forEach(ws => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.close();
            }
        });
        throw error;
    }
}

async function testMultiplayerGame() {
    console.log('👥 Testing 4-Player Game...');
    
    const connections = [];
    
    try {
        // Create 4 players
        const players = await Promise.all([
            createTestPlayer('Player1'),
            createTestPlayer('Player2'),
            createTestPlayer('Player3'),
            createTestPlayer('Player4')
        ]);
        
        connections.push(...players.map(p => p.ws));
        
        // Player 1 creates a game
        sendMessage(players[0], 'create_game');
        await waitForMessage(players[0], 'game_created', 5000);
        
        const gameCreatedMsg = players[0].messages.find(m => m.type === 'game_created');
        const gameId = gameCreatedMsg.gameId;
        
        // Other players join the game
        for (let i = 1; i < 4; i++) {
            players[i].gameId = gameId;
            sendMessage(players[i], 'join_game');
            await waitForMessage(players[i], 'game_joined', 5000);
        }
        
        console.log('✅ All 4 players joined successfully');
        
        // Test concurrent movement updates
        const movementPromises = players.map((player, index) => {
            const movementData = {
                position: { x: index * 100, y: index * 50 },
                velocity: { dx: index * 5, dy: index * 3 },
                rotation: index * 0.5,
                timestamp: Date.now()
            };
            
            sendMessage(player, 'player_move', movementData);
            
            // Each player should receive 3 movement updates (from other players)
            return waitForMultipleMessages(player, 'player_move', 3, 10000);
        });
        
        await Promise.all(movementPromises);
        console.log('✅ Concurrent movement synchronization successful');
        
        // Clean up
        players.forEach(player => player.ws.close());
        
    } catch (error) {
        connections.forEach(ws => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.close();
            }
        });
        throw error;
    }
}

async function testServerLoad() {
    console.log('⚡ Testing Server Load (20 connections)...');
    
    const NUM_CONNECTIONS = 20;
    const connections = [];
    
    try {
        // Create connections in batches to avoid overwhelming
        const BATCH_SIZE = 5;
        const players = [];
        
        for (let batch = 0; batch < NUM_CONNECTIONS / BATCH_SIZE; batch++) {
            const batchPlayers = await Promise.all(
                Array.from({ length: BATCH_SIZE }, (_, i) => 
                    createTestPlayer(`LoadTest${batch * BATCH_SIZE + i}`)
                )
            );
            
            players.push(...batchPlayers);
            connections.push(...batchPlayers.map(p => p.ws));
            
            // Small delay between batches
            await new Promise(resolve => setTimeout(resolve, 100));
        }
        
        console.log(`✅ Created ${NUM_CONNECTIONS} connections`);
        
        // Test ping/pong with all connections
        const pingPromises = players.map(player => {
            const pingMsg = {
                type: 'ping',
                timestamp: Date.now()
            };
            player.ws.send(JSON.stringify(pingMsg));
            return waitForMessage(player, 'pong', 5000);
        });
        
        await Promise.all(pingPromises);
        console.log('✅ All connections responded to ping');
        
        // Clean up all connections
        players.forEach(player => player.ws.close());
        
        // Wait for all to close
        await Promise.all(players.map(player => 
            new Promise(resolve => {
                if (player.ws.readyState === WebSocket.CLOSED) {
                    resolve();
                } else {
                    player.ws.on('close', resolve);
                }
            })
        ));
        
        console.log('✅ All connections closed cleanly');
        
    } catch (error) {
        connections.forEach(ws => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.close();
            }
        });
        throw error;
    }
}

function createTestPlayer(name) {
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

function waitForMultipleMessages(player, messageType, count, timeout = 5000) {
    return new Promise((resolve, reject) => {
        const timeoutId = setTimeout(() => {
            reject(new Error(`Timeout waiting for ${count} messages of type: ${messageType}`));
        }, timeout);
        
        const checkMessages = () => {
            const messages = player.messages.filter(m => m.type === messageType);
            if (messages.length >= count) {
                clearTimeout(timeoutId);
                resolve(messages);
            } else {
                setTimeout(checkMessages, 100);
            }
        };
        
        checkMessages();
    });
}

async function runAllTests() {
    try {
        await testConcurrentGameCreation();
        await testMultiplayerGame();
        await testServerLoad();
        
        console.log('🎉 All concurrent connection tests passed!');
        process.exit(0);
    } catch (error) {
        console.error('💥 Concurrent connection test failed:', error.message);
        process.exit(1);
    }
}

// Run tests if this file is executed directly
if (require.main === module) {
    runAllTests();
}

module.exports = {
    testConcurrentGameCreation,
    testMultiplayerGame,
    testServerLoad
};