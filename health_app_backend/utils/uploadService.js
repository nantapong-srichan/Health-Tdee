const { Storage } = require('@google-cloud/storage');
const path = require('path');

// สร้าง instance ของ Google Cloud Storage
// ต้องตั้งค่า GOOGLE_APPLICATION_CREDENTIALS ในไฟล์ .env หรือ environment variable
let storage;

try {
  // ตัวเลือก 1: ใช้ service account key file
  const keyFilePath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  
  if (keyFilePath) {
    storage = new Storage({
      projectId: process.env.GCP_PROJECT_ID,
      keyFilename: keyFilePath,
    });
  } else {
    // ตัวเลือก 2: ใช้ Application Default Credentials (สำหรับ production)
    storage = new Storage({
      projectId: process.env.GCP_PROJECT_ID,
    });
  }
  
  console.log('✅ Google Cloud Storage initialized');
} catch (error) {
  console.error('❌ Error initializing Google Cloud Storage:', error);
}

const bucket = storage?.bucket(process.env.GCP_BUCKET_NAME);

/**
 * อัปโหลดรูปภาพไปยัง Google Cloud Storage
 * @param {Buffer} fileBuffer - ข้อมูล buffer ของไฟล์
 * @param {string} fileName - ชื่อไฟล์ที่ต้องการบันทึก
 * @param {string} mimeType - MIME type ของไฟล์
 * @returns {Promise<string>} - URL สาธารณะของรูปที่อัปโหลด
 */
async function uploadImageToGCS(fileBuffer, fileName, mimeType = 'image/jpeg') {
  try {
    if (!bucket) {
      throw new Error('Google Cloud Storage bucket not configured');
    }

    // สร้างชื่อไฟล์ที่ไม่ซ้ำกัน (เพิ่ม timestamp)
    const timestamp = Date.now();
    const uniqueFileName = `food-images/${timestamp}_${fileName}`;

    // สร้าง file reference
    const file = bucket.file(uniqueFileName);

    // อัปโหลดไฟล์ไปยัง GCS
    await file.save(fileBuffer, {
      metadata: {
        contentType: mimeType,
      },
    });

    // ตั้งให้ไฟล์เป็น public (เพื่อให้สามารถเข้าถึงได้ผ่าน URL)
    await file.makePublic();

    // คืน URL สาธารณะ
    const publicUrl = `https://storage.googleapis.com/${process.env.GCP_BUCKET_NAME}/${uniqueFileName}`;

    console.log(`✅ Image uploaded successfully: ${publicUrl}`);
    return publicUrl;
  } catch (error) {
    console.error('❌ Error uploading image to GCS:', error);
    throw new Error(`Failed to upload image: ${error.message}`);
  }
}

/**
 * ลบรูปภาพจาก Google Cloud Storage
 * @param {string} imageUrl - URL ของรูปที่ต้องการลบ
 * @returns {Promise<void>}
 */
async function deleteImageFromGCS(imageUrl) {
  try {
    if (!bucket || !imageUrl) {
      return; // ไม่ลบหากไม่มี URL
    }

    // แยกชื่อไฟล์จาก URL
    const filePath = imageUrl.split(`${process.env.GCP_BUCKET_NAME}/`)[1];
    
    if (!filePath) return;

    const file = bucket.file(filePath);
    await file.delete();

    console.log(`✅ Image deleted successfully: ${filePath}`);
  } catch (error) {
    console.error('❌ Error deleting image from GCS:', error);
    // ไม่ throw error เพื่อไม่ให้มีผลต่อการบันทึก meal
  }
}

module.exports = {
  uploadImageToGCS,
  deleteImageFromGCS,
  bucket,
};
