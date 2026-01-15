#!/usr/bin/env python3
import json
import time
import random
from datetime import datetime, timedelta
from azure.eventhub import EventHubProducerClient, EventData
import sys
import os

def load_connection_string():
    """从文件加载Event Hub连接字符串"""
    conn_file = os.path.expanduser("~/ecommerce-data-platform/secrets/eventhub_connection.txt")
    try:
        with open(conn_file, 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        print(f"❌ 错误：找不到连接字符串文件: {conn_file}")
        print("请先运行任务1.2获取连接字符串")
        sys.exit(1)

def generate_order_event():
    """生成一个模拟订单事件"""
    now = datetime.utcnow()
    
    # 从现有数据中随机选择（模拟真实场景）
    customer_ids = list(range(1, 10001))  # 10000个客户
    product_ids = list(range(1, 501))     # 500个产品
    
    order_event = {
        "event_type": "order_created",
        "event_id": f"evt_{now.strftime('%Y%m%d%H%M%S')}_{random.randint(1000, 9999)}",
        "event_time": now.isoformat() + "Z",
        "order_id": random.randint(100001, 999999),
        "customer_id": random.choice(customer_ids),
        "product_id": random.choice(product_ids),
        "quantity": random.randint(1, 5),
        "unit_price": round(random.uniform(10.0, 500.0), 2),
        "total_amount": 0,  # 后面计算
        "status": "pending",
        "order_date": now.isoformat() + "Z",
        "year": now.year,
        "month": now.month,
        "day": now.day,
        "hour": now.hour
    }
    
    # 计算总金额
    order_event["total_amount"] = round(
        order_event["quantity"] * order_event["unit_price"], 
        2
    )
    
    return order_event

def send_events_batch(producer, num_events=10):
    """批量发送事件"""
    event_data_batch = producer.create_batch()
    
    for i in range(num_events):
        order = generate_order_event()
        event_data = EventData(json.dumps(order))
        
        try:
            event_data_batch.add(event_data)
        except ValueError:
            # 批次已满，先发送
            producer.send_batch(event_data_batch)
            event_data_batch = producer.create_batch()
            event_data_batch.add(event_data)
    
    # 发送最后一批
    if len(event_data_batch) > 0:
        producer.send_batch(event_data_batch)
    
    return num_events

def main():
    """主函数"""
    print("=== 实时订单流数据生成器 ===\n")
    
    # 加载连接字符串
    connection_str = load_connection_string()
    eventhub_name = "orders-stream"
    
    # 用户输入参数
    print("请选择运行模式：")
    print("1. 测试模式（发送10条消息后停止）")
    print("2. 持续模式（每秒发送1-3条消息，按Ctrl+C停止）")
    print("3. 批量模式（一次性发送大量消息）")
    
    choice = input("\n请输入选择 (1/2/3): ").strip()
    
    # 创建生产者客户端
    print(f"\n连接到Event Hub: {eventhub_name}...")
    producer = EventHubProducerClient.from_connection_string(
        conn_str=connection_str,
        eventhub_name=eventhub_name
    )
    
    try:
        if choice == "1":
            # 测试模式
            print("\n🚀 测试模式：发送10条消息...\n")
            sent = send_events_batch(producer, 10)
            print(f"✅ 成功发送 {sent} 条消息")
            
        elif choice == "2":
            # 持续模式
            print("\n🚀 持续模式：开始发送实时订单...")
            print("按 Ctrl+C 停止\n")
            
            total_sent = 0
            start_time = time.time()
            
            while True:
                num_events = random.randint(1, 3)
                sent = send_events_batch(producer, num_events)
                total_sent += sent
                
                elapsed = time.time() - start_time
                rate = total_sent / elapsed if elapsed > 0 else 0
                
                print(f"✅ 已发送 {total_sent} 条消息 | "
                      f"速率: {rate:.1f} 消息/秒 | "
                      f"时间: {elapsed:.0f}秒", end='\r')
                
                time.sleep(random.uniform(0.5, 2.0))
                
        elif choice == "3":
            # 批量模式
            num_messages = int(input("\n请输入要发送的消息数量: "))
            batch_size = 100  # 每批100条
            
            print(f"\n🚀 批量模式：发送 {num_messages} 条消息...")
            
            total_sent = 0
            start_time = time.time()
            
            while total_sent < num_messages:
                remaining = num_messages - total_sent
                current_batch = min(batch_size, remaining)
                
                sent = send_events_batch(producer, current_batch)
                total_sent += sent
                
                progress = (total_sent / num_messages) * 100
                print(f"进度: {progress:.1f}% ({total_sent}/{num_messages})", end='\r')
            
            elapsed = time.time() - start_time
            rate = total_sent / elapsed
            
            print(f"\n✅ 完成！发送 {total_sent} 条消息，"
                  f"用时 {elapsed:.1f}秒，"
                  f"平均速率 {rate:.1f} 消息/秒")
        else:
            print("❌ 无效选择")
            
    except KeyboardInterrupt:
        print("\n\n⚠️  用户中断，停止发送")
    except Exception as e:
        print(f"\n❌ 错误: {e}")
    finally:
        producer.close()
        print("\n🔒 连接已关闭")

if __name__ == "__main__":
    main()
