#!/bin/bash

# Script to set up Firestore emulator test data
echo "🚀 Setting up Firestore emulator test data..."

# Check if emulator is running
if ! curl -s http://localhost:4000 > /dev/null; then
    echo "❌ Firestore emulator is not running!"
    echo "Please start it first with: npm run serve"
    exit 1
fi

# Set environment to use emulator
export FIRESTORE_EMULATOR_HOST=localhost:8080
export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099

# Run the setup script
echo "📝 Populating Firestore with test data..."
node setup-test-data.js

echo "✅ Test data setup complete!"
echo "You can now run your tests with: npm test"
