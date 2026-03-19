exports.handler = async (event) => {
    console.log("Event:", JSON.stringify(event, null, 2));

    const actionGroup = event?.actionGroup;
    const apiPath = event?.apiPath;
    const parameters = event?.parameters || [];

    // Extract policyNumber from action group parameters
    const policyNumberParam = parameters.find(p => p.name === "policyNumber");
    const policyNumber = policyNumberParam?.value;

    if (!policyNumber) {
        return actionGroupResponse(actionGroup, apiPath, 400, {
            message: "Policy number not provided"
        });
    }

    const result = processPolicy(policyNumber);

    return actionGroupResponse(actionGroup, apiPath, 200, result);
};

function processPolicy(policyNumber) {
    // TODO: Replace with actual DB lookup or business logic
    return {
        policyNumber,
        policyStatus: "Active",
        holder: "<customer_name>"
    };
}

function actionGroupResponse(actionGroup, apiPath, statusCode, body) {
    return {
        actionGroup,
        apiPath,
        httpStatusCode: statusCode,
        responseBody: {
            "application/json": {
                body: JSON.stringify(body)
            }
        }
    };
}
