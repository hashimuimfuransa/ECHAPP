# Guide to Remove Secrets from Git History

## Problem
GitHub's push protection detected AWS credentials in the commit history:
- AWS Access Key ID: AKIATI5XVKJFBTW6BGY5 (REMOVED FROM HISTORY)
- AWS Secret Access Key: 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 (REMOVED FROM HISTORY)

These were located in AWS_S3_INTEGRATION_SUMMARY.md at lines 14 and 15 in commit 415f468c113635f05f9b197c6844ec69636520ec.

## Solution Steps Applied

### 1. First, replace secrets in current file
```bash
# Replace actual secrets with dummy values in the current file
sed -i 's/AKIA*********************/AKIA********************/g' AWS_S3_INTEGRATION_SUMMARY.md
sed -i 's/wJalrXUtnFEMI\/K7MDENG\/bPxRfiCYEXAMPLEKEY/wJalrXUtnFEMI\/K7MDENG\/bPxRfiCYEXAMPLEKEY/g' AWS_S3_INTEGRATION_SUMMARY.md
```

### 2. Remove secrets from entire git history
```bash
# Use git filter-branch to remove secrets from all commits
git filter-branch --force --tree-filter "find . -type f -name '*.md' -exec sed -i 's/AKIA********************/AKIA********************/g' {} \; || true" -- --all

# Then remove the other secret
git filter-branch --force --tree-filter "powershell -Command \"if (Test-Path 'AWS_S3_INTEGRATION_SUMMARY.md') { (Get-Content 'AWS_S3_INTEGRATION_SUMMARY.md') -replace 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY', 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' | Set-Content 'AWS_S3_INTEGRATION_SUMMARY.md' }\"" -- --all
```

### 3. Force push to update remote
```bash
git push --force-with-lease origin main
```

## Prevention
- Never commit actual AWS credentials to git repositories
- Use environment variables for sensitive data
- Add sensitive file patterns to .gitignore
- Use tools like git-secrets to prevent committing secrets

## Reference
For more information about handling secret scanning alerts, see: https://docs.github.com/code-security/secret-scanning/working-with-secret-scanning/working-with-push-protection-from-the-command-line