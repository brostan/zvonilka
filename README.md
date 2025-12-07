# Jitsi Meet Server

This repository contains the necessary files and configurations to set up a Jitsi Meet server for video conferencing.

## Overview

Jitsi Meet is an open-source video conferencing solution that allows users to create and join video calls easily. This project provides a complete setup using Ansible, Docker, and Terraform to deploy the Jitsi Meet server components.

## Project Structure

- **ansible/**: Contains Ansible playbooks and roles for deploying the server components.
- **docker/**: Contains the Docker Compose file for running Jitsi Meet in containers.
- **configs/**: Contains configuration files for Nginx, Prosody, and Jitsi Video Bridge.
- **scripts/**: Contains scripts for provisioning the server and obtaining SSL certificates.
- **terraform/**: Contains Terraform configuration for provisioning infrastructure.
- **docs/**: Contains documentation, including installation instructions.

## Getting Started

To set up the Jitsi Meet server, follow these steps:

1. **Clone the repository**:
   ```
   git clone https://github.com/jitsi/jitsi-meet-server.git
   cd jitsi-meet-server
   ```

2. **Provision the server**:
   Use the provided scripts to provision your server environment.
   ```
   ./scripts/provision.sh
   ```

3. **Obtain SSL certificates**:
   Run the SSL script to secure your server.
   ```
   ./scripts/obtain-ssl.sh
   ```

4. **Deploy using Ansible**:
   Execute the Ansible playbook to deploy the server components.
   ```
   ansible-playbook ansible/playbooks/site.yml
   ```

5. **Access the Jitsi Meet interface**:
   Open your web browser and navigate to your server's IP address or domain to start using Jitsi Meet.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the terms of the MIT License. See the LICENSE file for details.