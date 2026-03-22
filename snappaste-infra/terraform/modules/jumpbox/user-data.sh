#!/bin/bash
set -uo pipefail

# ──────────────────────────────────────────────
# Jumpbox Setup Script
# Installs: kubectl, Helm, AWS CLI
# Amazon Linux 2023 — SSM only, no SSH
# ──────────────────────────────────────────────

# ── Wait for NAT Gateway / network to be ready ──
# EC2 boots before NAT Gateway is fully routable — retry until network is up
echo "Waiting for network connectivity..."
for i in $(seq 1 30); do
  if curl -s --max-time 5 -o /dev/null https://aws.amazon.com; then
    echo "Network ready (attempt $i)"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "ERROR: Network not available after 5 minutes. Aborting."
    exit 1
  fi
  echo "Attempt $i: not ready, retrying in 10s..."
  sleep 10
done

set -e

# ── kubectl v1.34 (matches cluster version) ──
curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl"
chmod +x /tmp/kubectl
mv /tmp/kubectl /usr/local/bin/kubectl

# ── Helm 3 ──
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ── AWS CLI v2 ──
yum install -y aws-cli

# ── Set AWS region for all SSM sessions ──
echo "export AWS_DEFAULT_REGION=${aws_region}" >> /etc/profile.d/aws.sh

# ── Shortcut alias — configure kubectl on login ──
echo "alias kc='aws eks update-kubeconfig --name ${project_name}-${environment}-eks --region ${aws_region}'" >> /etc/profile.d/aws.sh

echo "Jumpbox setup complete"
