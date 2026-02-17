# Architecture

## Overview
- Scheduled Lambda runs on EventBridge
- Results published to a shared SNS topic
- Notification modules subscribe via filter policies

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
