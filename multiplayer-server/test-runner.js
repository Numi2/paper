#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

async function runCommand(command, args, options = {}) {
    return new Promise((resolve, reject) => {
        console.log(`\n🚀 Running: ${command} ${args.join(' ')}`);
        
        const child = spawn(command, args, {
            stdio: 'inherit',
            ...options
        });
        
        child.on('close', (code) => {
            if (code === 0) {
                resolve();
            } else {
                reject(new Error(`Command failed with exit code ${code}`));
            }
        });
        
        child.on('error', reject);
    });
}

async function checkServerRunning() {
    const WebSocket = require('ws');
    
    return new Promise((resolve) => {
        const ws = new WebSocket('ws://localhost:8080');
        
        const timeout = setTimeout(() => {
            resolve(false);
        }, 2000);
        
        ws.on('open', () => {
            clearTimeout(timeout);
            ws.close();
            resolve(true);
        });
        
        ws.on('error', () => {
            clearTimeout(timeout);
            resolve(false);
        });
    });
}

async function startServer() {
    console.log('🔧 Starting multiplayer server...');
    
    const serverProcess = spawn('node', ['server.js'], {
        stdio: ['inherit', 'pipe', 'pipe']
    });
    
    // Wait for server to start
    await new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
            reject(new Error('Server startup timeout'));
        }, 10000);
        
        const checkServer = async () => {
            if (await checkServerRunning()) {
                clearTimeout(timeout);
                resolve();
            } else {
                setTimeout(checkServer, 500);
            }
        };
        
        checkServer();
    });
    
    console.log('✅ Server started successfully');
    return serverProcess;
}

async function runTests() {
    const args = process.argv.slice(2);
    const testType = args[0] || 'all';
    
    console.log('🧪 Paper Airplane Multiplayer Test Runner');
    console.log('=' .repeat(50));
    
    try {
        let serverProcess = null;
        const serverRunning = await checkServerRunning();
        
        if (!serverRunning) {
            console.log('⚠️  Server not running, starting it...');
            serverProcess = await startServer();
        } else {
            console.log('✅ Server already running');
        }
        
        switch (testType) {
            case 'unit':
                console.log('🔬 Running unit tests only...');
                await runCommand('npm', ['test']);
                break;
                
            case 'integration':
                console.log('🔗 Running integration tests only...');
                await runCommand('npm', ['run', 'test:integration']);
                break;
                
            case 'connectivity':
                console.log('🔌 Running connectivity tests only...');
                await runCommand('node', ['tests/websocket-connectivity.test.js']);
                break;
                
            case 'protocol':
                console.log('📡 Running protocol tests only...');
                await runCommand('node', ['tests/multiplayer-protocol.test.js']);
                break;
                
            case 'concurrent':
                console.log('👥 Running concurrent tests only...');
                await runCommand('node', ['tests/concurrent-connections.test.js']);
                break;
                
            case 'all':
            default:
                console.log('🎯 Running all tests...');
                await runCommand('npm', ['test']);
                await runCommand('npm', ['run', 'test:integration']);
                break;
        }
        
        console.log('\n🎉 All tests completed successfully!');
        
        // Clean up server if we started it
        if (serverProcess) {
            console.log('🛑 Stopping server...');
            serverProcess.kill();
        }
        
        process.exit(0);
        
    } catch (error) {
        console.error('\n💥 Tests failed:', error.message);
        process.exit(1);
    }
}

function showHelp() {
    console.log(`
🧪 Paper Airplane Multiplayer Test Runner

Usage: node test-runner.js [test-type]

Test Types:
  all          Run all tests (default)
  unit         Run unit tests only
  integration  Run integration tests only
  connectivity Run WebSocket connectivity tests
  protocol     Run multiplayer protocol tests
  concurrent   Run concurrent connection tests

Examples:
  node test-runner.js          # Run all tests
  node test-runner.js unit     # Run unit tests only
  node test-runner.js protocol # Run protocol tests only

The test runner will automatically start the server if it's not running.
    `);
}

if (process.argv.includes('--help') || process.argv.includes('-h')) {
    showHelp();
} else {
    runTests();
}