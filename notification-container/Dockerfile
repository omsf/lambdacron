FROM public.ecr.aws/lambda/python:3.13

COPY notification-container/requirements.txt ${LAMBDA_TASK_ROOT}/requirements.txt
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

COPY notification-container/lambda.py ${LAMBDA_TASK_ROOT}
COPY src/lambdacron ${LAMBDA_TASK_ROOT}/lambdacron

CMD ["lambda.print_handler"]
