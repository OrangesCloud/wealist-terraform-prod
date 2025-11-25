

# Wealist AWS Infrastructure (Production)

이 저장소는 **Wealist 서비스의 운영(Production) 환경** 인프라를 **Terraform**으로 관리합니다.
기존 단일 인스턴스 구조에서 벗어나 **고가용성(High Availability)** 과 **자동 확장(Auto Scaling)** 이 가능한 아키텍처로 설계되었으며, 비용 효율성을 위해 \*\*가변적인 구성(Single AZ ↔ Multi AZ)\*\*을 지원합니다.

## 🏗️ 아키텍처 개요 (Architecture Overview)

* **Network:** `10.1.0.0/16` CIDR을 사용하여 기존 Dev 환경(`10.0.x.x`)과 격리된 VPC 구성.
* **Compute:** `Auto Scaling Group (ASG)`을 통해 트래픽에 따라 EC2 인스턴스 자동 증설/감소.
* **Deployment:** EC2 시작 시 **S3**에서 설정 파일을 다운로드하고, **SSM**에서 환경 변수를 주입받아 **Docker Compose V2**로 서비스 실행.
* **Database:** PostgreSQL(RDS) 및 Redis(ElastiCache) 사용. (Terraform 변수로 Multi-AZ 전환 가능)
* **Security:** 모든 민감 정보(DB 패스워드 등)는 **AWS SSM Parameter Store**를 통해 안전하게 주입.

-----

## 📦 관리되는 리소스 (Managed Resources)

| 카테고리 | 리소스 이름 (Logical) | 수량 | 상세 스펙 / 설정 | 비고 |
| :--- | :--- | :---: | :--- | :--- |
| **Network** | **VPC** | **1** | `10.1.0.0/16` | Dev와 격리됨 |
| | **Subnets** | **6** | Public 3개 + Private 3개 | 3개 AZ(a, c, d)에 분산 |
| | **NAT Gateway** | **1** | AZ-a에 배치 | 모든 Private Subnet이 공유 |
| | **Internet Gateway** | **1** | - | Public Subnet용 |
| **Compute** | **Backend ASG** | **1 그룹** | `t3.medium` (인스턴스 **2~6대**) | 트래픽에 따라 자동 조절 |
| | **Monitoring ASG** | **1 그룹** | `t3.small` (인스턴스 **1대**) | 장애 시 자동 복구 (Self-Healing) |
| | **IAM Role** | **1** | `wealist-prod-ec2-role` | EC2용 권한 |
| **Database** | **RDS (PostgreSQL)** | **1** | `db.t3.micro` / 20GB | Multi-AZ: **OFF** (단일 인스턴스) |
| **Cache** | **ElastiCache (Redis)** | **1** | `cache.t3.micro` | 노드: **1개** |
| **Load Balancer** | **ALB** | **1** | Application Load Balancer | |
| | **Listeners** | **2** | HTTP(80), HTTPS(443) | |
| | **Target Groups** | **4** | User, Board, Monitoring, Targets | |
| **Security** | **Security Groups** | **4** | ALB, EC2, RDS, Redis용 | |
| **Container** | **ECR Repository** | **2** | `board-service`, `user-service` | |

> **참고:** Frontend(S3, CloudFront) 및 Route53(DNS) 리소스는 기존 운영 환경과의 충돌 방지를 위해 이 Terraform 프로젝트에서 제외되었습니다. (수동 또는 별도 관리)

-----

## 🚀 배포 전 필수 준비 사항 (Prerequisites)

Terraform을 실행하기 전에 AWS 콘솔에서 다음 값들이 반드시 설정되어 있어야 합니다.

### 1\. AWS SSM Parameter Store 등록

애플리케이션 및 DB 접속 정보를 저장합니다. (Type: `String` 또는 `SecureString`)

* `/wealist/prod/db/postgres_superuser` (RDS 마스터 ID)
* `/wealist/prod/db/postgres_superuser_password` (RDS 마스터 PW - **SecureString**)
* `/wealist/prod/db/postgres_db` (초기 DB명)
* `/wealist/prod/db/user_db_name`, `user`, `password` (User 서비스용)
* `/wealist/prod/db/board_db_name`, `user`, `password` (Board 서비스용)
* `/wealist/prod/startup-script` (EC2 부팅 시 실행할 실제 쉘 스크립트)

### 2\. S3 버킷 구성 (`wealist-deploy-scripts`)

EC2가 부팅될 때 참조할 설정 파일들을 업로드해야 합니다.

* `s3://wealist-deploy-scripts/config/docker-compose.prod.yml`
* `s3://wealist-deploy-scripts/monitoring/docker-compose.yml`
* `s3://wealist-deploy-scripts/monitoring/prometheus.yml`

-----

## 🛠️ 사용 방법 (Usage)

### 1\. 초기화 및 계획 확인

```bash
cd environments/prod
terraform init
terraform plan
```

### 2\. 인프라 배포

```bash
terraform apply
```

### 3\. 비용 vs 가용성 모드 변경

`environments/prod/terraform.tfvars` 파일에서 변수 하나만 수정하면 됩니다.

```hcl
# 비용 절약 모드 (개발/테스트용)
enable_multi_az = false

# 고가용성 모드 (실제 운영용 - RDS Standby 및 Redis 노드 추가)
# enable_multi_az = true
```

-----

## 📝 추후 진행해야 할 작업 (To-Do List)

인프라 배포(`terraform apply`)가 완료된 후, 서비스 정상 가동을 위해 다음 작업이 필요합니다.

### ✅ 1. 데이터베이스 초기화 (수동)

RDS 생성 직후에는 `user_db`, `board_db`가 존재하지 않습니다. Bastion Host 등을 통해 접속하여 생성해야 합니다.

```sql
CREATE DATABASE wealist_user_db;
CREATE DATABASE wealist_board_db;
```

### ✅ 2. CI/CD 파이프라인 구축 (Github Actions)

소스 코드가 변경되면 자동으로 배포되도록 워크플로우를 구성해야 합니다.

* **Build:** Docker Image 빌드 및 ECR Push.
* **Deploy:** ASG Instance Refresh 명령을 통해 무중단 배포 수행.
  ```bash
  aws autoscaling start-instance-refresh --auto-scaling-group-name wealist-prod-backend-asg
  ```

### ✅ 3. 모니터링 구성 (Grafana/Prometheus)

* S3에 업로드된 `prometheus.yml`에 **AWS Service Discovery (`ec2_sd_configs`)** 설정이 올바르게 되어 있는지 확인해야 합니다. (ASG로 생성된 인스턴스를 자동으로 감지하기 위함)

### ✅ 4. SSM Startup Script 확정

`/wealist/prod/startup-script` 파라미터에 `docker compose pull && docker compose up -d` 등의 실제 실행 로직을 저장해야 합니다.