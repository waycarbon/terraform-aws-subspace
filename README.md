# terraform-aws-subspace
Opinionated module for quick Subspace Wireguard VPN deployment on AWS

## Introduction

Infrastructure deployment for [subspacecommunity/subspace](https://github.com/subspacecommunity/subspace)

## Documentation

This project is intended to be a thin layer over the subspace project. The added capabilities are:
- periodic backup to an S3 bucket
- ssh key written to a bucket of choice, so you can later access the EC2 instance via SSH
- Web App, Wireguard endpoint and Internal Alias Route53 Records

### Arguments

Refer to subspace documentation in the aforementioned repository. The module variables map directly to
the subspace configuration variables. The module variables also have descriptions.
