#!/bin/bash
# =================================================================
# DESTROY ALL ENVIRONMENTS
# Destroys both dev and prod environments
# =================================================================

set -e

echo "🔥 Destroying All Environments..."

# Safety check
echo "⚠️  WARNING: This will destroy BOTH development and production environments!"
echo "🔒 Type 'destroy-all' to confirm:"
read -r confirmation
if [ "$confirmation" != "destroy-all" ]; then
    echo "❌ Destruction cancelled. Confirmation not provided."
    exit 1
fi

# Destroy development environment
echo "🔥 Destroying Development Environment..."
if [ -f "destroy-dev.sh" ]; then
    ./destroy-dev.sh
else
    echo "⚠️  Development destroy script not found, skipping..."
fi

# Destroy production environment
echo "🔥 Destroying Production Environment..."
if [ -f "destroy-prod.sh" ]; then
    ./destroy-prod.sh
else
    echo "⚠️  Production destroy script not found, skipping..."
fi

echo "✅ All environments destroyed successfully!"
