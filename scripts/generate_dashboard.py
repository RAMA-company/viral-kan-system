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
