# backend/db.py
import os
import pymysql
import pandas as pd

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "db"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "123456"),
    "database": os.getenv("DB_NAME", "house_prices"),
    "charset": "utf8mb4",
}


def get_connection():
    return pymysql.connect(
        host=DB_CONFIG["host"],
        port=DB_CONFIG["port"],
        user=DB_CONFIG["user"],
        password=DB_CONFIG["password"],
        database=DB_CONFIG["database"],
        charset=DB_CONFIG["charset"],
    )


def load_raw_data_from_db() -> pd.DataFrame:
    """
    从 MySQL 读取 raw_sales, 并清洗脏行(尤其是 CSV 表头行被导入的情况)。
    最终返回列: datesold, postcode, price, propertytype, bedrooms
    """
    sql = """
        SELECT
            datesold,
            postcode,
            price,
            propertyType AS propertytype,
            bedrooms
        FROM raw_sales
    """

    conn = get_connection()
    try:
        df = pd.read_sql(sql, conn)
        # 统一列名小写
        df.columns = [c.strip().lower() for c in df.columns]

        print(">>> load_raw_data_from_db() raw rows:", len(df))
        print(">>> columns:", list(df.columns))

        # 先把关键列统一成字符串用于识别“表头行”等脏数据
        for col in ["datesold", "postcode", "price", "bedrooms", "propertytype"]:
            if col in df.columns:
                df[col] = df[col].astype(str).str.strip()

        # 1) 删除明显的“表头行”(被当成数据导入)
        #    例如: postcode == 'postcode', price == 'price', bedrooms == 'bedrooms', propertytype == 'propertyType'
        bad_header = (
            (df["postcode"].str.lower() == "postcode")
            | (df["price"].str.lower() == "price")
            | (df["bedrooms"].str.lower() == "bedrooms")
            | (df["propertytype"].str.lower().isin(["propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype", "propertytype"]))
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["datesold"].str.lower() == "datesold")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
            | (df["propertytype"].str.lower() == "propertytype")
        )
        # 额外识别 propertytype 为 'propertyType' 的情况
        bad_header = bad_header | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype")
        bad_header = bad_header | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype") | (df["propertytype"].str.lower() == "propertytype")
        bad_header = bad_header | (df["propertytype"].str.lower() == "propertytype")  # 兜底
        bad_header = bad_header | (df["propertytype"].str.lower() == "propertytype")

        # 更直接的兜底: 如果某行 price 不是数字, bedrooms 不是数字, 也视为脏行
        # (先不转 numeric, 用正则简单判断)
        non_numeric_price = ~df["price"].str.match(r"^\d+(\.\d+)?$", na=False)
        non_numeric_bed = ~df["bedrooms"].str.match(r"^\d+(\.\d+)?$", na=False)
        bad_header = bad_header | (non_numeric_price & non_numeric_bed)

        df = df[~bad_header].copy()

        # 2) 类型转换
        df["datesold"] = pd.to_datetime(df["datesold"], errors="coerce")
        df["postcode"] = pd.to_numeric(df["postcode"], errors="coerce")
        df["price"] = pd.to_numeric(df["price"], errors="coerce")
        df["bedrooms"] = pd.to_numeric(df["bedrooms"], errors="coerce")
        df["propertytype"] = df["propertytype"].astype(str).str.strip().str.lower()

        # 3) 丢弃关键字段无效行
        df = df.dropna(subset=["datesold", "price", "bedrooms", "propertytype"])

        # 4) 再做一些合理过滤(可选, 防止极端脏数据)
        df = df[df["price"] > 0]
        df = df[df["bedrooms"] >= 0]

        print(">>> load_raw_data_from_db() cleaned rows:", len(df))
        print(df.head())

        return df

    finally:
        conn.close()
