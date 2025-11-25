#!/bin/bash
# 1. Terraform이 주입해준 인프라 정보를 환경변수 파일로 저장
cat <<EOF > /home/ec2-user/.env.infrastructure
DB_HOST=$(echo ${db_endpoint} | cut -d':' -f1)
DB_PORT=5432
REDIS_HOST=${redis_endpoint}
REGION=${region}
EOF

# 2. SSM Parameter Store에서 "진짜 실행 스크립트"를 가져와서 실행
#    (아직 코드가 없어도, 나중에 SSM 값만 바꾸면 서버 재시작 시 반영됨)
aws ssm get-parameter \
  --name "/wealist/prod/startup-script" \
  --region ${region} \
  --query "Parameter.Value" \
  --output text > /home/ec2-user/startup.sh

chmod +x /home/ec2-user/startup.sh
/home/ec2-user/startup.sh