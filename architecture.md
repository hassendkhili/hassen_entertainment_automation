# Maestro Automation - Project Architecture

## 📂 Folder Structure (lib/)

- **`main.dart`**: نقطة الانطلاق للتطبيق (Entry Point). مسؤول فقط عن تشغيل الواجهة الأساسية والـ Theme.
- **`models/`**: يحتوي على هياكل البيانات (Data Structures).
    - `activity_model.dart`: يحدد شكل النشاط (الاسم، الوقت، المسار، حالة التشغيل) وكيفية حفظه بصيغة JSON.
- **`screens/`**: يحتوي على واجهات المستخدم الكاملة.
    - `dashboard_screen.dart`: الشاشة الرئيسية التي تعرض الساعة وقائمة المواعيد.

## 🚀 Future Roadmap
سيتم إضافة المجلدات التالية قريباً:
- `widgets/`: للأزرار المستقلة ومؤثرات الـ Lottie.
- `services/`: لفصل منطق الصوت (AudioPlayer) وتأثيرات الـ Soundwave.