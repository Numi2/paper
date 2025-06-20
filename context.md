# Project Context: Paper

This project is an iOS side-scrolling game built with SpriteKit, where the player controls a paper airplane navigating through obstacles and collecting stars. The codebase is organized for clarity and extensibility, with the main logic in `GameScene.swift` and view management in `GameViewController.swift`.

## Architecture Overview

- **GameViewController.swift**: Sets up the main view, creates and presents the `GameScene`, and configures orientation and status bar preferences.
- **GameScene.swift**: Implements the core game logic, including scene setup, player controls, physics, obstacle and collectible spawning, scoring, and game over handling. Uses SpriteKit's node hierarchy and physics system.
- **AppDelegate.swift**: Handles app lifecycle events (standard iOS boilerplate).
- **Assets.xcassets/**: Contains all game assets (images, videos, etc.), referenced by the game for visuals and effects.
- **GameScene.sks / Actions.sks**: SpriteKit scene and action files (not currently loaded in code, but available for visual editing or future use).

## Main Game Loop & Flow

1. **Scene Setup**: On launch, `GameViewController` presents a new `GameScene` sized to the view. `GameScene` sets up physics, world/camera nodes, parallax background layers, UI labels, and the player airplane.
2. **Player Controls**: The player taps and drags to set a target location. The airplane accelerates toward this point, with drag and wind effects applied. The airplane's vertical position and rotation are updated each frame.
3. **World Movement**: The world and parallax layers scroll leftward based on the airplane's speed, creating a sense of forward motion. Obstacles and collectibles are spawned off-screen to the right and move left.
4. **Obstacles & Collectibles**: Random obstacles (clouds, birds, buildings) and star collectibles are spawned at intervals. Each has a physics body for collision detection.
5. **Scoring & UI**: The score increases over time and with collectibles. UI labels display score, speed, and instructions. Speed label color changes with velocity.
6. **Game Over**: Colliding with an obstacle ends the game, displaying a game over message and final score. Tapping restarts the game.

## Key Classes & Responsibilities

- **GameScene**:
  - Manages all game objects (player, obstacles, collectibles, parallax layers).
  - Handles touch input for airplane control.
  - Implements the main update loop: physics, movement, spawning, cleanup, scoring.
  - Uses SpriteKit's physics contact delegate for collision handling.
  - Manages camera following and UI overlays.
- **GameViewController**:
  - Presents the game scene and configures the view.
- **AppDelegate**:
  - Standard iOS app lifecycle management.

## Controls & Physics

- **Touch Input**: Tap and drag to set the airplane's target direction. The airplane accelerates toward the touch point.
- **Physics**: Custom velocity, acceleration, drag, and wind are applied to the airplane. SpriteKit physics bodies are used for collision detection.
- **Camera**: Follows the airplane with dynamic offset and shake at high speeds.

## Asset Management

- **Images & Videos**: Stored in `Assets.xcassets`. Used for backgrounds, obstacles, collectibles, and effects.
- **Procedural Graphics**: Many game elements (airplane, clouds, birds, buildings, stars) are drawn programmatically using `SKShapeNode` for flexibility and style.

## Extension Points & Suggestions for AI Agents

- **Game Logic Enhancements**: Add new obstacle types, collectibles, or power-ups. Adjust airplane physics for different difficulty modes.
- **UI/UX Improvements**: Add menus, pause/resume, sound effects, or visual polish (particle effects, animations).
- **Asset Management**: Integrate new assets or replace procedural graphics with images for a different look.
- **Performance Optimization**: Profile and optimize node management, physics, or rendering for smoother gameplay.
- **Level Design**: Implement level progression, missions, or achievements.
- **Accessibility**: Add support for colorblind modes, larger text, or alternative control schemes.

## How to Get Started

- The main entry point is `GameViewController.swift`, which loads `GameScene.swift`.
- Most gameplay changes will be made in `GameScene.swift`.
- Assets can be added to `Assets.xcassets` and referenced in code.
- For new features, consider extending the node hierarchy or adding new SKNode subclasses.

---

This context should help future AI agents quickly understand the structure and flow of the game, and identify where to make improvements or add new features. 