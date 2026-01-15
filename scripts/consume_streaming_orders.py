#!/usr/bin/env python3
"""
Event Hub消息消费测试脚本
用途：读取Event Hub中的消息，验证数据流入
"""

import json
from azure.eventhub import EventHubConsumerClient
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
        sys.exit(1)

def on_event(partition_context, event):
    """处理收到的事件"""
    try:
        event_data = json.loads(event.body_as_str())
        print(f"\n📦 收到消息 (Partition {partition_context.partition_id}):")
        print(f"   Event ID: {event_data.get('event_id')}")
        print(f"   Order ID: {event_data.get('order_id')}")
        print(f"   Customer ID: {event_data.get('customer_id')}")
        print(f"   Amount: ${event_data.get('total_amount')}")
        print(f"   Time: {event_data.get('event_time')}")
        
        # 更新检查点
        partition_context.update_checkpoint(event)
    except Exception as e:
        print(f"❌ 处理消息失败: {e}")

def on_error(partition_context, error):
    """处理错误"""
    if partition_context:
        print(f"❌ Partition {partition_context.partition_id} 错误: {error}")
    else:
        print(f"❌ 错误: {error}")

def main():
    """主函数"""
    print("=== Event Hub消息消费测试 ===\n")
    
    connection_str = load_connection_string()
    eventhub_name = "orders-stream"
    consumer_group = "$Default"
    
    print(f"连接到Event Hub: {eventhub_name}")
    print(f"Consumer Group: {consumer_group}")
    print("开始接收消息...\n")
    print("按 Ctrl+C 停止\n")
    
    client = EventHubConsumerClient.from_connection_string(
        conn_str=connection_str,
        consumer_group=consumer_group,
        eventhub_name=eventhub_name
    )
    
    try:
        with client:
            client.receive(
                on_event=on_event,
                on_error=on_error,
                starting_position="-1"  # 从最新位置开始
            )
    except KeyboardInterrupt:
        print("\n\n⚠️  用户中断")
    finally:
        print("🔒 连接已关闭")

if __name__ == "__main__":
    main()
