-----YOUTUBE ANALYSIS-----

-- Starting with the Wikipedia data for September 2024, most subscribed channels
--Joining the wikipedia data and the statistics that I extracted
SELECT D1.channelName, D1.subscribers, D1.views, D1.totalVideos, D1.playlistId,
D2.Country, D2.Category, D2.Primary_Language, D2.Brand_Channel
INTO Youtube_Analysis..joinedtop50
FROM Youtube_Analysis..top50Channels D1
LEFT JOIN Youtube_Analysis..top50_wiki D2
ON D1.channelName = D2.Name 

--Verifying the resulted table
SELECT * FROM Youtube_Analysis..joinedtop50

--Find the most common countries in the top50 Youtube channels
--Since some channels belong to more then one country we need to split them to count correctly
WITH CountrySplit AS (
    SELECT TRIM(value) AS Country
    FROM Youtube_Analysis..joinedtop50
    CROSS APPLY STRING_SPLIT(Country, ',')
)

-- Count the occurrences of each country
SELECT Country, COUNT(Country) AS Country_count
FROM CountrySplit
GROUP BY Country
ORDER BY Country_count DESC;

--Find the most common categories in the top50 Youtube channels
SELECT Category, COUNT(Category) as Category_count
FROM Youtube_Analysis..joinedtop50
GROUP BY Category
ORDER BY Category_count DESC


--Find the number of brand channels in the top50 Youtube channels
SELECT Brand_Channel, COUNT(Brand_Channel) as Countt
FROM Youtube_Analysis..joinedtop50
GROUP BY Brand_Channel

--Find the channel languages in the top50 Youtube channels
SELECT Primary_Language, COUNT(Primary_Language) as Countt
FROM Youtube_Analysis..joinedtop50
GROUP BY Primary_Language
ORDER BY Countt DESC


--ANALYZING THE TOP 3 YOUTUBE CHANNELS

--------TOP 3 YOUTUBE CHANNELS ANALYSIS---------
SELECT *
FROM Youtube_Analysis..mrbeast
WHERE channelTitle IS NULL;

SELECT *
FROM Youtube_Analysis..cocomelon
WHERE channelTitle IS NULL;

--Tseries table has one row with null channelTitle. It will be replaced with actual channel title while combining tables.
SELECT *
FROM Youtube_Analysis..tseries
WHERE channelTitle IS NULL;


--Combining all rows in a single table
-- Create a new table with the unioned data
SELECT video_iD,
    CASE 
    WHEN channelTitle Is NULL THEN 'T-series'
    ELSE 'T-series'
    END AS channelTitle,
       title, 
       description, 
       tags_count, 
       publishedAt, 
       viewCount, 
       likeCount, 
       favoriteCount, 
       commentCount, 
       duration,
       definition,
       caption
INTO Youtube_Analysis..top3 -- Create the new table
FROM Youtube_Analysis..tseries

UNION ALL

SELECT video_id,
        channelTitle,
       title, 
       description, 
       tags_count, 
       publishedAt, 
       viewCount, 
       likeCount, 
       favoriteCount, 
       commentCount, 
       duration,
       definition,
       caption
FROM Youtube_Analysis..mrbeast

UNION ALL

SELECT video_id,
        channelTitle,
       title, 
       description, 
       tags_count, 
       publishedAt, 
       viewCount, 
       likeCount, 
       favoriteCount, 
       commentCount, 
       duration,
       definition,
       caption
FROM Youtube_Analysis..cocomelon

------CHANNEL STATISTICS------

--Finding the average video duration per channel
SELECT channelTitle,AVG(duration) as AVG_duration
FROM Youtube_Analysis..top3 
GROUP BY channelTitle
ORDER BY AVG_duration DESC

--Finding the average video views per channel
SELECT channelTitle,AVG(viewCount) as AVG_view
FROM Youtube_Analysis..top3 
GROUP BY channelTitle
ORDER BY AVG_view DESC

--Finding the average like count per channel
SELECT channelTitle,AVG(likeCount) as AVG_like
FROM Youtube_Analysis..top3 
GROUP BY channelTitle
ORDER BY AVG_like DESC

--TOP5 most viewed videos per channel
WITH ranked_videos AS (
    SELECT channelTitle, 
           title, 
           viewCount,
           video_id, 
           RANK() OVER (PARTITION BY channelTitle ORDER BY viewCount DESC) AS rank_by_views,
           likeCount,
           RANK() OVER (PARTITION BY channelTitle ORDER BY likeCount DESC) AS rank_by_likes
    FROM top3
)

SELECT channelTitle,title,viewCount,rank_by_views,video_id
FROM ranked_videos
WHERE rank_by_views <6
ORDER BY channelTitle,rank_by_views

--TOP5 most liked videos per channel
WITH ranked_videos AS (
    SELECT channelTitle, 
           title, 
           viewCount,
           video_id, 
           RANK() OVER (PARTITION BY channelTitle ORDER BY viewCount DESC) AS rank_by_views,
           likeCount,
           RANK() OVER (PARTITION BY channelTitle ORDER BY likeCount DESC) AS rank_by_likes
    FROM top3
)
SELECT channelTitle,title,likeCount,rank_by_likes,video_id
FROM ranked_videos
WHERE rank_by_likes <6
ORDER BY channelTitle,rank_by_likes


--Like ratio percentage and comment_ratio_percentage
SELECT channelTitle, 
       publishedAt,
       CASE 
           WHEN COALESCE(viewCount, 0) = 0 THEN 0  -- Handle division by zero or NULL viewCount
           ELSE (COALESCE(likeCount, 0) / COALESCE(viewCount, 1)) * 100  -- Handle NULL values in likeCount and viewCount
       END AS like_ratio_percentage,
       CASE
            WHEN COALESCE(viewCount,0) =0 THEN 0
            ELSE (COALESCE(commentCount,0) / COALESCE(viewCount,1)) * 100
        END AS comment_ratio_percentage
FROM top3

--Tags count vs views
SELECT channelTitle,tags_count, viewCount
FROM Youtube_Analysis..top3
ORDER BY channelTitle 

--Video duration vs view counts
SELECT duration, viewCount
FROM top3
WHERE duration IS NOT NULL AND viewCount IS NOT NULL;  -- Exclude rows with NULL values

SELECT * FROM Youtube_Analysis..cocomelon


------VIDEO UPLOAD TIME ANALYSIS------

-- Daily uploaded video counts
SELECT channelTitle, 
       CAST(publishedAt AS DATE) AS upload_day,
       COUNT(*) AS video_count 
FROM top3
GROUP BY channelTitle, CAST(publishedAt AS DATE)  
ORDER BY channelTitle, upload_day;

-- Weekly uploaded video counts
SELECT channelTitle, 
       DATEPART(YEAR, publishedAt) AS upload_year,  -- Extract the year
       DATEPART(WEEK, publishedAt) AS upload_week,  -- Extract the week number
       COUNT(*) AS video_count 
FROM top3
GROUP BY channelTitle, DATEPART(YEAR, publishedAt), DATEPART(WEEK, publishedAt)  -- Group by channel, year, and week
ORDER BY channelTitle, upload_year, upload_week;

--Monthly uploaded video counts
SELECT channelTitle, 
       DATEPART(YEAR, publishedAt) AS upload_year,  
       DATENAME(MONTH, publishedAt) AS upload_month,  
       DATEPART(MONTH, publishedAt) AS month_number,  -- Extract the month number for ordering
       COUNT(*) AS video_count  
FROM top3
GROUP BY channelTitle, DATEPART(YEAR, publishedAt), DATENAME(MONTH, publishedAt), DATEPART(MONTH, publishedAt)  
ORDER BY channelTitle, upload_year, month_number;  -- Order by year and month number for chronological ordering

--Do certain days perform better in terms of view counts, likes, and comments?
SELECT DATENAME(WEEKDAY, publishedAt) AS upload_day,
       AVG(viewCount) AS avg_views,       
       AVG(likeCount) AS avg_likes,      
       AVG(commentCount) AS avg_comments  
FROM top3
WHERE publishedAt IS NOT NULL
GROUP BY DATENAME(WEEKDAY, publishedAt), DATEPART(WEEKDAY, publishedAt)
ORDER BY avg_views, avg_likes,avg_comments

--Video growth over time
SELECT channelTitle, 
       DATEPART(YEAR, publishedAt) AS upload_year,  
       AVG(viewCount) AS avg_views, 
       AVG(likeCount) AS avg_likes, 
       AVG(commentCount) AS avg_comments
FROM top3
GROUP BY channelTitle, DATEPART(YEAR, publishedAt)
ORDER BY channelTitle, upload_year;


------DESCRIPTION IMPACT------
--Does having a description have an impact on avg_views,avg_likes and avg_comments?
SELECT 
    channelTitle,  -- Group by channel
    CASE 
        WHEN description IS NULL THEN 'Without Description'
        ELSE 'With Description'
    END AS description_status,
    AVG(viewCount) AS avg_views,       
    AVG(likeCount) AS avg_likes,       
    AVG(commentCount) AS avg_comments  
FROM top3
GROUP BY 
    channelTitle,  
    CASE 
        WHEN description IS NULL THEN 'Without Description'
        ELSE 'With Description'
    END
ORDER BY channelTitle, description_status;

--Does having a shorter or longer descriptions have an impact on the avg_likes, avg_comments, avg_views

SELECT channelTitle,
    CASE 
        WHEN description IS NULL THEN 'No Description' --This finds the lenght of character, length of characters without spaces, finds the space count then adds +1 for word count.
        WHEN (LEN(description) - LEN(REPLACE(description, ' ', '')) + 1) <= 10 THEN 'Short (<= 10 words)'
        WHEN (LEN(description) - LEN(REPLACE(description, ' ', '')) + 1) > 10 AND (LEN(description) - LEN(REPLACE(description, ' ', '')) + 1) <= 50 THEN 'Medium (11-50 words)'
        ELSE 'Long (> 50 words)'
    END AS description_word_count_category,
    AVG(viewCount) AS avg_views,       
    AVG(likeCount) AS avg_likes,       
    AVG(commentCount) AS avg_comments  
FROM top3
GROUP BY channelTitle,
    CASE 
        WHEN description IS NULL THEN 'No Description'
        WHEN (LEN(description) - LEN(REPLACE(description, ' ', '')) + 1) <= 10 THEN 'Short (<= 10 words)'
        WHEN (LEN(description) - LEN(REPLACE(description, ' ', '')) + 1) > 10 AND (LEN(description) - LEN(REPLACE(description, ' ', '')) + 1) <= 50 THEN 'Medium (11-50 words)'
        ELSE 'Long (> 50 words)'
    END
ORDER BY channelTitle;




