# chatAIAgent

Chat AI Agent using Amazon Connect AI Agent + Amazon Lex V2 + AWS Lambda.

## Architecture

```
User (Chat) → Amazon Connect → AI Agent (Bedrock) → Lex V2 (CapturePolicyNumber) → Lambda (policy_handler)
```

## How It Works

1. User starts a chat via Amazon Connect
2. The **Amazon Connect AI Agent** (powered by Amazon Bedrock) handles the conversation naturally
3. Once the user provides their policy number, the **Lex V2 CapturePolicyNumber intent** captures it
4. The policy number is stored as a contact attribute and passed to **Lambda** for processing

## Project Structure

```
├── lambda/
│   └── policy_handler.js       # Processes the policy number (Node.js 20.x)
├── lex/
│   └── bot_definition.json     # Lex V2 bot with AI Agent config + CapturePolicyNumber intent
├── connect/
│   └── contact_flow.json       # Amazon Connect contact flow with AI Agent block
```

## Setup Steps

### 1. Create Amazon Bedrock Agent
- Go to **Amazon Bedrock Console** → Agents → Create Agent.
- Give it instructions: _"You are a helpful insurance policy assistant. Collect the customer's policy number and confirm it."_
- Create an alias and note the `<bedrock_agent_id>` and `<bedrock_agent_alias_id>`.

### 2. Create Amazon Connect AI Agent
- Go to **Amazon Connect Console** → AI Agents → Create AI Agent.
- Select type: **Self-service**.
- Link it to your Bedrock Agent.
- Note the `<connect_ai_agent_id>`.

### 3. Deploy Lambda
- Create a Lambda function named `policy_handler`.
- Upload `lambda/policy_handler.js` as the function code.
- Set runtime to **Node.js 20.x** and handler to `policy_handler.handler`.

### 4. Create Lex V2 Bot
- Go to **Amazon Lex V2 Console** → Create bot using `lex/bot_definition.json`.
- Replace placeholders: `<account_id>`, `<region>`, `<bedrock_agent_id>`, `<bedrock_agent_alias_id>`.
- Build and publish the bot, note the `<bot_id>` and `<alias_id>`.

### 5. Import Contact Flow
- Go to **Amazon Connect Console** → Contact Flows → Import.
- Upload `connect/contact_flow.json`.
- Replace all placeholders (see table below).
- Associate the flow with your chat widget.

## Placeholders to Replace

| Placeholder                  | Description                              |
|------------------------------|------------------------------------------|
| `<account_id>`               | Your AWS account ID                      |
| `<region>`                   | AWS region (e.g. `us-east-1`)            |
| `<bot_id>`                   | Lex V2 Bot ID after creation             |
| `<alias_id>`                 | Lex V2 Bot Alias ID after publishing     |
| `<bedrock_agent_id>`         | Amazon Bedrock Agent ID                  |
| `<bedrock_agent_alias_id>`   | Amazon Bedrock Agent Alias ID            |
| `<connect_ai_agent_id>`      | Amazon Connect AI Agent ID               |
| `<customer_name>`            | Replace in Lambda with real DB lookup    |
