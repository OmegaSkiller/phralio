# Feature concept: Reading Rhythm

**Status:** proposal for discussion; not approved or implemented.\
**Date:** 29 September 2026.\
**Working product name:** Reading Rhythm.\
**One-line pitch:** A few minutes of guided reading practice that finds a comfortable pace, checks understanding, and helps you stretch a little at a time.

## 1. The experience we want

Phralio becomes a personal reading coach as well as a reader. The user completes short, interesting exercises, answers a few questions, and tells the app how the exercise felt. The next exercise responds to both understanding and comfort. Progress earns collectible achievements and optional social cards.

The core loop is:

**Choose today's session → read → check understanding → “How did that feel?” → see the next recommendation → practice again → celebrate and finish.**

The rewarding moment is “That felt easier, and I understood it.” Increasing the speed slider alone does not earn a speed achievement.

This is a product hypothesis. Better performance in Phralio's word-by-word exercises does not establish faster everyday reading or better comprehension outside the app. Numerical thresholds below are initial design choices to validate, not scientifically established training prescriptions.

## 2. Where it lives

- **Home:** a compact “Your reading rhythm” card with the next practice, approximate duration, and this week's practice days. Start practice is the primary action; View progress is secondary.
- **After onboarding:** one optional invitation: “Want help finding a comfortable pace?” The existing tour remains a way to learn the app. Training is a separate, ongoing activity.
- **Practice hub:** Today, Progress, and Achievements as sections within the feature. Keep the existing Home / Read / Saved / Settings navigation; no fifth bottom tab.
- **Reader:** a secondary “Practice your pace” action when paused. It opens a curated exercise, preserving the current document and position.
- **Settings:** edit practice language, session length, interests, weekly goal, reminders, or reset practice history separately from the library.

No account is required. The core practice loop and adaptation work offline with downloaded or bundled content.

## 3. First visit: show value before asking for a routine

The first visit takes approximately 4–6 minutes, with an honest estimate that includes questions and feedback.

| Step | Screen and interaction | What happens next |
| --- | --- | --- |
| Invitation | “Find your comfortable pace.” Explain short readings, understanding checks, and adjustable speed. Start / Not now. | Start opens a small setup, not a long questionnaire. |
| Reading language | Confirm the language of the practice texts, separately from interface language. | Only offer packs suitable for meaningful scoring in that language. |
| Your aim | Choose “Keep up with articles,” “Stay focused,” or “Read for pleasure.” Skip is available. | This chooses topics and exercise emphasis; it does not assign an ability level. |
| First preview | A 20-second sample starts paused. “New to this?” defaults to 150 target WPM. Users can choose another comfortable starting pace. | Try, pause, and adjust until ready. This familiarization is unscored. |
| First check | Read a fresh 120–180-word passage; answer three understanding questions; rate difficulty. | Establish provisional evidence and explain the next recommendation. |
| Second check | A different passage of comparable difficulty at the same or a lower pace, based on feedback. | Confirm a starting range if both attempts qualify. Otherwise offer an easier exercise or finish with a provisional plan. |
| Starting point | “Let's start around 180 WPM. You answered 3 of 3 questions on both readings.” Or: “We're still finding your pace. We'll start gently next time.” | Never invent a baseline from incomplete or unsuccessful checks. |
| Your routine | Choose 3, 5, or 8 minutes and 2, 3, or 5 practice days per week. Suggested default: 5 minutes, 3 days. Optional topic choices. | Save preferences; show the first earned practice badge. |
| Finish | “Your next practice is ready.” Open library / View my plan. Optional reminder action. | Ask for notification permission only if the user requests a reminder. |

Do not keep someone trapped in calibration. After at most three assessed passages, finish with either a confirmed starting point or a clearly provisional one. They can practice, stop, or recalibrate later.

## 4. A normal practice session, screen by screen

### A. Today's invitation

Example:

> **A little more flow**\
> About 5 minutes · 3 short readings\
> Start comfortably, try one small stretch, then settle back in.\
> **Start practice**

Secondary actions: Short session, Choose a topic, View plan. The user can change duration without losing progress or rewards already earned.

### B. A quick readiness check

“How's your focus today?” → **Ready / A little tired / Keep it gentle**.

One tap continues. Skip uses the current comfortable pace. This is a temporary session preference, not a permanent ability judgment. “Keep it gentle” disables upward speed suggestions for this session.

### C. Exercise briefing

Show the title, approximate reading time, one instruction, and the reason for the choice:

> **Warm up · 1 of 3**\
> Keep your attention on the word; pause whenever you need.\
> Starting a little below your comfortable pace.\
> **Read**

Provide an optional pace adjustment before starting. Start paused, retain the user's font and appearance, and use the existing reader gestures. Instructions remain stationary before playback.

### D. Read

Reuse Phralio's centered word, scope lines, progress bar, punctuation timing, tap-to-pause, and context canvas. No badges, timers counting down, confetti, coach messages, or competing visuals in the reading field.

Pause opens the existing context view. The user can move through words, lower the pace, resume, or end the exercise. These are legitimate reading actions. Attempts involving rereading or changed pace become practice evidence rather than comparable speed checks.

Finishing the passage opens the understanding check. Pausing or backgrounding never advances to a question or discards the user's position.

### E. Check understanding

Standard assessed exercises have three short questions, shown one at a time:

1. Main idea: “What was the passage mostly about?”
2. Meaningful detail: “Why did the character change their plan?”
3. Connection or inference supported by the text.

Use clear multiple-choice answers with a **Not sure** option. Avoid trivia, trick wording, specialist knowledge, or questions that test unrelated memory skills. There is no answer timer.

Allow **Read that part again**. It opens the relevant passage paused and marks the attempt as assisted. Do not withhold help to preserve a score.

Collect all three answers before revealing explanations, so an explanation cannot give away another answer. The review shows each answer, a short rationale, and an optional link to the relevant sentence. Initial answers remain the scoring evidence; corrections after review are learning, not a new perfect score.

### F. Ask for feedback after every exercise

The primary question is always the same:

> **How hard did that feel?**

| Choice | Plain-language meaning |
| --- | --- |
| Very easy | “I had plenty of room to spare.” |
| Easy | “Comfortable all the way through.” |
| Just right | “I needed to focus, but kept up.” |
| Hard | “I lost the thread in places.” |
| Too hard | “I couldn't keep up comfortably.” |

Use labeled choices, not emoji alone. A single tap records the rating. A separate Continue action gives the user time to see and change their choice.

For Hard / Too hard, optionally ask **What got in the way?** → Pace / Wording / Distraction / Tiredness / Display comfort / Not sure. One selection is enough; no required written response.

If understanding was low despite “Easy,” ask gently: “Was the wording unfamiliar, or was a question unclear?” The app should not assume the user is careless or dishonest. Offer Report a question and an explanation.

Feedback can be skipped. Missing feedback means unknown comfort, not “easy.” The next task can continue at the same or a gentler pace, but cannot unlock a speed increase from that attempt.

### G. Explain the next exercise

Examples:

- “You followed that comfortably. Try 210 WPM, up from 200?” → **Try it / Keep 200**.
- “That felt demanding. Let's keep the speed and use a shorter passage.” → **Continue / Adjust**.
- “A slower pace may help with the next text: 180 WPM.” → **Try 180 / Choose pace**.
- “That question may have been unclear. This exercise won't change your recommended pace.” → **Continue**.

No automatic start. Never surprise the user with a mid-passage increase. An upward suggestion always needs acceptance; declining it is neutral.

### H. Finish with a useful summary

Show one headline, up to three facts, and one next step:

> **A comfortable session**\
> 3 readings completed · 8 of 9 questions answered correctly\
> You tried 210 WPM. One more comfortable check on another day will help confirm it.\
> **Done** · View progress · Share

For a difficult session:

> **You've found a better starting point**\
> The last reading felt easier at 180 WPM. We'll start there next time.\
> Today's practice still counts.

Always distinguish “tried” from “confirmed.” Share is secondary, never a condition for collecting an achievement. “Done” ends the session; an optional extra exercise does not turn the plan into an endless queue.

## 5. Session recipes and exercise variety

| Session | Recipe | Purpose |
| --- | --- | --- |
| 3 minutes | Comfortable reading + one adaptive reading, including questions and feedback | An achievable short visit; no mandatory stretch |
| 5 minutes | Warm-up + one adaptive reading + comfortable finish | Default routine with a clear beginning and end |
| 8 minutes | Warm-up + two adaptive readings + comfortable finish | More practice, subject to fatigue feedback |
| Gentle day | Shorter passages at the same or lower pace; no increases | Preserve the routine without pressure |
| Weekly check-in | Two fresh comparable passages; a third on a later day if evidence is mixed | Check whether a new pace feels reliably comfortable |

Generate the estimate from passage length, selected timing policy, and an allowance for questions and feedback. If the user spends longer answering, keep the promise of a bounded exercise count rather than rushing them to meet a timer.

Exercise families:

| Family | Interaction | Adaptation |
| --- | --- | --- |
| Find the rhythm | Short narrative or everyday explanation, followed by questions | Establish comfort with the reader |
| Small stretch | Comparable new text at a slightly higher target pace | Test one speed change without changing text difficulty |
| Follow the meaning | Same pace, passage with a clear cause/effect or sequence | Strengthen understanding; use answer explanations |
| Hold a comfortable pace | Slightly longer text at the same pace | Explore sustained focus without also increasing speed |
| Recover and resume | Pause intentionally, use surrounding context, resume, then reflect | Teach control; participation reward only, no speed claim |
| Read something you chose | Open a personal library item for relaxed practice and self-reflection | Apply preferences to real reading; no scored comprehension claim without authored questions |

Introduce one variable at a time: pace, length, or text difficulty. A new genre or unfamiliar vocabulary starts at the same or a lower pace. Do not treat a harder text at the same WPM as regression.

## 6. Personalization rules

### What the coach uses

Keep the model small and explainable. Initial adaptation needs no AI service.

- Separate profile per practice language and comparable content band.
- Current recommended target pace, confirmed starting benchmark, and confirmation evidence.
- Last three comparable assessed attempts, using distinct passages.
- Correct first answers, assistance/review use, and question-quality flags.
- Difficulty and obstacle feedback; today's readiness preference.
- Completion, interruptions, rereading, manual pace changes, and typography/timing changes relevant to comparison.
- Interests and session length as preferences, not proxies for ability.

Pausing alone is not failure. An incoming call, a long interruption, or a manual adjustment makes an attempt unsuitable for a speed milestone; it can still earn participation credit.

### What counts as a qualifying speed check

All of these must hold:

- A fresh, unseen, reviewed passage in the same language, content band, and timing-policy group.
- Complete playback without seeking, answer assistance, or manual pace changes.
- Three of three first answers correct, with no Not sure answer or question report.
- Difficulty is Very easy, Easy, or Just right.
- No interruption that invalidates the comparison. A self-reported distraction excludes the attempt from speed confirmation.

Three questions provide limited evidence. Repetition on different passages and days reduces the chance of celebrating a lucky result; it does not turn the result into a standardized reading assessment.

### Initial decision table

Apply the first matching rule. Upward changes affect the next exercise only.

| Evidence | Next exercise | Effect on confirmed progress |
| --- | --- | --- |
| Too hard, wants to stop, or reports tiredness/discomfort | Offer stop or gentle practice; no upward suggestion. If continuing because pace was the issue, lower pace by about 10%. | No lost badges or negative score |
| Interrupted, assisted, feedback skipped, or question flagged | Hold pace or offer easier; replace flagged content and do not score that attempt for advancement. | No confirmation evidence |
| 0–1 of 3 correct | Review meaning; use a new comparable passage around 10% slower. If wording was the obstacle, use simpler content at the same pace instead. | Do not confirm a higher pace |
| 2 of 3 correct, first occurrence at this pace | Explain the missed answer; hold pace with new comparable content. | Practice evidence only |
| 2 of 3 on two consecutive comparable attempts | Lower pace about 10%, or simplify wording if identified as the cause. Change only one variable. | Update today's recommendation, retain historical achievements |
| 3 of 3 correct, but Hard | Hold pace with a shorter passage or offer 5% slower. | Not qualifying for an increase |
| Qualifying attempt at the current comfortable pace; user is ready | Offer a small stretch: approximately +5%, rounded to 5 WPM and capped at +15 WPM. | “Trying a new pace” until separately confirmed |
| Qualifying attempt at a proposed higher pace | Repeat that pace on new comparable content on another day; no further increase yet. | Count as evidence toward confirmation |
| Two qualifying attempts among the last three comparable checks at the same candidate pace, on at least two separate practice days | Confirm that candidate as the comfortable practice pace. | Eligible for a factual pace milestone |

Round reductions to 5 WPM, cap a single proposed reduction at 30 WPM, and stay inside the existing reader's supported range. “Choose pace” remains available if a small reduction is insufficient. At the current 100-WPM floor, suggest stronger pauses or shorter/easier content; do not silently propose an unsupported lower number.

Additional bounds:

- At most one new upward candidate per session. Do not stack several speed increases from a few easy questions.
- A challenge attempt can never also count as confirmation at a different pace.
- Two hard exercises in a session trigger an explicit “Finish for today?” choice and disable further upward suggestions.
- After a week away, start with a short comfortable check, optionally about 10% below the last recommendation. Historical progress remains visible; the user can choose their previous pace.
- After a language or timing-policy change, establish a separate baseline. Font/size changes trigger a comfort preview; materially different conditions must be rechecked before comparing milestones.
- User overrides always win. Record them as practice choices; never quietly overwrite regular-reader settings.

### Example of adaptation over several visits

| Visit | Reading and feedback | Coach response |
| --- | --- | --- |
| First visit | Two different texts at 200 target WPM; both 3/3, Easy | Establish 200 as the starting pace |
| Next day | Warm-up comfortable; accepts 210; gets 3/3, Just right | Record first evidence at 210; finish comfortably at 200 |
| Following day | Another comparable text at 210; 3/3, Easy | Confirm 210; show “A new comfortable pace” achievement |
| Later | Tries 220; 1/3, Hard; selects Wording | Explain answers; try simpler content at 220, without using that easier text to confirm progress in the original content band |
| Tired day | Chooses Keep it gentle | Offer short readings around 200; count practice, preserve the 210 milestone |

## 7. Progress that means something

Show three distinct views rather than one opaque “reading score”:

1. **Practice:** days practiced, completed exercises, and weekly goal.
2. **Understanding:** first-answer results across comparable exercises, with sample counts. Assisted attempts appear separately.
3. **Comfortable practice pace:** confirmed target WPM over time, with language, content band, and smart-pause policy. Unconfirmed trials appear as “Exploring.”

Phralio's target WPM controls base word timing. Punctuation, long-word, and paragraph pauses make actual passage delivery slower. Label target pace honestly; never present the slider value as measured everyday reading speed.

If a later version displays effective delivery rate, compute it from words actually delivered and active playback time, state how pauses are handled, and keep it separate from target WPM. Do not multiply WPM by a quiz percentage to invent “comprehension speed.”

Percentage improvement is available only between two confirmed, comparable target paces: `(current − starting) / starting × 100`, rounded conservatively. Always display the practice context and understanding evidence beside it. Otherwise show “More practice needed for a comparison.”

The chart can flatten or decrease as recommendations respond to current comfort. Historical best, current recommendation, and today's choice are separate facts. There is no requirement for an upward line every week.

## 8. Rewards and achievements

Use a collectible **Reading Passport**: a quiet grid of Lucide-based achievement marks with the date earned and a clear explanation. Each session fills one part of the user's weekly practice goal. The reward system works without a currency, shop, leaderboard, or public profile.

| Achievement | Earned when | Example message |
| --- | --- | --- |
| First Step | Finish one exercise and reach its review; feedback may be skipped | “Your first practice is in the book.” |
| Found My Rhythm | Complete the two qualifying initial checks | “You have a comfortable starting point.” |
| A Week of Reading | Meet the chosen weekly practice-day goal | “You made room for reading this week.” |
| Meaning Matters | Three distinct, unassisted assessed exercises with 3/3 first answers | “Three readings followed with care.” |
| New Comfortable Pace | Confirm a higher candidate under the rules above | “210 target WPM now feels comfortable.” |
| A Little Further | Confirm +10%, +25%, or +50% relative to a comparable starting benchmark | “A little more pace, with understanding checked.” |
| Steady Reader | Meet the weekly goal in four weeks; weeks need not be consecutive | “A routine that fits your life.” |
| Back in Rhythm | Complete an exercise after at least seven inactive days | “Good to have you back.” |

Reward rules:

- A practice day requires at least one completed exercise and its review. Opening the app, skipping a passage, or changing the clock does not count as practice. Store a consistent local-day identity to avoid duplicate daily credit after timezone changes.
- A partially finished session can still count as a practice day. Show the actual exercise count; do not label the full planned session complete.
- Easier exercises and low scores still earn participation credit. Accuracy and speed badges have their own explicit criteria.
- Repeating familiar material is welcome but cannot earn new speed or understanding evidence from memorized answers.
- Award each milestone once, keyed to its criterion and profile. Reopening a result screen must not award it again.
- Existing badges are not revoked after a tired day or missed week. Resetting practice history explicitly removes its achievements after confirmation.
- No lives, failing streak alarms, paid streak repairs, speed rankings, or reward for sharing. Weekly goals can change; show the goal that applied to a completed week rather than rewriting history.
- Offer a brief checkmark, haptic, or optional celebration on the result screen. Reduced motion uses a static state. Never interrupt the reading field with rewards.

## 9. Social sharing flow

Sharing is an export of a result the user chooses, not a connected social account.

1. Tap **Share** on a session summary or earned achievement.
2. Preview a locally generated card. Choose **Achievement / This week / Pace milestone**.
3. Choose a square feed layout (1080 × 1080) or portrait story layout (1080 × 1920), with comfortable safe margins.
4. Choose light or dark styling and optional details: first name, date, practice language, and statistics. Name is off by default. A pace card's language, target-pace label, and comparison context are required for an honest claim.
5. Offer an editable caption separately from the image.
6. Tap **Share…** to open the native share sheet, or **Save image**. The user chooses the destination and completes posting there. Copy caption remains available where a social app ignores supplied text.
7. Closing the sheet returns to the result. The app may know that sharing was opened; it must not claim “Posted” unless the platform actually confirms that outcome.

Example cards:

> **I made room for reading.**\
> 3 practice days this week · Phralio

> **A new comfortable pace.**\
> 220 target WPM · English practice\
> Understanding checked on 2 fresh passages\
> Phralio Reading Rhythm

> **A little further: +10%.**\
> 200 → 220 target WPM · Comparable English practice\
> Two qualifying checks · Normal smart pauses\
> Practiced in Phralio

Use the supplied split-P geometry, IBM Plex Sans, crisp light/AMOLED themes, and the selected vibrant accent. Place the small brand signature outside the result's main message. No screenshots of a user's document, book titles, passages, quiz answers, fatigue feedback, or private library information appear on default cards. Decorative sharing artwork stays outside the reader itself.

There is no public verification service in this proposal. Cards represent local practice records, not certified assessments. No auto-posting, contact access, referral spam, or gated rewards.

## 10. Content and languages

The adaptive system is only as trustworthy as its passages and questions.

- Start with an original, licensed, or verified public-domain content pack. Each item includes language, topic, word count, editorial difficulty band, text version, three reviewed questions, answer keys, explanations, and evidence sentences.
- Use engaging everyday subjects rather than exam-like filler. Let users skip disliked topics without losing their current pace.
- Match speed comparisons on passage length, genre, vocabulary, and sentence complexity as closely as practical. Label matches as an editorial approximation, not psychometric equivalence.
- Keep first exposure and replay distinct. Retire reported/ambiguous questions from advancement decisions until reviewed.
- Never fabricate a new “fresh” benchmark when a pack runs out. Offer a familiar practice exercise without advancement credit, another available pack, or a later check-in.
- Personal TXT, EPUB, Markdown, URL, and clipboard content can support unscored practice. It has no authoritative comprehension key. Do not upload it or automatically generate supposedly verified scores from it.
- Avoid a live generative-content dependency in the first version. Generated drafts, if used by editors later, need human review before joining assessed packs.

The interface should follow Phralio's ten supported languages. Reading language is an explicit independent choice; never silently substitute English. A language may have translated controls before it has a reviewed training pack; explain availability and let the user choose another language they read comfortably.

Current tokenization splits on whitespace. Chinese and Japanese therefore need appropriate segmentation, reviewed packs, and language-appropriate pace units before scored training can launch for them. Do not relabel whitespace chunks as words or compare scores across languages. These are release prerequisites for those training packs, not changes authorized by this idea document.

## 11. UX and recovery details

| Situation | Expected behavior |
| --- | --- |
| User exits mid-reading | Pause, preserve the local practice position, and offer Resume / Start fresh next visit. Mark a substantially interrupted attempt unsuitable for a pace comparison. |
| User exits during questions or feedback | Save answered questions and the unfinished step locally. Resume there; do not replay or award twice. |
| Phone call or app backgrounding | Pause immediately. Resume remains explicit. No speed penalty for an interruption. |
| User changes font, size, or theme | Preview immediately. Comfort takes priority; recheck comparability if conditions materially change. |
| User lowers speed during an exercise | Apply through the existing reader controls; record as practice, not a failed exam. |
| Save fails | Keep the result in the current session, show Retry, and avoid claiming an achievement is safely saved. Do not advance the plan until the result is recorded or explicitly discarded. |
| No internet | Bundled practice, local adaptation, progress, and image export still work. External sharing depends on the chosen destination. |
| Reminder denied | Continue normally. Reminders remain an optional convenience. |
| No appropriate new content | Explain the limit and offer unscored practice. No recycled benchmark disguised as fresh material. |
| Repeated difficulty | Offer simpler/shorter material, stronger pauses, a lower pace, or a break. No repeated “try harder” prompts. |
| User resets training | Confirm exactly which practice history and badges will be removed. Personal readings, stars, bookmarks, and reading positions remain intact. |

Use comfortable touch targets, native sheets and back navigation, text scaling, sufficient contrast, and reduced-motion behavior. In paused practice, only the text canvas scrolls word by word; surrounding reader chrome stays fixed. Feedback and question screens can use normal page scrolling when large text or small windows require it.

## 12. Local state and boundaries for a future implementation

Keep practice in a separate feature area with its own persistence. Do not insert exercise passages into the personal library or overwrite its reading positions.

Minimum durable state:

| Record | Contents |
| --- | --- |
| Practice profile | Reading language, goal, interests, preferred duration, current recommendation, baseline context, optional reminder preference |
| Content reference | Pack/item ID and version, editorial band, language, first-use/replay state |
| Session | Planned recipe, readiness choice, exercise order, unfinished screen, start/completion state |
| Attempt | Passage reference, target pace and timing policy, answers, assistance/interruption flags, difficulty, optional obstacle, outcome and next recommendation |
| Achievement | Stable criterion ID, earned date, supporting attempts, profile/language context |

Save the completed attempt, adaptation decision, and newly earned achievements atomically. Resuming or retrying a save must be idempotent. Store the adaptation-rule version so a later algorithm can explain past decisions rather than silently rewriting them.

Reuse the existing playback engine and timing policy. A feature-level practice coordinator chooses documents/settings, records observations, and selects the next exercise. It should not introduce a second reading engine. Practice settings are temporary; “Use this pace in my reader” is a separate explicit action at the end.

Detailed results and feedback stay local. This preserves the app's current no-account, no-content-upload model. No cloud coaching, cross-device sync, public profiles, or new data collection is implied by the proposal.

If existing optional usage analytics are enabled, proposed events can be limited to fixed actions such as practice opened, session finished, feedback skipped, achievement viewed, and share sheet opened. Do not send answers, ratings, personal pace, content IDs, titles, text, or reading positions. Aggregate event counts cannot establish unique-user retention or learning gains; evaluate those in a separate explicitly consented study.

## 13. Delivery slices and validation

### First useful release

Ship one complete loop: optional setup, two-passage calibration, short sessions, reviewed content in supported training languages, three-question checks, difficulty feedback, deterministic adaptation, local history, weekly practice goal, a small achievement set, and native share-card export. Keep the UI translated and training-pack availability explicit.

### Later, after observing real use

Expand reviewed language/topic packs; add longer-session recipes and optional real-library practice; explore delayed recall checks and transfer to conventional reading. Consider reminders and additional cosmetic achievements only if people find them useful. Cloud sync, social challenges, and AI-authored personal quizzes require separate proposals.

### Before implementation approval

- Prototype the complete first session and a returning session, including an easy result, a hard result, a skipped rating, and an interrupted exercise.
- Observe a small initial group of readers with varied familiarity. Check whether they understand the difference between target pace, comprehension results, and confirmed progress.
- Measure whether questions and feedback feel helpful or tedious. Adjust passage count and copy before optimizing streaks or sharing.
- Editorially review the first pack and the matching criteria. Confirm licensing and scoring-language readiness.
- Validate the content production workload: enough fresh, comparable passages are a launch dependency, not a later polish task.

### Acceptance scenarios for the eventual feature

- High speed with poor understanding never unlocks a pace milestone.
- “Too hard” and “Keep it gentle” prevent upward suggestions.
- Feedback is requested after every exercise, can be revised before continuing, and can be skipped without trapping the user.
- An assisted or repeated passage earns practice credit but cannot confirm faster performance.
- One successful higher-speed attempt remains a trial; confirmation requires separate-day evidence.
- A user can finish early, return after a break, or lower speed without losing achievements.
- A saved session resumes at the correct screen, without duplicate rewards or changes to personal-library data.
- Every adaptation can be explained in a short sentence and overridden by the user.
- Share previews expose exactly what will leave the device; cancel never posts, and no private reading text leaks into the card or analytics.
- Both themes, compact/landscape/tablet layouts, large text, reduced motion, and supported language packs remain usable.

Evaluate the concept by comfortable completed practice and comprehension-preserving progress on unseen matched texts, not by the highest WPM selected, session length, or share volume. Any claim that it improves everyday reading requires separate evidence of transfer beyond the app's exercises.

## 14. Starting decisions to review

Recommended defaults: **Reading Rhythm** as the feature name, 5-minute sessions three days a week, achievements without XP currency, explicit approval for each upward pace suggestion, and local-only personalization.

The highest-impact product choices before building are the first reviewed content languages, the amount of launch content, whether three questions per exercise feel proportionate, and how closely the content bands can support meaningful comparisons. The draft thresholds should change if prototype and content-review evidence suggests a better approach.

## Relationship to current work

This proposal builds on the [interactive onboarding plan](../design/onboarding-redesign.md) and the [existing design rules](../../DESIGN.md). The app already supplies the reading controls, imports, local library, themes, fonts, and optional analytics boundary. Guided training, authored comprehension checks, achievements, reminders for practice, adaptive plans, and social-card export described here are **proposed features**, not current capabilities.
