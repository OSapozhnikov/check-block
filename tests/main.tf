provider "aws" {
  region  = "us-west-2"
  profile = "main-test"
}

data "aws_instance" "instance" {
  filter {
    name   = "tag:Demo"
    values = ["true"]
  }
}
# Tests
check "instance_state" {
  assert {
    condition = data.aws_instance.instance.instance_state == "running"
    error_message = "ERROR: Instance ${data.aws_instance.instance.arn} stopped!"
  }
}

check "associate_public_ip_address" {
  assert {
    condition = data.aws_instance.instance.associate_public_ip_address == false
    error_message = "ERROR: Instance ${data.aws_instance.instance.arn} without public IP!"
  }
}

check "key_name" {
  assert {
    condition = data.aws_instance.instance.key_name == "temabitt"
    error_message = "ERROR: Instance ${data.aws_instance.instance.arn} have a wrong key_name!"
  }
}

check "monitoring" {
  assert {
    condition = data.aws_instance.instance.monitoring == false
    error_message = "ERROR: Instance ${data.aws_instance.instance.arn} without monitoring!"
  }
}

# Check for unused IAM roles (aws_iam_role)
locals {
  unused_limit = timeadd(timestamp(), "-720h")
}

check "check_iam_role_unused" {
  data "aws_iam_role" "example" {
    name = "app-lightlytics-init-stac-LightlyticsInitLambdaRol-QSK22CC5XMV0"
  }

  assert {
    condition = (
      timecmp(
        coalesce(data.aws_iam_role.example.role_last_used[0].last_used_date, local.unused_limit),
        local.unused_limit,
      ) > 0
    )
    error_message = format("ERROR: AWS IAM role '%s' is unused in the last 30 days!",
      data.aws_iam_role.example.name,
    )
  }
}

# service status
check "osm" {
  data "http" "nominatim" {
    url      = "https://nominatim.openstreetmap.org.ua/status.php?format=json"
    insecure = false
  }

  assert {
    condition     = data.http.nominatim.status_code == 300
    error_message = "ERROR: Nominatim response is ${data.http.nominatim.status_code}"
  }
}
