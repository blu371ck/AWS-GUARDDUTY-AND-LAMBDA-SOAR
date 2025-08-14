import json
import logging
from typing import Any, Dict

from aws_reflex.ec2 import get_ec2_handler

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event: Dict[str, Any], context: object) -> Dict[str, Any]:
    """
    Lambda handler triggered by a GuardDuty finding from Amazon EventBridge.

    This function receives the GuardDuty finding, passes it to the aws-reflex
    library's factory to get the correct handler, and then executes the
    automated response.

    Args:
        event: The EventBridge event containing the GuardDuty finding.
        context: The Lambda runtime context object.

    Returns:
        A dictionary with a status code and a message.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # The actual GuardDuty finding is nested inside the EventBridge event's 'detail' key.
        finding = event.get("detail")
        if not finding:
            logger.warning("Event did not contain a 'detail' key with finding information.")
            return {"statusCode": 200, "body": json.dumps("No finding found in event.")}

        # Use the factory from our layer to get the correct handler for this finding type.
        handler_instance = get_ec2_handler(finding)

        if handler_instance:
            # If a handler was found, execute its automated response logic.
            logger.info(f"Executing handler '{type(handler_instance).__name__}' for finding type '{finding.get('type')}'.")
            handler_instance.execute()
        else:
            # If no handler is configured for this finding type, log it and exit gracefully.
            logger.info(f"No handler configured for finding type '{finding.get('type')}'. Ignoring.")

        return {"statusCode": 200, "body": json.dumps("Processing complete.")}

    except Exception as e:
        logger.error(f"An unhandled error occurred during handler execution: {e}", exc_info=True)
        # Re-raise the exception to allow Lambda to handle retries if they are configured
        # and to mark the invocation as failed.
        raise