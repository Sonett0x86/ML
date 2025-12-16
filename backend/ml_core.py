# backend/ml_core.py
# 从 MySQL 读取 raw_sales → 构建时间序列 → 训练 SARIMA → 提供历史+预测

import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX

from .db import load_raw_data_from_db

_ts_cache: pd.DataFrame | None = None
_model_cache = None


def load_raw_data() -> pd.DataFrame:
    df = load_raw_data_from_db()
    # 再保险: 统一列名
    df.columns = [c.strip().lower() for c in df.columns]

    print(">>> load_raw_data() from DB: rows =", len(df))
    print(">>> columns:", list(df.columns))
    return df


def build_monthly_ts(df: pd.DataFrame) -> pd.DataFrame:
    """
    构建“2-bedroom house”的月度平均价格时间序列。
    """
    if df is None or df.empty:
        print(">>> ERROR: input df is empty in build_monthly_ts().")
        return pd.DataFrame(columns=["price", "price_filled"])

    # 确保字段存在
    required = {"datesold", "price", "bedrooms", "propertytype"}
    missing = required - set(df.columns)
    if missing:
        print(">>> ERROR: missing columns:", missing)
        return pd.DataFrame(columns=["price", "price_filled"])

    # 类型再保证一遍
    df["datesold"] = pd.to_datetime(df["datesold"], errors="coerce")
    df["price"] = pd.to_numeric(df["price"], errors="coerce")
    df["bedrooms"] = pd.to_numeric(df["bedrooms"], errors="coerce")
    df["propertytype"] = df["propertytype"].astype(str).str.strip().str.lower()

    df = df.dropna(subset=["datesold", "price", "bedrooms", "propertytype"]).copy()
    df = df.sort_values("datesold")

    print(">>> propertytype value counts (top):")
    print(df["propertytype"].value_counts().head())
    print(">>> bedrooms value counts (top):")
    print(df["bedrooms"].value_counts().head())

    # 过滤: 2-bedroom house
    df_2b = df[(df["propertytype"] == "house") & (df["bedrooms"] == 2)].copy()
    print(">>> filter(2-bedroom & house) rows:", len(df_2b))

    # 回退: bedrooms==2
    if df_2b.empty:
        df_2b = df[df["bedrooms"] == 2].copy()
        print(">>> fallback filter(bedrooms==2) rows:", len(df_2b))

    # 回退: 全量
    if df_2b.empty:
        df_2b = df.copy()
        print(">>> fallback filter(all rows) rows:", len(df_2b))

    if df_2b.empty:
        print(">>> ERROR: no valid rows after normalization.")
        return pd.DataFrame(columns=["price", "price_filled"])

    df_2b_ts = df_2b.set_index("datesold")
    ts_month = df_2b_ts["price"].resample("ME").mean().to_frame(name="price")
    ts_month["price_filled"] = ts_month["price"].ffill()

    print(">>> build_monthly_ts(): points =", len(ts_month))
    print(ts_month.head())

    return ts_month


def get_ts_series() -> pd.DataFrame:
    global _ts_cache
    if _ts_cache is None:
        raw_df = load_raw_data()
        _ts_cache = build_monthly_ts(raw_df)
    return _ts_cache


def train_sarima_model(ts_month: pd.DataFrame):
    if ts_month is None or ts_month.empty:
        raise ValueError("Time series is empty (ts_month).")

    y = ts_month["price_filled"] if "price_filled" in ts_month.columns else ts_month["price"]
    y = pd.to_numeric(y, errors="coerce").astype("float64").dropna()

    print(">>> train_sarima_model(): len(y) =", len(y))

    if len(y) < 24:
        raise ValueError(f"Not enough data points to train SARIMA, got only {len(y)}")

    model = SARIMAX(
        y,
        order=(1, 1, 0),
        seasonal_order=(0, 1, 0, 12),
        enforce_stationarity=False,
        enforce_invertibility=False,
    )
    results = model.fit(disp=False)
    return results


def get_trained_model():
    global _model_cache
    if _model_cache is None:
        ts_month = get_ts_series()
        _model_cache = train_sarima_model(ts_month)
    return _model_cache


def make_forecast(periods: int = 12) -> pd.DataFrame:
    model = get_trained_model()
    forecast_res = model.get_forecast(steps=periods)
    forecast_mean = forecast_res.predicted_mean

    forecast_df = forecast_mean.reset_index()
    forecast_df.columns = ["date", "price"]
    return forecast_df


def get_history_and_forecast(periods: int = 12, history_months: int | None = None):
    ts = get_ts_series()
    if ts is None or ts.empty:
        raise ValueError("Time series is empty, cannot produce forecast.")

    price_col = "price_filled" if "price_filled" in ts.columns else "price"
    ts = ts.sort_index()
    history_series = ts[price_col]

    if history_months is not None and history_months > 0:
        history_series = history_series.iloc[-history_months:]

    history_df = history_series.reset_index()
    history_df.columns = ["date", "price"]

    forecast_df = make_forecast(periods=periods)
    return history_df, forecast_df
