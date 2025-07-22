import os
import pandas as pd
from datetime import datetime

# تنظیم مسیرها
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data')
REPORT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'reports')
os.makedirs(REPORT_DIR, exist_ok=True)

def create_report():
    print("📝 تولید گزارش نهایی...")
    
    # بارگیری داده‌ها
    predictions_path = os.path.join(DATA_DIR, "predictions.csv")
    
    if not os.path.exists(predictions_path):
        print(f"⚠️ فایل {predictions_path} یافت نشد!")
        return
        
    try:
        df = pd.read_csv(predictions_path)
        
        if df.empty:
            print("⚠️ فایل پیش‌بینی‌ها خالی است!")
            return
    except Exception as e:
        print(f"⚠️ خطا در خواندن فایل: {str(e)}")
        return
    
    # تولید گزارش
    date_str = datetime.now().strftime("%Y-%m-%d_%H-%M")
    report_file = os.path.join(REPORT_DIR, f"viral_report_{date_str}.md")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# گزارش محتواهای ویروسی\n\n")
        f.write(f"**تاریخ تولید:** {datetime.now().strftime('%Y/%m/%d %H:%M')}\n\n")
        f.write(f"**تعداد توییت‌ها:** {len(df)}\n\n")
        
        # محتواهای برتر بر اساس تعامل
        if 'engagement' in df.columns:
            top_content = df.sort_values('engagement', ascending=False).head(10)
            f.write("## 10 محتوای برتر (بر اساس تعامل)\n\n")
            for i, row in top_content.iterrows():
                content = row.get('content', 'بدون محتوا')[:100]
                hashtag = row.get('hashtag', 'بدون هشتگ')
                
                f.write(f"{i+1}. **{content}...**\n")
                f.write(f"   - هشتگ: {hashtag}\n")
                f.write(f"   - امتیاز ویروسی: {row.get('prediction', 0.0):.2f}\n")
                f.write(f"   - تاریخ: {row.get('datetime', 'نامشخص')}\n\n")
        else:
            f.write("## محتواهای برتر\n\n")
            f.write("⚠️ داده‌های تعامل موجود نیست\n\n")
    
    print(f"✅ گزارش در {report_file} ذخیره شد")

if __name__ == "__main__":
    create_report()
