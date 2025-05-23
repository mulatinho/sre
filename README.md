# SRE (Site Reliability Engineering) Resources & Tools

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)

Welcome to the **SRE** repository—a curated collection of hands-on labs, configurations, and documentation designed to explore and demonstrate various Site Reliability Engineering (SRE) practices. This project serves as a practical resource for learning and applying SRE principles in real-world scenarios.

## Features
- **Automation**: Tools for automating SRE tasks.
- **Incident Management**: Templates for postmortems and runbooks.
- **Best Practices**: Guides on SLOs/SLIs, error budgets, and more.
- **Monitoring & Alerting**: Scripts and configs for Prometheus, Grafana, etc.

## Quick Start

### System Requirements

- **Linux** (Ubuntu 22.04+ recommended)
- **KVM/QEMU** with Libvirt
- **Vagrant** with `vagrant-libvirt` plugin
- **Ansible** 2.14+
- **kubectl**, **helm**, **kustomize**
- Optional: `virt-manager` for GUI VM inspection

### Installation
```bash
git clone https://github.com/mulatinho/sre.git
```


## Repository Structure
---

### `aws-s3-cloudfront-rds-lambda`

Demonstrates the deployment of a serverless application on AWS, integrating services such as S3, CloudFront, RDS, and Lambda.  
This lab showcases infrastructure as code practices using Terraform and emphasizes scalability and resilience in cloud architectures.

### `gcp-webapp`

Provides a comprehensive guide to deploying a web application on Google Cloud Platform (GCP).  
It covers the setup of GCP resources, application deployment, and monitoring strategies, offering insights into managing applications in a cloud environment.


### `kind`

A Kubernetes cluster deployed with two control-planes and four worker nodes and a local disk provisioner, a generic solution to do some tests configured with FluxCD to GitOps.

### `sre-documents`

Contains essential SRE documentation templates, including:

- **SLA/SLO/SLI**: Define service level agreements, objectives, and indicators.
- **Runbooks**: Step-by-step guides for handling common operational tasks and incidents.
- **Incident Postmortems/RCA**: Templates for analyzing and documenting incidents to prevent future occurrences.
- **Monitoring & Alerting**: Guidelines for setting up effective monitoring and alerting systems.
- **Project Management**: Frameworks for planning and executing SRE-related projects.

These documents serve as foundational tools for establishing robust SRE practices within an organization.

### `wireguard-vpn`

Offers a lab focused on setting up a secure VPN using WireGuard.  
This section includes configuration files and instructions for deploying a VPN server, enhancing secure communication within and across networks.

## Contributing
Contributions are welcome! If you have suggestions, improvements, or additional labs to share, please open an issue or submit a pull request. Together, we can enhance this repository to better serve the SRE community.
