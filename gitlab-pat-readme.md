# How to Create a Personal Access Token (PAT) on GitLab

A **Personal Access Token (PAT)** is used to authenticate with GitLab when using the API, Git operations, or command-line tools without entering your password each time. Follow these steps to create a PAT if you have never used GitLab before.

---

## **Step 1: Log in to GitLab**
1. Open a web browser and go to [GitLab](https://gitlab.com/).
2. If you don’t have an account, click **Register** and follow the instructions to create one.
3. If you already have an account, click **Sign in** and enter your credentials.

---

## **Step 2: Access the Personal Access Tokens Page**
1. Click on your **profile picture** in the top-right corner.
2. In the dropdown menu, select **Edit profile**.
3. In the left sidebar, click **Access Tokens**.

---

## **Step 3: Create a New Personal Access Token**
1. **Give your token a descriptive name** (e.g., `"GitLab API Token"` or `"My GitLab Token"`).
2. **Set an expiration date** for security purposes (recommended).
3. **Select the permissions (scopes) you need**:
   - **`read_repository`** – for read-only access to repositories.
   - **`write_repository`** – for pushing code to repositories.
   - **`api`** – for full API access.
   - **`sudo`** – for administrative privileges (use with caution).
   - Select additional scopes based on your use case.

---

## **Step 4: Generate and Copy the Token**
1. Click **Create personal access token**.
2. GitLab will display your token **only once**.
3. **Copy and save** the token in a secure location, such as a password manager.
4. If you lose it, you must **generate a new one**, as GitLab does not store your token.

---

## **Step 5: Use the PAT in Git Operations**
1. When prompted for your GitLab password in **Git, CLI, or API requests**, use your **PAT** instead of your regular password.
2. Example usage in Git (replace `YOUR_TOKEN` with your copied PAT):

   ```sh
   git clone https://oauth2:YOUR_TOKEN@gitlab.com/your-username/repository.git