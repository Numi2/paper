const { Game } = require('../../test-utils/game-class');

describe('Game Class', () => {
  let game;
  const mockWs = {
    send: jest.fn(),
    readyState: 1 // WebSocket.OPEN
  };

  beforeEach(() => {
    game = new Game('test-game-id', 'creator-id');
    jest.clearAllMocks();
  });

  describe('Game Creation', () => {
    test('should create a game with correct initial state', () => {
      expect(game.id).toBe('test-game-id');
      expect(game.players.size).toBe(0);
      expect(game.gameStarted).toBe(false);
      expect(typeof game.createdAt).toBe('number');
    });
  });

  describe('Player Management', () => {
    test('should add a player successfully', () => {
      const result = game.addPlayer('player-1', 'Test Player', mockWs);
      
      expect(result).toBe(true);
      expect(game.players.size).toBe(1);
      expect(game.players.get('player-1')).toBeDefined();
      expect(game.players.get('player-1').name).toBe('Test Player');
    });

    test('should reject players when game is full', () => {
      // Add maximum players (4)
      for (let i = 0; i < 4; i++) {
        game.addPlayer(`player-${i}`, `Player ${i}`, mockWs);
      }
      
      const result = game.addPlayer('player-5', 'Extra Player', mockWs);
      expect(result).toBe(false);
      expect(game.players.size).toBe(4);
    });

    test('should assign unique colors to players', () => {
      game.addPlayer('player-1', 'Player 1', mockWs);
      game.addPlayer('player-2', 'Player 2', mockWs);
      
      const player1 = game.players.get('player-1');
      const player2 = game.players.get('player-2');
      
      expect(player1.color).not.toBe(player2.color);
      expect(player1.color).toMatch(/^#[0-9A-F]{6}$/);
    });

    test('should remove a player successfully', () => {
      game.addPlayer('player-1', 'Test Player', mockWs);
      expect(game.players.size).toBe(1);
      
      game.removePlayer('player-1');
      expect(game.players.size).toBe(0);
    });
  });

  describe('Player Position Updates', () => {
    beforeEach(() => {
      game.addPlayer('player-1', 'Test Player', mockWs);
    });

    test('should update player position correctly', () => {
      const position = { x: 100, y: 200 };
      const velocity = { dx: 10, dy: 20 };
      const rotation = 1.5;

      game.updatePlayerPosition('player-1', position, velocity, rotation);
      
      const player = game.players.get('player-1');
      expect(player.position).toEqual(position);
      expect(player.velocity).toEqual(velocity);
      expect(player.rotation).toBe(rotation);
    });

    test('should update lastUpdate timestamp', () => {
      const beforeUpdate = game.players.get('player-1').lastUpdate;
      
      game.updatePlayerPosition('player-1', { x: 0, y: 0 }, { dx: 0, dy: 0 }, 0);
      
      const afterUpdate = game.players.get('player-1').lastUpdate;
      expect(afterUpdate).toBeGreaterThan(beforeUpdate);
    });
  });

  describe('Game Events', () => {
    beforeEach(() => {
      game.addPlayer('player-1', 'Test Player', mockWs);
    });

    test('should handle player crash event', () => {
      const event = { eventType: 'player_crashed' };
      
      game.handleGameEvent('player-1', event);
      
      const player = game.players.get('player-1');
      expect(player.isAlive).toBe(false);
    });

    test('should handle collectible gathered event', () => {
      const event = { eventType: 'collectible_gathered', value: 50 };
      const initialScore = game.players.get('player-1').score;
      
      game.handleGameEvent('player-1', event);
      
      const player = game.players.get('player-1');
      expect(player.score).toBe(initialScore + 50);
    });
  });

  describe('Game State', () => {
    test('should return correct game state', () => {
      game.addPlayer('player-1', 'Player 1', mockWs);
      game.addPlayer('player-2', 'Player 2', mockWs);
      
      const gameState = game.getGameState();
      
      expect(gameState.players).toHaveLength(2);
      expect(gameState.gameStarted).toBe(false);
      expect(gameState.obstacles).toHaveLength(0);
      expect(gameState.collectibles).toHaveLength(0);
      expect(typeof gameState.gameTime).toBe('number');
    });
  });

  describe('Message Broadcasting', () => {
    test('should broadcast message to all players', () => {
      const mockWs1 = { send: jest.fn(), readyState: 1 };
      const mockWs2 = { send: jest.fn(), readyState: 1 };
      
      game.addPlayer('player-1', 'Player 1', mockWs1);
      game.addPlayer('player-2', 'Player 2', mockWs2);
      
      const message = { type: 'test', data: 'hello' };
      game.broadcast(message);
      
      expect(mockWs1.send).toHaveBeenCalledWith(JSON.stringify(message));
      expect(mockWs2.send).toHaveBeenCalledWith(JSON.stringify(message));
    });

    test('should exclude specified player from broadcast', () => {
      const mockWs1 = { send: jest.fn(), readyState: 1 };
      const mockWs2 = { send: jest.fn(), readyState: 1 };
      
      game.addPlayer('player-1', 'Player 1', mockWs1);
      game.addPlayer('player-2', 'Player 2', mockWs2);
      
      const message = { type: 'test', data: 'hello' };
      game.broadcast(message, 'player-1');
      
      expect(mockWs1.send).not.toHaveBeenCalled();
      expect(mockWs2.send).toHaveBeenCalledWith(JSON.stringify(message));
    });
  });

  describe('Game Start', () => {
    test('should start game and broadcast to players', () => {
      const mockWs1 = { send: jest.fn(), readyState: 1 };
      const mockWs2 = { send: jest.fn(), readyState: 1 };
      
      game.addPlayer('player-1', 'Player 1', mockWs1);
      game.addPlayer('player-2', 'Player 2', mockWs2);
      
      game.startGame();
      
      expect(game.gameStarted).toBe(true);
      expect(mockWs1.send).toHaveBeenCalled();
      expect(mockWs2.send).toHaveBeenCalled();
      
      const sentMessage = JSON.parse(mockWs1.send.mock.calls[0][0]);
      expect(sentMessage.type).toBe('game_start');
    });
  });
});