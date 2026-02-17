from lambdacron.lambda_task import CronLambdaTask


class ExampleTask(CronLambdaTask):
    def _perform_task(self, event, context):
        return {"example": {"message": "Hello World"}}


task = ExampleTask()


def handler(event, context):
    task.lambda_handler(event, context)
