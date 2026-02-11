import re

def replace_secrets(blob_data):
    content = blob_data.decode('utf-8', errors='ignore')
    content = re.sub(r'[A-Z0-9]{20}', 'REDACTED_AWS_ACCESS_KEY', content)
    content = re.sub(r'[A-Za-z0-9/+]{40}', 'REDACTED_AWS_SECRET_KEY', content)
    content = re.sub(r'gsk_[a-zA-Z0-9_-]{50}', 'REDACTED_GROQ_API_KEY', content)
    return content.encode('utf-8')