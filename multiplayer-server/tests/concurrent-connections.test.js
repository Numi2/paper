const WebSocket = require('ws');

const SERVER_URL = 'ws://localhost:8080';

async function testConcurrentConnections() {
    console.log('👥 Testing Concurrent Connections...');
    
    const connections = [];
    const NUM_CONNECTIONS = 3;
    
    try {
        // Create 3 connections simultaneously
        const connectionPromises = Array.from({ length: NUM_CONNECTIONS }, () => {
            return new Promise((resolve, reject) => {
                const ws = new WebSocket(SERVER_URL);
                connections.push(ws);
                
                ws.on('open', () => resolve(ws));
                ws.on('error', reject);
                setTimeout(() => reject(new Error('Connection timeout')), 3000);
            });
        });
        
        await Promise.all(connectionPromises);
        console.log(`✅ Successfully created ${NUM_CONNECTIONS} concurrent connections`);
        
        // Close all connections
        connections.forEach(ws => ws.close());
        
    } catch (error) {
        connections.forEach(ws => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.close();
            }
        });
        throw error;
    }
}

async function runTest() {
    try {
        await testConcurrentConnections();
        console.log('🎉 Concurrent connection test passed!');
        process.exit(0);
    } catch (error) {
        console.error('💥 Test failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    runTest();
}

module.exports = { testConcurrentConnections };