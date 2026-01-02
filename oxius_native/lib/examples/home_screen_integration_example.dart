// Example integration for Home Screen
// Add this to your lib/screens/home_screen.dart

// 1. Import the widget at the top of your file:

// 2. Add one of these widgets to your home screen layout:

// Option A: Grid view (for dedicated section)
// Add this inside your ListView or Column in the home screen:
/*
ClassifiedCategoriesWidget(
  maxCategories: 6, // Show only 6 categories, null for all
  padding: EdgeInsets.all(16),
),
*/

// Option B: Horizontal scrollable list (for compact display)
// Add this inside your ListView or Column in the home screen:
/*
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Browse Classifieds',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to all categories
            },
            child: Text('View All'),
          ),
        ],
      ),
    ),
    ClassifiedCategoriesHorizontalList(
      maxCategories: 8,
    ),
  ],
),
*/

// 3. COMPLETE EXAMPLE - Add this to your home screen body:
/*
SingleChildScrollView(
  child: Column(
    children: [
      // Your existing banner/hero section
      YourBannerWidget(),
      
      // Add classified categories section
      SizedBox(height: 24),
      
      // Option 1: Horizontal List
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Browse Classifieds',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full categories page
                  },
                  child: Text('View All'),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          ClassifiedCategoriesHorizontalList(maxCategories: 8),
        ],
      ),
      
      SizedBox(height: 24),
      Divider(),
      SizedBox(height: 24),
      
      // OR Option 2: Grid View
      ClassifiedCategoriesWidget(
        maxCategories: 6,
        padding: EdgeInsets.all(16),
      ),
      
      // Your other home screen sections
      YourOtherWidgets(),
    ],
  ),
)
*/

// 4. Direct Navigation Example:
// If you want to add a button that directly opens a specific category:
/*
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassifiedCategoryListScreen(
          categoryId: 'your-category-uuid',
          categorySlug: 'your-category-slug',
        ),
      ),
    );
  },
  child: Text('Browse Jobs'),
)
*/

// 5. Custom Category Card:
// If you want to create a custom promotional card for a specific category:
/*
Card(
  margin: EdgeInsets.all(16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassifiedCategoryListScreen(
            categoryId: 'services-category-id',
            categorySlug: 'services-business',
          ),
        ),
      );
    },
    child: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.business, size: 48, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Services & Business',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Browse local services near you',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white),
        ],
      ),
    ),
  ),
)
*/
