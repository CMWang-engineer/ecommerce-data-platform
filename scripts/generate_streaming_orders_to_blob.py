#!/usr/bin/env python3
"""
实时订单生成器 - 直接写入Blob Storage
简化版本：不使用Event Hub Capture
"""

import json
import time
import random
from datetime import datetime
from azure.storage.blob import BlobServiceClient
import os

def generate_order_event():
    """生成订单事件"""
    now = datetime.utcnow()
    order_event = {
        "event_id": f"evt_{now.strftime('%Y%m%d%H%M%S')}_{random.randint(1000, 9999)}",
        "event_time": now.isoformat() + "Z",
        "order_id": random.randint(100001, 999999),
        "customer_id": random.randint(1, 10000),
        "product_id": random.randint(1, 500),
        "quantity": random.randint(1, 5),
        "unit_price": round(random.uniform(10.0, 500.0), 2),
        "status": "pending",
        "order_date": now.isoformat() + "Z",
        "year": now.year,
        "month": now.month,
        "day": now.day,
        "hour": now.hour
    }
    order_event["total_amount"] = round(order_event["quantity"] * order_event["unit_price"], 2)
    return order_event

def main():
    print("=== 流式订单生成器（写入Blob Storage）===\n")
    
    # 配置
    storage_name = os.getenv("STORAGE_NAME", "lemondata1766854279")
    container_name = "streaming"
    
    # 连接Storage
    blob_service_client = BlobServiceClient(
        account_url=f"https://{storage_name}.blob.core.windows.net",
        credential=None  # 使用DefaultAzureCredential
    )
    
    print("选择模式:")
    print("1. 测试模式（生成10条记录）")
    print("2. 持续模式（每秒1-3条）")
    print("3. 批量模式（一次性生成N条）")
    
    choice = input("\n选择 (1/2/3): ").strip()
    
    if choice == "1":
        # 测试模式
        orders = [generate_order_event() for _ in range(10)]
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        blob_name = f"raw/orders_{timestamp}.json"
        
        blob_client = blob_service_client.get_blob_client(container_name, blob_name)
        blob_client.upload_blob(
            json.dumps(orders, indent=2),
            overwrite=True
        )
        
        print(f"✅ 已写入10条记录到: {blob_name}")
        
    elif choice == "2":
        # 持续模式
        print("\n🚀 持续模式启动（Ctrl+C停止）\n")
        total = 0
        batch = []
        
        try:
            while True:
                order = generate_order_event()
                batch.append(order)
                total += 1
                
                # 每10条或每30秒写入一次
                if len(batch) >= 10:
                    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
                    blob_name = f"raw/orders_{timestamp}.json"
                    
                    blob_client = blob_service_client.get_blob_client(container_name, blob_name)
                    blob_client.upload_blob(
                        json.dumps(batch, indent=2),
                        overwrite=True
                    )
                    
                    print(f"✅ 已写入 {len(batch)} 条，总计 {total} 条")
                    batch = []
                
                time.sleep(random.uniform(0.5, 2.0))
                
        except KeyboardInterrupt:
            # 写入剩余的
            if batch:
                timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
                blob_name = f"raw/orders_{timestamp}.json"
                blob_client = blob_service_client.get_blob_client(container_name, blob_name)
                blob_client.upload_blob(json.dumps(batch, indent=2), overwrite=True)
                print(f"\n✅ 最后写入 {len(batch)} 条")
            
            print(f"\n总计生成: {total} 条订单")
            
    elif choice == "3":
        # 批量模式
        num = int(input("生成数量: "))
        orders = [generate_order_event() for _ in range(num)]
        
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        blob_name = f"raw/orders_{timestamp}.json"
        
        blob_client = blob_service_client.get_blob_client(container_name, blob_name)
        blob_client.upload_blob(
            json.dumps(orders, indent=2),
            overwrite=True
        )
        
        print(f"✅ 已写入 {num} 条记录到: {blob_name}")

if __name__ == "__main__":
    main()
