const path = require('path');

// Import all test modules
const connectivityTests = require('../websocket-connectivity.test.js');
const protocolTests = require('../multiplayer-protocol.test.js');
const concurrentTests = require('../concurrent-connections.test.js');

async function runIntegrationTests() {
    console.log('🚀 Starting Multiplayer Integration Tests');
    console.log('=' .repeat(50));
    
    const startTime = Date.now();
    let passed = 0;
    let failed = 0;
    
    const tests = [
        // Basic connectivity tests
        { name: 'WebSocket Connectivity', fn: connectivityTests.testWebSocketConnectivity },
        { name: 'Ping/Pong', fn: connectivityTests.testPingPong },
        { name: 'Multiple Connections', fn: connectivityTests.testMultipleConnections },
        
        // Protocol tests
        { name: 'Game Creation', fn: protocolTests.testGameCreation },
        { name: 'Game Joining', fn: protocolTests.testGameJoining },
        { name: 'Player Movement', fn: protocolTests.testPlayerMovement },
        { name: 'Game Events', fn: protocolTests.testGameEvents },
        { name: 'Player Leaving', fn: protocolTests.testPlayerLeaving },
        
        // Concurrent tests
        { name: 'Concurrent Game Creation', fn: concurrentTests.testConcurrentGameCreation },
        { name: '4-Player Game', fn: concurrentTests.testMultiplayerGame },
        { name: 'Server Load Test', fn: concurrentTests.testServerLoad }
    ];
    
    for (const test of tests) {
        try {
            console.log(`\n📋 Running: ${test.name}`);
            await test.fn();
            console.log(`✅ PASSED: ${test.name}`);
            passed++;
        } catch (error) {
            console.log(`❌ FAILED: ${test.name}`);
            console.log(`   Error: ${error.message}`);
            failed++;
        }
        
        // Small delay between tests
        await new Promise(resolve => setTimeout(resolve, 500));
    }
    
    const endTime = Date.now();
    const duration = (endTime - startTime) / 1000;
    
    console.log('\n' + '=' .repeat(50));
    console.log(`📊 Test Results:`);
    console.log(`   ✅ Passed: ${passed}`);
    console.log(`   ❌ Failed: ${failed}`);
    console.log(`   ⏱️  Duration: ${duration.toFixed(2)}s`);
    
    if (failed > 0) {
        console.log('\n💥 Some tests failed!');
        process.exit(1);
    } else {
        console.log('\n🎉 All integration tests passed!');
        process.exit(0);
    }
}

// Check if server is running
async function checkServerHealth() {
    const WebSocket = require('ws');
    
    return new Promise((resolve, reject) => {
        const ws = new WebSocket('ws://localhost:8080');
        
        const timeout = setTimeout(() => {
            reject(new Error('Server health check timeout'));
        }, 5000);
        
        ws.on('open', () => {
            clearTimeout(timeout);
            ws.close();
            resolve();
        });
        
        ws.on('error', (error) => {
            clearTimeout(timeout);
            reject(new Error(`Server not responding: ${error.message}`));
        });
    });
}

async function main() {
    try {
        console.log('🔍 Checking server health...');
        await checkServerHealth();
        console.log('✅ Server is responding');
        
        await runIntegrationTests();
    } catch (error) {
        console.error('💥 Integration tests failed:', error.message);
        console.error('❗ Make sure the multiplayer server is running on port 8080');
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}