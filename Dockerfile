# 使用轻量级的 nginx alpine 镜像（约 23MB）
FROM nginx:alpine

# 维护者信息
LABEL maintainer="返利助手"
LABEL description="返利助手 - 省钱购物好帮手"

# 移除默认的 nginx 配置
RUN rm -rf /usr/share/nginx/html/* \
    && rm /etc/nginx/conf.d/default.conf

# 复制自定义 nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 复制静态网站文件到 nginx 默认目录
COPY index.html /usr/share/nginx/html/
COPY main.css /usr/share/nginx/html/
COPY robots.txt /usr/share/nginx/html/
COPY root.txt /usr/share/nginx/html/
COPY img/ /usr/share/nginx/html/img/
COPY js/ /usr/share/nginx/html/js/

# 暴露 80 端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
