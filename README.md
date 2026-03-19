# chatAIAgent — Payment Status Chatbot

Gen AI chatbot for payment status using **Amazon Lex V2 + Bedrock (Claude 3 Haiku) + Amazon Connect**.

## Architecture

```
User (Chat) → Amazon Connect → Lex V2 Bot → Lambda (payment lookup)
                                    ↓
                          Bedrock Claude 3 Haiku (QnAIntent / fallback)
```

## How It Works

1. User starts a chat via Amazon Connect
2. Connect routes to the Lex V2 bot via `GetParticipantInput` block
3. Lex detects `CheckPaymentStatus` intent and collects the policy number slot
4. Lambda fulfillment looks up payment data and returns a natural language response
5. For unrecognised inputs, Lex falls back to Bedrock Claude 3 Haiku (QnAIntent)

## Project Structure

```
├── lambda/
│   └── payment_handler.js              # Lex V2 fulfillment Lambda (Node.js 20.x)
├── connect/
│   ├── contact_flow.json               # Amazon Connect chat flow (GetParticipantInput → Lex)
│   ├── ai_agent_prompt.txt             # Bedrock system prompt (QnAIntent)
│   └── lex_bot.json                    # Lex bot definition reference
├── infra/
│   └── deploy.sh                       # AWS CLI deployment script
```

## Deployment

### Prerequisites
- AWS CLI configured with sufficient permissions
- Amazon Connect instance already created
- Bedrock model access enabled for `anthropic.claude-3-haiku-20240307-v1:0` in `us-east-1`
- `zip` and `python3` available in your shell

### Steps

```bash
# 1. Enable Claude 3 Haiku in AWS Console
#    Bedrock → Model access → Request access → Claude 3 Haiku

# 2. Set your Connect instance ID in infra/deploy.sh
#    Replace: CONNECT_INSTANCE_ID="<connect_instance_id>"

# 3. Run the deploy script
cd infra
bash deploy.sh

# 4. Import the generated contact flow
#    Connect Console → Contact Flows → Import → /tmp/contact_flow_final.json

# 5. Associate the flow with your chat widget
```

## Mock Payment Data

| Policy Number | Status  | Amount    | Due Date   | Last Payment |
|---------------|---------|-----------|------------|--------------|
| POL-001       | Paid    | $1,200.00 | 2025-06-01 | 2025-05-01   |
| POL-002       | Pending | $850.00   | 2025-06-15 | 2025-04-15   |
| POL-003       | Overdue | $2,100.00 | 2025-05-01 | 2025-03-01   |

## Placeholders to Replace

| Placeholder              | Where             | Description                     |
|--------------------------|-------------------|---------------------------------|
| `<connect_instance_id>`  | `infra/deploy.sh` | Your Amazon Connect instance ID |
