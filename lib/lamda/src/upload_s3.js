const fs = require('fs');
const AWS = require('aws-sdk');
const bucketName = process.env.S3_BUCKET;

const s3 = new AWS.S3({
    accessKeyId: process.env.ACCESS_KEY_ID,
    secretAccessKey: process.env.SECRET_ACCESS_KEY,
});

const uploadFile = async (fileName, key) => {
  await new Promise((resolve, reject) => {
    fs.readFile(fileName, async (err, data) => {
      if (err) {
        reject(err);
      } else {
        const params = {
          Bucket: bucketName,
          Key: key,
          Body: data,
        };
        await s3.upload(params, function(s3Err, data) {
          if (s3Err) throw s3Err;
          console.log(`File uploaded successfully at ${data.Location}`);
          resolve();
        });
      }
    });
  });

  return `https://${bucketName}.s3.amazonaws.com/${key}`;
};

exports.uploadFile = uploadFile;
