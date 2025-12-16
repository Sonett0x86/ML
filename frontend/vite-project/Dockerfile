# frontend/vite-project/Dockerfile

# 1. 选一个 Node 环境
FROM node:20-alpine

# 2. 工作目录
WORKDIR /app

# 3. 先拷 package.json / package-lock.json，方便利用缓存
COPY package*.json ./

# 4. 安装依赖
RUN npm install

# 5. 再拷贝剩下的前端代码
COPY . .

# 6. 暴露 Vite 默认端口
EXPOSE 5173

# 7. 用 Vite dev server 启动，监听 0.0.0.0，方便宿主机访问
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
