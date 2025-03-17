#!/bin/bash
# Telegram Bot Setup Script
# This script helps set up a Telegram bot for the AI Personal Assistant project

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Telegram Bot Setup${NC}"
echo "This script will help you set up a Telegram bot for your AI Personal Assistant."
echo ""

# Check if .env file exists
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    touch "$ENV_FILE"
fi

# Check if TELEGRAM_BOT_TOKEN is already set
if grep -q "TELEGRAM_BOT_TOKEN" "$ENV_FILE"; then
    echo -e "${YELLOW}Telegram bot token already exists in .env file.${NC}"
    read -p "Do you want to replace it? (y/n): " replace_token
    if [[ "$replace_token" != "y" && "$replace_token" != "Y" ]]; then
        echo "Keeping existing token."
        exit 0
    fi
fi

# Instructions for creating a bot
echo -e "${GREEN}Instructions to create a Telegram bot:${NC}"
echo "1. Open Telegram and search for @BotFather"
echo "2. Start a chat with BotFather"
echo "3. Send the command /newbot"
echo "4. Follow the prompts to set a name and username for your bot"
echo "5. BotFather will provide an API token (keep this secure!)"
echo ""

# Get the token from user
read -p "Enter your Telegram bot token: " bot_token

if [[ -z "$bot_token" ]]; then
    echo -e "${RED}Error: Bot token cannot be empty.${NC}"
    exit 1
fi

# Validate token format (simple check)
if [[ ! "$bot_token" =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${YELLOW}Warning: The token format doesn't look right. It should be something like '123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ'${NC}"
    read -p "Continue anyway? (y/n): " continue_anyway
    if [[ "$continue_anyway" != "y" && "$continue_anyway" != "Y" ]]; then
        echo "Exiting."
        exit 1
    fi
fi

# Save token to .env file
if grep -q "TELEGRAM_BOT_TOKEN" "$ENV_FILE"; then
    # Replace existing token
    sed -i.bak "s/TELEGRAM_BOT_TOKEN=.*/TELEGRAM_BOT_TOKEN=$bot_token/" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
else
    # Add new token
    echo "" >> "$ENV_FILE"
    echo "# Telegram Bot Configuration" >> "$ENV_FILE"
    echo "TELEGRAM_BOT_TOKEN=$bot_token" >> "$ENV_FILE"
fi

echo -e "${GREEN}Telegram bot token saved to .env file.${NC}"

# Copy to n8n environment
N8N_ENV_FILE="$HOME/.n8n/.env"
if [ -f "$N8N_ENV_FILE" ]; then
    if grep -q "TELEGRAM_BOT_TOKEN" "$N8N_ENV_FILE"; then
        # Replace existing token
        sed -i.bak "s/TELEGRAM_BOT_TOKEN=.*/TELEGRAM_BOT_TOKEN=$bot_token/" "$N8N_ENV_FILE"
        rm -f "$N8N_ENV_FILE.bak"
    else
        # Add new token
        echo "" >> "$N8N_ENV_FILE"
        echo "# Telegram Bot Configuration" >> "$N8N_ENV_FILE"
        echo "TELEGRAM_BOT_TOKEN=$bot_token" >> "$N8N_ENV_FILE"
    fi
    echo -e "${GREEN}Telegram bot token also saved to n8n environment file.${NC}"
else
    echo -e "${YELLOW}n8n environment file not found at $N8N_ENV_FILE${NC}"
    echo "You'll need to manually add the token to your n8n environment."
fi

# Test the bot token
echo -e "${GREEN}Testing the bot token...${NC}"
response=$(curl -s "https://api.telegram.org/bot$bot_token/getMe")

if [[ "$response" == *"\"ok\":true"* ]]; then
    bot_username=$(echo "$response" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}Success! Bot @$bot_username is working.${NC}"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Start a chat with your bot: https://t.me/$bot_username"
    echo "2. Create an n8n workflow with a Telegram trigger node"
    echo "3. Configure the Telegram trigger node with your bot token"
    echo ""
    echo "For more information, see the Telegram bot setup guide in the documentation."
else
    error_description=$(echo "$response" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
    echo -e "${RED}Error: Could not connect to the bot. Response: $error_description${NC}"
    echo "Please check your token and try again."
fi 