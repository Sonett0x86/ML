# backend/Dockerfile

# 1. 选择基础镜像：官方 Python 3.11 精简版
FROM python:3.11-slim

# 2. 在容器里创建工作目录
WORKDIR /app

# 3. 把根目录下的 requirements.txt 拷进去
COPY requirements.txt /app/requirements.txt

# 4. 安装依赖
RUN pip install --no-cache-dir -r /app/requirements.txt

# 5. 把 backend 代码拷进去
COPY backend /app/backend

# 6. 设置 PYTHONPATH，方便以 "backend.xxx" 方式导入
ENV PYTHONPATH=/app

# 7. 启动命令：用 uvicorn 启动 FastAPI
CMD ["uvicorn", "backend.app:app", "--host", "0.0.0.0", "--port", "8000"]
