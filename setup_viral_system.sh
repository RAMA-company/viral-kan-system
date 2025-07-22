#!/bin/bash

# تابع نمایش پیام‌های رنگی
print_message() {
    local color=$1
    local message=$2
    local reset='\033[0m'
    
    case $color in
        "red") color_code='\033[0;31m' ;;
        "green") color_code='\033[0;32m' ;;
        "yellow") color_code='\033[0;33m' ;;
        "blue") color_code='\033[0;34m' ;;
        *) color_code='\033[0m' ;;
    esac
    
    echo -e "${color_code}${message}${reset}"
}

# مرحله 1: ایجاد ساختار دایرکتوری‌ها
print_message "blue" "📁 ایجاد ساختار دایرکتوری‌ها..."
mkdir -p scripts data models reports dashboard

# مرحله 2: ایجاد اسکریپت twitter_scraper.py
print_message "green" "🔄 ایجاد اسکریپت جمع‌آوری توییت‌ها..."
cat > scripts/twitter_scraper.py << 'EOF'
import os
import pandas as pd
import snscrape.modules.twitter as sntwitter
from datetime import datetime, timedelta
import random
import time
import sys

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
            [datetime.now(), "توییت نمونه: تحلیل بازار بیت‌کوین", 200, 40, 15, "#bitcoin"],
            [datetime.now(), "توییت نمونه: آخرین اخبار بازی‌های کامپیوتری", 180, 30, 10, "#gaming"],
            [datetime.now(), "توییت نمونه: تکنولوژی‌های نوظهور در 2023", 120, 20, 6, "#tech"],
            [datetime.now(), "توییت نمونه: تحولات بازار رمزارزها", 90, 15, 5, "#crypto"]
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

# مرحله 3: ایجاد اسکریپت predict.py
print_message "green" "🔄 ایجاد اسکریپت پیش‌بینی محتواهای ویروسی..."
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
EOF

# مرحله 4: ایجاد اسکریپت generate_dashboard.py
print_message "green" "🔄 ایجاد اسکریپت تولید داشبورد..."
cat > scripts/generate_dashboard.py << 'EOF'
import os
import pandas as pd
from datetime import datetime
import shutil
import json

# تنظیم مسیرها
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data')
DASHBOARD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'dashboard')
CONFIG_PATH = os.path.join(DASHBOARD_DIR, "config.json")
os.makedirs(DASHBOARD_DIR, exist_ok=True)

# بارگیری یا ایجاد تنظیمات
def load_config():
    default_config = {
        "schedule": 6,
        "last_reset": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }
    
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, 'r') as f:
                return json.load(f)
        except:
            return default_config
    return default_config

def save_config(config):
    with open(CONFIG_PATH, 'w') as f:
        json.dump(config, f)

def generate_dashboard():
    print("🖥️  ایجاد داشبورد تعاملی...")
    config = load_config()
    
    # بارگیری داده‌ها
    predictions_path = os.path.join(DATA_DIR, "predictions.csv")
    
    if os.path.exists(predictions_path):
        try:
            df = pd.read_csv(predictions_path)
        except Exception as e:
            print(f"⚠️ خطا در خواندن فایل پیش‌بینی‌ها: {str(e)}")
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
            --secondary: #3a0ca3;
            --light: #f8f9fa;
            --dark: #212529;
        }}
        
        body {{ 
            background-color: #f0f2f5; 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            padding-bottom: 50px;
        }}
        
        .navbar {{
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        
        .card {{
            border: none;
            border-radius: 12px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.05);
            transition: transform 0.3s;
            margin-bottom: 20px;
            overflow: hidden;
        }}
        
        .card:hover {{
            transform: translateY(-5px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.1);
        }}
        
        .tweet-card .card-body {{
            padding: 15px;
        }}
        
        .tweet-content {{
            font-size: 0.95rem;
            line-height: 1.6;
            margin-bottom: 12px;
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
            font-size: 0.85rem;
            z-index: 1000;
            box-shadow: 0 -2px 5px rgba(0,0,0,0.1);
        }}
        
        .viral-badge {{
            background: linear-gradient(135deg, #ff9a9e 0%, #fad0c4 100%);
            color: #d32f2f;
            font-weight: bold;
        }}
        
        .reset-btn {{
            background: linear-gradient(135deg, #ff416c, #ff4b2b);
            border: none;
            color: white;
            padding: 8px 16px;
            border-radius: 30px;
            font-weight: bold;
            transition: all 0.3s;
        }}
        
        .reset-btn:hover {{
            transform: scale(1.05);
            box-shadow: 0 4px 8px rgba(255, 75, 43, 0.3);
        }}
        
        @media (max-width: 768px) {{
            .card {{ border-radius: 10px; }}
            .tweet-content {{ font-size: 0.9rem; }}
        }}
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand d-flex align-items-center" href="#">
                <i class="bi bi-virus fs-4 me-2"></i>
                <span>سیستم تحلیل محتوای ویروسی</span>
            </a>
            <div class="d-flex">
                <span class="text-white">
                    <i class="bi bi-clock me-1"></i>
                    {datetime.now().strftime('%H:%M')}
                </span>
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
                                <p class="card-text mb-0">
                                    <i class="bi bi-arrow-repeat me-1"></i>
                                    برنامه‌ریزی: هر {config['schedule']} ساعت
                                </p>
                            </div>
                            <button class="reset-btn" onclick="resetSystem()">
                                <i class="bi bi-arrow-clockwise me-1"></i>
                                ریست سیستم
                            </button>
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
                            f'<span class="badge viral-badge">امتیاز ویروسی: {row.get("prediction", 0):.2f}</span>'
                            f'</div></div></div>'
                            for _, row in df.sort_values('prediction', ascending=False).head(10).iterrows()
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
                        "<div class='d-flex justify-content-between mb-2'><span>میانگین تعامل</span><strong>" + (f"{df['engagement'].mean():.0f}" if not df.empty and 'engagement' in df else "0") + "</strong></div>"
                        "<div class='d-flex justify-content-between mb-2'><span>بیشترین تعامل</span><strong>" + (f"{df['engagement'].max()}" if not df.empty and 'engagement' in df else "0") + "</strong></div>"
                        "<div class='d-flex justify-content-between'><span>میانگین امتیاز ویروسی</span><strong>" + (f"{df['prediction'].mean():.2f}" if not df.empty and 'prediction' in df else "0.00") + "</strong></div>"
                        "</div>" if not df.empty else '<div class="text-center py-4"><i class="bi bi-exclamation-circle fs-1 text-muted"></i><p class="mt-3">داده‌ای برای نمایش وجود ندارد</p></div>'}
                    </div>
                </div>
                
                <div class="card mt-4">
                    <div class="card-header bg-white border-0 py-3">
                        <h5 class="mb-0">تنظیمات برنامه‌ریزی</h5>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <label class="form-label">فاصله زمانی اجرا (ساعت)</label>
                            <input type="number" id="scheduleInput" class="form-control" min="1" max="24" value="{config['schedule']}">
                        </div>
                        <button class="btn btn-primary w-100" onclick="updateSchedule()">
                            <i class="bi bi-save me-1"></i>
                            ذخیره تنظیمات
                        </button>
                        <div class="mt-3">
                            <p class="small text-muted mb-1">آخرین ریست سیستم:</p>
                            <p class="mb-0">{config['last_reset']}</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="last-updated">
        <i class="bi bi-arrow-repeat me-1"></i> سیستم هر {config['schedule']} ساعت به‌طور خودکار به‌روز می‌شود | آخرین بروزرسانی: {datetime.now().strftime('%Y/%m/%d %H:%M')}
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // به‌روزرسانی خودکار هر 5 دقیقه
        setTimeout(() => location.reload(), 300000);
        
        // تابع ریست سیستم
        function resetSystem() {{
            fetch('/reset')
                .then(response => {{
                    if (response.ok) {{
                        alert('✅ سیستم با موفقیت ریست شد!');
                        location.reload();
                    }} else {{
                        alert('❌ خطا در ریست سیستم');
                    }}
                }})
                .catch(error => {{
                    console.error('Error:', error);
                    alert('❌ خطا در ارتباط با سرور');
                }});
        }}
        
        // تابع به‌روزرسانی برنامه‌ریزی
        function updateSchedule() {{
            const hours = document.getElementById('scheduleInput').value;
            fetch(`/update-schedule?hours=${{hours}}`)
                .then(response => {{
                    if (response.ok) {{
                        alert('✅ تنظیمات با موفقیت به‌روز شد!');
                        location.reload();
                    }} else {{
                        alert('❌ خطا در به‌روزرسانی تنظیمات');
                    }}
                }})
                .catch(error => {{
                    console.error('Error:', error);
                    alert('❌ خطا در ارتباط با سرور');
                }});
        }}
    </script>
</body>
</html>
"""
    
    # ذخیره فایل داشبورد
    dashboard_path = os.path.join(DASHBOARD_DIR, "index.html")
    with open(dashboard_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    # کپی برای دسترسی راحت‌تر
    try:
        shutil.copy(dashboard_path, "index.html")
    except:
        pass
    
    print(f"✅ داشبورد در {dashboard_path} ذخیره شد")

if __name__ == "__main__":
    generate_dashboard()
EOF

# مرحله 5: ایجاد اسکریپت اجرای اصلی
print_message "blue" "🔄 ایجاد اسکریپت اجرای سیستم..."
cat > run_system.sh << 'EOF'
#!/bin/bash

# تابع نمایش پیام‌های رنگی
print_message() {
    local color=$1
    local message=$2
    local reset='\033[0m'
    
    case $color in
        "red") color_code='\033[0;31m' ;;
        "green") color_code='\033[0;32m' ;;
        "yellow") color_code='\033[0;33m' ;;
        "blue") color_code='\033[0;34m' ;;
        *) color_code='\033[0m' ;;
    esac
    
    echo -e "${color_code}${message}${reset}"
}

# تابع اجرای کامل سیستم
run_pipeline() {
    print_message "blue" "\n🚀 شروع فرآیند جمع‌آوری داده‌ها..."
    python scripts/twitter_scraper.py
    
    print_message "blue" "\n🚀 شروع آموزش مدل و پیش‌بینی..."
    python scripts/predict.py
    
    print_message "blue" "\n🚀 ایجاد داشبورد..."
    python scripts/generate_dashboard.py
    
    print_message "green" "\n🎉 تمام مراحل با موفقیت تکمیل شد!"
    echo "داشبورد در دسترس: file://$(pwd)/index.html"
}

# تابع مدیریت ریست
handle_reset() {
    print_message "yellow" "\n🔄 ریست سیستم درخواست شده..."
    run_pipeline
    print_message "green" "✅ سیستم با موفقیت ریست شد"
}

# تابع به‌روزرسانی برنامه‌ریزی
update_schedule() {
    local hours=$1
    print_message "blue" "\n⏰ به‌روزرسانی برنامه‌ریزی به هر $hours ساعت"
    
    # به‌روزرسانی فایل تنظیمات
    python -c "import json; config = json.load(open('dashboard/config.json')); config['schedule'] = $hours; json.dump(config, open('dashboard/config.json', 'w'))"
    
    # توقف و راه‌اندازی مجدد سیستم
    pkill -f "run_system.sh"
    nohup ./run_system.sh > system.log 2>&1 &
    print_message "green" "✅ برنامه‌ریزی با موفقیت به‌روز شد"
}

# اولین اجرا
run_pipeline

# اجرای خودکار بر اساس برنامه‌ریزی
while true; do
    # بارگیری تنظیمات
    schedule_hours=$(python -c "import json; config = json.load(open('dashboard/config.json')); print(config['schedule'])")
    next_run_seconds=$((schedule_hours * 3600))
    
    print_message "yellow" "\n⏰ اجرای بعدی سیستم در $schedule_hours ساعت..."
    
    # شمارش معکوس با قابلیت ریست
    time_remaining=$next_run_seconds
    while [ $time_remaining -gt 0 ]; do
        hours=$((time_remaining / 3600))
        minutes=$(( (time_remaining % 3600) / 60 ))
        seconds=$((time_remaining % 60))
        
        printf "⏱️  زمان باقیمانده: %02d:%02d:%02d" $hours $minutes $seconds
        sleep 1
        time_remaining=$((time_remaining - 1))
        
        # پاک کردن خط قبلی
        printf "\r"
    done
    
    print_message "yellow" "\n🔄 اجرای مجدد سیستم..."
    run_pipeline
done
EOF

# مرحله 6: ایجاد اسکریپت سرور وب
print_message "blue" "🔄 ایجاد سرور وب برای مدیریت درخواست‌ها..."
cat > web_server.py << 'EOF'
import os
import json
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

# تنظیمات
PORT = 8080
CONFIG_PATH = "dashboard/config.json"

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            if self.path == '/reset':
                # اجرای ریست سیستم
                os.system("./run_system.sh --reset &")
                
                # به‌روزرسانی زمان آخرین ریست
                with open(CONFIG_PATH, 'r') as f:
                    config = json.load(f)
                config['last_reset'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                with open(CONFIG_PATH, 'w') as f:
                    json.dump(config, f)
                
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'OK')
                
            elif self.path.startswith('/update-schedule'):
                # استخراج ساعت جدید
                hours = int(self.path.split('=')[1])
                
                # به‌روزرسانی برنامه‌ریزی
                with open(CONFIG_PATH, 'r') as f:
                    config = json.load(f)
                config['schedule'] = hours
                with open(CONFIG_PATH, 'w') as f:
                    json.dump(config, f)
                
                # اعمال تنظیمات جدید
                os.system("./run_system.sh --update-schedule &")
                
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'OK')
                
            else:
                self.send_response(404)
                self.end_headers()
                
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())

def run_server():
    server = HTTPServer(('', PORT), RequestHandler)
    print(f"🌐 سرور وب در حال اجرا روی پورت {PORT}")
    server.serve_forever()

if __name__ == "__main__":
    # ایجاد فایل تنظیمات اولیه
    if not os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, 'w') as f:
            json.dump({
                "schedule": 6,
                "last_reset": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }, f)
    
    run_server()
EOF

# مرحله 7: نصب وابستگی‌ها
print_message "yellow" "🔧 نصب وابستگی‌های مورد نیاز..."
pip install snscrape pandas scikit-learn joblib > /dev/null 2>&1

# مرحله 8: اعطای مجوز اجرا
chmod +x run_system.sh
chmod +x scripts/*.py

# مرحله 9: اجرای سیستم
print_message "green" "\n🚀 اجرای سیستم برای اولین بار..."
nohup ./run_system.sh > system.log 2>&1 &
nohup python web_server.py > server.log 2>&1 &

print_message "green" "\n✅ سیستم با موفقیت راه‌اندازی شد!"
echo "داشبورد در دسترس: file://$(pwd)/index.html"
echo "برای دسترسی از موبایل، از آدرس زیر استفاده کنید:"
echo "https://$CODESPACE_NAME-8080.preview.app.github.dev"
