# Telegram Bot Setup Guide

This document outlines the process for setting up a Telegram bot for the AI Personal Assistant project.

## Prerequisites

- Telegram account
- n8n installed and running

## Steps to Create a Telegram Bot

1. **Start a conversation with BotFather**
   - Open Telegram and search for "@BotFather"
   - Start a chat with BotFather

2. **Create a new bot**
   - Send the command `/newbot` to BotFather
   - Follow the prompts to set a name and username for your bot
   - The username must end with "bot" (e.g., "my_personal_assistant_bot")

3. **Get the API token**
   - BotFather will provide an API token (keep this secure!)
   - It will look something like `123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ`

4. **Configure bot settings (optional)**
   - Set a description: `/setdescription`
   - Set a profile picture: `/setuserpic`
   - Set commands: `/setcommands`

## Integrating with n8n

1. **Store the API token**
   - Add the token to your n8n environment variables
   - Update `~/.n8n/.env` with `TELEGRAM_BOT_TOKEN=your-token-here`

2. **Create a Telegram trigger in n8n**
   - In the n8n workflow editor, add a "Telegram Trigger" node
   - Configure it with your bot token
   - Select the events you want to trigger on (messages, commands, etc.)

3. **Set up webhook (recommended) or polling**
   - For production: Use webhook for better performance
   - For development: Polling is simpler but less efficient

### Webhook Setup (Production)

For webhook setup, your n8n instance needs to be accessible from the internet. You can use:
- A cloud-hosted n8n instance
- A reverse proxy with SSL
- A service like ngrok for development

```bash
# Example using curl to set up a webhook
curl -F "url=https://your-domain.com/webhook/telegram" https://api.telegram.org/bot<YOUR_TOKEN>/setWebhook
```

### Polling Setup (Development)

For polling, no additional setup is required. The Telegram Trigger node in n8n will poll for updates at regular intervals.

## Testing the Bot

1. **Create a simple echo workflow in n8n**
   - Add a "Telegram Trigger" node
   - Add a "Telegram" node to send a response
   - Connect them and configure the response to echo back the received message

2. **Start a conversation with your bot**
   - Find your bot on Telegram by its username
   - Send a message to test if it responds

## Bot Commands

Consider implementing these basic commands:

- `/start` - Introduction and help message
- `/help` - List available commands
- `/status` - Check if the assistant is working properly

## Security Considerations

- Keep your API token secure
- Be cautious about what data your bot has access to
- Consider implementing user authentication for sensitive operations

## Next Steps

1. Implement basic message handling
2. Add voice message processing
3. Connect to the vector database for RAG functionality
4. Develop more advanced commands and features 