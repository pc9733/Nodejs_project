#!/bin/bash
# =================================================================
# APPLY ALL ENVIRONMENTS
# Creates or updates both dev and prod environments
# =================================================================

set -e

echo "🚀 Applying All Environments..."

# Safety check for production
echo "⚠️  WARNING: This will apply changes to BOTH environments including PRODUCTION!"
echo "🔒 Type 'apply-all' to confirm:"
read -r confirmation
if [ "$confirmation" != "apply-all" ]; then
    echo "❌ Apply cancelled. Confirmation not provided."
    exit 1
fi

# Apply development environment
echo "🚀 Applying Development Environment..."
if [ -f "apply-dev.sh" ]; then
    ./apply-dev.sh
else
    echo "⚠️  Development apply script not found, skipping..."
fi

# Apply production environment
echo "🚀 Applying Production Environment..."
if [ -f "apply-prod.sh" ]; then
    ./apply-prod.sh
else
    echo "⚠️  Production apply script not found, skipping..."
fi

echo "✅ All environments applied successfully!"
echo ""
echo "Next steps:"
echo "1. Deploy to dev: Trigger deploy-dev.yml workflow"
echo "2. Deploy to prod: Trigger deploy-prod.yml workflow with approval"
