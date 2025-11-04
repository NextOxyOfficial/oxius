from base.models import Order, OrderItem, Product
from django.contrib.auth import get_user_model

User = get_user_model()

# Check testvendor user
user = User.objects.get(email='testvendor@example.com')
print(f'User: {user.email}')

# Get user's products
products = Product.objects.filter(owner=user)
print(f'Products owned: {products.count()}')

# Get order items with user's products
order_items = OrderItem.objects.filter(product__in=products)
print(f'Order items with user products: {order_items.count()}')

# Get orders containing user's products
orders = Order.objects.filter(items__product__in=products).distinct()
print(f'Orders containing user products: {orders.count()}')

if orders.exists():
    print(f'\nFirst order details:')
    order = orders.first()
    print(f'  Order number: {order.order_number}')
    print(f'  Order ID: {order.id}')
    print(f'  Status: {order.order_status}')
    print(f'  Total: {order.total}')
    print(f'  Items: {order.items.count()}')
else:
    print('\nNo orders found!')
    print('\nChecking all orders in database:')
    all_orders = Order.objects.all()
    print(f'Total orders: {all_orders.count()}')
    if all_orders.exists():
        print('\nFirst order in database:')
        order = all_orders.first()
        print(f'  Order number: {order.order_number}')
        print(f'  Items count: {order.items.count()}')
        if order.items.exists():
            item = order.items.first()
            print(f'  First item product: {item.product.name if item.product else "None"}')
            print(f'  Product owner: {item.product.owner.email if item.product and item.product.owner else "None"}')
