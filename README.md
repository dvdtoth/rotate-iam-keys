# Rotating IAM Access keys with Lambda

This AWS Lambda function deletes Access Keys from specified IAM groups periodically.
I wrote about why this is useful here: https://medium.com/@dvdtoth/rotating-iam-access-keys-with-lambda-c86223ffb381

Read more about IAM best practices here:
https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

## Deploy the function

You have two options to deploy with: Terraform or Serverless.
You will need to set two variables, the name of the IAM groups and the schedule.

By default the trigger is set to run every Friday at 23:55.
For schedule expression check https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html

### Deploying with Terraform

Update variables in production.tfvars

```
zip revoke_keys.zip handler.js
terraform init
terraform apply -var-file="production.tfvars"
```


To remove:
```
terraform destroy -var-file="production.tfvars"
```  

### Deploying with Serverless

Update GROUPS env var and the schedule as needed in serverless.yml.

```
serverless deploy --aws-profile yourprofile
```


To remove:
```
serverless remove --aws-profile yourprofile
```