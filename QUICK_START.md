# Quick Start Guide - Meal Tracking Update

## 🚀 Getting Started

### 1. Install & Update Dependencies
```bash
cd g:\senior_project\health_app-backup
flutter clean
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

---

## ✅ What's Fixed

### ❌ Problem: Meals not saving
**✅ Solution**: 
- Added meal list to `SessionData`
- Implemented `addMeal()` method
- Meals now persist during session

### ❌ Problem: Unclear meal confirmation flow
**✅ Solution**:
- Created new `MealConfirmationScreen` with sliders
- Clear save/cancel options
- Visual feedback with badges

### ❌ Problem: No user profile access
**✅ Solution**:
- Created `ProfileScreen` with complete settings
- Accessible from bottom navigation
- Edit all user information

### ❌ Problem: Static meal display
**✅ Solution**:
- Home screen now shows real meals
- Updates in real-time
- Shows total calories dynamically

---

## 🎯 Key Features

### 1. **Slider-Based Meal Adjustment**
- Drag to adjust calories (0-5000)
- Drag to adjust protein (0-100g)
- Drag to adjust carbs (0-300g)
- Drag to adjust fat (0-150g)
- Real-time value display in badges

### 2. **User Profile Management**
- Edit personal information
- Change email
- Update password
- Manage health info
- Logout with confirmation

### 3. **Real-Time Meal Tracking**
- Meals appear instantly on home screen
- Total calories calculated automatically
- Progress indicator updates
- Empty state handling

### 4. **Improved Navigation**
- Profile accessible from bottom-right icon
- Clear navigation flow
- Proper back button support
- Success notifications

---

## 📱 Testing the App

### Test Scenario 1: Add a Meal
1. **Start**: Home screen
2. **Action**: Click camera button
3. **Action**: Select/take food photo
4. **Verify**: Recognition results appear
5. **Action**: Click "ยืนยัน" (Confirm)
6. **Verify**: Meal confirmation screen opens with sliders
7. **Action**: Adjust slider values (optional)
8. **Verify**: Badge values update in real-time
9. **Action**: Click "บันทึกอาหาร" (Save Meal)
10. **Verify**: Success notification appears
11. **Verify**: Return to home screen
12. **Verify**: Meal appears in list
13. **Verify**: Total calories updated

### Test Scenario 2: Manage Profile
1. **Start**: Home screen
2. **Action**: Click person icon (bottom-right)
3. **Verify**: Profile screen opens
4. **Verify**: Shows user avatar and name
5. **Action**: Click "ข้อมูลโปรไฟล์" (Profile)
6. **Verify**: Bottom sheet opens
7. **Action**: Edit name/fields
8. **Action**: Click "บันทึก" (Save)
9. **Verify**: Bottom sheet closes
10. **Action**: Try other menu options
11. **Action**: Click "ออกจากระบบ" (Logout)
12. **Verify**: Confirmation dialog appears
13. **Action**: Confirm logout
14. **Verify**: Navigation back to home

### Test Scenario 3: Multiple Meals
1. **Start**: Home with 0 meals
2. **Action**: Add first meal (Pad Thai, 450 cal)
3. **Verify**: Meal appears, total = 450
4. **Action**: Add second meal (Green Curry, 320 cal)
5. **Verify**: Both meals appear, total = 770
6. **Action**: Add third meal (Rice, 150 cal)
7. **Verify**: All meals appear, total = 920
8. **Verify**: Progress bar reflects total
9. **Verify**: No scrolling issues with multiple meals

---

## 🔍 Troubleshooting

### Issue: Meals disappear on refresh
**Expected**: Yes (session-based storage)
**Solution**: Implement backend persistence (future phase)

### Issue: Sliders too sensitive
**Solution**: Adjust `SliderTheme` in `meal_confirmation_screen.dart`

### Issue: Profile bottom sheet not closing
**Solution**: Ensure `Navigator.pop(context)` is called on save

### Issue: Home screen not updating
**Solution**: Check that `Consumer<SessionData>` is properly wrapping the meal list

### Issue: Navigation errors
**Solution**: Verify all screen imports in main.dart and home_screen.dart

---

## 📊 Files Overview

### Created Files:
```
✨ lib/profile_screen.dart (523 lines)
✨ lib/meal_confirmation_screen.dart (322 lines)
```

### Modified Files:
```
✏️ lib/session_data.dart - Added meal management
✏️ lib/home_screen.dart - Updated UI and navigation
✏️ lib/results_screen.dart - Changed navigation flow
```

### Documentation Files:
```
📄 IMPLEMENTATION_NOTES.md - Technical details
📄 MEAL_TRACKING_UPDATE.md - User guide
📄 DETAILED_CHANGES.md - File-by-file changes
📄 UI_VISUAL_GUIDE.md - Visual layout guide
📄 QUICK_START.md - This file
```

---

## 🎓 Code Examples

### Adding a Meal Programmatically
```dart
final sessionData = context.read<SessionData>();
sessionData.addMeal({
  'name': 'Pad Thai',
  'imagePath': 'assets/food1.png',
  'calories': 450.0,
  'protein': 18.5,
  'carbs': 52.0,
  'fat': 12.0,
  'timestamp': DateTime.now(),
});
```

### Getting Total Calories
```dart
final total = sessionData.getTotalCalories(); // Double
final goal = int.parse(sessionData.goal ?? '2000');
final remaining = goal - total;
```

### Displaying Meals
```dart
Consumer<SessionData>(
  builder: (context, sessionData, _) {
    return ListView.builder(
      itemCount: sessionData.meals.length,
      itemBuilder: (context, index) {
        final meal = sessionData.meals[index];
        return ListTile(
          title: Text(meal['name']),
          subtitle: Text('${meal['calories']} kcal'),
        );
      },
    );
  },
)
```

---

## 🎨 Customization Tips

### Change Slider Ranges
In `meal_confirmation_screen.dart`:
```dart
_buildNutritionSlider(
  kanitTheme,
  'Calories',
  'kcal',
  _calories,
  0,      // min
  5000,   // max ← Change here
  (value) => setState(() => _calories = value),
)
```

### Change Colors
In any screen file:
```dart
backgroundColor: const Color(0xFFFABB5A), // Change hex code
progressColor: const Color(0xFF...), // Your color
```

### Add More Profile Fields
In `profile_screen.dart`, add to menu items list:
```dart
{
  'icon': Icons.fitness_center,
  'title': 'จำนวนครั้งออกกำลัง',
  'onTap': () => _editWorkout(context, kanitTheme),
}
```

---

## 🚦 Next Steps

### Phase 1 (Current): ✅ Complete
- [x] Meal saving fixed
- [x] Slider UI implemented
- [x] Profile screen created
- [x] Home screen updated
- [x] Navigation working

### Phase 2 (Recommended):
- [ ] Add backend API integration
- [ ] Implement database persistence (SQLite/Firebase)
- [ ] Add meal history with date filtering
- [ ] Create weekly reports

### Phase 3 (Future):
- [ ] Nutrition goal alerts
- [ ] Meal recommendations
- [ ] Export data to PDF
- [ ] Share progress on social media

---

## 📚 Resources

### Official Documentation:
- [Flutter Provider](https://pub.dev/packages/provider)
- [Flutter Sliders](https://api.flutter.dev/flutter/material/Slider-class.html)
- [Flutter Google Fonts](https://pub.dev/packages/google_fonts)

### Custom Resources:
- See `IMPLEMENTATION_NOTES.md` for technical deep dive
- See `UI_VISUAL_GUIDE.md` for layout diagrams
- See `DETAILED_CHANGES.md` for line-by-line changes

---

## ✨ Tips for Best Results

1. **Test on multiple screen sizes** - Use Android emulator at different resolutions
2. **Test network conditions** - Simulate slow 3G for API calls (future)
3. **Check Thai text rendering** - Ensure Kanit font displays correctly
4. **Test all navigation paths** - Try back buttons from every screen
5. **Clear app cache** - `flutter clean && flutter pub get` if issues occur
6. **Use DevTools** - `flutter pub global run devtools` for debugging

---

## 🎉 Success Indicators

Your implementation is working correctly when:
- ✅ Meals appear on home screen after confirmation
- ✅ Total calories update automatically
- ✅ Sliders adjust values smoothly
- ✅ Profile screen opens from bottom navigation
- ✅ Profile edits save properly
- ✅ No console errors or warnings
- ✅ Navigation flows smoothly
- ✅ All Thai text displays correctly

---

## 💬 Support

If you encounter any issues:

1. **Check the error message** - Look for specific clues
2. **Review IMPLEMENTATION_NOTES.md** - Technical troubleshooting
3. **Check the modified files** - Verify imports and syntax
4. **Run flutter analyze** - Check for warnings
5. **Clear build cache** - `flutter clean` and try again

---

**Status**: ✅ Ready for Development & Testing

**Version**: 1.0 - Meal Tracking System Update

**Last Updated**: 2024

---

Happy coding! 🚀
