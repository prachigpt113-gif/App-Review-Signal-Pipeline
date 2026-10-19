-- Intermediate: stack Android + iOS into one unified review table.
-- Uses ref() so dbt builds BOTH staging models before this one.

with android as (
    select * from {{ ref('stg_reviews_android') }}
),

ios as (
    select * from {{ ref('stg_reviews_ios') }}
),

combined as (
    select * from android
    union all
    select * from ios
)

select
    review_id,
    user_name,
    review_text,
    rating,
    thumbs_up,
    app_version,
    review_date,
    app_name,
    platform,
    -- derive year-month for time-based analysis (your YEAR_MONTH column)
    to_char(review_date, 'YYYY-MM') as year_month
from combined