import snscrape.modules.twitter as sntwitter
import pandas as pd
from datetime import datetime, timedelta
import os

# تنظیمات
HASHTAGS = ["#crypto", "#bitcoin", "#ai", "#gaming", "#tech"]
MAX_TWEETS = 200  # برای هر هشتگ
DATA_DIR = "../data"

def scrape_twitter():
    os.makedirs(DATA_DIR, exist_ok=True)
    end_date = datetime.now()
    start_date = end_date - timedelta(days=2)
    
    all_tweets = []
    
    print(f"🚀 Starting scraping for {len(HASHTAGS)} hashtags...")
    
    for hashtag in HASHTAGS:
        query = f"{hashtag} since:{start_date.date()} lang:en"
        print(f"🔍 Scraping {query}")
        
        for i, tweet in enumerate(sntwitter.TwitterSearchScraper(query).get_items()):
            if i >= MAX_TWEETS:
                break
                
            all_tweets.append([
                tweet.date,
                tweet.content,
                tweet.likeCount,
                tweet.retweetCount,
                tweet.replyCount,
                hashtag
            ])
    
    # ایجاد DataFrame
    df = pd.DataFrame(all_tweets, 
                     columns=['datetime', 'content', 'likes', 'retweets', 'replies', 'hashtag'])
    
    # محاسبه تعامل کل
    df['engagement'] = df['likes'] + (df['retweets'] * 2) + df['replies']
    
    # ذخیره داده
    output_path = os.path.join(DATA_DIR, "data.csv")
    df.to_csv(output_path, index=False)
    print(f"✅ Saved {len(df)} tweets to {output_path}")

if __name__ == "__main__":
    scrape_twitter()