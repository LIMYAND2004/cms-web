#!/bin/bash
set -e

echo "🚀 部署 Frontend..."

# 创建共享网络（如果不存在）
if ! docker network ls | grep -q app-network; then
    echo "📡 创建共享网络 app-network..."
    docker network create app-network
fi

# 构建并启动
docker compose pull
docker compose up -d --remove-orphans
docker image prune -f

echo "✅ Frontend 部署完成！"
echo ""
echo "📊 服务状态:"
docker compose ps
