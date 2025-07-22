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
