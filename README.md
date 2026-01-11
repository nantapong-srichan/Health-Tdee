# Health App - Meal Tracking System

A comprehensive Flutter health and meal tracking application with AI-powered food recognition and user profile management.

### Quick Start

```bash
# Clean and prepare
flutter clean
flutter pub get

# Run the app
flutter run
```

##  Features

### Meal Tracking
-  Food recognition with AI/ML
-  Interactive sliders for nutrition adjustment
-  Persistent meal storage
-  Real-time calorie tracking
-  Success notifications

### User Profile
-  Personal information management
-  Email and password management
-  Health information tracking
-  Secure logout

### Home Screen
-  Daily calorie progress
-  Meal history display
-  Nutrition goal tracking
-  Date-based filtering

##  Testing

### Test the App
1. **Add a Meal**:
   - Tap camera button
   - Take/select photo
   - Adjust sliders in confirmation
   - Save meal

2. **Manage Profile**:
   - Click person icon
   - Edit profile information
   - Update email/password
   - Save changes

3. **View Tracking**:
   - See meals on home screen
   - Check total calories
   - Monitor progress


## 📈 Future Roadmap

### Phase 2
- Backend API integration
- Database persistence (Firebase/SQLite)
- Meal history with filtering
- Weekly nutrition reports

### Phase 3
- Advanced analytics
- Goal tracking
- Meal recommendations
- Export features

## 🐛 Troubleshooting

### Common Issues

**Meals not appearing?**
- Check that SessionData provider is set up in main.dart
- Verify Consumer<SessionData> wrapping meal list
- Look for any console errors

**Sliders not working?**
- Verify SliderTheme is properly configured
- Check min/max values are correct
- Ensure state is updating with setState

**Profile not opening?**
- Check that ProfileScreen import is correct
- Verify bottom navigation onPressed callback
- Check navigation isn't blocked

See [QUICK_START.md](QUICK_START.md#-troubleshooting) for more help.

