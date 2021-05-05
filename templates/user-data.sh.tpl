#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log) 2>&1
set -eu

function log {
  echo "--[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "STARTING USER-DATA"

# install wireguard on amazon linux 2
log "INSTALLING WIREGUARD"
curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
yum install kernel-headers-"$(uname -r)" kernel-devel-"$(uname -r)" -y
yum install wireguard-dkms wireguard-tools iptables-services jq -y

# build and wireguard kernel module
log "BUILDING WIREGUARD KERNEL MODULE"
dkms status
WIREGUARD_VERSION="$(dkms status | grep wireguard | awk -F ', ' '{print $2}')"
dkms build wireguard/"$WIREGUARD_VERSION"
dkms install wireguard/"$WIREGUARD_VERSION"

# install docker and pull image
log "INSTALLING DOCKER"
yum install -y docker
systemctl enable docker.service
systemctl start docker.service
gpasswd -a ec2-user docker

%{ if is_ecr_docker_image ~}
# authenticate to aws ecr
log "AUTHENTICATING TO AWS ECR"
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
%{ endif ~}

# update instance ip
log "UPDATING INSTANCE IP"
export INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
export REGION=$(curl -fsq http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')

# If the association succeeds, the EIP is available and there is no main node. This becomes the main node in this case.
EPI_ASSOCIATION_ID="$(aws --region $REGION ec2 associate-address --allocation-id ${eip_id} --instance-id $INSTANCE_ID | jq -r '.AssociationId')"

# restore backup if exists
BACKUP_FILE='wireguard.tar.gz'
BACKUP_EXISTS="$(aws s3api head-object --bucket ${wireguard_backup_bucket_name} --key "$BACKUP_FILE" 2>&1 | grep -c LastModified)" || true
if [[ "$BACKUP_EXISTS" != "0" ]]; then
  log "RESTORING BACKUP"
  mkdir -p /data
  aws s3 cp s3://${wireguard_backup_bucket_name}/"$BACKUP_FILE" /tmp
  tar -xzvf /tmp/"$BACKUP_FILE" --directory /data
else
  echo "!! NO BACKUP PRESENT. STARTING FRESH"
fi

# sets cronjob routines for main or redundant node
log "SETTING CRONJOB ROUTINE"
if [[ "$EPI_ASSOCIATION_ID" != "null" ]]; then
  echo "This is the main node"
  CRON_FILE=/etc/cron.hourly/backup_wireguard
  cat <<EOF >>"$CRON_FILE"
#!/bin/sh
set -euo pipefail

rm -rf /tmp/"$BACKUP_FILE"
tar -czvf /tmp/"$BACKUP_FILE" --directory /data .
aws s3 cp /tmp/"$BACKUP_FILE" s3://${wireguard_backup_bucket_name}
rm -rf /tmp/"$BACKUP_FILE"
EOF
else
  echo "This is a redundant node"
  CRON_FILE=/etc/cron.hourly/pull_wireguard_backup
  cat <<EOF >>"$CRON_FILE"
#!/bin/sh
set -euo pipefail

rm -rf /tmp/"$BACKUP_FILE"
rm -rf /tmp/wireguard-data
aws s3 cp s3://${wireguard_backup_bucket_name}/"$BACKUP_FILE"  /tmp
tar -xzvf /tmp/"$BACKUP_FILE" --directory /tmp/wireguard-data
docker stop subspace
rsync -va /tmp/wireguard-data /data
docker start subspace
rm -rf /tmp/wireguard-data
rm -rf /tmp/"$BACKUP_FILE"
EOF
fi
chmod +x "$CRON_FILE"

# Load modules.
log "LOADING KERNEL MODULES"
modprobe wireguard
modprobe iptable_nat
modprobe ip6table_nat

# Enable modules when rebooting.
echo "wireguard" >/etc/modules-load.d/wireguard.conf
echo "iptable_nat" >/etc/modules-load.d/iptable_nat.conf
echo "ip6table_nat" >/etc/modules-load.d/ip6table_nat.conf

# Check if systemd-modules-load service is active.
systemctl status systemd-modules-load.service

# Enable IP forwarding.
cat <<EOF >>/etc/sysctl.d/99-ip-forward.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF

sysctl -p

# create and start subspace docker
log "CREATING AND STARTING VPN DOCKER CONTAINER"
docker create \
  --name subspace \
  --restart always \
  --network host \
  --cap-add NET_ADMIN \
  --volume /data:/data \
  --env SUBSPACE_HTTP_HOST="${wireguard_subspace_http_host}" \
  --env SUBSPACE_ENDPOINT_HOST="${wireguard_endpoint_host}" \
  --env SUBSPACE_NAMESERVERS="1.1.1.1,8.8.8.8" \
  --env SUBSPACE_LISTENPORT="51820" \
  --env SUBSPACE_IPV4_POOL="10.99.97.0/24" \
  --env SUBSPACE_IPV6_POOL="fd00::10:97:0/64" \
  --env SUBSPACE_IPV4_GW="${wireguard_ipv4_gateway}" \
  --env SUBSPACE_IPV6_GW="${wireguard_ipv6_gateway}" \
  --env SUBSPACE_IPV6_NAT_ENABLED=1 \
  --env SUBSPACE_ALLOWED_IPS="${join(",", compact(distinct(wireguard_allowed_ips)))},10.99.97.0/24" \
  ${wireguard_subspace_docker_image}

docker start subspace

log "ENDING USER-DATA"
