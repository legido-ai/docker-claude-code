# GitHub App Setup Guide

## Overview

This guide provides step-by-step instructions for creating a GitHub App with minimal permissions for task management in the `legido-ai/tasks` repository. The app is designed to work with automated agents like Claudia for task automation while adhering to the principle of least privilege.

## Table of Contents

- [Security Principles](#security-principles)
- [Required Permissions](#required-permissions)
- [Step-by-Step Setup](#step-by-step-setup)
- [Installation Process](#installation-process)
- [Configuration with MCP](#configuration-with-mcp)
- [Testing and Verification](#testing-and-verification)
- [Troubleshooting](#troubleshooting)

## Security Principles

This GitHub App follows the **principle of least privilege**:

- ✅ **Minimal Permissions**: Only the permissions required for task management
- ✅ **Read/Write Access**: Limited to Issues, Contents, and Pull Requests
- ❌ **NO Administration**: Explicitly excludes repository deletion and administration capabilities
- ❌ **NO Repository Deletion**: Cannot delete or archive repositories
- ✅ **Single Repository**: Scoped to `legido-ai/tasks` only

## Required Permissions

The following permissions are required for task management operations:

### Repository Permissions

| Permission | Access Level | Purpose | Security Notes |
|------------|--------------|---------|----------------|
| **Contents** | Read & Write | Access repository files, commits, branches | Required for PR operations |
| **Issues** | Read & Write | Create, edit, close issues and comments | Core task management |
| **Pull Requests** | Read & Write | Create, edit, merge pull requests | Code review automation |
| **Metadata** | Read | Access repository metadata | Automatically granted |

### Permissions to AVOID

| Permission | Why Avoid |
|------------|-----------|
| **Administration** | Grants repository deletion and dangerous management operations |
| **Secrets** | Not needed for task management |
| **Workflows** | Not required unless automating GitHub Actions |
| **Environments** | Not needed for basic task operations |

## Step-by-Step Setup

### Step 1: Navigate to GitHub App Settings

1. Go to your GitHub organization or personal account
2. Click on **Settings**
3. In the left sidebar, click **Developer settings**
4. Click **GitHub Apps**
5. Click **New GitHub App**

**URL**: `https://github.com/organizations/legido-ai/settings/apps/new`
(Replace `legido-ai` with your organization name)

### Step 2: Configure Basic Information

Fill in the following fields:

| Field | Value | Notes |
|-------|-------|-------|
| **GitHub App name** | `legido-ai-task-manager` | Must be unique across GitHub |
| **Homepage URL** | `https://github.com/legido-ai/tasks` | Repository URL |
| **Webhook Active** | ❌ Unchecked | Not needed for MCP integration |

### Step 3: Set Repository Permissions

Scroll down to **Repository permissions** and configure:

1. **Contents**: Select `Read & write` from dropdown
   - Allows reading files and creating commits
   - Required for pull request operations

2. **Issues**: Select `Read & write` from dropdown
   - Allows creating, editing, and closing issues
   - Allows adding comments and labels

3. **Pull requests**: Select `Read & write` from dropdown
   - Allows creating and managing pull requests
   - Allows requesting reviews and merging

4. **Metadata**: Automatically set to `Read` (mandatory)
   - Required for all apps
   - Provides basic repository information

### Step 4: Verify NO Dangerous Permissions

**CRITICAL**: Ensure the following are NOT selected or are set to `No access`:

- ❌ **Administration**: Must be `No access`
- ❌ **Secrets**: Must be `No access`
- ❌ **Security events**: Not required
- ❌ **Deployments**: Not required

### Step 5: User Permissions

Set all **User permissions** to `No access` (not needed for repository tasks)

### Step 6: Subscribe to Events (Optional)

If you want webhook notifications:

- ✅ Issues
- ✅ Pull request
- ✅ Issue comment

For MCP integration, webhooks are **not required**.

### Step 7: Configure Installation Settings

Under **Where can this GitHub App be installed?**

- Select: ✅ **Only on this account**

This restricts installation to your organization only.

### Step 8: Create the App

1. Review all settings
2. Click **Create GitHub App**
3. You'll be redirected to your app's settings page

### Step 9: Generate Private Key

1. On the app settings page, scroll down to **Private keys**
2. Click **Generate a private key**
3. A `.pem` file will download to your computer
4. **IMPORTANT**: Store this file securely - you cannot download it again

### Step 10: Note Your App Credentials

Record the following information (found on the app settings page):

1. **App ID**: Found at the top of the page (e.g., `1957234`)
2. **Client ID**: Found in the "About" section
3. **Private Key**: The `.pem` file you downloaded

## Installation Process

### Install App to Repository

1. From your app settings page, click **Install App** in the left sidebar
2. Click **Install** next to your organization/account
3. Choose: ✅ **Only select repositories**
4. Select: ✅ `legido-ai/tasks`
5. Click **Install**

### Get Installation ID

After installation, note your **Installation ID**:

1. Go to `https://github.com/organizations/legido-ai/settings/installations`
2. Click on your app name
3. Check the URL: `https://github.com/organizations/legido-ai/settings/installations/INSTALLATION_ID`
4. The number at the end is your Installation ID (e.g., `12345678`)

## Configuration with MCP

### Environment Variables

Set the following environment variables in your `.env` file:

```env
# GitHub App Configuration
GITHUB_APP_ID=1957234                    # Your App ID
GITHUB_INSTALLATION_ID=12345678          # Your Installation ID
GITHUB_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
...your private key content...
-----END RSA PRIVATE KEY-----"
```

### Setup with docker-claude-code

1. Copy the setup script:
```bash
docker cp utils/setup-mcp-github.sh claude-code:/tmp/
```

2. Execute the setup script:
```bash
docker exec claude-code bash /tmp/setup-mcp-github.sh
```

3. Verify the configuration:
```bash
docker exec claude-code claude mcp list
```

Expected output:
```
Checking MCP server health...
github: docker run -i --rm -e GITHUB_APP_ID=... - ✓ Connected
```

## Testing and Verification

### Test 1: Verify App Permissions

```bash
# Test reading repository contents
curl -H "Authorization: Bearer YOUR_INSTALLATION_TOKEN" \
  https://api.github.com/repos/legido-ai/tasks/contents

# Test creating an issue
curl -X POST -H "Authorization: Bearer YOUR_INSTALLATION_TOKEN" \
  -d '{"title":"Test Issue","body":"Testing GitHub App"}' \
  https://api.github.com/repos/legido-ai/tasks/issues
```

### Test 2: Verify NO Repository Deletion

Attempt to delete repository (should fail):

```bash
curl -X DELETE -H "Authorization: Bearer YOUR_INSTALLATION_TOKEN" \
  https://api.github.com/repos/legido-ai/tasks
```

Expected response: `403 Forbidden` or `404 Not Found` (insufficient permissions)

### Test 3: Test with MCP

Inside the docker-claude-code container:

```bash
# List available MCP tools
claude mcp list

# Test GitHub operations through MCP
# (This would be done through Claude Code interface)
```

## Security Best Practices

### Private Key Management

1. **Never commit** private keys to version control
2. **Store securely** in environment variables or secret management systems
3. **Rotate regularly** by generating new keys and deleting old ones
4. **Limit access** to only systems that need it

### Environment Variables

```bash
# Add to .gitignore
echo ".env" >> .gitignore

# Use environment-specific files
.env.example     # Template with placeholder values
.env             # Actual secrets (never committed)
```

### Monitoring

1. **Review app activity** regularly at:
   `https://github.com/organizations/legido-ai/settings/installations`

2. **Check access logs** for unusual activity

3. **Audit permissions** periodically to ensure minimum requirements

### Revoking Access

If the app is compromised:

1. Go to `https://github.com/organizations/legido-ai/settings/installations`
2. Click on the app
3. Click **Uninstall** or **Suspend**
4. Generate new private keys if reinstalling

## Troubleshooting

### Issue: "Bad credentials" Error

**Cause**: Invalid or expired installation token

**Solution**:
- Verify App ID and Installation ID are correct
- Check private key is properly formatted with newlines
- Ensure environment variables are properly set

### Issue: "Not Found" or "403 Forbidden"

**Cause**: Insufficient permissions or app not installed

**Solution**:
- Verify app is installed on `legido-ai/tasks` repository
- Check repository permissions in app settings
- Ensure you're using the correct Installation ID

### Issue: "Resource not accessible by integration"

**Cause**: Operation requires permissions the app doesn't have

**Solution**:
- Review required permissions for the operation
- Update app permissions in GitHub settings
- Reinstall the app after permission changes

### Issue: Environment Variables Not Expanding

**Cause**: Using `claude mcp add-json` with variable references

**Solution**:
- Always use the `setup-mcp-github.sh` script
- Script properly expands environment variables
- Manual configuration requires actual values, not variable names

### Issue: Cannot Push to Repository

**Cause**: Contents permission may show `"push": false` in some cases

**Solution**:
- Verify Contents permission is set to "Read & write"
- Check installation token is properly generated
- Review GitHub API response headers for permission details

## Permissions Summary

### ✅ What This App CAN Do

- ✅ Read repository files and contents
- ✅ Create, edit, and close issues
- ✅ Add comments and labels to issues
- ✅ Create and manage pull requests
- ✅ Create commits and branches
- ✅ Request and submit reviews
- ✅ Merge pull requests

### ❌ What This App CANNOT Do

- ❌ Delete or archive repositories
- ❌ Modify repository settings
- ❌ Manage webhooks or deploy keys
- ❌ Access or modify secrets
- ❌ Transfer repository ownership
- ❌ Modify GitHub Actions workflows (unless Workflows permission added)
- ❌ Access organization-level settings

## Additional Resources

- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [GitHub App Permissions Reference](https://docs.github.com/en/rest/overview/permissions-required-for-github-apps)
- [Creating GitHub Apps Guide](https://docs.github.com/en/apps/creating-github-apps)
- [MCP GitHub Integration](https://github.com/legido-ai/mcp-github-app-auth)

## Support

For issues or questions:
- GitHub Issues: [docker-claude-code issues](https://github.com/legido-ai/docker-claude-code/issues)
- Documentation: [docker-claude-code docs](https://github.com/legido-ai/docker-claude-code)
