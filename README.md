# chatAIAgent

Chat AI Agent using Amazon Connect AI Agent + Amazon Lex V2 + AWS Lambda Action Group.

## Architecture

```
User (Chat) → Amazon Connect → Lex V2 (QnAIntent) → AI Agent → Action Group → Lambda (policy_handler)
```

## How It Works

1. User starts a chat via Amazon Connect
2. Lex V2 routes the conversation to the **AI Agent** via `AMAZON.QnAIntent`
3. The AI Agent (with a prompt) conversationally collects the policy number
4. Once collected, the AI Agent invokes the **Action Group Lambda** directly with the policy number as a parameter
5. Lambda processes the policy and returns the result to the AI Agent
6. AI Agent responds to the user with the result

## Project Structure

```
├── lambda/
│   └── policy_handler.js           # Handles AI Agent action group invocation
├── lex/
│   └── bot_definition.json         # Lex V2 bot with QnAIntent only
├── connect/
│   ├── contact_flow.json           # Amazon Connect chat flow
│   └── action_group/
│       └── api_schema.yaml         # OpenAPI schema for the AI Agent action group
```

## Setup Steps

### 1. Deploy Lambda
- Create a Lambda function named `policy_handler`.
- Upload `lambda/policy_handler.js` as the function code.
- Set runtime to **Node.js 20.x** and handler to `policy_handler.handler`.

### 2. Create Amazon Connect AI Agent
- Go to **Amazon Connect Console** → AI Agents → Create AI Agent.
- Select type: **Self-service**.
- Set the agent prompt:
  > _"You are a helpful insurance policy assistant. Ask the user for their policy number. Once provided, use the lookupPolicy action to retrieve their policy details and share the result with the user."_
- Add an **Action Group**:
  - Name: `PolicyActionGroup`
  - Lambda: `policy_handler`
  - API Schema: upload `connect/action_group/api_schema.yaml`
- Note the `<connect_ai_agent_id>`.

### 3. Create Lex V2 Bot
- Go to **Amazon Lex V2 Console** → Create bot using `lex/bot_definition.json`.
- Replace placeholders: `<account_id>`, `<region>`.
- Under the bot alias, enable **Generative AI** and link to your Connect AI Agent.
- Build and publish the bot, note the `<bot_id>` and `<alias_id>`.

### 4. Import Contact Flow
- Go to **Amazon Connect Console** → Contact Flows → Import.
- Upload `connect/contact_flow.json`.
- Replace placeholders: `<region>`, `<account_id>`, `<bot_id>`, `<alias_id>`.
- Associate the flow with your chat widget.

## Placeholders to Replace

| Placeholder       | Description                          |
|-------------------|--------------------------------------|
| `<account_id>`    | Your AWS account ID                  |
| `<region>`        | AWS region (e.g. `us-east-1`)        |
| `<bot_id>`        | Lex V2 Bot ID after creation         |
| `<alias_id>`      | Lex V2 Bot Alias ID after publishing |
| `<customer_name>` | Replace in Lambda with real DB lookup|
