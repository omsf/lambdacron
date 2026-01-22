FROM public.ecr.aws/lambda/python:3.13

RUN pip install --no-cache-dir jinja2

# Copy function code and runtime helpers
COPY examples/basic/print-notifier/handler.py ${LAMBDA_TASK_ROOT}
COPY src/cloud_cron ${LAMBDA_TASK_ROOT}/cloud_cron

# Set the Lambda handler
CMD ["handler.handler"]
