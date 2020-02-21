# Crawler using AWS Lambda and Puppeteer

## Development

- Require
  - Nodejs
  - Chrome browser

- Local development

```bash
npm run local
```

- Bundle package

```bash
npm run package
```

## AWS Setting

### Other components

### Prepare S3 bucket

- As usual

### DynamoDB

- Create table
- Use 1 key only and named `key`

### Lambda

- Add AWS Lambda function
- Add role to the function
  - AmazonElastiCacheFullAccess
  - AWSLambdaVPCAccessExecutionRole

- Setting environment variables

```bash
ACCESS_KEY_ID=
SECRET_ACCESS_KEY=
S3_BUCKET=
DYNAMO_DB_REGION=
DYNAMO_DB_TABLE=
```

- Upload package.zip to S3
  - Example: `https://apollon-53624.s3-ap-northeast-1.amazonaws.com/package.zip`
  - Choose Runtime: Node.js 8.10
  - Then "Save"
  - Run "Test" to test the function
