#!/usr/bin/env python3
"""
实时订单流数据模拟器（教学稳定版）
包含：
1) 新订单（new_stream）
2) 延迟到达的重复订单（delayed_batch）
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from faker import Faker
import random
import pyarrow as pa
import pyarrow.parquet as pq
import os
import glob

# ------------------------
# 基础初始化
# ------------------------
fake = Faker()
Faker.seed(42)
np.random.seed(42)
random.seed(42)

OUTPUT_DIR = "./output"

# ------------------------
# 核心生成函数
# ------------------------
def generate_streaming_orders(
    num_orders=100,
    hour_offset=0,
    delayed_orders=None
):
    """
    生成指定小时的订单流数据
    - 70% 新订单
    - 30% 延迟重复订单（如果 delayed_orders 不为空）
    """

    now = datetime.now()
    target_hour = now - timedelta(hours=hour_offset)
    base_ts = target_hour.replace(minute=0, second=0, microsecond=0)

    orders = []

    # ------------------------
    # 1️⃣ 新订单
    # ------------------------
    num_new = int(num_orders * 0.7)

    for i in range(num_new):
        order_ts = base_ts + timedelta(
            minutes=random.randint(0, 59),
            seconds=random.randint(0, 59)
        )

        total_amount = round(
            sum(
                random.randint(1, 3) * random.uniform(10, 500)
                for _ in range(random.randint(1, 5))
            ),
            2
        )

        orders.append({
            "order_id": f"STREAM_{target_hour.strftime('%Y%m%d%H')}_{i+1:05d}",
            "customer_id": random.randint(1, 10000),
            "order_date": order_ts.date(),
            "order_datetime": order_ts,
            "total_amount": total_amount,
            "order_type": "new_stream",
            "year": target_hour.year,
            "month": target_hour.month,
            "day": target_hour.day,
            "hour": target_hour.hour,
            "order_ts": int(order_ts.timestamp())
        })

    # ------------------------
    # 2️⃣ 延迟重复订单
    # ------------------------
    if delayed_orders is not None and not delayed_orders.empty:
        num_delayed = int(num_orders * 0.3)

        delayed_sample = delayed_orders.sample(
            n=min(num_delayed, len(delayed_orders)),
            random_state=42
        )

        for _, row in delayed_sample.iterrows():
            order_ts = base_ts + timedelta(
                minutes=random.randint(0, 59),
                seconds=random.randint(0, 59)
            )

            orders.append({
                "order_id": str(row["order_id"]),   # 🔑 保持相同 ID → 重复
                "customer_id": int(row["customer_id"]),
                "order_date": order_ts.date(),
                "order_datetime": order_ts,
                "total_amount": float(row["total_amount"]),
                "order_type": "delayed_batch",
                "year": target_hour.year,
                "month": target_hour.month,
                "day": target_hour.day,
                "hour": target_hour.hour,
                "order_ts": int(order_ts.timestamp())
            })

        print(f"  └─ 延迟重复订单: {len(delayed_sample)}")

    return pd.DataFrame(orders)


# ------------------------
# 保存函数
# ------------------------
def save_to_parquet(df, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    y, m, d, h = (
        df.iloc[0]["year"],
        df.iloc[0]["month"],
        df.iloc[0]["day"],
        df.iloc[0]["hour"]
    )

    filename = f"orders_streaming_{y:04d}{m:02d}{d:02d}{h:02d}.parquet"
    path = os.path.join(output_dir, filename)

    pq.write_table(pa.Table.from_pandas(df), path)

    print(f"✅ 写入 {path}")
    print(
        f"   新订单: {len(df[df.order_type == 'new_stream'])} | "
        f"延迟订单: {len(df[df.order_type == 'delayed_batch'])}"
    )


# ------------------------
# 主流程（关键）
# ------------------------
def main():
    print("=" * 60)
    print("实时订单流数据生成（稳定重复版）")
    print("=" * 60)

    delayed_pool = None

    # 过去 6 小时
    for hour_offset in range(6, 0, -1):
        print(f"\n生成 -{hour_offset} 小时数据")
        df = generate_streaming_orders(
            num_orders=random.randint(80, 120),
            hour_offset=hour_offset,
            delayed_orders=delayed_pool
        )
        save_to_parquet(df, OUTPUT_DIR)

        # 🔑 用第一批数据作为“延迟池”
        if delayed_pool is None:
            delayed_pool = df.copy()

    # 当前小时
    print("\n生成 当前小时 数据")
    df = generate_streaming_orders(
        num_orders=100,
        hour_offset=0,
        delayed_orders=delayed_pool
    )
    save_to_parquet(df, OUTPUT_DIR)

    print("\n✅ 数据生成完成")


# ------------------------
if __name__ == "__main__":
    main()

