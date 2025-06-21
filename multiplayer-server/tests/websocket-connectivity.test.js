const WebSocket = require('ws');

const SERVER_URL = 'ws://localhost:8080';

async function testConnection() {
    console.log('🔌 Testing WebSocket Connection...');
    
    return new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
            reject(new Error('Connection timeout'));
        }, 5000);
        
        const ws = new WebSocket(SERVER_URL);
        
        ws.on('open', () => {
            console.log('✅ WebSocket connected');
            clearTimeout(timeout);
            ws.close();
            resolve();
        });
        
        ws.on('error', (error) => {
            console.log('❌ Connection failed:', error.message);
            clearTimeout(timeout);
            reject(error);
        });
    });
}

async function runTest() {
    try {
        await testConnection();
        console.log('🎉 WebSocket test passed!');
        process.exit(0);
    } catch (error) {
        console.error('💥 Test failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    runTest();
}

module.exports = { testConnection };