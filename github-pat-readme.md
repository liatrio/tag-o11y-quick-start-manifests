# How to Create a Personal Access Token (PAT) on GitHub

A **Personal Access Token (PAT)** is used to authenticate with GitHub when using the API or command-line tools without entering your password each time. Follow these steps to create a PAT if you have never used GitHub before.

---

## **Step 1: Log in to GitHub**
1. Open a web browser and go to [GitHub](https://github.com/).
2. If you don’t have an account, click **Sign up** and follow the instructions to create one.
3. If you already have an account, click **Sign in** and enter your credentials.

---

## **Step 2: Access the Developer Settings**
1. In the top-right corner of GitHub, click on your **profile picture**.
2. In the dropdown menu, select **Settings**.
3. Scroll down in the left sidebar and click **Developer settings**.

---

## **Step 3: Navigate to Personal Access Tokens**
1. Inside **Developer settings**, click **Personal access tokens**.
2. Select **Tokens (classic)** if using traditional authentication, or **Fine-grained tokens** for more detailed permission control.
3. Click **Generate new token**.

---

## **Step 4: Set Up Your New Token**
1. **Give your token a descriptive name** (e.g., `"GitHub API Token"` or `"My Personal Token"`).
2. **Set an expiration date** for security purposes. You can choose:
   - A short period (e.g., 30 days)
   - **No expiration** (not recommended for security reasons)
3. **Select the permissions you need**:
   - For basic Git operations, check **repo** (allows access to repositories).
   - For authentication with GitHub CLI, you may need **workflow** and **write:packages**.
   - Be careful when granting **admin** or **delete** permissions.

---

## **Step 5: Generate and Copy the Token**
1. After selecting the permissions, click **Generate token**.
2. GitHub will display your token **only once**.
3. **Copy and save** it in a secure place like a password manager.
4. If you lose it, you must **generate a new one** since GitHub does not store your token.

---

## **Step 6: Use the PAT in Git Operations**
1. When prompted for your GitHub password in **Git, CLI, or API requests**, use your **PAT** instead of your regular password.
2. Example usage in Git (replace `YOUR_TOKEN` with your copied PAT):

   ```sh
   git clone https://YOUR_TOKEN@github.com/your-username/repository.git