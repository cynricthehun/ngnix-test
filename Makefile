.PHONY: dist

aws_region = us-east-2

aws_account_number_dev = 175010803476
aws_account_role_dev = SpaceReqDev

aws_account_number_prod = 660068201761
aws_account_role_prod = SpaceReqProd

# AWS ECR Registry values
ecr_registry_dev = $(aws_account_number_dev).dkr.ecr.$(aws_region).amazonaws.com
ecr_registry_prod = $(aws_account_number_prod).dkr.ecr.$(aws_region).amazonaws.com

# AWS ECR REPO Names (repo names are defined by our terraform code)
aws_ecr_dev_repo_name = nginx_container
aws_ecr_prod_repo_name = nginx_container

# docker image names
docker_dev_image_name = nginx
docker_prod_image_name = nginx

# docker tags
last_git_commit_hash = `git log -n1 --format=format:"%h"`

aws-login-dev:
	aws login --region $(aws_region) --role-arn "arn:aws:iam::$(aws_account_number_dev):role/$(aws_account_role_dev)"

aws-login-prod:
	aws login --region $(aws_region) --role-arn "arn:aws:iam::$(aws_account_number_prod):role/$(aws_account_role_prod)"

all: dist

dist:
	# Make the RPM file
	rpmbuild -bb IC2gCorrelation.spec
	# Let the service user read my RPM files.
	chmod 644 *.rpm

perms:
	# Make sure files and directories are world-readable
	find . -type f | xargs chmod go+r
	find . -type d | xargs chmod 755

docker-tag-dev:
	# tagging local docker image with latest and the last git commit hash digest
	docker tag $(docker_dev_image_name):latest $(ecr_registry_dev)/$(aws_ecr_dev_repo_name):latest
	docker tag $(docker_dev_image_name):latest $(ecr_registry_dev)/$(aws_ecr_dev_repo_name):$(last_git_commit_hash)

docker-tag-prod:
	# tagging local docker image with latest and the last git commit hash digest
	docker tag $(docker_prod_image_name):latest $(ecr_registry_prod)/$(aws_ecr_prod_repo_name):latest
	docker tag $(docker_prod_image_name):latest $(ecr_registry_prod)/$(aws_ecr_prod_repo_name):$(last_git_commit_hash)

pull-dev-nginx:
	docker pull nginx

docker-build-dev:
	docker build -f Dockerfile -t nginx:latest .

deploy-dev: aws-login-dev docker-build-dev docker-tag-dev
	# auto docker login using aws creds
	aws ecr get-login-password --region $(aws_region) | docker login --username AWS --password-stdin $(ecr_registry_dev)

	# pushing docker image to ecr (with tags)
	docker push --all-tags $(ecr_registry_dev)/$(aws_ecr_dev_repo_name)
