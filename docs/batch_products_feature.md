# Batch Products Feature - Admin Guide

## Overview
This feature allows administrators to associate products with educational batches (like SSC, HSC) so that relevant products are displayed to students when they select a batch in the courses section.

## Admin Setup Instructions

### 1. Adding Products to Batches

1. **Login to Django Admin** at `/admin`
2. Navigate to **Base > Products**
3. Edit any existing product or create a new one
4. In the product form, you'll see a new **"Batches"** field under the **"Categories & Organization"** section
5. Select one or more batches where this product should be displayed (e.g., SSC, HSC)
6. Save the product

### 2. Product Display Logic

- **Mobile View**: Shows 2x2 grid (4 products max)
- **Desktop View**: Shows 1x5 grid (5 products max)
- Products are fetched with a limit of 10 to ensure good performance
- Results are cached for 30 minutes to improve performance

### 3. Frontend Integration

The products will automatically appear on the courses page when students:
1. Select a batch (SSC, HSC, etc.)
2. Products associated with that batch will be displayed below the batch selector
3. Students can click "View All Products" to see more products with a filter applied

## API Endpoints

- **Get products for a batch**: `GET /api/elearning/batches/{batch_code}/products/`
- **Parameters**: 
  - `limit` (optional): Number of products to return (default: 10)

## Database Schema

```sql
-- New many-to-many relationship table
base_product_batches (
    id: Primary Key
    product_id: Foreign Key to base_product
    batch_id: Foreign Key to elearning_batch
)
```

## Example Usage

```javascript
// Fetch products for SSC batch
const products = await fetchBatchProducts(baseURL, 'ssc', { limit: 8 });
```

## Translation Keys Added

### English
- `recommended_products`: "Recommended Products"
- `no_products_available`: "No products available for this batch"
- `view_all_products`: "View All Products"

### Bengali  
- `recommended_products`: "প্রস্তাবিত পণ্য"
- `no_products_available`: "এই ব্যাচের জন্য কোনো পণ্য পাওয়া যায়নি"
- `view_all_products`: "সব পণ্য দেখুন"

## Files Modified

### Backend
- `base/models.py` - Added batches ManyToManyField to Product model
- `base/admin.py` - Enhanced ProductAdmin with batch selection
- `elearning/views.py` - Added products endpoint to BatchViewSet
- `base/migrations/0090_product_batches.py` - Database migration

### Frontend
- `components/courses/BatchProducts.vue` - New component for displaying products
- `pages/courses/index.vue` - Integrated BatchProducts component
- `services/elearningApi.js` - Added fetchBatchProducts function
- `i18n.config.ts` - Added translation keys

## Testing Instructions

1. Ensure Django server is running
2. Add some products in admin and associate them with batches
3. Go to `/courses` page
4. Select a batch (SSC/HSC)
5. Products should appear below the batch selector
6. Test both mobile and desktop views

## Performance Considerations

- Products are cached for 30 minutes for better performance
- Limited to 10 products per request to avoid slow loading
- Uses select_related and prefetch_related for optimized database queries
