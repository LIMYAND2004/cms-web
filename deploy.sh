#!/bin/bash
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 默认镜像标签
IMAGE_TAG="${1:-latest}"

echo "======================================"
echo "🚀 开始部署 Frontend"
echo "======================================"
echo "📦 镜像标签: ${GREEN}${IMAGE_TAG}${NC}"
echo ""

# 创建共享网络（如果不存在）
if ! docker network ls | grep -q app-network; then
    echo "📡 创建共享网络 app-network..."
    docker network create app-network
fi

# 拉取新镜像
echo "📥 拉取镜像 ${IMAGE_TAG}..."
IMAGE_TAG=${IMAGE_TAG} docker compose pull

# 获取旧容器ID（如果存在）
OLD_CONTAINER=$(docker ps -q -f name=frontend-app) || true

# 启动新容器
echo "⚡ 启动新容器..."
IMAGE_TAG=${IMAGE_TAG} docker compose up -d --remove-orphans

# 显示新镜像版本信息
echo ""
echo "📋 镜像信息:"
docker image inspect ghcr.io/limyand2004/frontend:${IMAGE_TAG} --format='  {{.Id}} {{.Created}}' || true
echo ""

# 等待容器启动
echo "⏳ 等待容器启动..."
sleep 5

# 健康检查
echo "🏥 执行健康检查..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if wget --quiet --tries=1 --spider http://localhost/ 2>/dev/null; then
        echo -e "${GREEN}✅ 健康检查通过${NC}"
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo -n "."
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo ""
    echo -e "${RED}❌ 健康检查失败，部署回滚${NC}"

    # 回滚：删除新容器
    IMAGE_TAG=${IMAGE_TAG} docker compose down
    if [ -n "$OLD_CONTAINER" ]; then
        docker start "$OLD_CONTAINER" || true
    fi
    exit 1
fi

# 清理未使用的镜像
echo ""
echo "🧹 清理未使用的镜像..."
docker image prune -f

# 显示服务状态
echo ""
echo "======================================"
echo -e "${GREEN}✅ Frontend 部署完成！${NC}"
echo "======================================"
echo ""
echo "📊 服务状态:"
IMAGE_TAG=${IMAGE_TAG} docker compose ps
echo ""
