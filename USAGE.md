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

You can provision a Virtual Machine (VM) if you prefer. Note that this is not as secure as using a dedicated machine, because  the host
machine is an attack vector against the VM. A VM might be easier, cheaper and safe enough for your needs... the choice is yours.


1. **Prepare a Debian Bullseye installation media** - Download the latest Debian Bullseye image from the official website and prepare a bootable USB or CD.

1. **Install Debian Bullseye with FDE**:
   - Boot from the installation media.
   - Follow the installation prompts.
   - When partitioning, select the option for Full Disk Encryption (FDE).
   - Complete the installation process and boot into your new system.

1. **Install Needed packages**:
   - Run `./install.sh` from this repo (or manually install those packages)

1. **Ensure Air-gap**:
   - Physically disconnect any network connections.
   - Avoid installing any unnecessary packages or services.
   - If using a Virtual Machine, either apply restrictive ingress/egress firewall rules,
     disconnect or remove the virtual ethernet device, and/or place the VM into a
     quarantined network or VLAN.

## Step 2: Prepare the Yubikey

1. **Ensure the Yubikey can be found:**
   Execute `ykman list` and confirm the yubikey is displayes
1. **Set a PIN and Management PIN for the Yubikey:**
   - Change the Yubikey PIN with: `ykman piv change-pin`
     The default is `123456`
     This should be a random, 8-character password. it will be entered when signing CSRs.
   - Change the Pin Unlock Code with: `ykman piv access change-puk`
     The default is `12345678`
     This will be used if you ever need to reset the PIN.
   - Execute `ykman piv access change-management-key --generate --protect` to generate
     a random management key which is stored on the Yubikey, protected by your PIN.
   - Confirm with `ykman piv info`
1. **Prepare Scripts**:
   - Copy the scripts from the `scripts/setup` directory of this project into your air-gapped 
     machine using a USB drive or similar means.
     You can also execute the commands from `scripts/setup` manually.

1. **Run Setup Scripts**:
   - Navigate to the directory containing the scripts.
   - Execute the scripts to install prerequisite packages and create necessary directories:

     ```bash
     cd /path/to/scripts/setup
     chmod +x setup.sh  # Make sure the scripts are executable
     ./setup.sh     # Run the setup script
     ```

## Step 3: Prepare Configuration Files

1. **Create Your Root CA OpenSSL Configuration File**:
   - In a local git clone of your forked copy of this repo, make a copy of the
    `root/openssl.config.template` file named `root/openssl.config`.
     
     This file is the configuration controlling your new root CA.
     The version in this repository is a template, and has values with the word
     `TODO` in them which you will need to update for your CA:
   - If necessary, adjust the `dir` directive under `[ CA_default ]`
     
     By default, we store everything under `/opt/ca`: the root CA files under
     `/opt/ca/root` and the intermediate CA files under `/opt/ca/intermediate`.
     If you plan to use different directories, update this path.
   - If desired, adjust `default_days` to change how long the root and 
     intermediate CA certificates are valid for. The template specifies 10 years
     (3650 days).
   - Similarly, adjust `default_crl_days` if desired. This specifies the default
     length of time that Certificate Revocation Lists are valid for. The default
     is 30 days.
   - You *must* adjust the `*_default` values from the `[ req_distinguished_name ]`
     section. These values all ship with `TODO_` and placeholder text. These
     values specify what will be on the actual Root CA, so make sure they
     properly describe your CA and environment. Pretend you're a user being asked
     to install and trust this CA, and provide values they expect to see.
   - The `[ pkcs11_section ]` contains values which worked for me on Debian 11,
     but might need to be adjusted for your environment. I found these values
     with `find / -type f -name libykcs11.so 2>/dev/null`
   - Edit `crlDistributionPoints` under `[ v3_ca ]` and specify the URI
     where you will be uploading the Certificate Revocation list (CRL) for your
     new root CA. **This is very important** as some applications will **not trust**
     certificates unless they can validate them against the CRL.

     The intention of this project is to hoste the CRL on the CloudFront Pages
     site backed by the GitHub fork of this repository, but you can specify any
     URI you like.
   - Finally, either edit `nameConstraints` to suit your needs, or remove this
     config stanza if you don't want restrictions on what domains or resources 
     the root CA's intermediate CAs may issue certificates for.

     `nameConstraints` is used to impose limitations on the subsequent 
     certificate chain. This extension is crucial for establishing boundaries on
     the scope of the CA and enhancing security by limiting where and how the 
     certificates it issues can be validly used.

     You can improve end user trust in your CA by restricting it to domains you
     own or control, preventing the CA from being used to create certificates 
     which allow man-in-the-middle eavedropping proxies.

     The `nameConstraints` extension consists of two main lists:

     Permitted Subtrees (`permittedSubtrees`): Specifies the namespace within 
     which all subject names in subsequent certificates must reside. If this is
     present in the certificate, any subsequent certificate's subject name must 
     be within one of the specified namespaces.

     Excluded Subtrees (`excludedSubtrees`): Specifies the namespace for which 
     no subject names in subsequent certificates may reside. If this is present,
     any subsequent certificate with a subject name within the excluded namespace
     is invalid.

     Within these lists, constraints can be applied to various types of names, 
     such as:

         - DNS: For domain names (e.g., permitted;DNS:.example.com allows any subdomain of example.com).
         - IP: For specific IP address ranges.
         - Directory: For distinguished names (DN) in a specific directory.
         - URI, RFC822 (email), and other name forms.

1. **Create Your Intermediate CA OpenSSL Configuration File**:
   - Similar to the Root CA configuration file, copy `intermediate/openssl.config.template`
     to `intermediate/openssl.config`
   - Again, if necessary, adjust the `dir` directive under `[ CA_default ]`
   - Similarly you must adjust the `*_default` values from the `[ req_distinguished_name ]`
     section.This is for the Intermediate CA, so they don't carry the implication
     that an end user must verify before trusting the certificate... but they are
     still public information and should be correct and sane.
   - Adjust the policy under `[ policy_loose ]` if desired (E.G. if you want to
     require that CSRs you sign have locality information)
   - Edit `crlDistributionPoints` and specify the URI where you will be uploading
     the Certificate Revocation list (CRL) for this Intermediate CA. Again, very
     important to publish the CRL for application trust.
   - Finally, again either edit `nameConstraints` to suit your needs, or remove.
     Note that the Root CA's `nameConstraints` applies to the Intermediate as well
     (all the way down the chain of trust).

1. **Generate the Root CA:**
   - Generate a private key on the yubikey with: 
     ```
     cd /opt/ca/root
     ykman piv keys generate -a RSA2048 -F PEM --pin-policy ALWAYS --touch-policy ALWAYS 9c public.pem
     ykman piv certificates generate -s 'C=US,ST=North Carolina,L=Asheville,O=Digital Fruition\, LLC,OU=Digital Fruition Certificate Authority,CN=Digital Fruition Root Certificate Authority' 9c public.pem
     ```
   - Confirm with `ykman piv info`
   - Export the Root CA with: `ykman piv certificates export 9c /opt/ca/root/cacert.pem`
   - Generate your CRL with:
     ```
     PKCS11_MODULE_PATH=/usr/lib/x86_64-linux-gnu/libykcs11.so openssl ca -gencrl -config /opt/ca/root/openssl.config -engine pkcs11 -keyform engine -keyfile "pkcs11:object=Private key for Digital Signature;type=private" -out /opt/ca/root/crl.pem
     ```
     Enter your Yubikey PIN (twice?) and then touch the yubikey
   - Confirm the CRL with `cat /opt/ca/root/crl.pem`
1. **Generate the Intermediate CA:**
   - Generate the Intermediate CA's private key:
     ```
     openssl genrsa -out /opt/ca/intermediate/private/intermediate.key.pem 4096
     ```
   - Have the Intermediate generate a CSR:
     ```
     openssl req -config /opt/ca/intermediate/openssl.config \
     -new -key /opt/ca/intermediate/private/intermediate.key.pem \
     -out /opt/ca/intermediate/intermediate.csr
     ```
   - Sign the Intermediate CSR with the root CA:
     ```
     PKCS11_MODULE_PATH=/usr/lib/x86_64-linux-gnu/libykcs11.so openssl ca \
     -config /opt/ca/root/openssl.config \
     -extensions v3_intermediate_ca \
     -out /opt/ca/intermediate/public.crt \
     -infiles opt/ca/intermediate/intermediate.csr \
     -engine pkcs11 -keyform engine \
     -key "pkcs11:object=Private key for Digital Signature;type=private"


     PKCS11_MODULE_PATH=/usr/lib/x86_64-linux-gnu/libykcs11.so openssl ca \
     -extensions v3_intermediate_ca \
     -out /opt/ca/intermediate/public.crt \
     -infiles opt/ca/intermediate/intermediate.csr \
     -engine pkcs11 -keyform engine \
     -keyfile "pkcs11:object=Private key for Digital Signature;type=private"


     PKCS11_MODULE_PATH=/usr/lib/x86_64-linux-gnu/libykcs11.so openssl ca \
     -config /opt/ca/root/openssl.config \
     -engine pkcs11 -keyform engine \
     -keyfile "pkcs11:object=Private key for Digital Signature;type=private" \
     -out /opt/ca/intermediate/public.crt \
     -infiles /opt/ca/intermediate/intermediate.csr
     ```

## Conclusion

Once you've completed these steps, you'll have an air-gapped CA environment with basic configurations for a Root and Intermediate CA. Continue with creating keys, signing certificates, and managing your CA as detailed in other documentation or guides specific to your CA's operational needs.

Remember, managing a CA, especially an air-gapped one, requires careful attention to security, backups, and procedures. Always ensure that your practices align with industry standards and your organizational security policies.
