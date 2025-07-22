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
