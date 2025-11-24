
resource "aws_instance" "backend" {
  ami           = var.ami_id
  instance_type = "t3.medium"

  # 네트워크 설정
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  private_ip             = "10.0.2.11" # 고정 IP 지정

  # IAM 역할 연결
  iam_instance_profile = var.iam_instance_profile

  # User Data (주신 스크립트 그대로 적용)
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install docker -y
    service docker start
    # ec2-user가 docker 명령을 사용할 수 있도록 그룹 추가
    usermod -a -G docker ec2-user

    # Docker Compose 설치 (최신 버전 사용)
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # 이후 CI/CD 파이프라인에서 Docker Compose 파일을 다운로드하고 실행합니다.
  EOF

  # (선택) 루트 볼륨 설정 (실제와 다르면 plan에서 변경 뜸)
  root_block_device {
    volume_type = "gp3" # (확인 필요: gp2 인지 gp3 인지)
    volume_size = 8     # (확인 필요: 8GB 인지 더 큰지)
  }

  tags = {
    Name = "${var.name_prefix}-backend-server"
  }

  lifecycle {
    ignore_changes = [user_data]
    # user_data 가 바뀌어도 무시하라는 설정입니다., 추후 문제 발생시 삭제해도 될거같습니다.
  }

}