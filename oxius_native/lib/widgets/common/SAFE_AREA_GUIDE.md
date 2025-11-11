# Safe Area Guide - Preventing Bottom Navigation Bar Overlap

## Problem
On devices with gesture navigation (Android 10+, iPhone X+), content can be hidden under the device's bottom navigation bar/gesture area.

## Universal Solutions

### ✅ Solution 1: Use SafeScaffold (Recommended for New Screens)

Replace `Scaffold` with `SafeScaffold` in all new screens:

```dart
import 'package:oxius_native/widgets/common/safe_scaffold.dart';

// ❌ OLD WAY
Scaffold(
  appBar: AppBar(...),
  body: MyContent(),
  bottomNavigationBar: MyBottomBar(),
)

// ✅ NEW WAY - Automatic safe area handling
SafeScaffold(
  appBar: AppBar(...),
  body: MyContent(),
  bottomNavigationBar: MyBottomBar(), // Automatically wrapped with SafeArea
)
```

**For screens with scrollable content and NO bottom bar:**
```dart
SafeScaffold(
  appBar: AppBar(...),
  body: ListView(
    children: [
      // Your content
    ],
  ),
  addBottomPadding: true, // Adds safe bottom padding automatically
  extraBottomPadding: 16,  // Optional: add extra spacing
)
```

---

### ✅ Solution 2: Use BottomSafePadding Widget

For screens with `ListView` or `SingleChildScrollView`:

```dart
import 'package:oxius_native/widgets/common/bottom_safe_padding.dart';

ListView(
  children: [
    MyWidget1(),
    MyWidget2(),
    MyFormFields(),
    ElevatedButton(...),
    
    // ✅ Add this at the end
    BottomSafePadding(extraPadding: 16),
  ],
)

// OR use the extension method:
ListView(
  children: [
    MyWidget1(),
    MyWidget2(),
    ElevatedButton(...),
  ].withBottomSafePadding(), // ✅ Cleaner syntax
)
```

---

### ✅ Solution 3: Use SafeBottomActionBar

For screens with bottom action buttons (Call, Chat, Submit, etc.):

```dart
import 'package:oxius_native/widgets/common/safe_bottom_action_bar.dart';

// Custom bottom bar
Scaffold(
  body: MyContent(),
  bottomNavigationBar: SafeBottomActionBar(
    child: Row(
      children: [
        Expanded(child: ElevatedButton(...)),
        SizedBox(width: 8),
        Expanded(child: OutlinedButton(...)),
      ],
    ),
  ),
)

// Pre-built two-button bar (Call & Chat pattern)
Scaffold(
  body: MyContent(),
  bottomNavigationBar: SafeBottomTwoActionBar(
    onFirstAction: _handleCall,
    onSecondAction: _handleChat,
    firstButtonChild: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.phone_rounded, size: 18),
        SizedBox(width: 8),
        Text('Call Now'),
      ],
    ),
    secondButtonChild: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, size: 18),
        SizedBox(width: 8),
        Text('Chat'),
      ],
    ),
    secondButtonOutlined: true, // Make second button outlined
  ),
)
```

---

## Quick Reference Table

| Screen Type | Solution | Example |
|------------|----------|---------|
| **New screen with bottom bar** | `SafeScaffold` | Product details, post details |
| **New screen with scrollable content** | `SafeScaffold` with `addBottomPadding: true` | Forms, settings |
| **Existing screen - bottom bar** | `SafeBottomActionBar` | Wrap your bottom bar |
| **Existing screen - scrollable** | `BottomSafePadding()` | Add to end of children list |
| **Two action buttons** | `SafeBottomTwoActionBar` | Call & Chat, Submit & Cancel |

---

## Migration Guide for Existing Screens

### Step 1: Identify Screen Type
- Has `bottomNavigationBar`? → Use `SafeBottomActionBar`
- Has `ListView`/`SingleChildScrollView`? → Use `BottomSafePadding`
- Creating new screen? → Use `SafeScaffold`

### Step 2: Apply Fix

**Example 1: Screen with bottom bar**
```dart
// Before
Scaffold(
  bottomNavigationBar: Container(
    padding: EdgeInsets.all(12),
    child: Row(children: [...]),
  ),
)

// After
Scaffold(
  bottomNavigationBar: SafeBottomActionBar(
    padding: EdgeInsets.all(12),
    child: Row(children: [...]),
  ),
)
```

**Example 2: Screen with scrollable content**
```dart
// Before
ListView(
  children: [
    MyContent(),
    SizedBox(height: 20), // ❌ Not enough on gesture devices
  ],
)

// After
ListView(
  children: [
    MyContent(),
    BottomSafePadding(extraPadding: 20), // ✅ Adapts to device
  ],
)
```

---

## Best Practices

### ✅ DO:
- Use `SafeScaffold` for all new screens
- Add `BottomSafePadding()` at the end of scrollable content
- Use `SafeBottomActionBar` for bottom action buttons
- Test on devices with gesture navigation

### ❌ DON'T:
- Use hardcoded bottom padding like `SizedBox(height: 20)`
- Forget to add safe padding when creating forms
- Wrap entire body with `SafeArea` (affects top area too)
- Use `MediaQuery.of(context).padding.bottom` directly (use our widgets)

---

## Testing Checklist

When creating a new screen, verify:
- [ ] Bottom buttons are fully visible on iPhone X+ (gesture bar)
- [ ] Bottom buttons are fully visible on Android 10+ (gesture navigation)
- [ ] Content doesn't have excessive padding on older devices
- [ ] Landscape mode works correctly
- [ ] Keyboard doesn't cause layout issues

---

## Common Patterns

### Pattern 1: Form Screen
```dart
SafeScaffold(
  appBar: AppBar(title: Text('Create Post')),
  body: ListView(
    padding: EdgeInsets.all(16),
    children: [
      TextFormField(...),
      TextFormField(...),
      ElevatedButton(
        onPressed: _submit,
        child: Text('Submit'),
      ),
    ].withBottomSafePadding(),
  ),
)
```

### Pattern 2: Detail Screen with Actions
```dart
SafeScaffold(
  appBar: AppBar(title: Text('Product Details')),
  body: SingleChildScrollView(
    child: Column(children: [...]),
  ),
  bottomNavigationBar: SafeBottomTwoActionBar(
    onFirstAction: _call,
    onSecondAction: _chat,
    firstButtonChild: Text('Call'),
    secondButtonChild: Text('Chat'),
    secondButtonOutlined: true,
  ),
)
```

### Pattern 3: Settings/List Screen
```dart
SafeScaffold(
  appBar: AppBar(title: Text('Settings')),
  body: ListView(
    children: [
      ListTile(...),
      ListTile(...),
      ListTile(...),
      BottomSafePadding(),
    ],
  ),
)
```

---

## Need Help?

If you encounter a screen type not covered here:
1. Check if it has a bottom bar → Use `SafeBottomActionBar`
2. Check if it's scrollable → Use `BottomSafePadding`
3. For new screens → Always use `SafeScaffold`

**Remember:** The goal is to never manually calculate safe areas again!
