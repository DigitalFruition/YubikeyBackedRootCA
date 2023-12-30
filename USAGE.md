# Usage Instructions

## Introduction

This document provides step-by-step instructions on setting up a Certificate Authority (CA) environment,
replicating the setup for [Digital Fruition, LLC](https://www.digitalfruition.com/)'s [internal CA](https://ca.digitalfruition.com/).
It is designed to guide you through provisioning an air-gapped Certificate Authority using Debian 
Bullseye with Full Disk Encryption (FDE) and configuring the necessary components for both a Root and 
Intermediate CA.

For a detailed understanding of the project, its scope, and the architectural decisions, please refer to `README.md`.

## Prerequisites

Before proceeding, ensure that you have:

- Basic understanding of Public Key Infrastructure (PKI) and certificate management.
- Familiarity with Debian Linux and command-line interfaces.
- The necessary hardware to set up an air-gapped environment.
- A [Yubikey device](https://www.yubico.com/products/) to generate and store the private key for the Root CA.
  (These instructions were tested with the Yubikey 5 series)

## Step 1: Provisioning the Air-gapped Machine

Using an air-gapped machine for these steps is important because it ensures that you're operating in a safe and clean environment.

While the private key for the Root CA will be stored on the Yubikey, the private key for the 
Intermediate CA is stored on-disk. Therefore it's critical that the machine you run through 
these steps on is secure, has full disk encryption, and is not used for any other purpose.

You can use any linux distribution of your choice and how to set up the machine is up to you;
the following instructions are a rough guide on how to set up a Debian Linux machine.

You can provision a Virtuam Lachine (VM) if you prefer. Note that this is s secure as the host
machine is an attack vector against the VM. A VM might be easier, cheaper and safe enough for
your needs... the choice is yours.

1. **Prepare a Debian Bullseye installation media** - Download the latest Debian Bullseye image from the official website and prepare a bootable USB or CD.

2. **Install Debian Bullseye with FDE**:
   - Boot from the installation media.
   - Follow the installation prompts.
   - When partitioning, select the option for Full Disk Encryption (FDE).
   - Complete the installation process and boot into your new system.

3. **Ensure Air-gap**:
   - Physically disconnect any network connections.
   - Avoid installing any unnecessary packages or services.
   - If using a Virtual Machine, either apply restrictive ingress/egress firewall rules,
     disconnect or remove the virtual ethernet device, and/or place the VM into a
     quarrantined network or VLAN.

## Step 2: Execute Setup Scripts

1. **Prepare Scripts**:
   - Copy the scripts from the `scripts/setup` directory of this project into your air-gapped machine using a USB drive or similar means.
     You can also execute the commands from `scripts/setup` manually.

2. **Run Setup Scripts**:
   - Navigate to the directory containing the scripts.
   - Execute the scripts to install prerequisite packages and create necessary directories:

     ```bash
     cd /path/to/scripts/setup
     chmod +x *.sh  # Make sure the scripts are executable
     ./setup.sh     # Run the setup script
     ```

## Step 3: Prepare Configuration Files

1. **Copy OpenSSL Configuration Templates**:
   - Copy `root/openssl.config.template` and `intermediate/openssl.config.template` from the project directory to the respective directories in `/opt/ca/`.

2. **Edit Configuration Files**:
   - Navigate to `/opt/ca/root` and `/opt/ca/intermediate`.
   - Rename the copied template files to `openssl.cnf` or a similar name that you'll recognize.
   - Edit the configuration files according to your environment and needs:

     ```bash
     cd /opt/ca/root
     mv openssl.config.template openssl.cnf
     nano openssl.cnf  # or use any other text editor
     # Repeat for the intermediate configuration
     ```

   - Be sure to adjust paths, domain names, and other variables to fit your specific setup.

## Conclusion

Once you've completed these steps, you'll have an air-gapped CA environment with basic configurations for a Root and Intermediate CA. Continue with creating keys, signing certificates, and managing your CA as detailed in other documentation or guides specific to your CA's operational needs.

Remember, managing a CA, especially an air-gapped one, requires careful attention to security, backups, and procedures. Always ensure that your practices align with industry standards and your organizational security policies.

---

After drafting this USAGE.md, ensure to link all necessary scripts, templates, and additional documentation accurately. Keep it updated as your environment or procedures evolve. This document will serve as a practical guide for anyone needing to replicate or understand the setup of your CA environment.