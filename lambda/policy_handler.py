import json


def lambda_handler(event, context):
    policy_number = event.get("Details", {}).get("Parameters", {}).get("policyNumber")

    if not policy_number:
        return {"status": "error", "message": "Policy number not provided"}

    # TODO: Add your policy lookup / processing logic here
    result = process_policy(policy_number)

    return {"status": "success", "policyNumber": policy_number, "result": result}


def process_policy(policy_number: str) -> dict:
    # Placeholder: replace with actual DB lookup or business logic
    return {"policyStatus": "Active", "holder": "<customer_name>", "policyNumber": policy_number}
