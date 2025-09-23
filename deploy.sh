#!/bin/bash
echo "🚀 Deploying Zadostno..."

cd /home/uwuclxdy/zadostno

# Pull latest changes
git pull origin main

# Run deployment
./.git/hooks/post-merge
