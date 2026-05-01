#!/bin/bash

# ============================================
# 返利助手 - Docker 镜像构建与推送脚本
# ============================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 镜像配置
REGISTRY="crpi-t48mrc123gu0aqxt.cn-hangzhou.personal.cr.aliyuncs.com"
NAMESPACE="csimg"
IMAGE_NAME="fanli-heoweb"
FULL_IMAGE="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}"

# 版本号：优先使用传入参数，否则使用时间戳
if [ -n "$1" ]; then
    VERSION="v$1"
else
    VERSION="v$(date +%Y%m%d%H%M)"
fi

# 完整镜像标签
IMAGE_TAG="${FULL_IMAGE}:${VERSION}"
IMAGE_LATEST="${FULL_IMAGE}:latest"

# 打印配置信息
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  返利助手 Docker 镜像构建脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}镜像仓库:${NC} ${REGISTRY}"
echo -e "${YELLOW}命名空间:${NC} ${NAMESPACE}"
echo -e "${YELLOW}镜像名称:${NC} ${IMAGE_NAME}"
echo -e "${YELLOW}版本标签:${NC} ${VERSION}"
echo -e "${YELLOW}完整标签:${NC} ${IMAGE_TAG}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 切换到脚本所在目录
cd "$(dirname "$0")"

# Step 1: 检查 Docker 是否运行
echo -e "${GREEN}[1/5] 检查 Docker 环境...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}错误: Docker 未运行，请先启动 Docker${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker 环境正常${NC}"
echo ""

# Step 2: 构建镜像
echo -e "${GREEN}[2/5] 构建镜像 ${IMAGE_TAG}...${NC}"
docker build \
    --platform linux/amd64 \
    -t "${IMAGE_TAG}" \
    -t "${IMAGE_LATEST}" \
    -f Dockerfile \
    .

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 镜像构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 镜像构建成功${NC}"
echo ""

# Step 3: 查看镜像大小
echo -e "${GREEN}[3/5] 镜像信息:${NC}"
docker images "${FULL_IMAGE}" | head -n 5
echo ""

# Step 4: 询问是否推送
read -p "$(echo -e ${YELLOW}是否推送到远程仓库? [y/N]: ${NC})" -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}已跳过推送${NC}"
    echo -e "${GREEN}本地运行命令:${NC}"
    echo -e "  docker run -d -p 8080:80 --name fanli-web ${IMAGE_TAG}"
    exit 0
fi

# Step 5: 推送镜像
echo -e "${GREEN}[4/5] 登录阿里云镜像仓库...${NC}"
echo -e "${YELLOW}提示: 如未登录，请执行 docker login ${REGISTRY}${NC}"

echo -e "${GREEN}[5/5] 推送镜像到仓库...${NC}"
docker push "${IMAGE_TAG}"
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 版本镜像推送失败${NC}"
    echo -e "${YELLOW}请先执行: docker login ${REGISTRY}${NC}"
    exit 1
fi

docker push "${IMAGE_LATEST}"
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ latest 镜像推送失败${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ 镜像推送成功!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}镜像地址:${NC}"
echo -e "  ${IMAGE_TAG}"
echo -e "  ${IMAGE_LATEST}"
echo ""
echo -e "${YELLOW}拉取并运行:${NC}"
echo -e "  docker pull ${IMAGE_TAG}"
echo -e "  docker run -d -p 80:80 --name fanli-web ${IMAGE_TAG}"
echo -e "${GREEN}========================================${NC}"
