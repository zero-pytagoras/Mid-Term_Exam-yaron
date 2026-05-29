# This is how REAME should look

#  README.md file for Project:  Status Dashboard

### Brief discription of the project
##### This appears under EXAM.md file
#  Table of Contents:
* [Features](#Features)
* [Prerequisites](#Prerequisites)
* [Installation](#Installation)
* [Development](#Development)
* [Troubleshooting](#Troubleshooting)
* [License](#Licence)


=========================================


# Features:

1. Python Flask app with `/`, `/api/status`, `/api/v1/status`, and `/api/v1/secret` endpoints
2. Containerized with Docker
3. Host-level reverse proxy with nginx
4. One-step installation script for Ubuntu Linux

# Prerequisites:

1. On the target Ubuntu machine, you must have:**
  - `docker`
  - `nginx`
  - `git`
  - `poetry` (for development or if you want to build locally)
  - `jq` if you want to use it for curl
2. Install all prerequisites with:
```sh
sudo apt update 
   sudo apt install -y docker.io nginx git python3-pip
   sudo systemctl enable --now docker 
   sudo usermod -aG docker $USER 
   pip3 install --user poetry
```
3. Install command for jq:
```sh
   sudo apt update 
   sudo apt install -y jq
```
   **Note:** You may need to log out and log back in for the Docker group change to take effect.


# Installation

1. Go to the location you want to clone the repository to and enter this command:
   git clone git@github.com:ThunderCats12/Mid-Term_Exam.git
2. enter the folder created and create and edit your `.env` file in project root:
```sh
    echo "PORT=5000" > .env
    echo "VERSION=1.0.0" > .env
    echo "API_KEY=letmein" > .env
```
   **Note:** Replace `your_secret_key` with your desired API key.
4. Run the installation script **As root (or with sudo):**
    `sudo ./install.sh`
   or pass the api key or other variables:
    `sudo API_KEY=secret ./install.sh`
   This will:
   •	Build the Docker image
   •	Stop and remove any previous container named status-dashboard
   •	Run the new container with your environment variables
   •	Configure nginx as a reverse proxy
   •	Reload nginx

5. Access the dashboard by opening your browser and go to:
   http://<your-vm-ip>/   
   or you can try using curl command:
```sh
    curl -s http://localhost/api/status | jq .
    curl -s -o /dev/null -w "%{http_code}\n" http://localhost/api/secret
    curl -s -H "X-API-Key: your_secret_key" http://localhost/api/secret | jq .
```
# Development

1. To run locally please make sure poetry installed
   if not:
```sh 
    pip3 install --user poetry
    poetry install
```
   then:
```sh
    export API_KEY=your_secret_key
    export VERSION=1.0.0
    poetry run python app.py
```
then:
```sh
curl http://localhost
```

# Troubleshooting

1. Ensure .env exists and contains API_KEY.
2. Ensure Docker, nginx, and Poetry are installed and on your $PATH.
3. If you change the port in .env, update nginx config and Docker run command accordingly.


# License Info

This project is licensed under the MIT License - see the LICENSE file for more detailes
