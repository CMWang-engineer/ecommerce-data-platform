"""
E-Commerce Data Generator
生成电商平台的测试数据
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os

np.random.seed(42)
random.seed(42)

def generate_customers(n=10000):
    print(f"生成 {n} 条客户数据...")
    countries = ['Sweden', 'Netherlands', 'Germany', 'Denmark', 'Norway']
    cities_map = {
        'Sweden': ['Stockholm', 'Gothenburg', 'Malmö', 'Uppsala'],
        'Netherlands': ['Amsterdam', 'Rotterdam', 'The Hague', 'Utrecht'],
        'Germany': ['Berlin', 'Munich', 'Hamburg', 'Frankfurt'],
        'Denmark': ['Copenhagen', 'Aarhus', 'Odense'],
        'Norway': ['Oslo', 'Bergen', 'Trondheim']
    }
    
    customers = []
    for i in range(1, n+1):
        country = random.choice(countries)
        city = random.choice(cities_map[country])
        customer = {
            'customer_id': i,
            'first_name': f'Customer{i}',
            'last_name': f'Last{i}',
            'email': f'customer{i}@example.com',
            'country': country,
            'city': city,
            'registration_date': (datetime.now() - timedelta(days=random.randint(1, 730))).strftime('%Y-%m-%d'),
            'customer_segment': random.choice(['Premium', 'Standard', 'Standard', 'Basic']),
            'is_active': random.choice([True, True, True, False])
        }
        customers.append(customer)
    return pd.DataFrame(customers)

def generate_products(n=1000):
    print(f"生成 {n} 条产品数据...")
    categories = ['Electronics', 'Clothing', 'Home & Garden', 'Sports', 'Books']
    products = []
    for i in range(1, n+1):
        category = random.choice(categories)
        price = round(random.uniform(10, 500), 2)
        product = {
            'product_id': i,
            'product_name': f'{category} Product {i}',
            'category': category,
            'price': price,
            'cost': round(price * 0.6, 2),
            'stock_quantity': random.randint(0, 1000),
            'supplier_id': random.randint(1, 50)
        }
        products.append(product)
    return pd.DataFrame(products)

def generate_orders(customers_df, n=50000):
    print(f"生成 {n} 条订单数据...")
    start_date = datetime.now() - timedelta(days=365)
    orders = []
    for i in range(1, n+1):
        customer_id = random.choice(customers_df['customer_id'].tolist())
        order_date = start_date + timedelta(days=random.randint(0, 365))
        order = {
            'order_id': i,
            'customer_id': customer_id,
            'order_date': order_date.strftime('%Y-%m-%d %H:%M:%S'),
            'order_status': random.choice(['Completed', 'Completed', 'Completed', 'Pending', 'Cancelled']),
            'payment_method': random.choice(['Credit Card', 'PayPal', 'Bank Transfer']),
            'shipping_cost': round(random.uniform(5, 25), 2)
        }
        orders.append(order)
    return pd.DataFrame(orders)

def generate_order_items(orders_df, products_df, avg_items=3):
    print(f"生成订单明细数据...")
    order_items = []
    item_id = 1
    for order_id in orders_df['order_id']:
        n_items = random.randint(1, avg_items * 2)
        selected = random.sample(products_df['product_id'].tolist(), min(n_items, len(products_df)))
        for product_id in selected:
            product = products_df[products_df['product_id'] == product_id].iloc[0]
            quantity = random.randint(1, 5)
            discount = random.choice([0, 0, 0, 5, 10, 15, 20])
            item = {
                'order_item_id': item_id,
                'order_id': order_id,
                'product_id': product_id,
                'quantity': quantity,
                'unit_price': product['price'],
                'discount_percent': discount
            }
            order_items.append(item)
            item_id += 1
    return pd.DataFrame(order_items)

def save_data(output_dir='data/raw'):
    os.makedirs(output_dir, exist_ok=True)
    print("\n" + "="*60)
    print("开始生成电商测试数据...")
    print("="*60 + "\n")
    
    customers = generate_customers(10000)
    products = generate_products(1000)
    orders = generate_orders(customers, 50000)
    order_items = generate_order_items(orders, products)
    
    print("\n保存数据到CSV...")
    customers.to_csv(f'{output_dir}/customers.csv', index=False)
    print(f"✅ customers.csv")
    products.to_csv(f'{output_dir}/products.csv', index=False)
    print(f"✅ products.csv")
    orders.to_csv(f'{output_dir}/orders.csv', index=False)
    print(f"✅ orders.csv")
    order_items.to_csv(f'{output_dir}/order_items.csv', index=False)
    print(f"✅ order_items.csv")
    
    print("\n" + "="*60)
    print("统计信息：")
    print("="*60)
    print(f"客户: {len(customers):,} 条")
    print(f"产品: {len(products):,} 条")
    print(f"订单: {len(orders):,} 条")
    print(f"订单明细: {len(order_items):,} 条")
    print("\n数据预览：")
    print(customers.head())
    print("\n🎉 数据生成完成！")
    return customers, products, orders, order_items

if __name__ == "__main__":
    save_data()
