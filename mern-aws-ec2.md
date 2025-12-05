## 🚀 Travel Memory MERN Application Deployment

## 🏗️ Deployment Architecture Overview

The application is deployed across **two EC2 instances** behind an **Application Load Balancer (ALB)**. **Nginx** serves as a reverse proxy on each instance, routing frontend requests and API traffic to the Node.js backend running on **Port 3000**. **MongoDB Atlas** is used as the external database service.

-----

## ✅ Prerequisites

Before starting, ensure you have the following:

  * **AWS Account:** With necessary permissions to create EC2, ALB, and ACM resources.
  * **Key Pair (.pem file):** Created during the EC2 launch for secure SSH access.
  * **Custom Domain Name:** Required for Phase 4 (Cloudflare setup).
  * **MongoDB Atlas Account:** To obtain the database connection string (`MONGO_URL`).

-----

## 📋 Deployment Phases

### Phase 1: Initial EC2 Setup and Software Installation

This phase sets up the base virtual server environment.

1.  **Launch EC2 Instance:** Launch a `t2.micro` instance (free tier eligible) using **Ubuntu Server 20.04 LTS (HVM)** AMI.
2.  **Configure Security Group (Firewall):** Open the following inbound ports:
      * **SSH (Port 22):** For connecting to the instance.
      * **HTTP (Port 80):** For web traffic (Nginx will listen here).
      * **Custom TCP (Port 3000):** *Optional* for direct backend testing.
3.  **Connect via SSH:** Change the key file permissions and connect using the public IP address:
    ```bash
    chmod 400 your-key-pair.pem
    ssh -i "your-key-pair.pem" ubuntu@<Public-IP-Address>
    ```
4.  **Install Software:** Update packages and install Node.js, npm, Nginx, and Git:
    ```bash
    sudo apt update
    sudo apt install nodejs npm nginx git
    ```

-----

### Phase 2: Application Configuration and Nginx Setup

This phase involves deploying the MERN stack code and configuring the reverse proxy.

1.  **Clone Repository and Install Backend Dependencies:**
    ```bash
    git clone https://github.com/UnpredictablePrashant/TravelMemory.git
    cd TravelMemory/backend
    npm install
    ```
2.  **Configure Backend `.env` File:** Create a `.env` file in the `backend` directory with your MongoDB Atlas connection string:
    ```
    PORT=3000
    MONGO_URL=mongodb+srv://<username>:<password>@<cluster-url>/<db-name>?retryWrites=true&w=majority
    ```
3.  **Configure Frontend URLs and Build:**
    ```bash
    cd ../frontend
    npm install
    # Update src/urls.js to point to the EC2 Public IP for initial testing
    export const BASE_URL = "http://<EC2-Public-IP-Address>/api";
    # Build the static files for deployment
    npm run build
    ```
4.  **Configure Nginx Reverse Proxy:** Nginx will serve the static React files and route `/api/` traffic to the backend.
      * Create a new configuration file:
        ```bash
        sudo nano /etc/nginx/sites-available/travelmemory
        ```
      * Paste the Nginx configuration, ensuring the `root` directive points to the static build directory: `root /home/ubuntu/TravelMemory/frontend/build;`. The configuration routes requests starting with `/api/` to `http://localhost:3000`.
      * Enable the configuration and restart Nginx:
        ```bash
        sudo ln -s /etc/nginx/sites-available/travelmemory /etc/nginx/sites-enabled/
        sudo systemctl restart nginx
        ```
      * ***Troubleshooting:*** If you see the **"Welcome to nginx\!"** page, it means the default configuration is loading. Fix this by removing the default symbolic link:
        ```bash
        sudo rm /etc/nginx/sites-enabled/default
        sudo nginx -t # Test syntax
        sudo systemctl restart nginx
        ```
5.  **Use PM2 for Process Management:** Install PM2 globally to keep the Node.js backend running continuously and start it on boot:
    ```bash
    sudo npm install -g pm2
    cd /home/ubuntu/TravelMemory/backend
    pm2 start index.js --name travelmemory-backend
    pm2 save
    pm2 startup
    # Follow 'pm2 startup' instructions to finalize setup.
    ```

-----

### Phase 3: Scaling and Load Balancing

Implement high availability by deploying a second instance and an Application Load Balancer (ALB).

1.  **Create a Second EC2 Instance:** Repeat all steps from **Phase 1 and Phase 2** to configure a second, identical EC2 instance.
2.  **Configure a Target Group:** Create a Target Group that listens on **HTTP Port 80** and register both EC2 instances as targets.
3.  **Create an Application Load Balancer (ALB):**
      * Set the scheme to **Internet-facing**.
      * Configure a **Security Group** to allow inbound traffic on **HTTP (Port 80)** and **HTTPS (Port 443)**.
      * Set up a **Listener on HTTP Port 80** and forward its traffic to the Target Group (e.g., `travelmemory-targets`).

-----

### Phase 4: Domain and HTTPS Setup with Cloudflare

Ensure the application is accessible via a custom domain and secured with HTTPS.

1.  **Request Certificate (ACM):** Use **AWS Certificate Manager (ACM)** to request a free public SSL certificate. Request certificates for your root domain (e.g., `yourdomain.com`) and a wildcard (e.g., `*.yourdomain.com`) using **DNS validation**.
2.  **Validate Certificate:** Add the **CNAME record** provided by ACM to your **Cloudflare DNS settings**. **Crucially, set the Proxy Status to OFF (Grey Cloud / DNS Only)** for validation. Wait until the status changes to "Issued" in ACM.
3.  **Configure Cloudflare DNS to ALB:**
      * **CNAME Record:** Create a CNAME record pointing `www` (or your desired subdomain) to the **DNS Name of your ALB**.
      * **Proxy Status:** Set the proxy status to **Proxied (Orange Cloud)** for Cloudflare's security/performance features.
4.  **Add HTTPS Listener to ALB:** Add an **HTTPS Port 443 listener** to your ALB. Set the default action to forward traffic to your Target Group, and select the **ACM certificate** you issued in Step 1.
5.  **Configure Cloudflare SSL Mode:** Go to Cloudflare's SSL/TLS settings and set the encryption mode to **Full (Strict)** to encrypt and validate the ACM certificate.
6.  **Redirect HTTP to HTTPS:** Force all traffic to the secure version.
      * **Easiest Method (Cloudflare):** Toggle **"Always Use HTTPS"** to On in Cloudflare's SSL/TLS $\rightarrow$ Edge Certificates.
      * **AWS Method (ALB):** Change the default action for the **HTTP:80 listener** to **Redirect** to **HTTPS Port 443**.

-----

## 🔒 Final Verification

Open your browser and type `http://yourdomain.com`.

  * It should automatically redirect to `https://`.
  * You should see the padlock icon in the address bar.
  * Your application should be fully functional.

Congratulations\! You have successfully deployed a scalable, secure, load-balanced MERN stack application on AWS.