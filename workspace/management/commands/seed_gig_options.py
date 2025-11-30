from django.core.management.base import BaseCommand
from workspace.models import GigCategory, GigSkill, GigDeliveryTime, GigRevisionOption


class Command(BaseCommand):
    help = 'Seed gig options (categories, skills, delivery times, revisions)'

    def handle(self, *args, **options):
        self.stdout.write('Seeding gig options...')
        
        # Create Categories
        categories_data = [
            {'name': 'Design & Creative', 'slug': 'design', 'icon': 'i-heroicons-paint-brush', 'order': 1},
            {'name': 'Programming & Tech', 'slug': 'development', 'icon': 'i-heroicons-code-bracket', 'order': 2},
            {'name': 'Writing & Translation', 'slug': 'writing', 'icon': 'i-heroicons-pencil', 'order': 3},
            {'name': 'Digital Marketing', 'slug': 'marketing', 'icon': 'i-heroicons-megaphone', 'order': 4},
            {'name': 'Business & Consulting', 'slug': 'business', 'icon': 'i-heroicons-briefcase', 'order': 5},
        ]

        categories = {}
        for cat_data in categories_data:
            cat, created = GigCategory.objects.get_or_create(slug=cat_data['slug'], defaults=cat_data)
            categories[cat_data['slug']] = cat
            status = 'Created' if created else 'Exists'
            self.stdout.write(f'  Category: {cat.name} - {status}')

        # Create Skills
        skills_data = {
            'design': ['Logo Design', 'Photoshop', 'Illustrator', 'Figma', 'UI/UX Design', 'Branding', 'Typography', 'Canva', 'Graphic Design', 'Web Design'],
            'development': ['JavaScript', 'Python', 'React', 'Vue.js', 'Node.js', 'PHP', 'Laravel', 'WordPress', 'API Development', 'Mobile App'],
            'writing': ['Content Writing', 'Copywriting', 'SEO Writing', 'Blog Writing', 'Proofreading', 'Translation', 'Technical Writing', 'Creative Writing'],
            'marketing': ['SEO', 'Social Media Marketing', 'Google Ads', 'Facebook Ads', 'Email Marketing', 'Content Strategy', 'Analytics', 'PPC'],
            'business': ['Business Plan', 'Financial Analysis', 'Market Research', 'Consulting', 'Project Management', 'Data Analysis', 'Virtual Assistant'],
        }

        for cat_slug, skills in skills_data.items():
            category = categories.get(cat_slug)
            for skill_name in skills:
                skill_slug = skill_name.lower().replace(' ', '-').replace('/', '-')
                skill, created = GigSkill.objects.get_or_create(
                    slug=skill_slug,
                    defaults={'name': skill_name, 'category': category}
                )
                if created:
                    self.stdout.write(f'    Skill: {skill.name}')

        # Create Delivery Times
        delivery_times = [
            {'label': '1 Day', 'days': 1, 'order': 1},
            {'label': '3 Days', 'days': 3, 'order': 2},
            {'label': '1 Week', 'days': 7, 'order': 3},
            {'label': '2 Weeks', 'days': 14, 'order': 4},
            {'label': '1 Month', 'days': 30, 'order': 5},
        ]

        for dt_data in delivery_times:
            dt, created = GigDeliveryTime.objects.get_or_create(days=dt_data['days'], defaults=dt_data)
            status = 'Created' if created else 'Exists'
            self.stdout.write(f'  Delivery Time: {dt.label} - {status}')

        # Create Revision Options
        revision_options = [
            {'label': '1 Revision', 'count': 1, 'order': 1},
            {'label': '2 Revisions', 'count': 2, 'order': 2},
            {'label': '3 Revisions', 'count': 3, 'order': 3},
            {'label': '5 Revisions', 'count': 5, 'order': 4},
            {'label': 'Unlimited', 'count': 999, 'order': 5},
        ]

        for rev_data in revision_options:
            rev, created = GigRevisionOption.objects.get_or_create(count=rev_data['count'], defaults=rev_data)
            status = 'Created' if created else 'Exists'
            self.stdout.write(f'  Revision Option: {rev.label} - {status}')

        self.stdout.write(self.style.SUCCESS('Successfully seeded gig options!'))
