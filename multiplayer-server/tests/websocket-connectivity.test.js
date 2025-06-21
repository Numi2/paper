const WebSocket = require('ws');

const SERVER_URL = 'ws://localhost:8080';
const TEST_TIMEOUT = 10000;

async function testWebSocketConnectivity() {
    console.log('🔌 Testing WebSocket Connectivity...');
    
    return new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
            reject(new Error('Connection timeout'));
        }, TEST_TIMEOUT);
        
        const ws = new WebSocket(SERVER_URL);
        
        ws.on('open', () => {
            console.log('✅ WebSocket connection established');
            clearTimeout(timeout);
            ws.close();
            resolve();
        });
        
        ws.on('error', (error) => {
            console.log('❌ WebSocket connection failed:', error.message);
            clearTimeout(timeout);
            reject(error);
        });
        
        ws.on('close', () => {
            console.log('🔐 WebSocket connection closed');
        });
    });
}

async function testPingPong() {
    console.log('🏓 Testing Ping/Pong...');
    
    return new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
            reject(new Error('Ping/Pong timeout'));
        }, TEST_TIMEOUT);
        
        const ws = new WebSocket(SERVER_URL);
        
        ws.on('open', () => {
            const pingMessage = {
                type: 'ping',
                timestamp: Date.now()
            };
            ws.send(JSON.stringify(pingMessage));
        });
        
        ws.on('message', (data) => {
            try {
                const message = JSON.parse(data.toString());
                if (message.type === 'pong') {
                    console.log('✅ Ping/Pong successful');
                    clearTimeout(timeout);
                    ws.close();
                    resolve();
                } else {
                    reject(new Error(`Unexpected message type: ${message.type}`));
                }
            } catch (error) {
                reject(new Error('Invalid JSON response'));
            }
        });
        
        ws.on('error', (error) => {
            console.log('❌ Ping/Pong failed:', error.message);
            clearTimeout(timeout);
            reject(error);
        });
    });
}

async function testMultipleConnections() {
    console.log('👥 Testing Multiple Connections...');
    
    const connections = [];
    const NUM_CONNECTIONS = 5;
    
    try {
        // Create multiple connections
        for (let i = 0; i < NUM_CONNECTIONS; i++) {
            const ws = new WebSocket(SERVER_URL);
            connections.push(ws);
            
            await new Promise((resolve, reject) => {
                ws.on('open', resolve);
                ws.on('error', reject);
                setTimeout(() => reject(new Error('Connection timeout')), 5000);
            });
        }
        
        console.log(`✅ Successfully created ${NUM_CONNECTIONS} connections`);
        
        // Close all connections
        connections.forEach(ws => ws.close());
        
        // Wait for all to close
        await Promise.all(connections.map(ws => new Promise(resolve => {
            ws.on('close', resolve);
        })));
        
        console.log('✅ All connections closed successfully');
        
    } catch (error) {
        console.log('❌ Multiple connections test failed:', error.message);
        // Clean up any open connections
        connections.forEach(ws => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.close();
            }
        });
        throw error;
    }
}

async function runAllTests() {
    try {
        await testWebSocketConnectivity();
        await testPingPong();
        await testMultipleConnections();
        
        console.log('🎉 All WebSocket connectivity tests passed!');
        process.exit(0);
    } catch (error) {
        console.error('💥 Test failed:', error.message);
        process.exit(1);
    }
}

// Run tests if this file is executed directly
if (require.main === module) {
    runAllTests();
}

module.exports = {
    testWebSocketConnectivity,
    testPingPong,
    testMultipleConnections
};