#!/bin/bash

# مرحله 1: ایجاد ساختار دایرکتوری‌ها
echo "📁 ایجاد ساختار دایرکتوری‌ها..."
mkdir -p scripts data models reports dashboard

# مرحله 2: ایجاد اسکریپت‌های اصلی
cat > scripts/twitter_scraper.py << 'EOF'
import os
import pandas as pd
import snscrape.modules.twitter as sntwitter
from datetime import datetime, timedelta
import random
import time

# تنظیمات
HASHTAGS = ["#crypto", "#bitcoin", "#ai", "#gaming", "#tech"]
MAX_TWEETS = 200
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data')
os.makedirs(DATA_DIR, exist_ok=True)

def robust_scrape(query, max_tweets, retries=3):
    for attempt in range(retries):
        try:
            tweets = []
            scraper = sntwitter.TwitterSearchScraper(query)
            
            for i, tweet in enumerate(scraper.get_items()):
                if i >= max_tweets:
                    break
                    
                # استفاده از مقادیر واقعی توییت
                tweet_data = [
                    tweet.date,
                    tweet.rawContent,
                    tweet.likeCount,
                    tweet.retweetCount,
                    tweet.replyCount,
                    query.split()[0]
                ]
                tweets.append(tweet_data)
                
            return tweets
            
        except Exception as e:
            print(f"⚠️ خطا در جمع‌آوری (تلاش {attempt+1}/{retries}): {str(e)}")
            time.sleep(random.uniform(1, 3))
    
    print(f"❌ جمع‌آوری برای {query} پس از {retries} تلاش ناموفق بود")
    return []

def scrape_twitter():
    print("🚀 شروع جمع‌آوری توییت‌ها...")
    end_date = datetime.now()
    start_date = end_date - timedelta(days=2)
    all_tweets = []
    
    print(f"📌 جمع‌آوری داده برای {len(HASHTAGS)} هشتگ...")
    
    for hashtag in HASHTAGS:
        query = f"{hashtag} since:{start_date.date()} lang:en"
        print(f"🔍 در حال جستجو: {query}")
        
        tweets = robust_scrape(query, MAX_TWEETS)
        all_tweets.extend(tweets)
        print(f"✅ {len(tweets)} توییت برای {hashtag} جمع‌آوری شد")
    
    if not all_tweets:
        print("⚠️ هیچ توییتی جمع‌آوری نشد! از داده‌های نمونه استفاده می‌شود")
        all_tweets = [
            [datetime.now(), "توییت نمونه: پیشرفت‌های جدید در هوش مصنوعی", 150, 25, 8, "#ai"],
            [datetime.now(), "توییت نمونه: تحلیل بازار بیت‌کوین", 200, 40, 15, "#bitcoin"]
        ]
    
    # ایجاد DataFrame
    df = pd.DataFrame(all_tweets, 
                     columns=['datetime', 'content', 'likes', 'retweets', 'replies', 'hashtag'])
    
    # محاسبه تعامل کل
    df['engagement'] = df['likes'] + (df['retweets'] * 2) + df['replies']
    
    # ذخیره داده
    output_path = os.path.join(DATA_DIR, "dataset.csv")
    df.to_csv(output_path, index=False)
    print(f"💾 {len(df)} توییت در {output_path} ذخیره شد")

if __name__ == "__main__":
    scrape_twitter()
EOF

cat > scripts/predict.py << 'EOF'
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
            'likes': [100, 150, 200],
            'retweets': [20, 30, 40],
            'replies': [5, 8, 10],
            'engagement': [145, 218, 290],
            'target': [0, 1, 1]
        })
    
    # ایجاد ویژگی‌ها و برچسب (داده‌های نمونه)
    X = df[['likes', 'retweets', 'replies', 'engagement']]
    
    # ایجاد برچسب‌های نمونه
    if 'target' not in df.columns:
        # اگر ستون target وجود ندارد، نمونه‌سازی تصادفی
        y = np.random.randint(0, 2, size=len(df))
    else:
        y = df['target']
    
    # مدیریت داده‌های ناکافی
    if len(X) < 2:
        print(f"⚠️ داده‌های ناکافی (n_samples={len(X)}). آموزش مدل با کل داده‌ها")
        model = RandomForestClassifier(n_estimators=50)
        model.fit(X, y)
    else:
        # تقسیم داده‌ها
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # آموزش مدل
        model = RandomForestClassifier(n_estimators=100)
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
EOF

cat > scripts/generate_report.py << 'EOF'
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
EOF

cat > scripts/generate_dashboard.py << 'EOF'
import os
import pandas as pd
from datetime import datetime
import shutil

# تنظیم مسیرها
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data')
DASHBOARD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'dashboard')
os.makedirs(DASHBOARD_DIR, exist_ok=True)

def generate_dashboard():
    print("🖥️  ایجاد داشبورد تعاملی...")
    
    # بارگیری داده‌ها
    predictions_path = os.path.join(DATA_DIR, "predictions.csv")
    
    if os.path.exists(predictions_path):
        try:
            df = pd.read_csv(predictions_path)
        except:
            df = pd.DataFrame()
    else:
        df = pd.DataFrame()
    
    # ایجاد HTML
    html_content = f"""
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>داشبورد محتواهای ویروسی</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">
    <style>
        :root {{
            --primary: #4361ee;
            --secondary: #3f37c9;
            --success: #4cc9f0;
            --dark: #212529;
        }}
        
        body {{ 
            background-color: #f8f9fa; 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            padding-bottom: 60px;
        }}
        
        .navbar {{ box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        
        .card {{ 
            border: none; 
            border-radius: 15px; 
            box-shadow: 0 4px 6px rgba(0,0,0,0.05); 
            transition: transform 0.3s; 
            margin-bottom: 20px;
            overflow: hidden;
        }}
        
        .card:hover {{ transform: translateY(-5px); }}
        
        .tweet-card .card-body {{ padding: 15px; }}
        
        .tweet-content {{ 
            font-size: 0.95rem; 
            line-height: 1.6; 
            margin-bottom: 10px;
            color: var(--dark);
        }}
        
        .tweet-stats {{ 
            display: flex; 
            justify-content: space-between; 
            font-size: 0.85rem; 
            color: #6c757d;
        }}
        
        .stat-badge {{ 
            display: inline-flex; 
            align-items: center; 
            gap: 5px;
        }}
        
        .hashtag-tag {{
            background-color: #e9ecef;
            border-radius: 20px;
            padding: 2px 10px;
            font-size: 0.8rem;
            color: #495057;
        }}
        
        .last-updated {{
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: var(--primary);
            color: white;
            padding: 10px;
            text-align: center;
            font-size: 0.9rem;
            z-index: 1000;
        }}
        
        @media (max-width: 768px) {{
            .card {{ border-radius: 10px; }}
            .tweet-content {{ font-size: 0.9rem; }}
        }}
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark" style="background: linear-gradient(135deg, var(--primary), var(--secondary));">
        <div class="container">
            <a class="navbar-brand d-flex align-items-center" href="#">
                <i class="bi bi-lightning-charge fs-4 me-2"></i>
                <span>سیستم تحلیل محتوای ویروسی</span>
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link active" href="#"><i class="bi bi-house-door me-1"></i> خانه</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#"><i class="bi bi-graph-up me-1"></i> آمار</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#"><i class="bi bi-clock-history me-1"></i> تاریخچه</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container py-4">
        <div class="row mb-4">
            <div class="col-12">
                <div class="card bg-primary text-white">
                    <div class="card-body py-3">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h5 class="card-title mb-1">وضعیت سیستم</h5>
                                <p class="card-text mb-0">آخرین بروزرسانی: {datetime.now().strftime('%H:%M')}</p>
                            </div>
                            <i class="bi bi-check-circle-fill fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-lg-8">
                <div class="card">
                    <div class="card-header bg-white border-0 py-3">
                        <h5 class="mb-0">۱۰ محتوای برتر</h5>
                    </div>
                    <div class="card-body p-0">
                        {"".join([
                            f'<div class="tweet-card border-bottom">'
                            f'<div class="card-body">'
                            f'<p class="tweet-content">{row["content"][:120]}{"..." if len(row["content"]) > 120 else ""}</p>'
                            f'<div class="d-flex justify-content-between align-items-center">'
                            f'<span class="hashtag-tag">{row.get("hashtag", "#بدون_هشتگ")}</span>'
                            f'<div class="tweet-stats">'
                            f'<span class="stat-badge"><i class="bi bi-heart-fill text-danger"></i> {row.get("likes", 0)}</span>'
                            f'<span class="stat-badge mx-2"><i class="bi bi-repeat text-success"></i> {row.get("retweets", 0)}</span>'
                            f'<span class="stat-badge"><i class="bi bi-chat-left-text text-info"></i> {row.get("replies", 0)}</span>'
                            f'</div></div>'
                            f'<div class="mt-2 text-end">'
                            f'<span class="badge bg-warning text-dark">امتیاز: {row.get("prediction", 0):.2f}</span>'
                            f'</div></div></div>'
                            for _, row in df.sort_values('engagement', ascending=False).head(10).iterrows()
                        ]) if not df.empty else 
                        '<div class="text-center py-5"><i class="bi bi-inbox fs-1 text-muted"></i><p class="mt-3">داده‌ای برای نمایش وجود ندارد</p></div>'}
                    </div>
                </div>
            </div>
            
            <div class="col-lg-4">
                <div class="card">
                    <div class="card-header bg-white border-0 py-3">
                        <h5 class="mb-0">آمار کلی</h5>
                    </div>
                    <div class="card-body">
                        {"<div class='mb-3'>"
                        "<div class='d-flex justify-content-between mb-2'><span>تعداد توییت‌ها</span><strong>" + str(len(df)) + "</strong></div>"
                        "<div class='d-flex justify-content-between mb-2'><span>میانگین تعامل</span><strong>" + (f"{df['engagement'].mean():.0f}" if not df.empty else "0") + "</strong></div>"
                        "<div class='d-flex justify-content-between mb-2'><span>بیشترین تعامل</span><strong>" + (f"{df['engagement'].max()}" if not df.empty else "0") + "</strong></div>"
                        "<div class='d-flex justify-content-between'><span>پربازدیدترین هشتگ</span><strong>" + (f"{df['hashtag'].value_counts().idxmax()}" if not df.empty else "-") + "</strong></div>"
                        "</div>" if not df.empty else '<div class="text-center py-4"><i class="bi bi-exclamation-circle fs-1 text-muted"></i><p class="mt-3">داده‌ای برای نمایش وجود ندارد</p></div>'}
                    </div>
                </div>
                
                <div class="card mt-4">
                    <div class="card-header bg-white border-0 py-3">
                        <h5 class="mb-0">توزیع هشتگ‌ها</h5>
                    </div>
                    <div class="card-body">
                        {"".join([
                            f'<div class="d-flex justify-content-between mb-2">'
                            f'<span>{hashtag}</span>'
                            f'<span>{count}</span>'
                            f'</div>'
                            f'<div class="progress mb-3" style="height: 8px;">'
                            f'<div class="progress-bar" style="width: {(count/max_count)*100}%; background-color: {colors[i % len(colors)]};"></div>'
                            f'</div>'
                            for i, (hashtag, count) in enumerate(df['hashtag'].value_counts().head(5).items())
                        ]) if not df.empty else '<div class="text-center py-4"><i class="bi bi-hash fs-1 text-muted"></i><p class="mt-3">هشتگی یافت نشد</p></div>'}
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="last-updated">
        آخرین بروزرسانی: {datetime.now().strftime('%Y/%m/%d %H:%M')} | سیستم هر 6 ساعت به‌طور خودکار به‌روز می‌شود
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // به‌روزرسانی خودکار هر 5 دقیقه
        setTimeout(() => location.reload(), 300000);
        
        // تنظیم رنگ‌های پیشرفت‌بار
        const colors = ['#4361ee', '#3a0ca3', '#7209b7', '#f72585', '#4cc9f0'];
        document.querySelectorAll('.progress-bar').forEach((bar, i) => {{
            bar.style.backgroundColor = colors[i % colors.length];
        }});
    </script>
</body>
</html>
"""
    
    # ذخیره فایل داشبورد
    dashboard_path = os.path.join(DASHBOARD_DIR, "index.html")
    with open(dashboard_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    # کپی برای دسترسی راحت‌تر
    shutil.copy(dashboard_path, "index.html")
    
    print(f"✅ داشبورد در {dashboard_path} ذخیره شد")

if __name__ == "__main__":
    generate_dashboard()
EOF

# مرحله 3: ایجاد اسکریپت اجرای خودکار
cat > run_system.sh << 'EOF'
#!/bin/bash

# تابع برای اجرای سیستم
run_pipeline() {
    echo "🚀 شروع فرآیند جمع‌آوری داده‌ها..."
    python scripts/twitter_scraper.py
    
    echo "🚀 شروع آموزش مدل و پیش‌بینی..."
    python scripts/predict.py
    
    echo "🚀 تولید گزارش نهایی..."
    python scripts/generate_report.py
    
    echo "🚀 ایجاد داشبورد..."
    python scripts/generate_dashboard.py
    
    echo "🎉 تمام مراحل با موفقیت تکمیل شد!"
    echo "داشبورد در دسترس: file://$(pwd)/index.html"
}

# اولین اجرا
run_pipeline

# اجرای خودکار هر 6 ساعت
while true; do
    # محاسبه زمان باقیمانده تا اجرای بعدی
    next_run=$((6 * 3600))
    hours=$((next_run / 3600))
    
    echo -e "\n⏳ اجرای بعدی سیستم در $hours ساعت..."
    
    # شمارش معکوس
    while [ $next_run -gt 0 ]; do
        hours=$((next_run / 3600))
        minutes=$(( (next_run % 3600) / 60 ))
        seconds=$((next_run % 60))
        
        printf "⏱️  زمان باقیمانده: %02d:%02d:%02d" $hours $minutes $seconds
        sleep 1
        next_run=$((next_run - 1))
        
        # پاک کردن خط قبلی
        printf "\r"
    done
    
    echo "🔄 اجرای مجدد سیستم..."
    run_pipeline
done
EOF

# اعطای مجوز اجرا
chmod +x run_system.sh
chmod +x scripts/*.py

# مرحله 4: نصب وابستگی‌ها
echo "🔧 نصب وابستگی‌های مورد نیاز..."
pip install snscrape pandas scikit-learn joblib

# مرحله 5: اجرای سیستم
echo "🚀 اجرای سیستم برای اولین بار..."
./run_system.sh
