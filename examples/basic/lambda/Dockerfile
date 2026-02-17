FROM public.ecr.aws/lambda/python:3.13

# Copy function code and runtime helpers
COPY examples/basic/lambda/lambda_module.py ${LAMBDA_TASK_ROOT}
COPY src/lambdacron ${LAMBDA_TASK_ROOT}/lambdacron

# Set the Lambda handler
CMD ["lambda_module.handler"]
