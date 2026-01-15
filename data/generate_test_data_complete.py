"""
Day 7 完整测试数据生成器
生成4个关联正确的测试文件
"""

import pandas as pd
import random
from datetime import datetime, timedelta

print("🎯 生成Day 7完整测试数据集...")

# 1. 生成test_customers（500条）
print("📊 生成 test_customers.csv...")
test_customers = pd.DataFrame({
    'customer_id': range(20001, 20501),
    'first_name': [f'Test{i}' for i in range(500)],
    'last_name': [f'User{i}' for i in range(500)],
    'email': [f'test{i}@test.com' for i in range(500)],
    'city': random.choices(['Stockholm', 'Gothenburg', 'Malmo'], k=500),
    'country': ['Sweden'] * 500,
    'registration_date': [(datetime.now() - timedelta(days=random.randint(0, 365))).strftime('%Y-%m-%d') for _ in range(500)]
})
test_customers.to_csv('test_customers.csv', index=False)
print(f"✅ test_customers.csv: {len(test_customers)} rows")

# 2. 生成test_products（100条，从原数据中抽样）
print("📊 生成 test_products.csv...")
test_products = pd.DataFrame({
    'product_id': range(5001, 5101),  # 新的product_id范围
    'product_name': [f'Test Product {i}' for i in range(100)],
    'category': random.choices(['Electronics', 'Clothing', 'Books', 'Home'], k=100),
    'price': [round(random.uniform(10, 500), 2) for _ in range(100)],
    'stock_quantity': [random.randint(0, 1000) for _ in range(100)]
})
test_products.to_csv('test_products.csv', index=False)
print(f"✅ test_products.csv: {len(test_products)} rows")

# 3. 生成test_orders（500条）
print("📊 生成 test_orders.csv...")
test_orders = pd.DataFrame({
    'order_id': range(50001, 50501),
    'customer_id': random.choices(range(20001, 20501), k=500),  # 关联到test_customers
    'order_date': [(datetime.now() - timedelta(days=random.randint(0, 30))).strftime('%Y-%m-%d %H:%M:%S') for _ in range(500)],
    'order_status': random.choices(['pending', 'completed', 'cancelled'], k=500)
})
test_orders.to_csv('test_orders.csv', index=False)
print(f"✅ test_orders.csv: {len(test_orders)} rows")

# 4. 生成test_order_items（1000-1500条，每个订单2-3个商品）
print("📊 生成 test_order_items.csv...")
order_items = []
order_item_id = 100001

for order_id in range(50001, 50501):
    num_items = random.randint(2, 3)  # 每个订单2-3个商品
    for _ in range(num_items):
        order_items.append({
            'order_item_id': order_item_id,
            'order_id': order_id,  # 关联到test_orders
            'product_id': random.choice(range(5001, 5101)),  # 关联到test_products
            'quantity': random.randint(1, 3),
            'unit_price': round(random.uniform(10, 500), 2)
        })
        order_item_id += 1

test_order_items = pd.DataFrame(order_items)
test_order_items.to_csv('test_order_items.csv', index=False)
print(f"✅ test_order_items.csv: {len(test_order_items)} rows")

# 生成数据摘要
print("\n📋 测试数据摘要:")
print(f"  - test_customers: 500 rows (ID: 20001-20500)")
print(f"  - test_products: 100 rows (ID: 5001-5100)")
print(f"  - test_orders: 500 rows (ID: 50001-50500)")
print(f"  - test_order_items: {len(test_order_items)} rows (ID: 100001+)")
print("\n✅ 所有测试数据生成完成！")
