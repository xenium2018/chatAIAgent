const MOCK_PAYMENTS = {
    "POL-001": { status: "Paid",    amount: "$1,200.00", dueDate: "2025-06-01", lastPayment: "2025-05-01" },
    "POL-002": { status: "Pending", amount: "$850.00",   dueDate: "2025-06-15", lastPayment: "2025-04-15" },
    "POL-003": { status: "Overdue", amount: "$2,100.00", dueDate: "2025-05-01", lastPayment: "2025-03-01" },
};

exports.handler = async (event) => {
    const intentName = event.sessionState?.intent?.name;
    const slots = event.sessionState?.intent?.slots ?? {};
    const policySlot = slots.PolicyNumber?.value?.interpretedValue;

    if (intentName === "CheckPaymentStatus") {
        if (!policySlot) {
            return elicitSlot(event, "PolicyNumber", "Please provide your policy number (e.g. POL-001).");
        }

        const payment = MOCK_PAYMENTS[policySlot.toUpperCase()];
        if (!payment) {
            return elicitSlot(event, "PolicyNumber",
                `I couldn't find a policy with number ${policySlot}. Please double-check and try again.`);
        }

        const { status, amount, dueDate, lastPayment } = payment;
        const message = `Here are the payment details for policy ${policySlot.toUpperCase()}:\n` +
            `• Status: ${status}\n• Amount Due: ${amount}\n• Due Date: ${dueDate}\n• Last Payment: ${lastPayment}`;

        return close(event, message);
    }

    return close(event, "I can help you check your payment status. Please provide your policy number.");
};

function elicitSlot(event, slotName, message) {
    return {
        sessionState: {
            dialogAction: { type: "ElicitSlot", slotToElicit: slotName },
            intent: { ...event.sessionState.intent, state: "InProgress" },
            sessionAttributes: event.sessionState.sessionAttributes ?? {}
        },
        messages: [{ contentType: "PlainText", content: message }]
    };
}

function close(event, message) {
    return {
        sessionState: {
            dialogAction: { type: "Close" },
            intent: { ...event.sessionState.intent, state: "Fulfilled" },
            sessionAttributes: event.sessionState.sessionAttributes ?? {}
        },
        messages: [{ contentType: "PlainText", content: message }]
    };
}
