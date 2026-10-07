---
name: PiPlanner Hackathon Plan v3
overview: "PiPlanner on iPhone is a SwiftUI dedicated-savings ledger. Consent Yes updates the balance automatically. Consent No lets the customer update it each time, either manually or by a balance sync (UPI PIN check for an account in Paytm, manual entry for an account on another UPI app). A single goal defaults to 100%. Every new amount becomes a History entry where, once, the split can be changed or a goal created. Goals are fully CRUD-managed. Deleting a goal releases its saving, split equally by default, with one manual edit or a new goal. Shopping is never reviewed or blocked. The rule engine owns every rupee; Grok turns plain language into proposals the engine validates."
todos:
  - id: write-hackathon-doc
    content: Rewrite docs/HACKATHON.md around the savings ledger (this file)
    status: completed
  - id: write-screen-flow
    content: docs/SCREEN_FLOW.md with every screen, its states, and where each action goes
    status: completed
  - id: write-user-flow
    content: docs/USER_FLOW.md with the journeys, decision points, and edge rules
    status: completed
  - id: write-design-spec
    content: docs/DESIGN.md with Paytm-theme tokens, components, wireframes, and copy
    status: completed
  - id: build-ledger-engine
    content: Build the pure Swift ledger and its unit tests before any screen
    status: pending
  - id: build-screens
    content: Build the SwiftUI screens in the order listed under Two-day build
    status: pending
isProject: false
---

# PiPlanner — Hackathon Plan v3

**One-line definition.** Every credit to your savings account gets a goal before it can be spent, and what you already assigned never moves unless you move it.

**Theme.** Customer Experience, with a secondary Revenue Impact angle (goal-linked Paytm actions the customer chooses). Open Innovation is the backup label.

```text
PiPlanner
Every Rupee Has a Plan.
Goal-based savings ledger, powered by Grok, inside Paytm
```

**Philosophy line.** Paytm helps you move money. PiPlanner helps you know where that money should take you. The customer decides.

## What changed in v3

Latest changes:

- **Consent flow follows the hand-drawn tree.** Yes: automatic balance updates. No: the customer chooses Manually or Balance sync each time. Balance sync on an account linked in Paytm goes UPI PIN → Check balance → Fetch. Balance sync on an account from another UPI app falls back to manual entry.
- **One goal means 100%.** With a single goal the saving percentage defaults to 100% and no split screen is shown.

Merged from the latest plan file:

- **Updating without consent.** Declining consent no longer blocks anything; the customer updates the balance themselves (superseded in detail by the consent tree above).
- **History is the working surface.** The tab is named History. Every Sync or typed amount writes an entry and opens it. The one-time percentage change, creating a goal, editing a goal, and deleting a goal all happen from that open entry. After Save it is a record.
- **Delete starts from an equal split** of the released amount across the remaining goals, and the customer may add a goal on that screen.
- **All goal edits wait for the next transaction**, including target, dates, and inflation.
- **Shopping is out entirely.** No review, no gating, and the spend coach is off the roadmap too.
- **HLD, modules, records, sync sequence, and trust boundary** added.
- **FigJam board links** added. Ask starters cut to two.

Kept from v2, because the latest file still carried the earlier versions: the ledger-first pitch, demo script, slides, metrics, QA matrix, judging-criteria section, the consistent demo profile, full goal CRUD from the Goals tab, and the rules for an unchanged balance, a lower balance, and the last goal.

## Core idea coverage

| Core requirement | Where it lives |
|---|---|
| Multiple bank accounts, one marked dedicated savings | Accounts screen |
| Consent flow for balance update | Consent sheet (Yes / No), then Update balance: Manually or Balance sync with UPI PIN |
| Goal: name, target, current saving, required savings, start and end date, inflation popup (default 7%) | Goal chat or Goal form, Inflation popup |
| Goal setup stored as history (₹1,00,000 at 60/40) | Opening entry in History |
| Previous amount stored so Sync finds the new amount | Snapshot store |
| New credit updates goals by default percentage | History entry, suggested split |
| Edit percentages once, for that new amount only | Open History entry |
| Create a new goal for that new amount | Open History entry |
| Goal edits apply only to new transactions | Goal form; edits are held until the next transaction |
| Goal transfer | Transfer sheet, own History entry |
| Goal deletion shows the saving percentage screen | Delete screen |

## Ledger rules

1. **Snapshot.** The last balance of the dedicated account is stored. When a balance is fetched (automatically, or by a PIN balance check), new amount = fetched − stored. When it is entered manually, new amount = what the customer types.
2. **One entry per new amount.** Sync and Update balance each write one History entry with the suggested split and open it.
3. **Open, then saved.** While an entry is open the customer may, once, change its percentages or create a goal for it. Save locks it. Goal totals change on Save. A new Sync or Update balance is not offered while an entry is open.
4. **Slices are append-only.** A saved entry is never edited. Current saving of a goal = sum of its slices.
5. **Standing split.** Percentages across all goals, summing to 100. It only suggests the split of the next new amount. With exactly one goal it is 100% by default: the percentage field is prefilled and the split screens are skipped. Adding a second goal reopens the split.
6. **Create.** A new goal starts at ₹0 unless created on an open entry, on the delete screen, or funded by a transfer. Creating one reopens the standing split.
7. **Update.** Any edit (name, target, dates, inflation, standing percentage) is held and applied at the next transaction. Until then the goal card shows "Change saved. Applies at the next credit." No earlier entry is rewritten.
8. **Transfer.** Moves saved money between two goals as its own History entry. Standing percentages are unchanged.
9. **Delete.** Opens the saving-percentage screen: the released amount, split equally across the remaining goals. The customer may edit the percentages once or create a goal there. Confirm writes one entry and removes the goal. The standing split is renormalised across the goals that remain.
10. **Last goal.** With one goal left, delete is allowed only if a new goal is created on the delete screen to receive the money.
11. **Balance unchanged.** Sync says there is no new credit and writes nothing.
12. **Balance lower.** Sync opens the withdrawal sheet, reducing each goal in proportion to its saving, editable once. With manual entry the same sheet opens from "Record a withdrawal" on Manual amount.
13. **Consent.** Asked for the dedicated account, where credits and income arrive.
    - **Yes:** Sync reads the balance without further steps.
    - **No:** each update opens a choice.
      - *Manually:* the customer types the amount.
      - *Balance sync, account linked in Paytm:* UPI PIN → Check balance → the balance is fetched.
      - *Balance sync, account on another UPI app:* Paytm cannot check it, so the customer enters it manually.
    Every route produces the same History entry.
14. **Shopping.** The spending account is shown on Accounts and nowhere else. Nothing reviews or interrupts a payment.

**Formulas (in Swift, never in Grok).**

```text
adjusted target  = target × (1 + inflation) ^ (months from start to end / 12)
required savings = (adjusted target − current saving) / months remaining
status           = on track if this month's slices ≥ required savings, else behind
```

## Demo profile

Rahul, monthly income ₹1,20,000, monthly spending ₹71,000, so about ₹49,000 can reach savings. Dedicated savings opens at ₹1,00,000.

The latest file still used the earlier profile (18 months against a 24-month calculation, a ₹20,000 credit against ₹45,204 needed for one goal). This one is kept because its numbers agree with each other.

| Goal | Target | Dates | Inflation | Adjusted target | Standing % |
|---|---|---|---|---|---|
| Car | ₹10,00,000 | Oct 2026 – Sep 2030 (48 months) | 7% | ₹13,10,796 | 60 |
| Emergency | ₹2,00,000 | Oct 2026 – Sep 2027 (12 months) | 7% | ₹2,14,000 | 40 |
| Vacation (created on the entry) | ₹50,000 | Oct 2026 – Mar 2027 (6 months) | 7% | ₹51,720 | 20 |

**Ledger through the demo.**

| Step | Car | Emergency | Vacation | Balance |
|---|---|---|---|---|
| Opening entry 60/40 | ₹60,000 | ₹40,000 | – | ₹1,00,000 |
| Sync entry +₹50,000, suggested 60/40 | +₹30,000 | +₹20,000 | – | |
| Changed once to 50/30/20 with Vacation, saved | ₹85,000 | ₹55,000 | ₹10,000 | ₹1,50,000 |
| Transfer ₹5,000 Emergency → Car | ₹90,000 | ₹50,000 | ₹10,000 | ₹1,50,000 |
| Delete Vacation, ₹10,000 released, equal split ₹5,000 / ₹5,000, edited to 60/40 | ₹96,000 | ₹54,000 | – | ₹1,50,000 |

**Required savings on screen.**

| Moment | Car | Emergency | Vacation |
|---|---|---|---|
| After opening | ₹26,058 | ₹14,500 | – |
| Vacation at creation | | | ₹8,620 |
| After the saved credit | ₹25,537 | ₹13,250 | ₹6,953 |
| After the transfer | ₹25,433 | ₹13,667 | ₹6,953 |

Car gets ₹25,000 of the credit against ₹26,058 needed, so it reads "₹1,058 behind this month". That shows the cost of adding Vacation.

## Grok's role

1. **Plain language to proposal.** Goal sentences become goal drafts. "Put 20% of this into a ₹50,000 Goa trip by March" becomes a new goal plus the one-time split on the open entry. "Move 5k from Emergency to Car" becomes a transfer draft. Grok returns structured JSON, the engine validates it, and the customer confirms a card.
2. **Inflation.** One sentence on why 7% is the starting point; any other figure is an editable estimate.
3. **Explanation.** Old money versus new money on each entry.
4. **Ask.** Starters: "What happens if I change the split?" and "Why is inflation 7%?"

If Grok is unavailable, every action still runs through forms with template sentences. No number depends on Grok.

## Three-minute demo

1. **Accounts and consent (20 s).** Mark Savings as dedicated. Consent: Yes.
2. **Goals by conversation (35 s).** One sentence, two goals at 60/40, 7% inflation, lock. History now holds the opening entry.
3. **Sync (50 s).** Sync writes a ₹50,000 entry and opens it: previous ₹1,00,000, fetched ₹1,50,000, suggested ₹30,000 / ₹20,000. Rahul asks for the Goa trip at 20%. Save at ₹25,000 / ₹15,000 / ₹10,000.
4. **Proof (15 s).** History: the opening entry still reads 60/40.
5. **Manage (40 s).** Edit Car's end date: "Applies at the next credit." Transfer ₹5,000. Delete Vacation: equal split shown, edited to 60/40.
6. **Consent No (20 s).** Reset, answer No. Update balance → Balance sync → UPI PIN → Check balance fetches ₹1,00,000. Later, Update balance → Manually → ₹50,000. The same entry appears in History.
7. **Close.** Comparison slide and the roadmap sentence.

## iOS app

SwiftUI, iPhone simulator, portrait, one mock profile, no login, no backend, no real bank or payment call. Details in [SCREEN_FLOW.md](SCREEN_FLOW.md), [USER_FLOW.md](USER_FLOW.md), and [DESIGN.md](DESIGN.md).

```text
Welcome
  -> Accounts
  -> Consent sheet
       Yes -> balance fetched automatically
       No  -> Update balance
                Manually -> Manual amount
                Balance sync
                  Account in Paytm -> UPI PIN -> Check balance -> Fetch
                  Other UPI app    -> Manual amount
  -> Goal chat -> Inflation popup (default 7%) -> Opening split
  -> Tab shell: Goals | History | Ask
       Goals
         -> Sync (consent Yes) / Update balance (consent No) -> History entry
         -> Goal detail -> Goal form (edit) / Transfer / Delete
         -> New goal -> Goal form -> Standing split
         -> Settings
       History
         -> open entry: update percentages, create a goal, edit a goal, delete a goal
         -> saved entry: read only
```

### Two-day build

- Views: Welcome, Accounts, Consent, Update balance, UPI PIN (mock), Manual amount, Goal chat, Goal form, Inflation popup, Opening split, Goals, Goal detail, Standing split, Sync, History, History entry, Transfer, Delete, Withdrawal, Ask, Settings.
- Day 1: ledger engine with unit tests, Accounts, Consent, Manual amount, Goal form, Inflation, Opening split, Goals, Sync and Update balance, History entry.
- Day 2: History list, Goal detail, Standing split, Transfer, Delete, Grok proposals and Ask, Withdrawal, Settings with Reset demo, rehearsal.
- Cut order if short of time: Withdrawal sheet, then Ask, then Grok on transfer. Never cut the History entry, the goal form, or the consent No routes.

Leave out: widgets, push, login, charts, a second currency, real balance APIs, Autopay, any payment SDK, and any screen that reviews or interrupts a purchase.

## HLD

In-process SwiftUI app. A later balance API replaces the mock fetch; consent, snapshots, and the ledger stay the same.

```text
SwiftUI
  Welcome, Accounts, Consent, Goal chat, Goals, History, Ask
  Sheets: Inflation, Opening split, Update balance, UPI PIN, Manual amount, Sync,
          History entry, Goal form, Transfer, Delete, Withdrawal
        |
        v
App state (in memory)
  accounts, consent, goals, snapshot, history
        |
        +---> Rule engine (pure Swift)
        |       inflation, required savings, sync delta, apply %,
        |       one-time change, transfer, delete redistribution, withdrawal
        |
        +---> Grok orchestrator
                sentence -> JSON draft -> engine validates -> proposal card
                numbers -> short copy; template fallback
```

### Modules

- **UI.** Renders engine output and never computes rupees.
- **App state.** Holds the session. Reset demo restores Rahul's opening profile.
- **Consent gate.** Yes reads the balance for the opening split and every Sync. No routes each update through the Update balance choice; a fetch then happens only after a UPI PIN balance check on an account linked in Paytm.
- **Snapshot store.** One previous balance. After a fetch, the fetched balance becomes the next previous. After a manual entry, previous + typed amount becomes the next previous.
- **History.** One entry per new amount, transfer, delete, or withdrawal.
- **Rule engine.** Everything under Ledger rules.
- **Grok orchestrator.** Drafts and copy only.

### Records

```swift
struct Account { let id: UUID; let bank: String; let maskedLabel: String
                 var role: Role; var mockBalance: Decimal
                 var linkedInPaytm: Bool }                        // false = other UPI app, so manual entry only
                                                                  // exactly one account is .dedicatedSavings
enum Role { case dedicatedSavings, spending }

struct Consent { var isOn: Bool; var acceptedScope: String }     // off = ask Manually / Balance sync on every update

struct Goal {
    let id: UUID
    var name: String, target: Decimal, start: Date, end: Date
    var inflation: Decimal = 0.07
    var standingPercent: Decimal      // only suggests the NEXT new amount
    var pendingEdit: GoalEdit?        // held here, applied when the next entry is written
    var isDeleted = false             // kept so old entries still resolve a name
}

enum EntryKind { case opening, credit, transfer, deleteRedistribution, withdrawal }
enum EntrySource { case fetched, pinCheck, typed }   // auto (consent Yes), PIN balance check, manual
enum EntryState { case open, saved }  // open = the one-time change is still available

struct HistoryEntry {
    let id: UUID, kind: EntryKind, source: EntrySource, date: Date
    let previousBalance: Decimal
    let fetchedBalance: Decimal?      // nil when the amount was typed
    let newAmount: Decimal
    var state: EntryState
    var slices: [Slice]               // replaced once while open, frozen on save
    var customSplit = false
}

// signed, so a transfer is one negative slice and one positive slice
struct Slice { let id: UUID; let goalID: UUID; let amount: Decimal; let entryID: UUID }

// current saving is derived, never stored, so History cannot drift from the totals
func saved(_ goal: UUID, in history: [HistoryEntry]) -> Decimal {
    history.filter { $0.state == .saved }
           .flatMap(\.slices).filter { $0.goalID == goal }
           .reduce(0) { $0 + $1.amount }
}
```

### Sync sequence

```text
Customer taps Sync or Update balance
  -> consent Yes: previous ₹1,00,000, mock fetch ₹1,50,000, delta ₹50,000
  -> consent No, Balance sync, account in Paytm: UPI PIN -> Check balance -> same delta
  -> consent No, Manually, or account on another UPI app: delta = typed amount
  -> apply any pending goal edits
  -> write an open History entry with the suggested split, and open it
  -> once: change percentages for this amount, create a goal, edit a goal
     for the next transaction, or delete a goal via the saving-percentage screen
  -> Save: entry is frozen, snapshot updated, Goals re-renders
```

### Trust boundary

Grok receives goal names, percentages, amounts, dates, inflation, and status. It never receives an account number, UPI id, phone, payee, or statement line.

**Production path.** Balance reads would come through an Account Aggregator consent. With consent Yes, automatic reads would come through an Account Aggregator consent. With consent No, the balance check is Paytm's existing UPI balance enquiry, which needs the PIN each time and works only for accounts linked in Paytm; in production the PIN is entered on the secure UPI page, and the prototype's PIN pad is a labelled mock. Confirm both with payments and compliance. The manual route means the product also works for accounts Paytm cannot read. No money moves, so no wallet or new regulated product is needed.

## Judging criteria

**Paytm business impact (30%).** A reason to open Paytm at every credit; goal-linked gold, SIP, travel, and insurance offers the customer chooses; works on any linked account and, through manual entry, on any account at all; cheap to ship.

**Grokbot usage (20%).** Grok is the input method: goals, the split on a new entry, and a transfer each take one sentence. Show the form once as the fallback.

**Working prototype and feasibility (20%).** The full ledger runs on device with unit tests. Only the mock fetch changes in production.

**Cross-functional collaboration (20%).** At most three members from Tech. Name what each function did: product (rules and edge cases), design (History entry and scope wording), engineering (engine, app, orchestrator), QA (matrix below), compliance or risk (consent copy, "no money moves"), business (offer sizing). List only functions that took part.

**Innovation (10%).** Pots at Monzo or Jupiter move money inside one bank. Jar and PhonePe Daily Savings save a fixed amount into gold. PiPlanner moves no money, works on any account, assigns each credit as it arrives, and keeps every past assignment visible and frozen.

## QA matrix

- Each goal's saving equals the sum of its slices; all goals sum to the stored balance.
- Standing percentages sum to 100 after create, edit, and delete.
- A saved entry cannot be reopened; an open entry allows one percentage change.
- No Sync or Update balance while an entry is open.
- A goal edit changes nothing until the next entry is written, and changes no earlier entry.
- Transfer cannot exceed the source goal's saving.
- Delete proposes an equal split of exactly the released amount; with one goal left it requires a new goal.
- Unchanged balance writes nothing; a lower balance opens the withdrawal sheet.
- Consent No never fetches without a PIN step; an account not linked in Paytm only ever offers manual entry.
- Automatic, PIN-check, and manual routes produce the same entry for the same amounts.
- With one goal the percentage is 100% and no split screen appears; a second goal reopens the split.
- No rupee Grok quotes differs from the engine; the Grok payload has no account identifier.
- No screen reviews, warns about, or blocks a payment.

## Metrics on mock data

- ₹50,000 of ₹50,000 assigned in the session of the credit.
- Opening entry unchanged after four later operations.
- One sentence and one Save to add a goal and split a credit.
- Ledger total equals account balance at every step, on the automatic, PIN-check, and manual routes.

Pilot metrics: share of credits assigned within 24 hours, share of updates by route (automatic, PIN check, manual), goals per customer, 30 and 90 day retention, goal-linked purchases.

## Pitch (8 slides)

1. Title.
2. Problem: a savings account is one number, so nobody can tell which rupees are for what.
3. Solution: mark one account, set goals, assign every new amount on arrival.
4. How it works: snapshot, delta, History entry, standing split. Grok proposes, the engine validates, the customer saves.
5. Live demo: Sync and the open History entry.
6. Managed goals: create, edit, transfer, delete, with history that never rewrites. Manual mode.
7. HLD, trust boundary, production path.
8. Business impact, who built what, roadmap, philosophy line.

## Registration text

The 3 Oct deadline has passed. If the spend-coach paragraph was submitted, open with: "We registered PiPlanner as a goal coach; we built the part every goal coach needs first, the ledger that knows which rupee belongs to which goal."

If the text can still be edited:

PiPlanner is a Grok-powered goal ledger inside Paytm. A customer marks one bank account as dedicated savings and either allows automatic balance updates or updates the balance themselves, by a PIN balance check or by typing it. They describe goals in plain language. Each new amount becomes a history entry split across goals by their percentages, which they can change once for that amount. Earlier entries stay frozen, and goals can be created, edited, transferred between, and deleted. No money moves and no payment is ever interrupted. Theme: Customer Experience.

## Roadmap (say it, do not build it)

Phase 2: Account Aggregator balance reads, automatic sync on credit, several dedicated accounts. Phase 3: Hindi and Hinglish, streaks, shared goals. Phase 4: goal-linked SIP, gold, travel, and insurance offers the customer chooses.

## End-to-end flow in plain language

1. Choose the savings account this plan will use.
2. Say Yes to automatic balance updates, or No and update it yourself: type it, or check the balance with your UPI PIN if the account is in Paytm.
3. Name the goals. PiPlanner suggests a split. Change it if needed, then lock it.
4. Each new amount adds an entry in History showing only that amount.
5. On that entry, once, keep the suggested percentages, change them, or create a goal.
6. A goal edit waits for the next transaction. A transfer writes its own entry. Deleting a goal shows where its money goes before confirming.

### FigJam boards

- User flow: https://www.figma.com/board/Z6HYzZKbAqrHjRqKb5mItB
- App flow: https://www.figma.com/board/q9gB65WYRUGiQIybdN9yz5
