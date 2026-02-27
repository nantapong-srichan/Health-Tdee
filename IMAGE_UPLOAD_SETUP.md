# ระบบบันทึกรูปภาพอาหาร - Setup Guide

## ภาพรวม

ระบบสมบูรณ์สำหรับบันทึกรูปภาพอาหารกับ Google Cloud Storage:

- **Frontend**: Flutter app อัปโหลดรูปภาพ
- **Backend**: Node.js + Express จัดการการอัปโหลด
- **Storage**: Google Cloud Storage เก็บรูปภาพ
- **Database**: MongoDB เก็บข้อมูลและ URL ของรูป

## Quick Start

### 1. Backend Setup

```bash
cd health_app_backend

# Install dependencies
npm install

# Copy .env file
cp .env.example .env

# Edit .env with your Google Cloud credentials
# GCP_PROJECT_ID=your-project-id
# GCP_BUCKET_NAME=your-bucket-name
# GOOGLE_APPLICATION_CREDENTIALS=./path/to/key.json

# Run backend
npm run dev
```

### 2. Google Cloud Setup

```bash
# 1. สร้าง GCP Project
gcloud projects create health-app

# 2. สร้าง Storage Bucket
gsutil mb -l asia-northeast1 gs://health-app-food-images

# 3. สร้าง Service Account
gcloud iam service-accounts create health-app-backend

# 4. สร้าง Key File
gcloud iam service-accounts keys create key.json \
  --iam-account=health-app-backend@PROJECT_ID.iam.gserviceaccount.com

# 5. ให้ Permissions
gcloud projects add-iam-policy-binding health-app \
  --member="serviceAccount:health-app-backend@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectCreator"
```

### 3. Flutter Setup

```bash
cd ..

# Add dependencies
flutter pub add http image_picker

# Update code to use new ImageUploadService
# ดูรายละเอียดใน FOOD_IMAGE_STORAGE.md
```

## File Structure

```
health_app/
├── health_app_backend/
│   ├── utils/
│   │   └── uploadService.js          # Google Cloud integration
│   ├── controllers/
│   │   └── mealController.js         # Updated with image upload
│   ├── routes/
│   │   └── meals.js                  # Multer middleware added
│   ├── models/
│   │   └── Meal.js                   # imageUrl field
│   ├── .env.example                  # Configuration template
│   └── package.json                  # Updated with @google-cloud/storage
│
├── lib/
│   ├── services/
│   │   └── image_upload_service.dart # Flutter image upload service
│   └── meal_confirmation_screen.dart # Updated with image upload
│
├── FOOD_IMAGE_STORAGE.md             # Complete documentation
└── IMAGE_UPLOAD_SETUP.md             # This file
```

## ฟังก์ชันต่างๆ

### Backend: uploadImageToGCS()

```javascript
// ไฟล์: health_app_backend/utils/uploadService.js

uploadImageToGCS(fileBuffer, fileName, mimeType)
// Returns: Promise<string> - Public URL of uploaded image
```

**ตัวอย่าง:**
```javascript
const url = await uploadImageToGCS(
  fileBuffer,
  'food_photo.jpg',
  'image/jpeg'
);
// URL: https://storage.googleapis.com/bucket-name/food-images/...
```

### Backend: deleteImageFromGCS()

```javascript
deleteImageFromGCS(imageUrl)
// ลบรูปภาพจาก GCS
```

### Flutter: uploadFoodImage()

```dart
// ไฟล์: lib/services/image_upload_service.dart

final service = ImageUploadService();
String? result = await service.uploadFoodImage(imageFile);
```

### Flutter: uploadFoodImageWithMealData()

```dart
String? result = await service.uploadFoodImageWithMealData(
  imageFile: imageFile,
  foodName: 'Pad Thai',
  nutrition: {...},
  estimatedWeight: 250,
  mealType: 'lunch',
);
```

## API Endpoints

### POST /api/meals
สร้าง meal พร้อมรูปภาพ

```
Request:
- multipart/form-data
- image: File
- foodName: String
- nutrition[calories]: Number
- nutrition[protein]: Number
- ...

Response:
{
  "success": true,
  "meal": {
    "_id": "...",
    "imageUrl": "https://storage.googleapis.com/...",
    ...
  }
}
```

### PUT /api/meals/:id
อัปเดต meal (ลบรูปเก่า อัปโหลดรูปใหม่)

### DELETE /api/meals/:id
ลบ meal และรูปภาพจาก GCS

## การใช้งานในแอป

### 1. User เลือกรูปจากคลัง
```dart
// ใน image_picker_screen.dart
final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
```

### 2. ไปที่หน้า Confirmation พร้อมรูป
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MealConfirmationScreen(
      foodName: 'Pad Thai',
      imagePath: pickedFile.path,
      nutritionValues: {...},
    ),
  ),
);
```

### 3. User กด "บันทึกอาหาร"
```dart
// ใน meal_confirmation_screen.dart
void _saveMeal(BuildContext context) async {
  // 1. อัปโหลดรูปไป GCS
  String? imageUrl = await _imageUploadService.uploadFoodImage(imageFile);
  
  // 2. บันทึก meal data + imageUrl ลง MongoDB
  final response = await mealService.saveMeal(...);
  
  // 3. แสดง success message
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### 4. หนุนการแสดงรูป
```dart
// ใน home_screen.dart หรือจำที่อื่นๆ
Image.network(
  meal.imageUrl,  // URL จาก MongoDB
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Image.asset('assets/placeholder.png');
  },
)
```

## Security Notes

✅ **สิ่งที่ทำไป:**
- JWT authentication สำหรับทุก API call
- MIME type validation (image/jpeg, image/png, image/webp)
- File size limit (10MB)
- Authorization check (user สามารถแก้ไขได้แค่ meal ของตัวเอง)

⚠️ **ต้องทำเพิ่มเติม:**
- HTTPS in production
- Rate limiting
- CORS configuration
- Image encryption/compression
- Audit logging

## Troubleshooting

### Q: "Google Cloud Storage bucket not configured"
**A:** ตรวจสอบ:
1. `.env` มี `GCP_BUCKET_NAME`
2. `GOOGLE_APPLICATION_CREDENTIALS` path ถูกต้อง
3. Service account key file มีอยู่

### Q: "Permission denied" when uploading
**A:** ตรวจสอบ Service Account มี roles:
- `roles/storage.objectCreator` - สร้างไฟล์
- `roles/storage.objectViewer` - อ่านไฟล์

### Q: ไม่เห็นรูป URL ใน MongoDB
**A:**
1. ตรวจสอบ upload ไม่ error
2. ตรวจสอบ Controller ได้รับ file
3. ตรวจสอบ GCS logs

### Q: เขื่อรูปบนแอป fail
**A:** ตรวจสอบ:
1. URL ใน database ถูกต้อง
2. GCS bucket settings อนุญาต public read
3. Network connectivity

## Environment Variables

```env
GCP_PROJECT_ID=your-gcp-project-id
GCP_BUCKET_NAME=your-bucket-name
GOOGLE_APPLICATION_CREDENTIALS=./credentials/key.json

MONGODB_URI=mongodb+srv://...
JWT_SECRET=your-secret-key
```

## Testing

```bash
# Test backend
curl -X POST http://localhost:3000/api/meals \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@/path/to/image.jpg" \
  -F "foodName=Test Food" \
  -F "nutrition[calories]=500"

# Check GCS
gsutil ls gs://health-app-food-images/food-images/
```

## Next Steps

1. ✅ ตั้งค่า Google Cloud Storage
2. ✅ Deploy Backend
3. ✅ Setup Flutter app
4. ⏳ Test end-to-end flow
5. ⏳ Performance optimization
6. ⏳ Add image compression/resizing
7. ⏳ Deploy to production

## Support

สำหรับปัญหาเพิ่มเติม ดูไฟล์:
- `FOOD_IMAGE_STORAGE.md` - Complete documentation
- Backend logs - `npm run dev`
- GCS logs - Google Cloud Console

---

**Created:** February 2026
**Version:** 1.0.0
