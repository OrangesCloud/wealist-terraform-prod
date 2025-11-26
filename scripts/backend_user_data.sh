#!/bin/bash
set -e

# 로그 파일 설정
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Backend User Data Script Started ==="
date

# 1. 시스템 업데이트 및 필수 패키지 설치
echo ">>> Installing system packages..."
yum update -y
yum install -y docker ruby wget aws-cli jq

# 2. Docker 서비스 시작 및 자동 시작 설정
echo ">>> Starting Docker service..."
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# 3. Docker Compose 설치 (v2)
echo ">>> Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="2.24.0"
curl -L "https://github.com/docker/compose/releases/download/v$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 4. CodeDeploy Agent 설치
echo ">>> Installing CodeDeploy Agent..."
cd /home/ec2-user
wget https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# 5. 인프라 정보를 환경 변수 파일로 저장
echo ">>> Creating infrastructure environment file..."
cat <<EOF > /home/ec2-user/.env.infrastructure
REGION=${region}
ACCOUNT_ID=${account_id}
DB_ENDPOINT=${db_endpoint}
REDIS_ENDPOINT=${redis_endpoint}
S3_BUCKET=${s3_bucket_name}
EOF

# 6. ECR 로그인 헬퍼 스크립트 생성
echo ">>> Creating ECR login helper script..."
cat <<'EOFSCRIPT' > /home/ec2-user/ecr-login.sh
#!/bin/bash
source /home/ec2-user/.env.infrastructure
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
EOFSCRIPT

chmod +x /home/ec2-user/ecr-login.sh
chown ec2-user:ec2-user /home/ec2-user/ecr-login.sh

# 7. 애플리케이션 디렉토리 생성
echo ">>> Creating application directories..."
mkdir -p /home/ec2-user/app
chown -R ec2-user:ec2-user /home/ec2-user/app

# 8. 임시 헬스체크 서버 시작 (CodeDeploy가 실제 앱을 배포할 때까지)
echo ">>> Starting temporary health check servers..."
# User Service Health Check (8080)
docker run -d --name temp-user-health \
  --restart unless-stopped \
  -p 8080:80 \
  nginx:alpine \
  sh -c 'mkdir -p /usr/share/nginx/html/api/users/actuator && echo "{\"status\":\"UP\"}" > /usr/share/nginx/html/api/users/actuator/health && nginx -g "daemon off;"'

# Board Service Health Check (8000)
docker run -d --name temp-board-health \
  --restart unless-stopped \
  -p 8000:80 \
  nginx:alpine \
  sh -c 'mkdir -p /usr/share/nginx/html/api/boards && echo "{\"status\":\"UP\"}" > /usr/share/nginx/html/api/boards/health && nginx -g "daemon off;"'

# 9. CodeDeploy Agent 상태 확인
echo ">>> Checking CodeDeploy Agent status..."
systemctl status codedeploy-agent --no-pager

echo "=== Backend User Data Script Completed ==="
date
