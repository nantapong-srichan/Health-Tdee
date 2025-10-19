// คลาสสำหรับเก็บผลลัพธ์การรู้จำอาหาร
class RecognitionResult {
  final String foodName;      // ชื่ออาหารที่รู้จำได้
  final double confidence;    // ความมั่นใจในการรู้จำ (0-1)
  final double estimatedWeight; // น้ำหนักที่ประมาณได้ (กรัม)

  RecognitionResult({
    required this.foodName,
    required this.confidence,
    required this.estimatedWeight,
  });
}