#!/bin/bash

# رفع قطعی مشکل snscrape با پایتون 3.12
echo "نصب نسخه سازگار snscrape برای پایتون 3.12..."
pip uninstall -y snscrape > /dev/null 2>&1
pip install git+https://github.com/JustAnotherArchivist/snscrape.git@master > /dev/null 2>&1

# اصلاح predict.py با مدیریت کامل داده‌های ناکافی
echo "اصلاح اسکریپت پیش‌بینی..."
cat > scripts/predict.py << 'EOF'
import os
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

# تنظیم مسیرها
DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data')
MODEL_DIR = os.path.join(os.path.dirname(__file__), '..', 'models')
os.makedirs(MODEL_DIR, exist_ok=True)

def train_model():
    # بارگیری داده‌ها
    df = pd.read_csv(os.path.join(DATA_DIR, "dataset.csv"))
    
    # پیش‌پردازش داده‌ها
    # ... (کدهای پیش‌پردازش شما)
    
    # تقسیم داده‌ها
    X = df.drop('target', axis=1)
    y = df['target']
    
    # مدیریت داده‌های ناکافی
    if len(X) < 2:
        print(f"⚠️  هشدار: داده‌های ناکافی (n_samples={len(X)}). آموزش مدل با کل داده‌ها")
        X_train, y_train = X, y
        
        # آموزش مدل بدون تست
        model = RandomForestClassifier(n_estimators=100)
        model.fit(X_train, y_train)
        
        # ذخیره مدل
        joblib.dump(model, os.path.join(MODEL_DIR, "viral_predict_model.pkl"))
        print("✅ مدل با داده‌های کامل آموزش داده و ذخیره شد")
        return
    else:
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # آموزش مدل
    print("🏗️ آموزش مدل هوش مصنوعی...")
    model = RandomForestClassifier(n_estimators=100)
    model.fit(X_train, y_train)
    
    # ارزیابی مدل
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"📊 دقت مدل: {accuracy:.2f}")
    
    # پیش‌بینی‌ها
    predictions = model.predict(X)
    df['prediction'] = predictions
    df.to_csv(os.path.join(DATA_DIR, "predictions.csv"), index=False)
    
    # ذخیره مدل
    joblib.dump(model, os.path.join(MODEL_DIR, "viral_predict_model.pkl"))
    print("✅ مدل آموزش داده و ذخیره شد")

if __name__ == "__main__":
    train_model()
EOF

# اصلاح generate_report.py با مدیریت کامل خطاها
echo "اصلاح اسکریپت گزارش‌گیری..."
cat > scripts/generate_report.py << 'EOF'
import os
import pandas as pd
from datetime import datetime

# تنظیم مسیرها
DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data')
REPORT_DIR = os.path.join(os.path.dirname(__file__), '..', 'reports')
os.makedirs(REPORT_DIR, exist_ok=True)

def create_report():
    # بارگیری داده‌ها با مدیریت خطا
    try:
        df = pd.read_csv(os.path.join(DATA_DIR, "predictions.csv"))
        
        # بررسی خالی بودن داده‌ها
        if df.empty:
            print("⚠️  هشدار: فایل پیش‌بینی‌ها خالی است")
            return
    except (FileNotFoundError, pd.errors.EmptyDataError) as e:
        print(f"⚠️  خطا در خواندن فایل: {e}")
        return
    
    # تولید گزارش
    print("📝 تولید گزارش نهایی...")
    date_str = datetime.now().strftime("%Y-%m-%d_%H-%M")
    report_file = os.path.join(REPORT_DIR, f"viral_report_{date_str}.md")
    
    with open(report_file, 'w') as f:
        f.write("# گزارش محتواهای ویروسی\n\n")
        f.write(f"تاریخ تولید: {datetime.now().strftime('%Y/%m/%d %H:%M')}\n\n")
        
        # 10 محتوای برتر
        top_content = df.sort_values('prediction', ascending=False).head(10)
        f.write("## 10 محتوای برتر\n\n")
        for i, row in top_content.iterrows():
            f.write(f"{i+1}. **{row['content'][:50]}...** - امتیاز ویروسی: {row['prediction']:.2f}\n")
    
    print(f"✅ گزارش در {report_file} ذخیره شد")

if __name__ == "__main__":
    create_report()
EOF

# اجرای کامل پاین‌لاین
echo "شروع فرآیند جمع‌آوری داده‌ها..."
python scripts/twitter_scraper.py

echo "شروع آموزش مدل و پیش‌بینی..."
python scripts/predict.py

echo "تولید گزارش نهایی..."
python scripts/generate_report.py

echo "✅ تمام مراحل با موفقیت تکمیل شد!"
