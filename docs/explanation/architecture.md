# Architecture

## Overview
- Scheduled Lambda runs on EventBridge
- Results published to a shared SNS topic
- Notification modules subscribe via filter policies

The basic idea is that we have a scheduled lambda function (triggered by EventBridge events) that performs some tasks and publishes results to a shared SNS topic. Then we have notification modules that subscribe to this SNS topic with filter policies to receive only the relevant messages. This allows us to decouple the task execution from the notification handling and makes it easier to add new notification modules in the future without changing the core logic of the scheduled lambda.

![Architecture Diagram](AWSArchitecture-ConceptualArchitecture.drawio.svg)

## Modules
- Scheduled Lambda module
- SNS topic and subscriptions
- SQS FIFO queues for dedup
- Notification handler lambdas

![Module-based architecture diagram](AWSArchitecture-ModuleArchitecture.drawio.svg)

## Data Flow
- Task execution
- SNS publish with `result_type`
- SNS -> SQS -> Lambda
