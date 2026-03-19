exports.handler = async (event) => {
    // AI Agent stores extracted entities in sessionAttributes
    const policyNumber =
        event?.sessionAttributes?.policyNumber ||
        event?.Details?.Parameters?.policyNumber;

    if (!policyNumber) {
        return { status: "error", message: "Policy number not provided" };
    }

    const result = processPolicy(policyNumber);

    return { status: "success", policyNumber, result };
};

function processPolicy(policyNumber) {
    // TODO: Replace with actual DB lookup or business logic
    return { policyStatus: "Active", holder: "<customer_name>", policyNumber };
}
