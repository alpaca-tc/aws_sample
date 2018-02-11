image_name=nginx_http2https
repo=016559158979.dkr.ecr.ap-northeast-1.amazonaws.com/nginx_http2https

build:
	docker build -t $(image_name) .

run:
	docker run -p 3000:80 -it ${image_name}:latest

tag: build
	docker tag $(image_name):latest $(repo):latest

# ログインが必要な場合は `$(aws ecr get-login --no-include-email --region ap-northeast-1)`
push: tag
	docker push $(repo):latest
