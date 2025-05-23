#!/usr/bin/env python
"""
Test script for Gold Sponsor API endpoints
"""
import os
import sys
import django
from django.test import Client
from django.urls import reverse
import json

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

def test_gold_sponsor_apis():
    client = Client()
    
    print("Testing Gold Sponsor API endpoints...")
    print("=" * 50)
    
    # Test 1: Get sponsorship packages
    print("1. Testing GET /api/bn/gold-sponsors/packages/")
    try:
        response = client.get('/api/bn/gold-sponsors/packages/')
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Found {len(data)} packages")
            for pkg in data:
                print(f"   - {pkg['name']}: ৳{pkg['price']} ({pkg['duration_months']} months)")
        else:
            print(f"   Error: {response.content.decode()}")
    except Exception as e:
        print(f"   Exception: {e}")
    
    print()
    
    # Test 2: Test Gold Sponsor application submission
    print("2. Testing POST /api/bn/gold-sponsors/apply/")
    test_data = {
        'business_name': 'Test Business Inc.',
        'business_description': 'A test business for Gold Sponsor application',
        'contact_email': 'test@testbusiness.com',
        'phone_number': '+8801234567890',
        'website': 'https://testbusiness.com',
        'profile_url': 'https://facebook.com/testbusiness',
        'package_id': 1
    }
    
    try:
        response = client.post('/api/bn/gold-sponsors/apply/', data=test_data)
        print(f"   Status: {response.status_code}")
        if response.status_code == 201:
            data = response.json()
            print(f"   Success: {data['message']}")
            print(f"   Sponsor ID: {data['sponsor']['id']}")
            print(f"   Business: {data['sponsor']['business_name']}")
            print(f"   Status: {data['sponsor']['status']}")
        else:
            print(f"   Error: {response.content.decode()}")
    except Exception as e:
        print(f"   Exception: {e}")
    
    print()
    
    # Test 3: Get active Gold Sponsors
    print("3. Testing GET /api/bn/gold-sponsors/list/")
    try:
        response = client.get('/api/bn/gold-sponsors/list/')
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Found {len(data)} active/featured sponsors")
        else:
            print(f"   Error: {response.content.decode()}")
    except Exception as e:
        print(f"   Exception: {e}")
    
    print("\nTesting completed!")

if __name__ == '__main__':
    test_gold_sponsor_apis()
