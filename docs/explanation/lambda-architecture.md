# Lambda Container Image Architecture


## Overview

LambdaCron uses Docker images to back our Lambda functions. Docker-based Lambdas are easier to develop and test locally, and are actually faster to start up than zip-based Lambdas.

Since your Lambda needs to be backed by an ECR repository in your own region, we require that our lambda modules take an image URI as input. We provide modules that cover 2 approaches to having the user deploy the image into their own ECR repository:

1. `lambda-image-build`: Directly build the code. This takes a local code source and builds the Docker image, then deploys it to the user's account. This is most suitable for development and for users who want to customize the code.
2. `lambda-image-republish`: Republish a public ECR image. This simply copies a public image into the user's ECR repository. This is for users who want to use the default code, or pin to a specific and well-documented version of the image.

In order to facilitate developers creating their own tools build on LambdaCron, we also provide a `lambda-image-public` module, which builds the image and publishes it to a public ECR repository.

![AWSArchitecture-LambdaModules.drawio.svg](AWSArchitecture-LambdaModules.drawio.svg)

The two approaches are illustrated in the figure. The direct-from-source approach is on the top, and the republish approach is on the bottom. Normally, the core maintainer of the image does the first stage in the republish approach, and users can do the second stage to copy the image into their own account.
