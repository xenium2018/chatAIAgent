exports.handler = async (event) => {
    // Called by Lex fulfillment hook from AI Agent
    const sessionAttributes = event?.sessionAttributes || {};
    const slots = event?.currentIntent?.slots || {};

    // AI Agent passes extracted policy number either via slots or sessionAttributes
    const policyNumber =
        slots?.policyNumber ||
        sessionAttributes?.policyNumber ||
        event?.Details?.Parameters?.policyNumber;

    if (!policyNumber) {
        return lexResponse(sessionAttributes, "Failed", {
            contentType: "PlainText",
            content: "I could not find your policy number. Could you please provide it again?"
        });
    }

    const result = processPolicy(policyNumber);

    // Save policy number back to session attributes so Connect flow can read it
    return lexResponse(
        { ...sessionAttributes, policyNumber, policyStatus: result.policyStatus },
        "Fulfilled",
        {
            contentType: "PlainText",
            content: `Thank you! I found your policy. Status: ${result.policyStatus}.`
        }
    );
};

function processPolicy(policyNumber) {
    // TODO: Replace with actual DB lookup or business logic
    return { policyStatus: "Active", holder: "<customer_name>", policyNumber };
}

function lexResponse(sessionAttributes, fulfillmentState, message) {
    return {
        sessionAttributes,
        dialogAction: {
            type: "Close",
            fulfillmentState,
            message
        }
    };
}
