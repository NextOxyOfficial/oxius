# Gold Sponsor System Implementation

## Overview
A complete Gold Sponsor application system has been implemented for the business network platform, allowing businesses to apply for premium sponsorship packages and enabling administrators to manage applications through Django admin.

## Features Implemented

### 1. Database Models
- **SponsorshipPackage**: Manages different sponsorship packages with pricing and duration
- **GoldSponsor**: Stores sponsor applications with business details and status tracking

### 2. API Endpoints
- `GET /api/bn/gold-sponsors/packages/` - Retrieve all active sponsorship packages
- `POST /api/bn/gold-sponsors/apply/` - Submit a new Gold Sponsor application
- `GET /api/bn/gold-sponsors/list/` - Get active/featured sponsors for display

### 3. Frontend Component
- **GoldSponsorModal.vue**: Complete Vue.js component with:
  - Dynamic package fetching from API
  - Form validation and submission
  - File upload for business logos
  - Loading states and error handling
  - Success notifications

### 4. Admin Interface
- **SponsorshipPackageAdmin**: Manage sponsorship packages
- **GoldSponsorAdmin**: Review and approve sponsor applications with bulk actions

## File Structure

```
business_network/
├── models.py (contains SponsorshipPackage and GoldSponsor models)
├── admin.py (admin configurations)
├── urls.py (includes gold-sponsors URLs)
├── gold_sponsors/
│   ├── __init__.py
│   ├── serializers.py (API serializers)
│   ├── views.py (API views)
│   └── urls.py (API URL patterns)
└── management/
    └── commands/
        └── create_sponsorship_packages.py

frontend/components/business-network/
└── GoldSponsorModal.vue (main frontend component)
```

## API Usage Examples

### Get Sponsorship Packages
```javascript
const packages = await $fetch('/api/bn/gold-sponsors/packages/');
```

### Submit Application
```javascript
const formData = new FormData();
formData.append('business_name', 'Example Business');
formData.append('contact_email', 'contact@example.com');
formData.append('package_id', 1);
// ... other fields

const response = await $fetch('/api/bn/gold-sponsors/apply/', {
  method: 'POST',
  body: formData
});
```

## Database Schema

### SponsorshipPackage
- `id`: Primary key
- `name`: Package name (e.g., "1 Month Gold Sponsor")
- `description`: Package description
- `price`: Decimal price in BDT
- `duration_months`: Duration in months
- `is_active`: Boolean for package availability
- `created_at`, `updated_at`: Timestamps

### GoldSponsor
- `id`: Primary key
- `business_name`: Business name
- `business_description`: Business description
- `slug`: URL-friendly slug
- `contact_email`: Contact email
- `phone_number`: Phone number
- `website`: Business website
- `profile_url`: Social media profile
- `logo`: Business logo upload
- `package`: Foreign key to SponsorshipPackage
- `start_date`, `end_date`: Sponsorship period
- `status`: Application status (pending/active/rejected/expired)
- `is_featured`: Boolean for featured display
- `created_at`, `updated_at`: Timestamps

## Initial Data

Four sponsorship packages are created by default:
1. **1 Month Gold Sponsor** - ৳2,999 (1 month)
2. **3 Months Gold Sponsor** - ৳8,099 (3 months, 10% discount)
3. **6 Months Gold Sponsor** - ৳15,299 (6 months, 15% discount)
4. **12 Months Gold Sponsor** - ৳28,799 (12 months, 20% discount)

## Admin Features

### Sponsorship Package Management
- Create, edit, and manage packages
- Set pricing and duration
- Enable/disable packages

### Gold Sponsor Management
- Review applications
- Approve/reject sponsors
- Feature/unfeature sponsors
- Bulk actions for efficiency
- Search and filter capabilities

## Setup Commands

1. **Apply migrations**:
   ```bash
   python manage.py migrate
   ```

2. **Create initial packages**:
   ```bash
   python manage.py create_sponsorship_packages
   ```

3. **Create admin user** (if needed):
   ```bash
   python manage.py createsuperuser
   ```

## Testing

A test script `test_gold_sponsors.py` is included to verify:
- Package retrieval API
- Application submission API
- Active sponsor listing API

Run with: `python test_gold_sponsors.py`

## Frontend Integration

The GoldSponsorModal component can be integrated into any Vue page:

```vue
<template>
  <GoldSponsorModal 
    :isOpen="showModal" 
    @close="showModal = false"
    @submit="handleSubmit"
  />
</template>

<script setup>
import GoldSponsorModal from '~/components/business-network/GoldSponsorModal.vue'

const showModal = ref(false)

const handleSubmit = (sponsorData) => {
  console.log('Sponsor application submitted:', sponsorData)
  // Handle success (show notification, redirect, etc.)
}
</script>
```

## Security Features

- CSRF protection on API endpoints
- File upload validation for logos
- Email validation
- Package existence validation
- Status-based access control

## Next Steps

1. **Payment Integration**: Add payment processing for sponsor applications
2. **Email Notifications**: Send confirmation emails to applicants
3. **Sponsor Dashboard**: Create a dashboard for sponsors to manage their listings
4. **Analytics**: Track sponsor performance and engagement
5. **Advanced Features**: Add promotional codes, custom packages, etc.

## Maintenance

- Regular cleanup of expired sponsorships
- Monitor application volume and adjust packages
- Update pricing as needed
- Backup sponsor data regularly
