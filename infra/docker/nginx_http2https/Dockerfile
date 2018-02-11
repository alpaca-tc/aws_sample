# Nginxコンテナ
# - HTTPで来たリクエストをHTTPSにリダイレクトする
# - www.から始まるドメインのリクエストをwww.を削除してリダイレクトする
FROM nginx:1.13.8-alpine

EXPOSE 80

COPY nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
