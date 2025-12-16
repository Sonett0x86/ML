# backend/app.py

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from .ml_core import get_ts_series, get_history_and_forecast, get_trained_model

# 监控: Prometheus exporter
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI(
    title="House Price Forecast API",
    description="2-bedroom 房价时间序列预测服务（基于 SARIMA 模型）",
    version="1.1.0",
)

# 允许前端跨域访问
# 你现在是 allow_origins=["*"] :contentReference[oaicite:3]{index=3}, 开发阶段没问题.
# 上云后建议改成你的前端域名或反代域名.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 暴露 Prometheus metrics: GET /metrics
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.on_event("startup")
def warmup_on_startup():
    """
    预热: 容器启动时就训练并缓存模型, 避免第一次调用 /forecast 时卡住.
    你的模型训练是第一次请求才训练并缓存 :contentReference[oaicite:4]{index=4},
    上云时更容易因首次请求超时导致体验差, 这里直接预热.
    """
    try:
        get_trained_model()
    except Exception as e:
        # 不阻止容器启动, 但会在日志里看到错误, 便于排查 DB 初始化/数据问题.
        print(">>> warmup_on_startup() failed:", repr(e))


@app.get("/health")
def health_check():
    """
    简单健康检查接口:
    返回当前时间序列的数据点数量, 用于确认服务是否正常.
    """
    ts = get_ts_series()
    return {
        "status": "ok",
        "data_points": len(ts),
    }


@app.get("/forecast")
def forecast(months: int = Query(12, ge=1, le=36)):
    """
    返回最近一段历史数据 + 未来 months 个月的预测结果.
    """
    history_df, forecast_df = get_history_and_forecast(periods=months)
    return {
        "months": months,
        "history": history_df.to_dict(orient="records"),
        "forecast": forecast_df.to_dict(orient="records"),
    }
