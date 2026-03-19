# chatAIAgent

Chat AI Agent using Amazon Connect AI Agent + AWS Lambda.

## Architecture

```
User (Chat) → Amazon Connect → AI Agent (collects policy number) → contact attribute → Lambda
```

## How It Works

1. User starts a chat via Amazon Connect
2. **Connect AI Agent** conversationally collects the policy number
3. AI Agent stores the policy number as a contact attribute
4. Lambda is invoked with the policy number for further processing

## Project Structure

```
├── lambda/
│   └── policy_handler.js       # Processes the policy number (Node.js 20.x)
├── connect/
│   ├── contact_flow.json       # Amazon Connect chat flow
│   └── action_group/
│       └── api_schema.yaml     # OpenAPI schema for the AI Agent action group
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
  > _"You are a helpful insurance policy assistant. Ask the user for their policy number. Once provided, save it as a contact attribute named policyNumber."_
- Note the `<connect_ai_agent_id>`.

### 3. Import Contact Flow
- Go to **Amazon Connect Console** → Contact Flows → Import.
- Upload `connect/contact_flow.json`.
- Replace placeholders: `<region>`, `<account_id>`, `<connect_ai_agent_id>`.
- Associate the flow with your chat widget.

## Placeholders to Replace

| Placeholder             | Description                          |
|-------------------------|--------------------------------------|
| `<account_id>`          | Your AWS account ID                  |
| `<region>`              | AWS region (e.g. `us-east-1`)        |
| `<connect_ai_agent_id>` | Amazon Connect AI Agent ID           |
| `<customer_name>`       | Replace in Lambda with real DB lookup|
