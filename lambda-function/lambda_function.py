import json
import time

def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

def lambda_handler(event, context):
    start_time = time.time()
    
    # Extract the input number from the event payload
    n = event.get("number", 20)  # Default to 20 if not provided
    
    # Perform the computation
    result = fibonacci(n)
    
    end_time = time.time()
    duration = end_time - start_time
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'input': n,
            'fibonacci': result,
            'duration_seconds': duration
        })
    }
