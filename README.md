# App Review Signal Pipeline

A tested, version-controlled **dbt + Snowflake** pipeline that turns 4,000+ raw app-store reviews into engineered retention signals — and surfaces a counter-intuitive finding about which users are most at risk of leaving.

---

## The finding

For one app (Headspace), the reviews that *sounded* most engaged — people describing daily use, streaks, being long-time users — were also the ones **most likely to use quitting or cancellation language**:

| Group | Shows quit language |
|---|---|
| Engaged-sounding reviews | **8.3%** (33 / 396) |
| Casual reviews | **6.0%** (93 / 1,541) |

So the loudest, most-committed voices were signalling churn *more* than casual users — the opposite of the usual "engagement = stickiness" assumption. Reading the reviews behind the numbers, the dissatisfaction clustered around the **billing/renewal moment** (unexpected auto-renewals, hard refunds), not loss of interest — reframing the problem from *disengagement* to *monetization trust*.

> **Note on the numbers:** these are *review-text signals*, not backend usage data. "Engaged" and "churning" are inferred from how people describe themselves in their reviews — a strong directional signal, not a retention metric.

---

## Architecture

Raw reviews land in Snowflake, then dbt transforms them in layers:

```
sources (raw Android + iOS review tables)
  → staging        standardize each platform into one shape
      → intermediate   union both platforms into one table
          → marts          engineer signals + segments  (materialized as a table)
```

- **Sources** — declared raw tables in Snowflake (`_sources.yml`)
- **Staging** (`stg_reviews_android`, `stg_reviews_ios`) — one model per platform; reconciles very different column shapes (iOS lacks review IDs, thumbs-up, etc.) into a common structure so they can be unioned
- **Intermediate** (`int_all_reviews`) — stacks both platforms, derives `year_month`
- **Marts** (`review_signals`) — the analytical model: keyword/phrase flags for paywall, engagement, churn, and retention signals, rolled into intent segments (`engaged-free`, `converted-happy`, `churned`, `casual`)

Dependency order is resolved automatically by dbt from `ref()` / `source()` — no manual sequencing.

---

## Testing

Automated dbt tests run on every build, so a logic regression fails the run instead of leaking into analysis:

- `not_null` on `rating`, `platform`, and derived segment columns
- `accepted_values` on `rating` (1–5), `platform` (android / ios), `rating_bucket` (detractor / neutral / promoter), and `intent_segment` (the four segments)

The `accepted_values` tests on the derived columns are effectively tests of the transformation logic itself — if the `CASE` statements ever produced an unintended category, the build breaks.

---

## How signals are tagged (and the honest limitation)

Signals are built with **keyword/phrase matching** (`ILIKE`), not an ML sentiment model — a deliberate choice: with a few thousand reviews, transparent rules that can be inspected and refined by hand were more trustworthy than a black-box score.

The tradeoff, stated plainly: keyword rules match *strings, not meaning*. For example, a broad pattern like `%pay%` will catch "happy to pay" alongside "too expensive to pay for." These are **signals worth investigating, not validated conclusions** — segments were spot-checked by reading samples, not formally validated against a hand-labelled set.

---

## Stack

`dbt` · `Snowflake` · `SQL`

## Status

Analytics phase complete — tested pipeline + the diagnosis above. Next phase: translating the finding into a product response (an honest-renewal spec), developed as a separate case study.

---

*Analysis based on publicly available app-store reviews, used for non-commercial, educational purposes. Individual reviewers are not identified; analysis is at the aggregate-signal level.*
