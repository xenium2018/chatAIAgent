#!/bin/bash
set -e

# ── CONFIG ────────────────────────────────────────────────────────────────────
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_NAME="payment_handler"
LAMBDA_ROLE_NAME="payment-handler-lambda-role"
LEX_ROLE_NAME="payment-lex-role"
BOT_NAME="PaymentStatusBot"
BOT_LOCALE="en_US"
CONNECT_INSTANCE_ID="<connect_instance_id>"   # ← Replace with your Connect instance ID
# ─────────────────────────────────────────────────────────────────────────────

echo "==> Account: $ACCOUNT_ID | Region: $REGION"

# ── 1. Lambda IAM role ────────────────────────────────────────────────────────
echo "==> Creating Lambda IAM role..."
LAMBDA_TRUST='{
  "Version":"2012-10-17",
  "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
}'
LAMBDA_ROLE_ARN=$(aws iam create-role \
  --role-name $LAMBDA_ROLE_NAME \
  --assume-role-policy-document "$LAMBDA_TRUST" \
  --query Role.Arn --output text 2>/dev/null || \
  aws iam get-role --role-name $LAMBDA_ROLE_NAME --query Role.Arn --output text)

aws iam attach-role-policy \
  --role-name $LAMBDA_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true

echo "==> Lambda Role ARN: $LAMBDA_ROLE_ARN"
sleep 10

# ── 2. Deploy Lambda ──────────────────────────────────────────────────────────
echo "==> Deploying Lambda..."
cd ../lambda
zip -q payment_handler.zip payment_handler.js

LAMBDA_ARN=$(aws lambda create-function \
  --function-name $LAMBDA_NAME \
  --runtime nodejs20.x \
  --role $LAMBDA_ROLE_ARN \
  --handler payment_handler.handler \
  --zip-file fileb://payment_handler.zip \
  --region $REGION \
  --query FunctionArn --output text 2>/dev/null || \
  aws lambda update-function-code \
    --function-name $LAMBDA_NAME \
    --zip-file fileb://payment_handler.zip \
    --region $REGION \
    --query FunctionArn --output text)

rm payment_handler.zip
echo "==> Lambda ARN: $LAMBDA_ARN"
cd ../infra

# ── 3. Lex IAM role ───────────────────────────────────────────────────────────
echo "==> Creating Lex IAM role..."
LEX_TRUST='{
  "Version":"2012-10-17",
  "Statement":[{"Effect":"Allow","Principal":{"Service":"lexv2.amazonaws.com"},"Action":"sts:AssumeRole"}]
}'
LEX_ROLE_ARN=$(aws iam create-role \
  --role-name $LEX_ROLE_NAME \
  --assume-role-policy-document "$LEX_TRUST" \
  --query Role.Arn --output text 2>/dev/null || \
  aws iam get-role --role-name $LEX_ROLE_NAME --query Role.Arn --output text)

# Allow Lex to invoke Lambda and call Bedrock
aws iam put-role-policy \
  --role-name $LEX_ROLE_NAME \
  --policy-name LexBedrockLambdaPolicy \
  --policy-document "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[
      {\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"$LAMBDA_ARN\"},
      {\"Effect\":\"Allow\",\"Action\":\"bedrock:InvokeModel\",\"Resource\":\"arn:aws:bedrock:$REGION::foundation-model/anthropic.claude-3-haiku-20240307-v1:0\"}
    ]
  }" 2>/dev/null || true

echo "==> Lex Role ARN: $LEX_ROLE_ARN"
sleep 10

# ── 4. Create Lex V2 Bot ──────────────────────────────────────────────────────
echo "==> Creating Lex V2 bot..."
BOT_ID=$(aws lexv2-models create-bot \
  --bot-name $BOT_NAME \
  --description "Payment status chatbot" \
  --role-arn $LEX_ROLE_ARN \
  --data-privacy childDirected=false \
  --idle-session-ttl-in-seconds 300 \
  --region $REGION \
  --query botId --output text 2>/dev/null || \
  aws lexv2-models list-bots --region $REGION \
    --query "botSummaries[?botName=='$BOT_NAME'].botId | [0]" --output text)

echo "==> Bot ID: $BOT_ID"

# Wait for bot to be available
aws lexv2-models wait bot-available --bot-id $BOT_ID --region $REGION

# ── 5. Create Bot Locale ──────────────────────────────────────────────────────
echo "==> Creating bot locale..."
aws lexv2-models create-bot-locale \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --nlu-intent-confidence-threshold 0.40 \
  --region $REGION 2>/dev/null || true

# ── 6. Create CheckPaymentStatus intent (no utterances yet — slot ref added after) ──
echo "==> Creating CheckPaymentStatus intent..."
INTENT_ID=$(aws lexv2-models create-intent \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --intent-name "CheckPaymentStatus" \
  --description "Check payment status by policy number" \
  --fulfillment-code-hook '{"enabled":true}' \
  --region $REGION \
  --query intentId --output text)

echo "==> Intent ID: $INTENT_ID"

# ── 7. Create slot type and PolicyNumber slot ─────────────────────────────────
echo "==> Creating PolicyNumber slot type..."
SLOT_TYPE_ID=$(aws lexv2-models create-slot-type \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --slot-type-name "PolicyNumberType" \
  --value-selection-setting '{"resolutionStrategy":"OriginalValue"}' \
  --region $REGION \
  --query slotTypeId --output text)

echo "==> Creating PolicyNumber slot..."
SLOT_ID=$(aws lexv2-models create-slot \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --intent-id $INTENT_ID \
  --slot-name "PolicyNumber" \
  --slot-type-id $SLOT_TYPE_ID \
  --value-elicitation-setting '{
    "slotConstraint":"Required",
    "promptSpecification":{
      "messageGroups":[{"message":{"plainTextMessage":{"value":"Please provide your policy number (e.g. POL-001)."}}}],
      "maxRetries":3,
      "allowInterrupt":true
    }
  }' \
  --region $REGION \
  --query slotId --output text)

echo "==> Slot ID: $SLOT_ID"

# Now update intent with sample utterances including the slot reference
echo "==> Updating intent with sample utterances..."
aws lexv2-models update-intent \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --intent-id $INTENT_ID \
  --intent-name "CheckPaymentStatus" \
  --fulfillment-code-hook '{"enabled":true}' \
  --sample-utterances '[
    {"utterance":"Check my payment status"},
    {"utterance":"What is my payment status"},
    {"utterance":"Payment status for my policy"},
    {"utterance":"I want to check my payment"},
    {"utterance":"My policy number is {PolicyNumber}"},
    {"utterance":"Look up policy {PolicyNumber}"}
  ]' \
  --region $REGION

# ── 8. Create QnAIntent (Bedrock Gen AI fallback) ─────────────────────────────
echo "==> Creating QnAIntent with Bedrock..."
aws lexv2-models create-intent \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --intent-name "FallbackIntent" \
  --parent-intent-signature "AMAZON.FallbackIntent" \
  --qn-a-intent-configuration "{
    \"dataSourceConfiguration\": {
      \"bedrockModelConfiguration\": {
        \"modelArn\": \"arn:aws:bedrock:$REGION::foundation-model/anthropic.claude-3-haiku-20240307-v1:0\",
        \"guardrailConfiguration\": {}
      }
    },
    \"bedrockModelConfiguration\": {
      \"modelArn\": \"arn:aws:bedrock:$REGION::foundation-model/anthropic.claude-3-haiku-20240307-v1:0\"
    }
  }" \
  --region $REGION 2>/dev/null || echo "==> QnAIntent skipped (may need manual setup in console)"

# ── 9. Attach Lambda to bot locale ───────────────────────────────────────────
echo "==> Attaching Lambda to bot locale..."
aws lexv2-models update-bot-locale \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --nlu-intent-confidence-threshold 0.40 \
  --code-hook-specification "{
    \"lambdaCodeHook\": {
      \"lambdaARN\": \"$LAMBDA_ARN\",
      \"codeHookInterfaceVersion\": \"1.0\"
    }
  }" \
  --region $REGION

# Allow Lex to invoke Lambda
aws lambda add-permission \
  --function-name $LAMBDA_NAME \
  --statement-id AllowLexInvoke \
  --action lambda:InvokeFunction \
  --principal lexv2.amazonaws.com \
  --source-arn "arn:aws:lex:$REGION:$ACCOUNT_ID:bot-alias/$BOT_ID/*" \
  --region $REGION 2>/dev/null || echo "==> Lambda permission already exists, skipping."

# ── 10. Build and publish bot ─────────────────────────────────────────────────
echo "==> Building bot locale..."
aws lexv2-models build-bot-locale \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --region $REGION

aws lexv2-models wait bot-locale-built \
  --bot-id $BOT_ID \
  --bot-version "DRAFT" \
  --locale-id $BOT_LOCALE \
  --region $REGION

echo "==> Creating bot version..."
BOT_VERSION=$(aws lexv2-models create-bot-version \
  --bot-id $BOT_ID \
  --bot-version-locale-specification "{\"$BOT_LOCALE\":{\"sourceBotVersion\":\"DRAFT\"}}" \
  --region $REGION \
  --query botVersion --output text)

aws lexv2-models wait bot-version-available \
  --bot-id $BOT_ID \
  --bot-version $BOT_VERSION \
  --region $REGION

echo "==> Creating bot alias..."
BOT_ALIAS_ID=$(aws lexv2-models create-bot-alias \
  --bot-id $BOT_ID \
  --bot-alias-name "live" \
  --bot-version $BOT_VERSION \
  --bot-alias-locale-settings "{\"$BOT_LOCALE\":{\"enabled\":true,\"codeHookSpecification\":{\"lambdaCodeHook\":{\"lambdaARN\":\"$LAMBDA_ARN\",\"codeHookInterfaceVersion\":\"1.0\"}}}}" \
  --region $REGION \
  --query botAliasId --output text)

echo "==> Bot Alias ID: $BOT_ALIAS_ID"

# ── 11. Associate Lex bot with Connect instance ───────────────────────────────
echo "==> Associating Lex bot with Connect instance..."
aws connect associate-lex-bot \
  --instance-id $CONNECT_INSTANCE_ID \
  --lex-bot "Name=$BOT_NAME,LexRegion=$REGION" \
  --region $REGION 2>/dev/null || true

# ── 12. Patch and output contact flow ────────────────────────────────────────
echo "==> Patching contact flow..."
BOT_ALIAS_ARN="arn:aws:lex:$REGION:$ACCOUNT_ID:bot-alias/$BOT_ID/$BOT_ALIAS_ID"
sed "s|arn:aws:lex:us-east-1:<account_id>:bot-alias/<bot_id>/<bot_alias_id>|$BOT_ALIAS_ARN|g" \
  ../connect/contact_flow.json > /tmp/contact_flow_final.json

echo ""
echo "✅ Deployment complete!"
echo ""
echo "  Lambda ARN    : $LAMBDA_ARN"
echo "  Bot ID        : $BOT_ID"
echo "  Bot Alias ARN : $BOT_ALIAS_ARN"
echo ""
echo "Next steps:"
echo "  1. Enable Claude 3 Haiku in Bedrock Console → Model access (us-east-1)"
echo "  2. Connect Console → Contact Flows → Import → /tmp/contact_flow_final.json"
echo "  3. Associate the flow with your chat widget"
