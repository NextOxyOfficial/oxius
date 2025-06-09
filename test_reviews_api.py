#!/usr/bin/env python
import os
import django
import json
from django.test import Client

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from base.models import User
from rest_framework_simplejwt.tokens import RefreshToken

def test_reviews_api():
    # Get a user for testing
    user = User.objects.first()
    if not user:
        print("❌ No users found in database")
        return
    
    print(f"Testing with user: {user.username}")
    
    # Generate JWT token
    refresh = RefreshToken.for_user(user)
    access_token = str(refresh.access_token)
    
    # Test with JWT authentication
    client = Client()
    product_id = "4064019b-1591-4681-846c-20003d535d9c"
    url = f'/api/reviews/products/{product_id}/reviews/'
    
    # Test POST with JWT
    review_data = {
        'rating': 5,
        'comment': 'This is a test review from Python script!'
    }
    
    response = client.post(
        url,
        data=json.dumps(review_data),
        content_type='application/json',
        HTTP_AUTHORIZATION=f'Bearer {access_token}'
    )
    
    print(f"POST Status: {response.status_code}")
    print(f"POST Content: {response.content.decode()}")
    
    if response.status_code == 201:
        print("✅ SUCCESS: Review created successfully!")
        
        # Test GET to see if the review appears
        get_response = client.get(url)
        print(f"GET Status: {get_response.status_code}")
        reviews_data = json.loads(get_response.content.decode())
        print(f"Total reviews: {len(reviews_data)}")
        
        if reviews_data:
            latest_review = reviews_data[0]
            print(f"Latest review: {latest_review['rating']}⭐ - {latest_review['comment']}")
        
    else:
        print("❌ FAILED: Review creation failed")
        try:
            error_data = json.loads(response.content)
            print("Error details:", json.dumps(error_data, indent=2))
        except:
            print(f"Raw error: {response.content}")

if __name__ == "__main__":
    test_reviews_api()
