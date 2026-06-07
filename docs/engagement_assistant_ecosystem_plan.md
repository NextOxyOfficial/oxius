# AdsyClub — Engagement & "Assistant Brain" Ecosystem Plan

Goal: make the app proactively pull each individual user back in and keep them
engaged — personalized suggestions, well-timed push, lifecycle nudges, light
gamification, and a per-user assistant that treats the user like a personal
helper (a "brain" that senses, understands, decides, acts, and learns).

This builds on what already exists — it does **not** rebuild it.

---

## 0. Mental model — the brain loop

```
        ┌─────────────────────────────────────────────────────────┐
        │                                                         │
   SENSE ─▶ UNDERSTAND ─▶ DECIDE ─▶ ACT ─▶ LEARN ──┘ (feeds back)
  (events)  (user state)  (next-best  (push/in-app  (outcomes tune
                           action)     /assistant)   the decisions)
```

Each individual user gets: a continuously-updated profile, a chosen "next best
action" at the right time, delivered on the right channel, and the result
measured so the system gets smarter.

---

## 1. What already exists (leverage, don't rebuild)

| Capability | Where | Reuse for |
|---|---|---|
| FCM push + multicast | `base/fcm_service.py`, `base/push_notifications.py` | Delivery channel |
| Saved notifications + "Updates" tab + deep-link | `base/view_modules/notification_api_views.py`, app inbox | In-app delivery + Visit button |
| Society feed ranking (affinity/interest/recency/decay) | `business_network/views.py` `get_queryset` | Personalization signals |
| "People you may know" | `business_network/views.py` `UserSuggestionsView` | Connection recommendations |
| Diamonds virtual currency + transactions | `base/models.py` `DiamondPackages`, `DiamondTransaction` | Gamification rewards |
| Referral rewards | `referral_rewards/` | Invite loop |
| Celery + django-celery-beat | `backend/settings.py` beat schedule | Periodic brain jobs |
| Email service | `base/email_service.py` | Win-back / digest email |
| Home popup | `home_popup_service.dart`, `global_popup/` | In-app surface for a nudge |
| Super-app surfaces | BN feed, eShop, classifieds, rideshare, recharge, eLearning, gigs, news, wallet/KYC | Cross-feature suggestions |

Gaps to add: **event tracking**, **per-user state/lifecycle**, **next-best-action
engine**, **gamification (streak/missions/badges)**, **assistant persona**,
**smart timing + measurement**.

---

## 2. Subsystem A — Senses (event tracking)

A single lightweight, append-only event log is the raw material for everything.

**Model** `engagement.UserEvent`
```
user (FK, null for anon/device)         event_type (str, indexed)
session_id (str)                        surface (feed|eshop|rideshare|chat|...)
object_type / object_id (str, nullable) metadata (JSONField)
created_at (datetime, indexed)
```

**`track(user, event_type, **ctx)` helper** — fire-and-forget (push to a Celery
queue or buffer; never block the request). Instrument the high-signal moments:

- App: `app_open`, `session_start/end`, screen views, dwell time.
- BN: `post_view`, `post_like`, `comment`, `follow`, `share`, `short_watch`.
- eShop: `product_view`, `add_to_cart`, `order_placed`, `store_visit`.
- Marketplace/classified: `listing_view`, `listing_post`, `contact_seller`.
- Rideshare: `ride_search`, `ride_request`, `ride_complete`.
- Recharge / gigs / courses / news / wallet: the equivalent key actions.
- Money: `deposit`, `withdraw`, `earning_credited`, `diamond_spend`.
- Lifecycle: `kyc_submitted`, `profile_step_completed`, `pro_subscribed`.

Keep raw events ~90 days (partition/rollup older into aggregates).

---

## 3. Subsystem B — Memory (per-user state)

A Celery job rolls events into a compact, queryable per-user profile that the
brain reads cheaply.

**Model** `engagement.UserState` (one row per user)
```
last_active_at, last_session_at, sessions_7d, sessions_30d
active_days_streak, longest_streak, current_streak_started
lifecycle_stage  = new | onboarding | activated | habitual |
                   at_risk | dormant | resurrected | churned
churn_risk        (0–1 heuristic, later ML)
value_tier        = explorer | earner | spender | creator | pro
top_interests     (JSON: tags/categories from feed affinity)
top_surfaces      (JSON: which features they use)
preferred_hours   (JSON: when they're usually active)
balance, diamonds, is_pro, kyc_status, profile_completion  (denormalized)
pending           (JSON: cart items, expiring sub, unclaimed referral, draft post,
                   incomplete course, withdrawable balance, pending KYC)
updated_at
```

**Lifecycle rules (heuristic to start):**
- `new`: signed up < 24h, < 2 sessions.
- `onboarding`: profile_completion < 60% or no first key action.
- `activated`: did ≥1 core action (post/order/ride/recharge/gig).
- `habitual`: ≥4 active days in last 7.
- `at_risk`: was habitual, now 0 sessions in 3–7 days, or sharp drop.
- `dormant`: 7–30 days inactive. `churned`: > 30 days.
- `resurrected`: returned after dormant/churned.

This is the "self" each nudge is personalized against.

---

## 4. Subsystem C — Cortex (Next-Best-Action engine)

The decision core. A **catalog of actions**, each evaluated per user; the top
eligible one (respecting caps) is delivered.

**Model** `engagement.NudgeDefinition`
```
key, title_template, body_template, deep_link_template
segment_filter (which lifecycle_stage / value_tier / conditions)
trigger (event-based | scheduled | state-condition)
priority (base score)        cooldown (don't repeat within N days)
channels (push, inapp_card, updates, email)   max_per_user_per_week
active (bool)                ab_variant (nullable)
```

**Model** `engagement.NudgeLog` (user, nudge_key, channel, sent_at, opened_at,
converted_at, variant) — for caps, dedupe, and measurement.

**Decision job (Celery, e.g. every 15–30 min + event-triggered):**
1. For each candidate user, load `UserState`.
2. Filter the catalog by segment + eligibility (condition true, cooldown passed,
   weekly cap not hit, channel allowed, within quiet hours / preferred window).
3. Score each eligible nudge = `priority × urgency × personal_relevance`
   (relevance from interests/affinity; urgency from time-sensitivity, e.g. sub
   expiring tomorrow).
4. Pick top 1 (occasionally 2), record `NudgeLog`, dispatch via the channel.

This is "next best action," the same pattern Facebook/Duolingo/Amazon use.

**Recommendation modules feeding the cortex (reuse existing graph):**
- Feed (done). Follow suggestions (`UserSuggestionsView`, done).
- **Product/eShop recs**: from `product_view` + category + co-purchase.
- **Gig recs**: match open earn-tasks to the user's history/skills.
- **Course recs**: next course from category / incomplete ones.
- **"Complete the loop" recs**: cart left, listing with no photos, draft post.

---

## 5. Subsystem D — Voice (delivery + smart timing)

Channels, in priority order, all already partly built:
1. **Push (FCM)** — time-sensitive, re-engagement. Deep-link to the exact screen.
2. **In-app "For You" card / home strip** — personalized suggestions on open.
3. **Updates tab** — durable list (already shows push + Visit button).
4. **Assistant message** (see §7) — conversational nudges.
5. **Email** — win-back for dormant/churned, weekly digest.

**Smart timing rules (critical to avoid annoyance):**
- Send near each user's `preferred_hours`; respect quiet hours (e.g. 10pm–8am).
- Global frequency cap (e.g. ≤1 promotional push/day, ≤3/week) + per-nudge
  cooldown. Transactional (someone messaged/ordered) is exempt.
- Dedupe and suppress if the user already did the action.
- Per-user "notification health": back off automatically if they stop opening.

---

## 6. Subsystem E — Dopamine (gamification & habit loops)

Use the existing **Diamonds** currency as the reward primitive.

**New models** `gamification.{DailyCheckin, Mission, UserMission, Badge, UserBadge}`
- **Daily check-in + streak**: open app → claim daily diamonds; streak multiplies
  (day 7 bonus). Streak freeze for Pro. Drives the daily-return habit.
- **Missions/quests** (daily + weekly, personalized to lifecycle):
  - New: "complete profile", "make your first post", "verify KYC".
  - Activated: "post 3 listings", "complete 5 gigs this week", "refer a friend".
  - Spender/creator: "list a product", "get 10 followers".
  - Reward in diamonds / badges / feed boost.
- **Badges & levels**: visible status (already have KYC/Pro badges) → add activity
  badges (Top Seller, Helpful, Streak Master).
- **Progress bars + "Congrats" UI** on completion (dopamine moment).
- **Social proof triggers** (mostly transactional push): new follower, like,
  comment, message, order, "X people viewed your store today".

---

## 7. The Assistant persona — "AdsyAssistant"

A single, friendly per-user assistant surface that ties it together — the
"human-brain treating each user" feel.

**Where:** a pinned conversation in AdsyConnect (system user "AdsyAssistant") and/
or a home "Assistant" card. Reuses the chat + Updates infrastructure.

**What it does (all from real user data, never generic):**
- **Greeting + daily briefing**: "Good morning Rahim 👋 — 3 new followers, 2 orders
  (৳1,250), balance ৳7,571. Your store subscription renews in 3 days."
- **Proactive reminders**: expiring subscription, pending KYC (so you can withdraw),
  unclaimed referral reward, cart left behind, course 60% done, draft post.
- **Suggestions**: "5 new gigs match you", "people you may know (3)", "trending in
  your area", "recharge offer for your operator".
- **Celebrations**: streaks, milestones, first sale, level-up.
- **One-tap actions**: every assistant message deep-links to the exact screen.

Backend: assistant messages are just `NudgeLog`-driven entries rendered into the
assistant thread + Updates tab. Start rule-based (templates filled from
`UserState.pending` + recs); later add an LLM layer for natural phrasing/summaries.

---

## 8. Subsystem F — Learn (measurement & tuning)

- Log impression → open → conversion per nudge (`NudgeLog`).
- Metrics: D1/D7/D30 retention, DAU/MAU, sessions/user, cross-feature adoption,
  nudge CTR & conversion, unsubscribe/mute rate, push-open rate.
- A/B test variants (title/timing/channel) via `ab_variant`.
- Heuristic churn model first (recency + frequency drop) → ML later once events
  accumulate.
- Guardrail metric: notification opt-out / mute rate must stay low.

---

## 9. Phased rollout (realistic, builds on done work)

**Phase A — Senses (1–2 wk).** `UserEvent` model + `track()` + instrument the
~20 highest-signal events. Cheap, unblocking. *Nothing visible yet; data starts.*

**Phase B — Memory (1 wk).** `UserState` + nightly/rolling Celery aggregation +
lifecycle rules. Surface a basic admin dashboard (segments, churn-risk counts).

**Phase C — First nudges (1–2 wk).** `NudgeDefinition`/`NudgeLog` + a small NBA
job + **3–4 high-ROI nudges** reusing existing push/Updates:
- Win-back dormant ("we miss you + here's what's new / a diamond bonus").
- Expiring subscription reminder (data already exists).
- Pending KYC → "verify to withdraw ৳X".
- Abandoned cart / incomplete profile.
Smart timing + frequency caps from day one.

**Phase D — Habit loop (1–2 wk).** Daily check-in + streak (diamonds), 2–3
personalized missions, "Congrats" UI. This is the biggest retention lever.

**Phase E — AdsyAssistant (1–2 wk).** System assistant thread + daily briefing +
proactive reminders + recommendation cards (reuse feed/affinity + UserSuggestions
+ new product/gig/course recs). Rule-based templates first.

**Phase F — Learn & expand (ongoing).** Measurement dashboard, A/B testing,
more recommendation modules, then an LLM layer for natural assistant language and
smarter summaries/churn prediction.

> Recommended order to ship value fastest: **A → B → C → D → E**. Phase C and D
> alone typically move D7/D30 retention the most; the assistant (E) makes it feel
> "smart and human."

---

## 10. Guardrails

- **Notification fatigue is the #1 risk** — strict caps, preferred-hour sending,
  auto back-off on non-openers, and an in-app notification-preferences screen.
- **Relevance over volume** — only send when there's a real, personal reason.
- **Privacy** — events power UX, not surveillance; allow opt-out; keep raw events
  time-bounded; never expose another user's data in a nudge.
- **Transactional vs promotional** separation (always allow the former).

---

## 11. New apps/models summary (greenfield)

```
engagement/        UserEvent, UserState, NudgeDefinition, NudgeLog
gamification/      DailyCheckin, Mission, UserMission, Badge, UserBadge
(reuse)            DiamondTransaction (rewards), FCM + UserNotification (delivery),
                   feed affinity + UserSuggestionsView (recs), Celery beat (jobs)
```

Everything plugs into the existing FCM/Updates/Diamonds/Celery stack — no new
infrastructure required, only new tables + Celery jobs + a thin assistant UI.
