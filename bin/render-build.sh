#!/usr/bin/env bash
# exit on error
set -o errexit

# Install gems
echo "Installing Gems..."
bundle install

# === ここにDBマイグレーションを追加 ===
echo "Running Migrations..."
bundle exec rails db:migrate 
# ==================================

# Assets precompile
echo "Precompiling Assets..."
bundle exec rails assets:precompile