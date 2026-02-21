# Architecture

## Overview

The basic idea is that we have a scheduled lambda function (triggered by EventBridge events) that performs some tasks and publishes results to a shared SNS topic. Then we have notification modules that subscribe to this SNS topic with filter policies to receive only the relevant messages. This allows us to decouple the task execution from the notification handling and makes it easier to add new notification modules in the future without changing the core logic of the scheduled lambda.

![Architecture Diagram](AWSArchitecture-ConceptualArchitecture.drawio.svg)

The overall data flow is that an EventBridge event triggers the scheduled lambda. That scheduled lambda executes its tasks and then publishes results to the SNS topic.The results are a JSON object where the keys represent the type of result (e.g., "success", "failure", "warning") and the values contain additional information that can be useful for notifying the end user. The SQS FIFO queues subscribe to specific notification types based on filter policies, so a given queue might, for example, only receive messages where `result_type` is "failure". The notification handler lambdas are then triggered by messages in the SQS queues, and use Jinja templates to format the notifications before sending them to the end user (e.g., via email).

## Modules

When we decompose the architecture into Terraform modules, the architecture splits differently from the conceptual architecture. The message broker splits into some components being associated with the notification lambdas (the SQS queues) and some parts being associated with the core functionality (the SNS topic).

![Module-based architecture diagram](AWSArchitecture-ModuleArchitecture.drawio.svg)

We provide a `scheduled-lambda` module that handles everything about the EventBridge rules and the Lambda function that performs the scheduled tasks. You'll need to provide a Docker image for the Lambda function, which will do the actual business logic.

The root module wraps the `scheduled-lambda` module with an SNS topic, and handles the wiring of that.

Notification modules are separate, and when you deploy, you'll need to include your own notification modules: the root module does not contain any default notifications. Each notification module manages the SQS queue and the Lambda function to handle messages, as well as the subscription to the SNS topic with the appropriate filter policy. There's a core `notification-plumbing` module, and individual modules for different notification types (e.g., email via SES), are wrappers around that core module, exposing the correct parameters to configure the specific notification type.



## Notification Templates

One of the big ideas of LambdaCron is that the notifications use Jinja templates to format the messages sent to the end user. This allows for a lot of flexibility in how the notifications are presented, and makes it easy to include dynamic content based on the results of the scheduled tasks.

The key thing is that the template must correspond to the structure of the JSON object published to the SNS topic. This is how we can insert a message broker that knows nothing about the specific use case of the scheduled lambda: it just gives us a message (as a JSON object) and then it tells us how to format that message using the Jinja template.
