const { Game } = require('../../test-utils/game-class');

describe('Game Class', () => {
  test('should create a game', () => {
    const game = new Game('test-game-id', 'creator-id');
    expect(game.id).toBe('test-game-id');
    expect(game.players.size).toBe(0);
  });
});