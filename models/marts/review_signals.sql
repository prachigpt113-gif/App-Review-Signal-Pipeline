-- Marts: the analytical model. All business logic lives here.
-- Reads the unified review table and engineers signal flags + segments.
-- Materializes as a TABLE (set by folder config in dbt_project.yml).

with reviews as (
    select * from {{ ref('int_all_reviews') }}
)

select
    review_id,
    app_name,
    platform,
    rating,
    review_text,
    review_date,
    year_month,
    thumbs_up,

    -- Rating bucket: NPS-style grouping
    case
        when rating <= 2 then 'detractor'
        when rating = 3  then 'neutral'
        else 'promoter'
    end as rating_bucket,

    -- Paywall / conversion friction
    (review_text ilike '%premium%'
     or review_text ilike '%subscription%'
     or review_text ilike '%paywall%'
     or review_text ilike '%pay%'
     or review_text ilike '%worth it%'
     or review_text ilike '%free version%'
     or review_text ilike '%used to be free%'
     or review_text ilike '%behind a paywall%') as is_paywall_mention,

    -- High engagement signals
    (review_text ilike '%every day%'
     or review_text ilike '%daily%'
     or review_text ilike '%streak%'
     or review_text ilike '%years%'
     or review_text ilike '%every morning%'
     or review_text ilike '%habit%'
     or review_text ilike '%love this app%') as is_engagement_high,

    -- Quit / churn signals
    (review_text ilike '%deleted%'
     or review_text ilike '%uninstalled%'
     or review_text ilike '%cancelled%'
     or review_text ilike '%canceling%'
     or review_text ilike '%switching%'
     or review_text ilike '%moving to%') as is_quit_signal,

    -- Retention / renewal signals
    (review_text ilike '%renewed%'
     or review_text ilike '%renew%'
     or review_text ilike '%not worth renewing%'
     or review_text ilike '%cancelled subscription%'
     or review_text ilike '%repetitive%'
     or review_text ilike '%same content%'
     or review_text ilike '%new content%') as is_retention_signal,

    -- Intent segment
    case
        when (review_text ilike '%every day%' or review_text ilike '%daily%'
              or review_text ilike '%habit%' or review_text ilike '%years%')
         and not (review_text ilike '%cancelled%' or review_text ilike '%deleted%')
        then 'engaged-free'
        when (review_text ilike '%worth it%' or review_text ilike '%renewed%'
              or review_text ilike '%subscriber%') and rating >= 4
        then 'converted-happy'
        when (review_text ilike '%cancelled%' or review_text ilike '%deleted%'
              or review_text ilike '%uninstalled%')
        then 'churned'
        else 'casual'
    end as intent_segment

from reviews