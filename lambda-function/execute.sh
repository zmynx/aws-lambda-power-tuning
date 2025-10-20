#!/bin/bash
# config

set -euox pipefail

if [[ $# -gt 1 ]]
then
    echo "Incorrect Usage: $0 [input json file path]"
    exit 1
fi

STACK_NAME=powerTuning
INPUT=$(cat "${1:-sample-execution-input.json}")  # or use a static string

PROFILE="aws-saas-platform-ai-dev"
REGION="us-east-1"

# retrieve state machine ARN
STATE_MACHINE_ARN=$(aws stepfunctions list-state-machines \
    --query "stateMachines[?contains(name,\`${STACK_NAME}\`)]|[0].stateMachineArn" \
    --output text \
    --profile $PROFILE \
    --region $REGION \
    | cat)

# start execution
EXECUTION_ARN=$(aws stepfunctions start-execution \
    --state-machine-arn $STATE_MACHINE_ARN \
    --input "$INPUT" \
    --query 'executionArn' \
    --output text\
    --profile $PROFILE \
    --region $REGION)

echo -n "Execution started..."

# poll execution status until completed
while true;
do
    # retrieve execution status
    STATUS=$(aws stepfunctions describe-execution \
        --execution-arn $EXECUTION_ARN \
        --query 'status' \
        --output text \
        --profile $PROFILE \
        --region $REGION)

    if test "$STATUS" == "RUNNING"; then
        # keep looping and wait if still running
        echo -n "."
        sleep 1
    elif test "$STATUS" == "FAILED"; then
        # exit if failed
        echo -e "\nThe execution failed, you can check the execution logs with the following script:\naws stepfunctions get-execution-history --execution-arn $EXECUTION_ARN"
        break
    else
        # print execution output if succeeded
        echo $STATUS
        echo "Execution output: "
        # retrieve output
        aws stepfunctions describe-execution \
            --execution-arn $EXECUTION_ARN \
            --query 'output' \
            --output text \
            --profile $PROFILE \
            --region $REGION \
            | cat
        break
    fi
done
