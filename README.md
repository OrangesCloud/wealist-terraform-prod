# Wealist AWS Infrastructure (Terraform)

Wealist 서비스의 AWS 인프라를 Terraform으로 관리하는 저장소입니다.
고가용성(HA), 자동 확장(Auto Scaling), 무중단 배포(CodeDeploy)를 지원하는 프로덕션급 아키텍처입니다.

📊 **[상세 아키텍처 다이어그램 보기 →](./ARCHITECTURE.md)**

---

## 🏗️ 아키텍처 개요

### 3-Tier 아키텍처

```
Internet
    │
    ├─── CloudFront (Frontend) ─── S3
    │
    └─── ALB (Backend)
            │
            ├─── TG: User (8080) ──┐
            │                       │
            ├─── TG: Board (8000) ─┤
            │                       │         ┌─────────────────┐
            │                       │         │  Monitoring ASG │
            └─── TG: Monitoring ───┼────────▶│  (1 instance)   │
                                    │         │  - Prometheus   │
                ┌───────────────────┘         │  - Grafana      │
                │                             └─────────────────┘
                ▼
        ┌───────────────────────┐
        │  Backend ASG (2~6)    │
        │  ┌─────┬─────┬─────┐  │
        │  │AZ-a │AZ-c │AZ-d │  │
        │  │User │User │User │  │
        │  │Board│Board│Board│  │
        │  └─────┴─────┴─────┘  │
        └───────┬───────────────┘
                │
        ┌───────┴────────┐
        │                │
        ▼                ▼
   RDS PostgreSQL   Redis Cluster
    (Multi-AZ)       (Failover)
```

### 주요 특징

- **Region**: ap-northeast-2 (Seoul)
- **VPC**: 10.1.0.0/16 (Production), 10.0.0.0/16 (Dev)
- **Availability Zones**: 3개 (2a, 2c, 2d)
- **Compute**: EC2 Auto Scaling (2~6 instances)
- **Database**: RDS PostgreSQL (수동 관리)
- **Cache**: ElastiCache Redis (자동 Failover 지원)
- **CI/CD**: GitHub Actions OIDC + CodeDeploy

---

## 📁 프로젝트 구조

```
wealist-terraform-prod/
├── environments/
│   ├── prod/              # 프로덕션 (10.1.0.0/16)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── backend.tf
│   │   └── outputs.tf
│   └── dev/               # 개발 (10.0.0.0/16)
│
├── modules/
│   ├── vpc/               # VPC, Subnets, IGW, NAT, Routing
│   ├── security/          # Security Groups
│   ├── iam/               # IAM Roles (EC2, CodeDeploy, GitHub OIDC)
│   ├── ec2/               # Launch Template, ASG
│   ├── alb/               # ALB, Target Groups, Listeners
│   ├── ecr/               # Container Registry
│   ├── elasticache/       # Redis Cluster
│   ├── rds/               # RDS Subnet Group (인스턴스는 수동)
│   ├── frontend/          # S3 + CloudFront
│   ├── route53/           # DNS
│   └── codedeploy/        # CodeDeploy Apps
│
└── ssm-prod/              # SSM Parameters, S3 Buckets (별도 State)
```

---

## 📦 관리되는 리소스

### Production 환경 리소스

| 카테고리 | 리소스 | 수량 | 스펙 |
|----------|--------|:----:|------|
| **Network** | VPC | 1 | 10.1.0.0/16 |
| | Subnets | 6 | Public 3개 + Private 3개 (3 AZ) |
| | NAT Gateway | 1 | AZ-a (비용 최적화) |
| | VPC Endpoints | 4 | SSM, S3 |
| **Compute** | Backend ASG | 1 | t3.small (2~6대) |
| | Monitoring ASG | 1 | t3.small (1대) |
| **Load Balancer** | ALB | 1 | Internet-facing |
| | Target Groups | 4 | User, Board, Monitoring, Targets |
| **Database** | RDS PostgreSQL | 1 | **AWS Console 수동 관리** |
| | ElastiCache Redis | 1 | cache.t3.micro (1~2 노드) |
| **Container** | ECR Repositories | 2 | user-service, board-service |
| **CI/CD** | CodeDeploy Apps | 2 | User, Board |
| **IAM** | Roles | 3 | EC2, CodeDeploy, GitHub Actions |
| **Frontend** | S3 + CloudFront | 1 | wealist.co.kr |
| **Storage** | S3 Buckets | 3 | tfstate, artifacts, deploy-scripts |

### Terraform으로 관리하지 않는 리소스

- **RDS Instance**: AWS Console에서 수동 생성 (데이터 보호)
- **ACM Certificates**: AWS Console에서 발급 (도메인 검증 필요)
- **SSM Parameters**: AWS Console에서 등록 (민감 정보)

---

## 🌐 네트워크 구성

### VPC 및 서브넷

| 환경 | VPC CIDR | Public Subnets | Private Subnets |
|------|----------|----------------|-----------------|
| **Production** | 10.1.0.0/16 | 10.1.0/24, 10.1.1/24, 10.1.2/24 | 10.1.10/24, 10.1.11/24, 10.1.12/24 |
| **Development** | 10.0.0.0/16 | 10.0.0/24, 10.0.1/24, 10.0.14/24 | 10.0.2/24, 10.0.3/24, 10.0.4/24 |

### 라우팅

- **Public Subnets**: 0.0.0.0/0 → Internet Gateway
- **Private Subnets**: 0.0.0.0/0 → NAT Gateway (AZ-a)
- **VPC Endpoints**: S3, SSM (NAT 경유 불필요)

### Security Groups

| SG | Inbound | Outbound |
|----|---------|----------|
| **ALB** | 80, 443 from 0.0.0.0/0 | All |
| **EC2** | 8080, 8000, 3001, 9090 from ALB SG | All |
| **RDS** | 5432 from EC2 SG | All |
| **Redis** | 6379 from EC2 SG | All |

---

## 🚀 사전 준비사항

### AWS Console에서 수동 생성 필요

#### 1. S3 Backend 버킷
- 버킷명: `wealist-tfstate-bucket`
- Region: `ap-northeast-2`
- Versioning 활성화

#### 2. ACM Certificate 발급
- **ALB용**: `ap-northeast-2` 리전에서 `wealist.co.kr` 인증서 발급
- **CloudFront용**: `us-east-1` 리전에서 `wealist.co.kr` 인증서 발급
- DNS 검증 방식 사용

#### 3. SSM Parameters 등록
Systems Manager → Parameter Store에서 다음 파라미터 생성:
- `/wealist/prod/db/rds_master_username`
- `/wealist/prod/db/rds_master_password` (SecureString)
- `/wealist/prod/db/user_db_name`
- `/wealist/prod/db/board_db_name`
- `/wealist/prod/oauth/google_client_id`
- `/wealist/prod/oauth/google-client-secret` (SecureString)
- `/wealist/prod/jwt/jwt_secret` (SecureString)
- `/wealist/prod/db/endpoint` (RDS 생성 후)

#### 4. RDS 수동 생성
RDS → Database 생성:
- Engine: PostgreSQL 17.x
- Instance: db.t3.micro
- VPC: wealist-prod-vpc (Terraform 생성 후)
- Subnet Group: wealist-prod-db-sb-grp
- Security Group: wealist-prod-rds-sg
- Multi-AZ: 고가용성 필요 시 활성화

생성 후:
- RDS 엔드포인트를 SSM Parameter Store에 저장
- PostgreSQL 접속하여 `CREATE DATABASE wealist_user_db;`
- `CREATE DATABASE wealist_board_db;` 생성

---

## 🛠️ 사용 방법

### Terraform 초기화 및 배포

```bash
# Production 환경
cd environments/prod
terraform init
terraform plan
terraform apply
```

### Multi-AZ 모드 전환

`environments/prod/terraform.tfvars` 수정:

```hcl
# 비용 절약 모드 (기본)
enable_multi_az = false

# 고가용성 모드 (프로덕션 권장)
enable_multi_az = true
```

---

## 🔄 CI/CD 파이프라인

### GitHub Actions OIDC 인증

GitHub Actions에서 AWS 접근 시 **장기 액세스 키 없이** OIDC를 통해 임시 자격 증명 사용:
- Organization: `wealist-project`
- Branch: `deploy-prod`
- IAM Role: `wealist-prod-github-actions-role`

### 배포 프로세스

1. GitHub Actions에서 Docker 이미지 빌드
2. ECR에 이미지 Push
3. 배포 아티팩트(appspec.yml, scripts, docker-compose.yml)를 S3에 업로드
4. CodeDeploy 배포 트리거
5. EC2 인스턴스에서 순차 배포 (OneAtATime)
6. Health Check 통과 시 ALB에 등록

### CodeDeploy 배포 전략

- **OneAtATime**: 인스턴스를 하나씩 순차 배포
- **Health Check**: 각 인스턴스 배포 후 검증
- **Automatic Rollback**: 실패 시 자동 롤백

---

## 📚 주요 설정

### terraform.tfvars (Production)

```hcl
name_prefix = "wealist-prod"
vpc_cidr    = "10.1.0.0/16"

az_1 = "ap-northeast-2a"
az_2 = "ap-northeast-2c"
az_3 = "ap-northeast-2d"

public_subnet_1_cidr  = "10.1.0.0/24"
public_subnet_2_cidr  = "10.1.1.0/24"
public_subnet_3_cidr  = "10.1.2.0/24"
private_subnet_1_cidr = "10.1.10.0/24"
private_subnet_2_cidr = "10.1.11.0/24"
private_subnet_3_cidr = "10.1.12.0/24"

enable_multi_az = false

backend_instance_type = "t3.small"
backend_desired_capacity = 2
backend_min_size = 2
backend_max_size = 6

redis_node_type = "cache.t3.micro"
```

### Backend 설정

```hcl
terraform {
  backend "s3" {
    bucket  = "wealist-tfstate-bucket"
    key     = "prod/network.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }
}
```

---

- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

---

**Made with ❤️ by Wealist Team**
