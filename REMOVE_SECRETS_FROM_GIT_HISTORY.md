# Removing Secrets from Git History

Since the MongoDB URI was exposed in the Git history, it's important to remove it completely from the repository history to ensure security.

## Warning
⚠️ **IMPORTANT**: These operations will rewrite Git history and affect all collaborators. Coordinate with your team before proceeding.

## Method 1: Using git filter-repo (Recommended)

### Install git-filter-repo
```bash
# On Windows with Git Bash
pip install git-filter-repo

# Or using package managers
# On macOS with Homebrew
brew install git-filter-repo

# On Ubuntu/Debian
sudo apt-get install python3-pip
pip3 install git-filter-repo
```

### Remove the exposed secret
```bash
cd d:\ECHAPP

# Remove the specific string from all history
git filter-repo --replace-text <(echo "mongodb+srv://hashimuimfuransa:hashimu@cluster0.qzuhv97.mongodb.net/echapp?retryWrites=true&w=majority&appName=Cluster0==>REDACTED_MONGODB_URI") --force
```

### Force push to update remote repository
```bash
git push --force-with-lease origin main
```

## Method 2: Using BFG Repo-Cleaner

### Download BFG
Download from: https://rtyley.github.io/bfg-repo-cleaner/

### Clean the repository
```bash
# Clone a fresh copy of your repo (important!)
git clone --mirror https://github.com/hashimuimfuransa/ECHAPP.git echapp-mirror
cd echapp-mirror

# Run BFG to remove the secret
java -jar bfg.jar --replace-text replacements.txt

# Replace 'replacements.txt' with a file containing:
# mongodb+srv://hashimuimfuransa:hashimu@cluster0.qzuhv97.mongodb.net/echapp?retryWrites=true&w=majority&appName=Cluster0==>REDACTED_MONGODB_URI

# Clean up and push
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force-with-lease origin main
```

## Post-Cleanup Steps

1. **Inform all team members** to re-clone the repository
2. **Update any CI/CD pipelines** that might be affected
3. **Rotate the exposed credentials** (create a new MongoDB URI)
4. **Update all environment variables** with new credentials
5. **Test all deployments** to ensure everything works correctly

## Prevention

1. **Always use .gitignore** for sensitive files like `.env`
2. **Use pre-commit hooks** to scan for secrets before committing
3. **Use secret scanning tools** like GitGuardian, TruffleHog, or GitLeaks
4. **Educate team members** about security best practices

## Pre-commit Hook Setup

Install the following to prevent future secret leaks:

```bash
# Install pre-commit
pip install pre-commit

# Install pre-commit hooks
pre-commit install

# Add to your .pre-commit-config.yaml:
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

## Rotating the MongoDB URI

After cleaning the history, be sure to:

1. Log into MongoDB Atlas
2. Change the database user password
3. Generate a new connection string
4. Update all environment configurations
5. Test the new connection thoroughly

Remember to never commit sensitive information to version control in the future!