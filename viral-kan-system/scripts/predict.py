import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import joblib
import os

DATA_DIR = "../data"
MODEL_DIR = "../models"
os.makedirs(MODEL_DIR, exist_ok=True)

def train_model():
    # بارگیری داده‌ها
    df = pd.read_csv(os.path.join(DATA_DIR, "data.csv"))
    df['datetime'] = pd.to_datetime(df['datetime'])
    
    # مهندسی ویژگی‌ها
    df['hour'] = df['datetime'].dt.hour
    df['text_length'] = df['content'].str.len()
    df['has_question'] = df['content'].str.contains('\?').astype(int)
    
    # برچسب‌گذاری
    engagement_threshold = df['engagement'].quantile(0.85)
    df['is_viral'] = (df['engagement'] >= engagement_threshold).astype(int)
    
    # ویژگی‌ها و برچسب
    features = ['hour', 'text_length', 'has_question']
    X = df[features]
    y = df['is_viral']
    
    # تقسیم داده
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # آموزش مدل
    print("🏗️ Training AI model...")
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # ارزیابی
    accuracy = model.score(X_test, y_test)
    print(f"🔬 Model Accuracy: {accuracy:.2%}")
    
    # پیش‌بینی
    df['viral_prob'] = model.predict_proba(X)[:, 1] * 100
    
    # ذخیره مدل و داده
    model_path = os.path.join(MODEL_DIR, "viral_model.pkl")
    joblib.dump(model, model_path)
    
    predictions_path = os.path.join(DATA_DIR, "predictions.csv")
    df.to_csv(predictions_path, index=False)
    print(f"💾 Saved predictions to {predictions_path}")

if __name__ == "__main__":
    train_model()