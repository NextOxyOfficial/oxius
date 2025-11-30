from django.core.management.base import BaseCommand
from workspace.models import Gig, GigReview
from base.models import User
from decimal import Decimal
import random


class Command(BaseCommand):
    help = 'Create 30 dummy gigs for testing'

    def handle(self, *args, **options):
        # Get all users or create a default one
        users = list(User.objects.all()[:10])
        
        if not users:
            self.stdout.write(self.style.ERROR('No users found. Please create some users first.'))
            return
        
        # Dummy gig data
        gig_templates = [
            # Design & Creative
            {
                'title': 'I will design a professional logo for your business',
                'description': 'Get a unique, professional logo that represents your brand identity. Includes 3 concepts, unlimited revisions, and all source files.',
                'category': 'design',
                'price': Decimal('50.00'),
                'delivery_time': 3,
                'revisions': 5,
            },
            {
                'title': 'I will create stunning social media graphics',
                'description': 'Eye-catching social media posts, stories, and banners for Instagram, Facebook, Twitter, and LinkedIn.',
                'category': 'design',
                'price': Decimal('35.00'),
                'delivery_time': 2,
                'revisions': 3,
            },
            {
                'title': 'I will design a modern business card',
                'description': 'Professional business card design that makes a lasting impression. Print-ready files included.',
                'category': 'design',
                'price': Decimal('25.00'),
                'delivery_time': 1,
                'revisions': 3,
            },
            {
                'title': 'I will create a professional flyer or brochure',
                'description': 'High-quality flyer or brochure design for your business, event, or product launch.',
                'category': 'design',
                'price': Decimal('45.00'),
                'delivery_time': 2,
                'revisions': 4,
            },
            {
                'title': 'I will design UI/UX for your mobile app',
                'description': 'Modern and user-friendly mobile app interface design with Figma source files.',
                'category': 'design',
                'price': Decimal('150.00'),
                'delivery_time': 7,
                'revisions': 5,
            },
            {
                'title': 'I will create a brand identity package',
                'description': 'Complete brand identity including logo, color palette, typography, and brand guidelines.',
                'category': 'design',
                'price': Decimal('200.00'),
                'delivery_time': 5,
                'revisions': 4,
            },
            
            # Programming & Tech
            {
                'title': 'I will build a responsive website using React',
                'description': 'Modern, fast, and SEO-friendly React website with responsive design for all devices.',
                'category': 'development',
                'price': Decimal('300.00'),
                'delivery_time': 7,
                'revisions': 3,
            },
            {
                'title': 'I will develop a custom WordPress website',
                'description': 'Professional WordPress website with custom theme, plugins, and full admin access.',
                'category': 'development',
                'price': Decimal('250.00'),
                'delivery_time': 5,
                'revisions': 3,
            },
            {
                'title': 'I will create a REST API using Django',
                'description': 'Scalable and secure REST API with authentication, documentation, and deployment support.',
                'category': 'development',
                'price': Decimal('400.00'),
                'delivery_time': 10,
                'revisions': 2,
            },
            {
                'title': 'I will fix bugs in your Python code',
                'description': 'Quick and efficient bug fixes for Python applications, Django, Flask, or scripts.',
                'category': 'development',
                'price': Decimal('50.00'),
                'delivery_time': 1,
                'revisions': 2,
            },
            {
                'title': 'I will build a mobile app using Flutter',
                'description': 'Cross-platform mobile app for iOS and Android with beautiful UI and smooth performance.',
                'category': 'development',
                'price': Decimal('500.00'),
                'delivery_time': 14,
                'revisions': 3,
            },
            {
                'title': 'I will set up your e-commerce store',
                'description': 'Complete e-commerce setup with payment integration, inventory management, and shipping.',
                'category': 'development',
                'price': Decimal('350.00'),
                'delivery_time': 7,
                'revisions': 2,
            },
            
            # Writing & Translation
            {
                'title': 'I will write SEO-optimized blog articles',
                'description': 'Engaging, well-researched blog posts that rank on Google and drive organic traffic.',
                'category': 'writing',
                'price': Decimal('30.00'),
                'delivery_time': 2,
                'revisions': 2,
            },
            {
                'title': 'I will translate English to Bengali professionally',
                'description': 'Accurate and natural translation by a native Bengali speaker with 5+ years experience.',
                'category': 'writing',
                'price': Decimal('20.00'),
                'delivery_time': 1,
                'revisions': 2,
            },
            {
                'title': 'I will write compelling product descriptions',
                'description': 'Persuasive product descriptions that convert visitors into customers.',
                'category': 'writing',
                'price': Decimal('25.00'),
                'delivery_time': 1,
                'revisions': 2,
            },
            {
                'title': 'I will proofread and edit your content',
                'description': 'Professional proofreading and editing to make your content error-free and polished.',
                'category': 'writing',
                'price': Decimal('15.00'),
                'delivery_time': 1,
                'revisions': 1,
            },
            {
                'title': 'I will write a professional resume and cover letter',
                'description': 'ATS-friendly resume and cover letter that gets you interviews.',
                'category': 'writing',
                'price': Decimal('40.00'),
                'delivery_time': 2,
                'revisions': 3,
            },
            {
                'title': 'I will write website copy that converts',
                'description': 'Compelling website copy for landing pages, about pages, and service pages.',
                'category': 'writing',
                'price': Decimal('75.00'),
                'delivery_time': 3,
                'revisions': 2,
            },
            
            # Digital Marketing
            {
                'title': 'I will manage your social media accounts',
                'description': 'Complete social media management including content creation, scheduling, and engagement.',
                'category': 'marketing',
                'price': Decimal('150.00'),
                'delivery_time': 30,
                'revisions': 0,
            },
            {
                'title': 'I will run Facebook and Instagram ads',
                'description': 'Targeted ad campaigns that drive traffic, leads, and sales for your business.',
                'category': 'marketing',
                'price': Decimal('100.00'),
                'delivery_time': 7,
                'revisions': 2,
            },
            {
                'title': 'I will do SEO optimization for your website',
                'description': 'On-page and off-page SEO to improve your search engine rankings.',
                'category': 'marketing',
                'price': Decimal('200.00'),
                'delivery_time': 14,
                'revisions': 1,
            },
            {
                'title': 'I will create an email marketing campaign',
                'description': 'Effective email sequences that nurture leads and drive conversions.',
                'category': 'marketing',
                'price': Decimal('80.00'),
                'delivery_time': 5,
                'revisions': 2,
            },
            {
                'title': 'I will grow your YouTube channel',
                'description': 'YouTube optimization, SEO, and growth strategies to increase subscribers and views.',
                'category': 'marketing',
                'price': Decimal('120.00'),
                'delivery_time': 14,
                'revisions': 1,
            },
            {
                'title': 'I will create a Google Ads campaign',
                'description': 'High-converting Google Ads campaigns with keyword research and optimization.',
                'category': 'marketing',
                'price': Decimal('150.00'),
                'delivery_time': 7,
                'revisions': 2,
            },
            
            # Business & Consulting
            {
                'title': 'I will create a business plan for your startup',
                'description': 'Comprehensive business plan with market analysis, financial projections, and strategy.',
                'category': 'business',
                'price': Decimal('250.00'),
                'delivery_time': 7,
                'revisions': 3,
            },
            {
                'title': 'I will do market research for your business',
                'description': 'In-depth market research with competitor analysis and industry insights.',
                'category': 'business',
                'price': Decimal('150.00'),
                'delivery_time': 5,
                'revisions': 2,
            },
            {
                'title': 'I will provide financial consulting',
                'description': 'Expert financial advice for budgeting, investment, and business growth.',
                'category': 'business',
                'price': Decimal('100.00'),
                'delivery_time': 3,
                'revisions': 1,
            },
            {
                'title': 'I will create a pitch deck for investors',
                'description': 'Professional pitch deck that helps you secure funding from investors.',
                'category': 'business',
                'price': Decimal('180.00'),
                'delivery_time': 5,
                'revisions': 3,
            },
            {
                'title': 'I will help with your business strategy',
                'description': 'Strategic consulting to help you grow your business and increase revenue.',
                'category': 'business',
                'price': Decimal('200.00'),
                'delivery_time': 7,
                'revisions': 2,
            },
            {
                'title': 'I will set up your accounting system',
                'description': 'Complete accounting setup with bookkeeping, invoicing, and financial reporting.',
                'category': 'business',
                'price': Decimal('120.00'),
                'delivery_time': 3,
                'revisions': 1,
            },
        ]
        
        created_count = 0
        
        for template in gig_templates:
            # Assign random user
            user = random.choice(users)
            
            # Create gig
            gig = Gig.objects.create(
                user=user,
                title=template['title'],
                description=template['description'],
                category=template['category'],
                price=template['price'],
                delivery_time=template['delivery_time'],
                revisions=template['revisions'],
                status='active',
                is_featured=random.choice([True, False, False, False]),  # 25% chance of featured
                views_count=random.randint(10, 500),
                orders_count=random.randint(0, 50),
            )
            
            # Add some random reviews
            num_reviews = random.randint(0, 10)
            reviewers = [u for u in users if u != user]
            
            for _ in range(min(num_reviews, len(reviewers))):
                reviewer = random.choice(reviewers)
                reviewers.remove(reviewer)
                
                GigReview.objects.create(
                    gig=gig,
                    user=reviewer,
                    rating=random.randint(3, 5),
                    comment=random.choice([
                        'Great work! Highly recommended.',
                        'Excellent service, will order again.',
                        'Very professional and delivered on time.',
                        'Good quality work.',
                        'Amazing experience!',
                        'Exceeded my expectations.',
                        '',
                    ])
                )
            
            created_count += 1
            self.stdout.write(f'Created gig: {gig.title}')
        
        self.stdout.write(self.style.SUCCESS(f'Successfully created {created_count} dummy gigs'))
