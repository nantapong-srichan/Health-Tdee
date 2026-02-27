# ระบบบันทึกรูปภาพอาหารด้วย Google Cloud Storage

## ภาพรวมระบบ

ระบบนี้ช่วยให้ผู้ใช้สามารถบันทึกรูปภาพอาหารและข้อมูลโภคนการในแอปพลิเคชัน โดยรูปภาพจะถูกอัปโหลดไปยัง Google Cloud Storage และเก็บ URL ของรูปในฐานข้อมูล MongoDB

### ขั้นตอนการทำงาน

```
1. ผู้ใช้เลือกรูปภาพอาหาร (Image Picker)
   ↓
2. Flutter ส่งรูปภาพไปยัง Backend (Multipart Request)
   ↓
3. Backend อัปโหลดรูปภาพไปยัง Google Cloud Storage
   ↓
4. Backend ได้รับ URL ของรูปภาพจาก GCS
   ↓
5. Backend บันทึกข้อมูลอาหารและ URL ลง MongoDB
   ↓
6. Flutter ได้รับ response พร้อม meal ID
   ↓
7. ผู้ใช้สามารถเรียกใช้รูปภาพผ่าน URL
```

## Setup Google Cloud Storage

### 1. สร้าง Google Cloud Project

```bash
# ติดตั้ง Google Cloud CLI
# https://cloud.google.com/sdk/docs/install

# สร้าง project
gcloud projects create health-app-project

# ตั้ง default project
gcloud config set project health-app-project
```

### 2. สร้าง Storage Bucket

```bash
# สร้าง bucket (ชื่อต้องไม่ซ้ำกันทั่วโลก)
gsutil mb -l asia-northeast1 gs://health-app-food-images

# ตั้ง permission ให้ public read
gsutil iam ch allUsers:objectViewer gs://health-app-food-images

# หรือใช้ policy JSON file
gsutil iam ch serviceAccount:SERVICE_ACCOUNT@PROJECT.iam.gserviceaccount.com:objectCreator gs://health-app-food-images
```

### 3. สร้าง Service Account

```bash
# สร้าง service account
gcloud iam service-accounts create health-app-backend \
  --display-name="Health App Backend"

# สร้าง key file (JSON)
gcloud iam service-accounts keys create key.json \
  --iam-account=health-app-backend@health-app-project.iam.gserviceaccount.com

# ให้ permissions กับ bucket
gcloud projects add-iam-policy-binding health-app-project \
  --member="serviceAccount:health-app-backend@health-app-project.iam.gserviceaccount.com" \
  --role="roles/storage.objectCreator"

gcloud projects add-iam-policy-binding health-app-project \
  --member="serviceAccount:health-app-backend@health-app-project.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

### 4. ตั้งค่า Environment Variables

สร้าง `.env` ไฟล์ในโฟลเดอร์ `health_app_backend/`:

```env
# Google Cloud Storage
GCP_PROJECT_ID=health-app-project
GCP_BUCKET_NAME=health-app-food-images
GOOGLE_APPLICATION_CREDENTIALS=./path/to/key.json

# MongoDB
MONGODB_URI=mongodb://username:password@host:port/database

# JWT
JWT_SECRET=your_secret_key

# API
API_PORT=3000
API_HOST=http://localhost:3000
```

## Backend Implementation

### 1. Package Dependencies

```bash
npm install @google-cloud/storage multer
```

### 2. File Structure

```
health_app_backend/
├── utils/
│   └── uploadService.js      # Google Cloud Storage integration
├── controllers/
│   └── mealController.js     # Updated with image upload
├── routes/
│   └── meals.js              # Updated with multer middleware
├── models/
│   └── Meal.js               # imageUrl field added
└── .env                       # Configuration
```

### 3. Image Upload Service

[uploadService.js](../health_app_backend/utils/uploadService.js) ให้ฟังก์ชัน:

- `uploadImageToGCS()` - อัปโหลดรูปภาพไปยัง GCS
- `deleteImageFromGCS()` - ลบรูปภาพจาก GCS

### 4. Meal Controller

Updated `mealController.js` รับรองการ:

- **POST /api/meals** - สร้าง meal พร้อมรูปภาพ
- **PUT /api/meals/:id** - อัปเดต meal พร้อมอัปโหลดรูปใหม่
- **DELETE /api/meals/:id** - ลบ meal และรูปภาพ

### 5. Routes with Multer

```javascript
// meals.js
const multer = require('multer');

const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  fileFilter: (req, file, cb) => {
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

router.post('/', upload.single('image'), mealController.saveMeal);
router.put('/:id', upload.single('image'), mealController.updateMeal);
```

## Flutter Implementation

### 1. Image Upload Service

[image_upload_service.dart](../lib/services/image_upload_service.dart) ให้ฟังก์ชัน:

- `uploadFoodImage()` - อัปโหลดรูปภาพเพียงอย่างเดียว
- `uploadFoodImageWithMealData()` - อัปโหลดรูปพร้อมข้อมูล meal

### 2. Meal Confirmation Screen

Updated [meal_confirmation_screen.dart](../lib/meal_confirmation_screen.dart):

- เพิ่มการอัปโหลดรูปภาพเมื่อบันทึก meal
- แสดง loading indicator ระหว่างการอัปโหลด
- จัดเก็บ URL ของรูปแทน local file path

### 3. การใช้งาน

```dart
final imageUploadService = ImageUploadService();

// วิธี 1: อัปโหลดรูปเพียงอย่างเดียว
String? imageUrl = await imageUploadService.uploadFoodImage(imageFile);

// วิธี 2: อัปโหลดรูปพร้อมข้อมูล meal
String? result = await imageUploadService.uploadFoodImageWithMealData(
  imageFile: imageFile,
  foodName: 'ข้าวหมูแดง',
  nutrition: {
    'calories': 500,
    'protein': 25,
    'carbohydrates': 60,
    'fat': 15,
  },
  estimatedWeight: 250,
  mealType: 'lunch',
);
```

## MongoDB Schema

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  foodName: String,
  nutrition: {
    calories: Number,
    protein: Number,
    carbohydrates: Number,
    fat: Number,
    fiber: Number,
    sodium: Number,
  },
  estimatedWeight: Number,
  imageUrl: String,  // URL ของรูปจาก Google Cloud Storage
  confidence: Number,
  mealType: String,
  mealTime: Date,
  notes: String,
  createdAt: Date,
  updatedAt: Date,
}
```

## URL Format

รูปภาพจะเก็บไว้ที่:

```
https://storage.googleapis.com/{BUCKET_NAME}/food-images/{TIMESTAMP}_{FILENAME}
```

ตัวอย่าง:
```
https://storage.googleapis.com/health-app-food-images/food-images/1707312000000_photo.jpg
```

## API Endpoints

### Create Meal with Image

```
POST /api/meals
Content-Type: multipart/form-data

Body:
- image: File
- foodName: String
- nutrition[calories]: Number
- nutrition[protein]: Number
- nutrition[carbohydrates]: Number
- nutrition[fat]: Number
- estimatedWeight: Number
- mealType: String

Response:
{
  "success": true,
  "message": "Meal saved successfully",
  "meal": {
    "_id": "...",
    "imageUrl": "https://storage.googleapis.com/...",
    ...
  }
}
```

### Update Meal with New Image

```
PUT /api/meals/:id
Content-Type: multipart/form-data

Body:
- image: File (optional, if updating image)
- Other nutrition fields...

Response:
{
  "success": true,
  "message": "Meal updated successfully",
  "meal": {
    "_id": "...",
    "imageUrl": "https://storage.googleapis.com/...",
    ...
  }
}
```

### Delete Meal (removes image from GCS)

```
DELETE /api/meals/:id

Response:
{
  "success": true,
  "message": "Meal deleted successfully"
}
```

## Security Considerations

### 1. Authentication
- ทุก request ต้อง include JWT token ใน header
- Backend ตรวจสอบ token ก่อนการอัปโหลด

### 2. File Validation
- ตรวจสอบ MIME type (image/jpeg, image/png, image/webp)
- ตรวจสอบขนาดไฟล์ (max 10MB)
- ตรวจสอบชื่อไฟล์ (remove special characters)

### 3. GCS Permissions
- Service Account มี permission แค่ `objectCreator` และ `objectViewer`
- Bucket policy อนุญาต public read only
- Private images สำหรับ specific users

### 4. Data Privacy
- เก็บ user ID กับ meal data
- ตรวจสอบ authorization ก่อนแสดง meal ของ user อื่น

## Troubleshooting

### Error: "Google Cloud Storage bucket not configured"
- ตรวจสอบ `.env` ไฟล์มี `GCP_BUCKET_NAME` และ `GOOGLE_APPLICATION_CREDENTIALS`
- ตรวจสอบ service account key file มีอยู่จริง

### Error: "Permission denied" เมื่ออัปโหลด
- ตรวจสอบ service account มี `roles/storage.objectCreator`
- ตรวจสอบ bucket permissions

### Error: "File size exceeds limit"
- ขนาดไฟล์ต้องน้อยกว่า 10MB
- สามารถปรับได้ใน `multer.limits.fileSize`

### Images not accessible
- ตรวจสอบ bucket policy อนุญาต public read
- ตรวจสอบ URL format ถูกต้อง

## Performance Tips

1. **Image Compression**
   - Compress images ก่อนอัปโหลด (Flutter)
   - ใช้ library เช่น `image_picker_web` ที่มี compression

2. **Caching**
   - Cache images locally ใน app
   - ใช้ CDN cache headers ใน GCS

3. **Parallel Uploads**
   - อัปโหลดหลาย images พร้อมกัน
   - Implement queue system สำหรับ batch uploads

4. **Background Processing**
   - ใช้ Worker threads สำหรับ image uploads
   - Implement retry logic สำหรับ failed uploads

## Next Steps

1. ทดสอบการอัปโหลดรูปภาพ
2. เพิ่ม image compression
3. เพิ่ม image resizing สำหรับ thumbnails
4. Implement image caching strategy
5. เพิ่ม image editing features
