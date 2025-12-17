#!/bin/bash

# Jenkins Setup Script for PERN GitOps
# This script helps you set up Jenkins for the PERN GitOps pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  PERN GitOps Jenkins Setup${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    echo "Please install Docker Compose first: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose are installed${NC}"
echo ""

# Function to prompt for credentials
prompt_credentials() {
    echo -e "${YELLOW}Please provide the following credentials:${NC}"
    echo ""
    
    read -p "GitHub Username: " GITHUB_USERNAME
    read -sp "GitHub Personal Access Token (with repo and write:packages scopes): " GITHUB_TOKEN
    echo ""
    read -sp "Jenkins Admin Password (default: admin123): " JENKINS_ADMIN_PASSWORD
    JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD:-admin123}
    echo ""
    echo ""
    
    # Optional ArgoCD token
    read -p "ArgoCD Token (optional, press Enter to skip): " ARGOCD_TOKEN
    echo ""
}

# Create .env file
create_env_file() {
    echo -e "${BLUE}Creating .env file...${NC}"
    
    cat > .env << EOF
# Jenkins Configuration
JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}
JENKINS_URL=http://localhost:8080

# GitHub Credentials
GITHUB_USERNAME=${GITHUB_USERNAME}
GITHUB_TOKEN=${GITHUB_TOKEN}

# GHCR Credentials (same as GitHub)
GHCR_USERNAME=${GITHUB_USERNAME}
GHCR_TOKEN=${GITHUB_TOKEN}

# ArgoCD (optional)
ARGOCD_TOKEN=${ARGOCD_TOKEN}
EOF
    
    echo -e "${GREEN}✓ .env file created${NC}"
}

# Start Jenkins
start_jenkins() {
    echo -e "${BLUE}Starting Jenkins...${NC}"
    
    # Detect Docker Compose command (v1 vs v2)
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        echo -e "${RED}Error: Docker Compose not found${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Using: ${DOCKER_COMPOSE}${NC}"
    
    # Check Docker socket accessibility
    echo ""
    echo -e "${YELLOW}⚠️  Security Notice:${NC}"
    echo "This setup mounts the Docker socket for building images."
    echo "For production, consider using Docker-in-Docker or Kaniko instead."
    echo ""
    
    # Try to get docker group GID
    DOCKER_GID=$(getent group docker | cut -d: -f3 2>/dev/null || echo "999")
    
    # Export for docker-compose
    export DOCKER_GID
    
    ${DOCKER_COMPOSE} up -d
    
    echo -e "${GREEN}✓ Jenkins is starting...${NC}"
    echo ""
    echo -e "${YELLOW}Waiting for Jenkins to be ready (this may take a minute)...${NC}"
    
    # Wait for Jenkins to be ready
    COUNTER=0
    MAX_ATTEMPTS=60
    
    while [ $COUNTER -lt $MAX_ATTEMPTS ]; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Jenkins is ready!${NC}"
            break
        fi
        sleep 5
        COUNTER=$((COUNTER+1))
        echo -n "."
    done
    
    if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
        echo -e "${RED}Warning: Jenkins took longer than expected to start${NC}"
        echo "Check logs with: ${DOCKER_COMPOSE} logs -f jenkins"
    fi
}

# Display access information
display_info() {
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}  Jenkins Setup Complete!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "Jenkins URL: ${BLUE}http://localhost:8080${NC}"
    echo -e "Username: ${BLUE}admin${NC}"
    echo -e "Password: ${BLUE}${JENKINS_ADMIN_PASSWORD}${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Open http://localhost:8080 in your browser"
    echo "2. Log in with the credentials above"
    echo "3. The 'pern-gitops-pipeline' job should be automatically configured"
    echo "4. Click 'Build with Parameters' to run your first build"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  View logs:        ${DOCKER_COMPOSE} logs -f jenkins"
    echo "  Stop Jenkins:     ${DOCKER_COMPOSE} down"
    echo "  Restart Jenkins:  ${DOCKER_COMPOSE} restart"
    echo "  Remove all:       ${DOCKER_COMPOSE} down -v"
    echo ""
}

# Main execution
main() {
    # Check if .env already exists
    if [ -f .env ]; then
        echo -e "${YELLOW}.env file already exists${NC}"
        read -p "Do you want to recreate it? (y/N): " RECREATE
        if [[ $RECREATE =~ ^[Yy]$ ]]; then
            prompt_credentials
            create_env_file
        else
            echo "Using existing .env file"
        fi
    else
        prompt_credentials
        create_env_file
    fi
    
    echo ""
    start_jenkins
    display_info
}

# Run main function
main
