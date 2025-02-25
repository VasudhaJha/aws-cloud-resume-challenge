# The Cloud Resume Challenge - AWS (My Way)

## Overview

This repository contains my implementation of the Cloud Resume Challenge - AWS, tailored to my learning style and goals.

Instead of following the traditional approach of using the AWS Management Console, and then using **IaC, source control** and **CI/CD pipelines** in the final steps, as listed in the challenge, I focused on automating the process using modern DevOps practices from the start.

Here,

- All AWS resources are provisioned using Terraform.

- GitHub Actions automate the deployment process for both the frontend and backend.

## What This Project Does

This project hosts a personal resume website on AWS with:

- **A frontend**: A static website showcasing the resume, hosted on an S3 bucket and distributed via CloudFront.

- **A backend**: An API built using API Gateway and Lambda that interacts with a DynamoDB table to track and display visitor counts.

## Project goals

- Get hands-on experience with AWS services like S3, CloudFront, API Gateway, Lambda, and DynamoDB.

- Apply DevOps best practices.

## Key Features

### 1. Terraform Configuration

#### Resources Provisioned

-  S3 bucket for static website hosting.

- CloudFront for content delivery.

- DynamoDB table for visitor count storage.

- API Gateway and Lambda function for backend.

### 2. Frontend Deployment

- Static files (HTML, CSS, JS) are hosted in an S3 bucket.

- CloudFront distribution ensures fast delivery.

- CI/CD pipeline updates the S3 bucket and invalidates the CloudFront cache on code changes.

### 3. Backend Deployment

- Python Lambda function tracks visitor counts and updates DynamoDB.

- CI/CD pipeline runs Python tests, packages the code, and deploys it to AWS.

### 4. CI/CD Pipelines

1. Terraform Pipeline: Validates, formats, and applies infrastructure changes.

2. Frontend Pipeline: Deploys website updates to S3 and clears CloudFront cache.

3. Backend Pipeline: Tests and deploys Python Lambda code.

## Challenges Faced

## Lessons Learned

