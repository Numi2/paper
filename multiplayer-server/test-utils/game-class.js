// Extract Game class for testing purposes
// This file isolates the Game class logic from the WebSocket server

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
        const MAX_PLAYERS_PER_GAME = 4;
        
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
            if (playerId !== excludePlayerId && player.ws && player.ws.readyState === 1) {
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

module.exports = { Game };