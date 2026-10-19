-- Staging: clean the raw Android reviews into a standard shape.
-- Job here is ONLY renaming + casting, no business logic.

select
    review_id,
    user_name,
    content        as review_text,
    score          as rating,
    thumbs_up,
    app_version,
    review_date,
    app_name,
    'android'      as platform
from {{ source('raw', 'reviews_android') }}