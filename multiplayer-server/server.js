const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

// Create WebSocket server on port 8080
const wss = new WebSocket.Server({ port: 8080 });

// Game state storage
const games = new Map();
const players = new Map();

// Game configuration
const MAX_PLAYERS_PER_GAME = 4;
const GAME_START_DELAY = 3000; // 3 seconds

class Game {
    constructor(id, creatorId) {
        this.id = id;
        this.players = new Map();
        this.obstacles = new Map();
        this.collectibles = new Map();
        this.gameStarted = false;
        this.createdAt = Date.now();
        this.worldOffset = 0;
        
        console.log(`Game created: ${id} by player ${creatorId}`);
    }
    
    addPlayer(playerId, playerName, ws) {
        if (this.players.size >= MAX_PLAYERS_PER_GAME) {
            return false;
        }
        
        const playerColors = [
            "#FFFFFF", "#FF6B6B", "#4ECDC4", "#45B7D1", 
            "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8"
        ];
        
        const player = {
            id: playerId,
            name: playerName,
            ws: ws,
            position: { x: 0, y: 0 },
            velocity: { dx: 0, dy: 0 },
            rotation: 0,
            score: 0,
            isAlive: true,
            color: playerColors[this.players.size % playerColors.length],
            lastUpdate: Date.now()
        };
        
        this.players.set(playerId, player);
        console.log(`Player ${playerName} (${playerId}) joined game ${this.id}`);
        
        return true;
    }
    
    removePlayer(playerId) {
        this.players.delete(playerId);
        console.log(`Player ${playerId} left game ${this.id}`);
        
        // Clean up empty games
        if (this.players.size === 0) {
            games.delete(this.id);
            console.log(`Game ${this.id} cleaned up (no players)`);
        }
    }
    
    updatePlayerPosition(playerId, position, velocity, rotation) {
        const player = this.players.get(playerId);
        if (player) {
            player.position = position;
            player.velocity = velocity;
            player.rotation = rotation;
            player.lastUpdate = Date.now();
        }
    }
    
    handleGameEvent(playerId, event) {
        const player = this.players.get(playerId);
        if (!player) return;
        
        switch (event.eventType) {
            case 'player_crashed':
                player.isAlive = false;
                console.log(`Player ${playerId} crashed in game ${this.id}`);
                break;
                
            case 'collectible_gathered':
                player.score += event.value || 50;
                console.log(`Player ${playerId} scored ${event.value || 50} points in game ${this.id}`);
                break;
        }
    }
    
    getGameState() {
        const playerStates = Array.from(this.players.values()).map(player => ({
            id: player.id,
            name: player.name,
            position: player.position,
            velocity: player.velocity,
            rotation: player.rotation,
            score: player.score,
            isAlive: player.isAlive,
            color: player.color
        }));
        
        return {
            players: playerStates,
            obstacles: Array.from(this.obstacles.values()),
            collectibles: Array.from(this.collectibles.values()),
            gameStarted: this.gameStarted,
            gameTime: Date.now() - this.createdAt,
            worldOffset: this.worldOffset
        };
    }
    
    broadcast(message, excludePlayerId = null) {
        this.players.forEach((player, playerId) => {
            if (playerId !== excludePlayerId && player.ws.readyState === WebSocket.OPEN) {
                player.ws.send(JSON.stringify(message));
            }
        });
    }
    
    startGame() {
        this.gameStarted = true;
        console.log(`Game ${this.id} started with ${this.players.size} players`);
        
        const message = {
            type: 'game_start',
            gameId: this.id,
            playerId: '',
            playerName: '',
            timestamp: Date.now(),
            data: this.getGameState()
        };
        
        this.broadcast(message);
    }
}

// Handle new WebSocket connections
wss.on('connection', (ws) => {
    console.log('New client connected');
    
    ws.on('message', (data) => {
        try {
            const message = JSON.parse(data.toString());
            handleMessage(ws, message);
        } catch (error) {
            console.error('Error parsing message:', error);
            ws.send(JSON.stringify({
                type: 'error',
                message: 'Invalid message format'
            }));
        }
    });
    
    ws.on('close', () => {
        console.log('Client disconnected');
        handleDisconnection(ws);
    });
    
    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
});

function handleMessage(ws, message) {
    const { type, gameId, playerId, playerName, data } = message;
    
    switch (type) {
        case 'create_game':
            handleCreateGame(ws, playerId, playerName);
            break;
            
        case 'join_game':
            handleJoinGame(ws, gameId, playerId, playerName);
            break;
            
        case 'leave_game':
            handleLeaveGame(ws, gameId, playerId);
            break;
            
        case 'player_move':
            handlePlayerMove(gameId, playerId, data);
            break;
            
        case 'game_event':
            handleGameEvent(gameId, playerId, data);
            break;
            
        case 'ping':
            ws.send(JSON.stringify({
                type: 'pong',
                timestamp: Date.now()
            }));
            break;
            
        default:
            console.log(`Unknown message type: ${type}`);
    }
}

function handleCreateGame(ws, playerId, playerName) {
    const gameId = uuidv4();
    const game = new Game(gameId, playerId);
    games.set(gameId, game);
    
    // Add creator as first player
    game.addPlayer(playerId, playerName, ws);
    players.set(playerId, { gameId, ws });
    
    // Send game created confirmation
    ws.send(JSON.stringify({
        type: 'game_created',
        gameId: gameId,
        playerId: playerId,
        playerName: playerName,
        timestamp: Date.now(),
        data: {
            gameId: gameId,
            maxPlayers: MAX_PLAYERS_PER_GAME,
            currentPlayers: 1,
            players: [{ id: playerId, name: playerName, isReady: true, color: "#FFFFFF" }],
            gameStarted: false
        }
    }));
}

function handleJoinGame(ws, gameId, playerId, playerName) {
    const game = games.get(gameId);
    
    if (!game) {
        ws.send(JSON.stringify({
            type: 'error',
            message: 'Game not found'
        }));
        return;
    }
    
    if (!game.addPlayer(playerId, playerName, ws)) {
        ws.send(JSON.stringify({
            type: 'error',
            message: 'Game is full'
        }));
        return;
    }
    
    players.set(playerId, { gameId, ws });
    
    // Send join confirmation to the new player
    ws.send(JSON.stringify({
        type: 'game_joined',
        gameId: gameId,
        playerId: playerId,
        playerName: playerName,
        timestamp: Date.now(),
        data: {
            gameId: gameId,
            maxPlayers: MAX_PLAYERS_PER_GAME,
            currentPlayers: game.players.size,
            players: Array.from(game.players.values()).map(p => ({
                id: p.id,
                name: p.name,
                isReady: true,
                color: p.color
            })),
            gameStarted: game.gameStarted
        }
    }));
    
    // Notify other players
    game.broadcast({
        type: 'player_joined',
        gameId: gameId,
        playerId: playerId,
        playerName: playerName,
        timestamp: Date.now(),
        data: {
            gameId: gameId,
            maxPlayers: MAX_PLAYERS_PER_GAME,
            currentPlayers: game.players.size,
            players: Array.from(game.players.values()).map(p => ({
                id: p.id,
                name: p.name,
                isReady: true,
                color: p.color
            })),
            gameStarted: game.gameStarted
        }
    }, playerId);
    
    // Auto-start game when enough players join
    if (game.players.size >= 2 && !game.gameStarted) {
        setTimeout(() => {
            if (games.has(gameId) && game.players.size >= 2) {
                game.startGame();
            }
        }, GAME_START_DELAY);
    }
}

function handleLeaveGame(ws, gameId, playerId) {
    const game = games.get(gameId);
    if (!game) return;
    
    game.removePlayer(playerId);
    players.delete(playerId);
    
    // Notify remaining players
    game.broadcast({
        type: 'player_left',
        gameId: gameId,
        playerId: playerId,
        timestamp: Date.now(),
        data: {
            gameId: gameId,
            maxPlayers: MAX_PLAYERS_PER_GAME,
            currentPlayers: game.players.size,
            players: Array.from(game.players.values()).map(p => ({
                id: p.id,
                name: p.name,
                isReady: true,
                color: p.color
            })),
            gameStarted: game.gameStarted
        }
    });
}

function handlePlayerMove(gameId, playerId, data) {
    const game = games.get(gameId);
    if (!game || !game.gameStarted) return;
    
    game.updatePlayerPosition(playerId, data.position, data.velocity, data.rotation);
    
    // Broadcast to other players
    game.broadcast({
        type: 'player_move',
        gameId: gameId,
        playerId: playerId,
        timestamp: Date.now(),
        data: data
    }, playerId);
}

function handleGameEvent(gameId, playerId, data) {
    const game = games.get(gameId);
    if (!game) return;
    
    game.handleGameEvent(playerId, data);
    
    // Broadcast event to other players
    game.broadcast({
        type: 'game_event',
        gameId: gameId,
        playerId: playerId,
        timestamp: Date.now(),
        data: data
    }, playerId);
}

function handleDisconnection(ws) {
    // Find and remove player from their game
    for (const [playerId, playerInfo] of players.entries()) {
        if (playerInfo.ws === ws) {
            handleLeaveGame(ws, playerInfo.gameId, playerId);
            break;
        }
    }
}

// Periodic cleanup of inactive games
setInterval(() => {
    const now = Date.now();
    for (const [gameId, game] of games.entries()) {
        // Remove games that are older than 1 hour with no players
        if (game.players.size === 0 && (now - game.createdAt) > 3600000) {
            games.delete(gameId);
            console.log(`Cleaned up inactive game: ${gameId}`);
        }
    }
}, 300000); // Check every 5 minutes

console.log('Paper Airplane Multiplayer Server started on port 8080');
console.log('WebSocket endpoint: ws://localhost:8080');