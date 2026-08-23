import pandas as pd
import random
import uuid
from faker import Faker
from datetime import timedelta

# Configurar Faker para generar nombres y datos en español latino
fake = Faker('es_MX')

NUM_USERS = 10000
NUM_ORDERS = 30000

print("Generando datos para E-Cart Analytics...")

# ---------------- 1. Tabla USERS ----------------
users_data = []
countries = ['GT', 'SV', 'HN', 'CR', 'CO', 'MX', 'CL'] # Países de la región

for _ in range(NUM_USERS):
    created = fake.date_time_between(start_date='-2y', end_date='-1m')
    updated = created + timedelta(days=random.randint(0, 30))
    
    users_data.append({
        'id': str(uuid.uuid4()),
        'name': fake.name(),
        'email': fake.unique.email(),
        'country': random.choice(countries),
        'created_at': created.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': updated.strftime('%Y-%m-%d %H:%M:%S')
    })

df_users = pd.DataFrame(users_data)

# ---------------- 2. Tabla ORDERS ----------------
orders_data = []
order_statuses = ['Pending', 'Completed', 'Cancelled', 'Shipped']

for _ in range(NUM_ORDERS):
    user_id = random.choice(df_users['id'])
    order_date = fake.date_time_between(start_date='-1y', end_date='now')
    updated = order_date + timedelta(days=random.randint(0, 5))
    
    orders_data.append({
        'id': str(uuid.uuid4()),
        'user_id': user_id,
        'total_amount': round(random.uniform(15.0, 500.0), 2),
        'status': random.choices(order_statuses, weights=[10, 70, 5, 15])[0], # Mayoría completadas
        'order_date': order_date.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': updated.strftime('%Y-%m-%d %H:%M:%S')
    })

df_orders = pd.DataFrame(orders_data)

# ---------------- 3. Tabla ORDER_ITEMS ----------------
order_items_data = []

for order_id in df_orders['id']:
    # Cada orden puede tener entre 1 y 5 productos
    num_items = random.randint(1, 5)
    for _ in range(num_items):
        qty = random.randint(1, 4)
        price = round(random.uniform(5.0, 150.0), 2)
        
        order_items_data.append({
            'id': str(uuid.uuid4()),
            'order_id': order_id,
            'product_id': f"PROD-{random.randint(100, 999)}",
            'quantity': qty,
            'price': price
        })

df_order_items = pd.DataFrame(order_items_data)

# ---------------- Exportar a CSV (Simulando S3 Bronze) ----------------
df_users.to_csv('raw_postgres_users.csv', index=False)
df_orders.to_csv('raw_postgres_orders.csv', index=False)
df_order_items.to_csv('raw_postgres_order_items.csv', index=False)

print("¡Archivos generados exitosamente! (raw_postgres_users.csv, raw_postgres_orders.csv, raw_postgres_order_items.csv)")