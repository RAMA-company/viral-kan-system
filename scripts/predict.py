import os
import pandas as pd
import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# تنظیم مسیرها
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data')
MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'models')
os.makedirs(MODEL_DIR, exist_ok=True)

def train_model():
    print("🤖 آموزش مدل پیش‌بینی...")
    
    # بارگیری داده‌ها
    data_path = os.path.join(DATA_DIR, "dataset.csv")
    if not os.path.exists(data_path):
        print(f"⚠️ فایل {data_path} یافت نشد!")
        return
        
    df = pd.read_csv(data_path)
    
    # بررسی وجود داده
    if df.empty:
        print("⚠️ فایل داده خالی است! استفاده از داده‌های نمونه")
        df = pd.DataFrame({
            'likes': [100, 150, 200, 250, 180],
            'retweets': [20, 30, 40, 50, 25],
            'replies': [5, 8, 10, 12, 7],
            'engagement': [145, 218, 290, 362, 237],
            'target': [0, 1, 1, 1, 0]
        })
    
    # ایجاد ویژگی‌ها
    features = ['likes', 'retweets', 'replies', 'engagement']
    
    # اطمینان از وجود ستون‌ها
    for feature in features:
        if feature not in df.columns:
            df[feature] = 0
    
    X = df[features]
    
    # ایجاد برچسب‌های نمونه
    if 'target' not in df.columns:
        y = np.random.randint(0, 2, size=len(df))
    else:
        y = df['target']
    
    # مدیریت داده‌های ناکافی
    if len(X) < 2:
        print(f"⚠️ داده‌های ناکافی (n_samples={len(X)}). آموزش مدل با کل داده‌ها")
        model = RandomForestClassifier(n_estimators=50, random_state=42)
        model.fit(X, y)
    else:
        # تقسیم داده‌ها
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # آموزش مدل
        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        
        # ارزیابی مدل
        y_pred = model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        print(f"📊 دقت مدل: {accuracy:.2f}")
    
    # ذخیره مدل
    model_path = os.path.join(MODEL_DIR, "viral_predict_model.pkl")
    joblib.dump(model, model_path)
    print(f"💾 مدل در {model_path} ذخیره شد")
    
    # ایجاد پیش‌بینی‌ها
    df['prediction'] = model.predict(X)
    
    # ذخیره پیش‌بینی‌ها
    predictions_path = os.path.join(DATA_DIR, "predictions.csv")
    df.to_csv(predictions_path, index=False)
    print(f"💾 پیش‌بینی‌ها در {predictions_path} ذخیره شد")

if __name__ == "__main__":
    train_model()
