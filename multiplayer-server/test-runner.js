#!/usr/bin/env node

const { spawn } = require('child_process');

async function runCommand(command, args) {
    return new Promise((resolve, reject) => {
        console.log(`\n🚀 Running: ${command} ${args.join(' ')}`);
        
        const child = spawn(command, args, {
            stdio: 'inherit'
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

async function runTests() {
    console.log('🧪 Paper Airplane Test Runner');
    console.log('=' .repeat(40));
    
    try {
        console.log('🔌 Running connectivity test...');
        await runCommand('node', ['tests/websocket-connectivity.test.js']);
        
        console.log('\n🎉 Test completed successfully!');
        process.exit(0);
        
    } catch (error) {
        console.error('\n💥 Test failed:', error.message);
        process.exit(1);
    }
}

runTests();