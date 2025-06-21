const WebSocket = require('ws');

const SERVER_URL = 'ws://localhost:8080';

async function testBasicProtocol() {
    console.log('📡 Testing Basic Protocol...');
    
    return new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
            reject(new Error('Protocol test timeout'));
        }, 5000);
        
        const ws = new WebSocket(SERVER_URL);
        
        ws.on('open', () => {
            // Send a simple ping message
            const message = {
                type: 'ping',
                timestamp: Date.now()
            };
            ws.send(JSON.stringify(message));
        });
        
        ws.on('message', (data) => {
            try {
                const message = JSON.parse(data.toString());
                if (message.type === 'pong') {
                    console.log('✅ Protocol communication successful');
                    clearTimeout(timeout);
                    ws.close();
                    resolve();
                }
            } catch (error) {
                clearTimeout(timeout);
                reject(new Error('Invalid protocol response'));
            }
        });
        
        ws.on('error', (error) => {
            clearTimeout(timeout);
            reject(error);
        });
    });
}

async function runTest() {
    try {
        await testBasicProtocol();
        console.log('🎉 Protocol test passed!');
        process.exit(0);
    } catch (error) {
        console.error('💥 Test failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    runTest();
}

module.exports = { testBasicProtocol };