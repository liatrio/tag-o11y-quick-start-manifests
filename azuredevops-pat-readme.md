# How to Create a Personal Access Token (PAT) on Azure DevOps

A **Personal Access Token (PAT)** is used to authenticate with Azure DevOps when using the API or command-line tools. Follow these steps to create a PAT for the Azure DevOps receiver.

---

## **Step 1: Log in to Azure DevOps**
1. Open a web browser and go to [Azure DevOps](https://dev.azure.com/).
2. If you don't have an account, click **Start free** and follow the instructions.
3. If you already have an account, sign in with your Microsoft credentials.

---

## **Step 2: Access User Settings**
1. In the top-right corner, click on your **profile icon**.
2. In the dropdown menu, select **Personal access tokens**.

---

## **Step 3: Create a New Token**
1. Click **+ New Token**.
2. **Give your token a descriptive name** (e.g., `"OTEL Collector Token"` or `"Metrics Collection"`).  
3. **Select your organization** from the dropdown.
4. **Set an expiration date**:
   - Choose a custom expiration (e.g., 90 days, 1 year)
   - Or select **Custom defined** for a specific date

---

## **Step 4: Set Token Permissions**

For the Azure DevOps receiver to collect VCS metrics, you need the following **minimum permissions**:

### Required Scopes:
- ✅ **Code** → **Read** (to access repository information)
- ✅ **Project and Team** → **Read** (to access project metadata)

### Optional (for future features):
- **Work Items** → **Read** (if work item metrics are added)
- **Build** → **Read** (if build metrics are added)

**Important:** Use the principle of least privilege - only grant the permissions needed.

---

## **Step 5: Generate and Copy the Token**
1. After selecting permissions, click **Create**.
2. Azure DevOps will display your token **only once**.
3. **Copy and save** it immediately in a secure place (password manager recommended).
4. If you lose it, you must **generate a new one** since Azure DevOps does not store your token.

---

## **Step 6: Configure the Token in Your Environment**

### For Local Development:
1. Navigate to `collectors/azuredevopsreceiver/`
2. Create a `.env` file (if it doesn't exist):
   ```bash
   touch .env
   ```
3. Add your credentials:
   ```bash
   ADO_PAT=your_personal_access_token_here
   ADO_ORG=your_organization_name
   ADO_PROJECT=your_project_name
   ADO_SEARCH_QUERY=  # Optional: filter repos by name (e.g., "service")
   ```

### Security Notes:
- ✅ The `.env` file is gitignored - never commit tokens to version control
- ✅ Rotate tokens regularly (every 90 days recommended)
- ✅ Revoke tokens immediately if compromised
- ✅ Use separate tokens for different environments (dev, staging, prod)

---

## **Step 7: Verify Token Access**

Test your token using the Azure DevOps REST API:

```bash
curl -u :YOUR_PAT_HERE https://dev.azure.com/YOUR_ORG/_apis/projects?api-version=7.0
```

You should receive a JSON response with your projects. If you get a 401 error, verify:
- Token hasn't expired
- Correct permissions are granted
- Organization name is correct

---

## **Troubleshooting**

### "Authentication failed" errors:
- Verify the token hasn't expired
- Check that you copied the entire token (no spaces or truncation)
- Ensure the token has the required scopes

### "Access denied" errors:
- Verify your user account has access to the organization/project
- Check that the token has the correct permissions
- Confirm the organization and project names are correct

---

## **Additional Resources**
- [Azure DevOps PAT Documentation](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate)
- [Azure DevOps REST API Reference](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
