import os
import django
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from raise_up.models import RaiseUpPost, RaiseUpPostDetail, UserProfile

User = get_user_model()

class Command(BaseCommand):
    help = 'Create 20 dummy raise-up posts'

    def handle(self, *args, **options):
        # Create dummy users and profiles first
        dummy_users_data = [
            {'username': 'nusrat_jahan', 'first_name': 'Nusrat', 'last_name': 'Jahan', 'profession': 'Founder, CleanTech', 'is_pro': True, 'kyc': True},
            {'username': 'rafi_hasan', 'first_name': 'Rafi', 'last_name': 'Hasan', 'profession': 'Founder, HealthTech', 'is_pro': False, 'kyc': True},
            {'username': 'mahmudul_islam', 'first_name': 'Mahmudul', 'last_name': 'Islam', 'profession': 'Program Coordinator, EdTech', 'is_pro': True, 'kyc': False},
            {'username': 'fatima_khatun', 'first_name': 'Fatima', 'last_name': 'Khatun', 'profession': 'CEO, AgriTech', 'is_pro': True, 'kyc': True},
            {'username': 'karim_ahmed', 'first_name': 'Karim', 'last_name': 'Ahmed', 'profession': 'Founder, FinTech', 'is_pro': False, 'kyc': True},
            {'username': 'rashida_begum', 'first_name': 'Rashida', 'last_name': 'Begum', 'profession': 'Social Entrepreneur', 'is_pro': True, 'kyc': True},
            {'username': 'omar_faruk', 'first_name': 'Omar', 'last_name': 'Faruk', 'profession': 'Tech Innovator', 'is_pro': False, 'kyc': False},
            {'username': 'salma_akter', 'first_name': 'Salma', 'last_name': 'Akter', 'profession': 'Green Energy Expert', 'is_pro': True, 'kyc': True},
        ]

        users = []
        for user_data in dummy_users_data:
            user, created = User.objects.get_or_create(
                username=user_data['username'],
                defaults={
                    'first_name': user_data['first_name'],
                    'last_name': user_data['last_name'],
                    'email': f"{user_data['username']}@example.com",
                    'phone': f"+880171{hash(user_data['username']) % 10000000:07d}"
                }
            )
            
            profile, created = UserProfile.objects.get_or_create(
                user=user,
                defaults={
                    'profession': user_data['profession'],
                    'avatar': f'https://images.unsplash.com/photo-{1500000000 + hash(user_data["username"]) % 100000000}?auto=format&fit=crop&w=256&q=60',
                    'is_pro': user_data['is_pro'],
                    'kyc_verified': user_data['kyc']
                }
            )
            users.append(user)

        # Dummy posts data
        posts_data = [
            {
                'title': 'Solar Water Purifier Micro-Business',
                'summary': 'Low-cost solar purification units with local distribution partners. Seeking seed capital + impact donations.',
                'sector': 'CleanTech',
                'location': 'Rajshahi',
                'city': 'Rajshahi',
                'area': 'Boalia',
                'stage': 'seed',
                'stage_color': 'purple',
                'funding_type': 'investment_donation',
                'min_investment': 10000,
                'expected_return': '12-18% (est.)',
                'risk_level': 'medium',
                'traction': '120 pre-orders',
                'raised': 38500,
                'goal': 120000,
                'thumbnail': 'https://images.unsplash.com/photo-1509395062183-67c5ad6faff9?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': 'https://www.youtube.com/embed/aqz-KE-bpKQ',
                'is_featured': True,
                'user_index': 0
            },
            {
                'title': 'Micro-Clinic: Affordable Health Checkups',
                'summary': 'A subscription-based micro-clinic model for low-income areas. Looking for investors to scale 3 locations.',
                'sector': 'HealthTech',
                'location': 'Dhaka',
                'city': 'Dhaka',
                'area': 'Mirpur',
                'stage': 'growth',
                'stage_color': 'blue',
                'funding_type': 'investment',
                'min_investment': 25000,
                'expected_return': '20-28% (est.)',
                'risk_level': 'low',
                'traction': '1,800 members',
                'raised': 76000,
                'goal': 250000,
                'thumbnail': 'https://images.unsplash.com/photo-1580281657527-47f249e8f33a?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': 'https://www.youtube.com/embed/ScMzIvxBSi4',
                'is_featured': True,
                'user_index': 1
            },
            {
                'title': 'Skill Hub: Youth Training & Job Placement',
                'summary': 'Training youth on digital skills and connecting to jobs. Donations help sponsor courses; investors help expand.',
                'sector': 'EdTech',
                'location': 'Chattogram',
                'city': 'Chattogram',
                'area': 'Agrabad',
                'stage': 'early',
                'stage_color': 'purple',
                'funding_type': 'revenue_share',
                'min_investment': 5000,
                'expected_return': 'Revenue-share',
                'risk_level': 'high',
                'traction': '320 learners',
                'raised': 24500,
                'goal': 90000,
                'thumbnail': 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': 'https://www.youtube.com/embed/dQw4w9WgXcQ',
                'is_featured': True,
                'user_index': 2
            },
            {
                'title': 'Smart Farming IoT Solutions',
                'summary': 'IoT sensors for crop monitoring and automated irrigation. Helping farmers increase yield by 40%.',
                'sector': 'AgriTech',
                'location': 'Sylhet',
                'city': 'Sylhet',
                'area': 'Zindabazar',
                'stage': 'seed',
                'stage_color': 'emerald',
                'funding_type': 'investment',
                'min_investment': 15000,
                'expected_return': '25-35% (est.)',
                'risk_level': 'medium',
                'traction': '50 pilot farms',
                'raised': 45000,
                'goal': 180000,
                'thumbnail': 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': 'https://www.youtube.com/embed/example1',
                'is_featured': True,
                'user_index': 3
            },
            {
                'title': 'Mobile Banking for Rural Areas',
                'summary': 'Digital payment solutions for unbanked rural communities. Agent-based model with smartphone app.',
                'sector': 'FinTech',
                'location': 'Khulna',
                'city': 'Khulna',
                'area': 'Sonadanga',
                'stage': 'growth',
                'stage_color': 'blue',
                'funding_type': 'investment',
                'min_investment': 50000,
                'expected_return': '18-25% (est.)',
                'risk_level': 'low',
                'traction': '2,500 users',
                'raised': 125000,
                'goal': 400000,
                'thumbnail': 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': 'https://www.youtube.com/embed/example2',
                'is_featured': True,
                'user_index': 4
            },
            {
                'title': 'Women Empowerment Craft Cooperative',
                'summary': 'Supporting rural women artisans with e-commerce platform and fair trade practices.',
                'sector': 'Social Enterprise',
                'location': 'Barisal',
                'city': 'Barisal',
                'area': 'Sadar',
                'stage': 'early',
                'stage_color': 'amber',
                'funding_type': 'donation',
                'min_investment': 2000,
                'expected_return': 'Social Impact',
                'risk_level': 'low',
                'traction': '150 artisans',
                'raised': 18000,
                'goal': 60000,
                'thumbnail': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': 'https://www.youtube.com/embed/example3',
                'is_featured': False,
                'user_index': 5
            }
        ]

        # Add 14 more posts to reach 20 total
        additional_posts = [
            {
                'title': 'Renewable Energy Storage Systems',
                'summary': 'Battery storage solutions for solar and wind energy in rural communities.',
                'sector': 'CleanTech',
                'location': 'Rangpur',
                'city': 'Rangpur',
                'area': 'Sadar',
                'stage': 'seed',
                'stage_color': 'purple',
                'funding_type': 'investment',
                'min_investment': 30000,
                'expected_return': '22-30% (est.)',
                'risk_level': 'medium',
                'traction': '25 installations',
                'raised': 85000,
                'goal': 300000,
                'thumbnail': 'https://images.unsplash.com/photo-1466611653911-95081537e5b7?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': 'https://www.youtube.com/embed/example4',
                'is_featured': False,
                'user_index': 6
            },
            {
                'title': 'Telemedicine Platform for Villages',
                'summary': 'Connecting rural patients with city doctors through video consultations and mobile health units.',
                'sector': 'HealthTech',
                'location': 'Mymensingh',
                'city': 'Mymensingh',
                'area': 'Sadar',
                'stage': 'early',
                'stage_color': 'blue',
                'funding_type': 'investment_donation',
                'min_investment': 8000,
                'expected_return': '15-20% (est.)',
                'risk_level': 'medium',
                'traction': '500 consultations',
                'raised': 32000,
                'goal': 120000,
                'thumbnail': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': 'https://www.youtube.com/embed/example5',
                'is_featured': False,
                'user_index': 7
            }
        ]

        # Generate 12 more varied posts
        sectors = ['EdTech', 'AgriTech', 'FinTech', 'HealthTech', 'CleanTech', 'Social Enterprise']
        cities = ['Dhaka', 'Chattogram', 'Sylhet', 'Khulna', 'Rajshahi', 'Barisal', 'Rangpur', 'Mymensingh']
        stages = ['seed', 'early', 'growth']
        colors = ['purple', 'blue', 'emerald', 'amber']
        
        for i in range(12):
            additional_posts.append({
                'title': f'Innovation Project {i+9}',
                'summary': f'Innovative solution for {sectors[i % len(sectors)]} sector addressing local community needs.',
                'sector': sectors[i % len(sectors)],
                'location': cities[i % len(cities)],
                'city': cities[i % len(cities)],
                'area': 'Sadar',
                'stage': stages[i % len(stages)],
                'stage_color': colors[i % len(colors)],
                'funding_type': 'investment' if i % 2 == 0 else 'investment_donation',
                'min_investment': 5000 + (i * 2000),
                'expected_return': f'{10 + (i * 2)}-{20 + (i * 2)}% (est.)',
                'risk_level': ['low', 'medium', 'high'][i % 3],
                'traction': f'{50 + (i * 25)} users',
                'raised': 10000 + (i * 5000),
                'goal': 50000 + (i * 10000),
                'thumbnail': f'https://images.unsplash.com/photo-{1500000000 + i}?auto=format&fit=crop&w=1200&q=60',
                'video_embed_url': f'https://www.youtube.com/embed/example{i+6}',
                'is_featured': i < 2,  # First 2 additional posts are featured
                'user_index': i % len(users)
            })

        posts_data.extend(additional_posts)

        # Create posts
        created_count = 0
        for post_data in posts_data:
            user = users[post_data['user_index']]
            
            post, created = RaiseUpPost.objects.get_or_create(
                title=post_data['title'],
                defaults={
                    'summary': post_data['summary'],
                    'sector': post_data['sector'],
                    'location': post_data['location'],
                    'city': post_data['city'],
                    'area': post_data['area'],
                    'stage': post_data['stage'],
                    'stage_color': post_data['stage_color'],
                    'funding_type': post_data['funding_type'],
                    'min_investment': post_data['min_investment'],
                    'expected_return': post_data['expected_return'],
                    'risk_level': post_data['risk_level'],
                    'traction': post_data['traction'],
                    'raised': post_data['raised'],
                    'goal': post_data['goal'],
                    'thumbnail': post_data['thumbnail'],
                    'video_embed_url': post_data['video_embed_url'],
                    'poster': user,
                    'is_featured': post_data['is_featured']
                }
            )
            
            if created:
                created_count += 1
                
                # Create post details
                RaiseUpPostDetail.objects.create(
                    post=post,
                    overview=f"Detailed overview of {post.title}. This innovative project aims to solve real problems in the {post.sector} sector.",
                    use_of_funds=[
                        "Product development and testing",
                        "Marketing and user acquisition", 
                        "Team expansion and operations",
                        "Technology infrastructure"
                    ],
                    milestones=[
                        "Month 1-2: Complete prototype development",
                        "Month 3-4: Launch pilot program",
                        "Month 5-6: Scale to target market"
                    ]
                )

        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {created_count} raise-up posts')
        )
