# S3 Bucket Configuration Guide

## Issue: "The bucket does not allow ACLs" Error and 403 Forbidden Error

If you encounter the error "The bucket does not allow ACLs" when uploading images or "HTTP request failed, statusCode: 403" when loading images, it means your S3 bucket is configured with "Block Public Access" settings that prevent public access to uploaded files.

## Solution

Since we've removed the ACL from the upload code, you need to configure your S3 bucket properly for public access:

### 1. Enable Public Access for Your S3 Bucket

1. Go to your AWS S3 Console
2. Select your bucket (`echcoahing` in this case)
3. Go to the "Permissions" tab
4. Edit the "Block Public Access" settings
5. Uncheck ALL four options:
   - Block new public ACLs
   - Block public and cross-account ACLs  
   - Block public bucket policies
   - Block cross-account bucket policies
6. Save the changes (you'll need to confirm this action)

### 2. Add a Bucket Policy for Public Read Access

In the "Permissions" tab, add the following bucket policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::echcoahing/*"
        }
    ]
}
```

Replace `echcoahing` with your actual bucket name.

### 3. CORS Configuration (Critical for Mobile Apps)

In the "Permissions" tab, also configure CORS (Cross-Origin Resource Sharing):

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "HEAD"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"]
    }
]
```

### 4. Enable Static Website Hosting (Optional but Recommended)

1. In your bucket, go to the "Properties" tab
2. Scroll down to "Static website hosting"
3. Enable it and set both index document and error document to a placeholder like `index.html`

## Why This Change Was Necessary

Modern S3 buckets created after September 2022 default to blocking ACLs and restricting public access. The previous code used `ACL: 'public-read'` which is no longer compatible with these newer bucket configurations. The new approach relies on bucket policies for public access control instead of object-level ACLs.

## Verification

After making these changes:
1. Restart your backend server
2. Wait 5-10 minutes for AWS policy changes to propagate
3. Try uploading a new image
4. The image should now load without 403 Forbidden errors