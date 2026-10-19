-- Staging: clean the raw iOS reviews into the SAME shape as Android.
-- iOS has fewer columns, so we fill the missing ones with NULL
-- to keep both staging models union-compatible.

select
    cast(null as varchar)   as review_id,
    cast(null as varchar)   as user_name,
    review                  as review_text,
    rating,
    cast(null as number)    as thumbs_up,
    cast(null as varchar)   as app_version,
    review_date,
    app_name,
    'ios'                   as platform
from {{ source('raw', 'reviews_ios') }}