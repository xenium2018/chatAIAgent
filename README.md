# chatAIAgent

Chat AI Agent using Amazon Connect + Amazon Lex V2 (AI Agent) + AWS Lambda.

## Architecture

```
User (Chat) → Amazon Connect → Lex V2 AI Agent → Collects Policy Number → Lambda (policy_handler)
```

## Project Structure

```
├── lambda/
│   └── policy_handler.js       # Processes the policy number
├── lex/
│   └── bot_definition.json     # Lex V2 bot with CapturePolicyNumber intent + FallbackIntent (AI Agent)
├── connect/
│   └── contact_flow.json       # Amazon Connect contact flow
```

## Setup Steps

### 1. Deploy Lambda
- Create a Lambda function named `policy_handler` in your AWS account.
- Upload `lambda/policy_handler.js` as the function code.
- Set the runtime to **Node.js 20.x** and handler to `policy_handler.handler`.
- Add the Lambda ARN to `lex/bot_definition.json` and `connect/contact_flow.json`.

### 2. Create Lex V2 Bot
- Go to **Amazon Lex V2 Console** → Create bot using `lex/bot_definition.json`.
- Replace placeholders: `<account_id>`, `<region>`.
- Enable **Generative AI** on the bot alias for the AI agent capability.
- Build and publish the bot, note the `<bot_id>` and `<alias_id>`.

### 3. Import Contact Flow
- Go to **Amazon Connect Console** → Contact Flows → Import.
- Upload `connect/contact_flow.json`.
- Replace placeholders: `<region>`, `<account_id>`, `<bot_id>`, `<alias_id>`.
- Associate the flow with your chat widget.

## Placeholders to Replace

| Placeholder     | Description                          |
|-----------------|--------------------------------------|
| `<account_id>`  | Your AWS account ID                  |
| `<region>`      | AWS region (e.g. `us-east-1`)        |
| `<bot_id>`      | Lex V2 Bot ID after creation         |
| `<alias_id>`    | Lex V2 Bot Alias ID after publishing |
| `<customer_name>` | Replace in Lambda with real DB lookup |
