param(
  [string]$Region = "us-west-2",
  [string]$OutputDir = "terraform"
)

$ErrorActionPreference = "Stop"

if (!(Get-Command aws -ErrorAction SilentlyContinue)) {
  throw "AWS CLI was not found in PATH."
}

if (!(Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$outFile = Join-Path $OutputDir "discovery-$Region.txt"

"# AWS discovery for $Region" | Set-Content -Path $outFile -Encoding UTF8
"# Generated at $(Get-Date -Format o)" | Add-Content -Path $outFile -Encoding UTF8
"" | Add-Content -Path $outFile -Encoding UTF8

function Add-Section {
  param(
    [string]$Title,
    [scriptblock]$Command
  )

  "## $Title" | Add-Content -Path $outFile -Encoding UTF8
  try {
    & $Command 2>&1 | Out-String | Add-Content -Path $outFile -Encoding UTF8
  }
  catch {
    "ERROR: $($_.Exception.Message)" | Add-Content -Path $outFile -Encoding UTF8
  }
  "" | Add-Content -Path $outFile -Encoding UTF8
}

Add-Section "Caller identity" { aws sts get-caller-identity --output table }
Add-Section "VPCs" { aws ec2 describe-vpcs --region $Region --query "Vpcs[].{VpcId:VpcId,CidrBlock:CidrBlock,Name:Tags[?Key=='Name']|[0].Value}" --output table }
Add-Section "Subnets" { aws ec2 describe-subnets --region $Region --query "Subnets[].{SubnetId:SubnetId,VpcId:VpcId,Az:AvailabilityZone,CidrBlock:CidrBlock,Name:Tags[?Key=='Name']|[0].Value}" --output table }
Add-Section "Security groups" { aws ec2 describe-security-groups --region $Region --query "SecurityGroups[].{GroupId:GroupId,VpcId:VpcId,Name:GroupName}" --output table }
Add-Section "ECS clusters" { aws ecs list-clusters --region $Region --output table }
Add-Section "ECR repositories" { aws ecr describe-repositories --region $Region --query "repositories[].{Name:repositoryName,Uri:repositoryUri}" --output table }
Add-Section "ALBs" { aws elbv2 describe-load-balancers --region $Region --query "LoadBalancers[].{Name:LoadBalancerName,Arn:LoadBalancerArn,DNS:DNSName,VpcId:VpcId}" --output table }
Add-Section "DocumentDB clusters" { aws docdb describe-db-clusters --region $Region --query "DBClusters[].{Identifier:DBClusterIdentifier,Arn:DBClusterArn,Endpoint:Endpoint,Status:Status}" --output table }
Add-Section "Lambda functions" { aws lambda list-functions --region $Region --query "Functions[].{Name:FunctionName,Arn:FunctionArn,Runtime:Runtime}" --output table }
Add-Section "API Gateway REST APIs" { aws apigateway get-rest-apis --region $Region --query "items[].{Name:name,Id:id,CreatedDate:createdDate}" --output table }
Add-Section "S3 buckets" { aws s3api list-buckets --query "Buckets[].{Name:Name,Created:CreationDate}" --output table }
Add-Section "CloudFront distributions" { aws cloudfront list-distributions --query "DistributionList.Items[].{Id:Id,Domain:DomainName,Enabled:Enabled,Comment:Comment}" --output table }

Write-Host "Discovery written to $outFile"
