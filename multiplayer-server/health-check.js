#!/usr/bin/env node

const WebSocket = require('ws');

const SERVER_URL = process.env.SERVER_URL || 'ws://localhost:8080';
const TIMEOUT = parseInt(process.env.HEALTH_CHECK_TIMEOUT) || 5000;

async function healthCheck() {
    console.log(`🔍 Checking health of ${SERVER_URL}...`);
    
    return new Promise((resolve, reject) => {
        const startTime = Date.now();
        
        const timeout = setTimeout(() => {
            reject(new Error(`Health check timeout after ${TIMEOUT}ms`));
        }, TIMEOUT);
        
        const ws = new WebSocket(SERVER_URL);
        
        ws.on('open', () => {
            // Send ping to verify server is responding
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
                    const responseTime = Date.now() - startTime;
                    clearTimeout(timeout);
                    ws.close();
                    resolve({
                        status: 'healthy',
                        responseTime: responseTime,
                        timestamp: new Date().toISOString()
                    });
                }
            } catch (error) {
                clearTimeout(timeout);
                ws.close();
                reject(new Error('Invalid response from server'));
            }
        });
        
        ws.on('error', (error) => {
            clearTimeout(timeout);
            reject(new Error(`Connection failed: ${error.message}`));
        });
        
        ws.on('close', (code) => {
            if (code !== 1000) {
                clearTimeout(timeout);
                reject(new Error(`Connection closed unexpectedly with code: ${code}`));
            }
        });
    });
}

async function main() {
    try {
        const result = await healthCheck();
        
        console.log('✅ Server is healthy');
        console.log(`📊 Response time: ${result.responseTime}ms`);
        console.log(`🕐 Checked at: ${result.timestamp}`);
        
        // Exit with success
        process.exit(0);
        
    } catch (error) {
        console.error('❌ Server health check failed');
        console.error(`💥 Error: ${error.message}`);
        
        // Exit with error code for monitoring systems
        process.exit(1);
    }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Health check interrupted');
    process.exit(1);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Health check terminated');
    process.exit(1);
});

if (require.main === module) {
    main();
}

module.exports = { healthCheck };