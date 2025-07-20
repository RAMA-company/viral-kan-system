import pandas as pd
import matplotlib.pyplot as plt
from fpdf import FPDF
import os
from datetime import datetime

DATA_DIR = "../data"
REPORTS_DIR = "../reports"
os.makedirs(REPORTS_DIR, exist_ok=True)

def create_report(hashtag="#crypto"):
    # بارگیری داده‌ها
    df = pd.read_csv(os.path.join(DATA_DIR, "predictions.csv"))
    df = df[df['hashtag'] == hashtag]
    
    if df.empty:
        print(f"❌ No data found for {hashtag}")
        return None
    
    # تنظیمات گزارش
    report = FPDF()
    report.add_page()
    report.set_font("Arial", 'B', 16)
    report.cell(0, 10, f"Viral Kan Report: {hashtag}", 0, 1, 'C')
    
    # اطلاعات کلی
    report.set_font("Arial", '', 12)
    report.cell(0, 10, f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}", 0, 1)
    report.cell(0, 10, f"Total Posts Analyzed: {len(df)}", 0, 1)
    report.ln(10)
    
    # نمودار ساعتی
    hourly = df.groupby('hour')['viral_prob'].mean()
    plt.figure(figsize=(10, 5))
    hourly.plot(kind='bar', color='skyblue')
    plt.title('Average Viral Probability by Hour')
    plt.xlabel('Hour of Day (UTC)')
    plt.ylabel('Probability (%)')
    plt.ylim(0, 100)
    plt.grid(axis='y', linestyle='--')
    
    chart_path = os.path.join(REPORTS_DIR, f"{hashtag}_chart.png")
    plt.savefig(chart_path, bbox_inches='tight')
    plt.close()
    
    report.cell(0, 10, "Hourly Trend Analysis:", 0, 1)
    report.image(chart_path, x=10, w=180)
    report.ln(5)
    
    # پست‌های برتر
    top_posts = df.nlargest(3, 'viral_prob')
    report.cell(0, 10, "Top Viral Posts:", 0, 1)
    
    for i, row in top_posts.iterrows():
        report.multi_cell(0, 8, f"Post {i+1} ({row['viral_prob']:.1f}% viral):")
        report.multi_cell(0, 8, f"\"{row['content'][:100]}...\"")
        report.ln(2)
    
    # ذخیره گزارش
    report_path = os.path.join(REPORTS_DIR, f"{hashtag}_report.pdf")
    report.output(report_path)
    print(f"📊 Report saved to {report_path}")
    return report_path

if __name__ == "__main__":
    create_report()