# PiPlanner — Design Spec

For the SwiftUI prototype. iPhone, portrait, light mode only for the demo.

## Principles

1. **Locked money looks locked.** Already-saved amounts are grey, with a lock icon, and never sit inside an editable control.
2. **Two scopes, two labels.** "This credit only" and "From the next credit" are the only two phrases used for percentage changes. Never "update split" on its own.
3. **Rupees beside every percentage.** A percentage is never shown without the amount it produces.
4. **Totals are visible.** Any screen that edits a split shows a running total and disables its button until the total is right.
5. **Grok proposes, a card confirms.** Chat output that changes anything appears as a card with Confirm, never as plain text.
6. **Open and saved entries look different.** An open History entry has a sky "Assign now" pill and live controls. A saved one is grey-locked with no controls at all.
7. **No shopping anywhere.** No spend row, no warning, no review-before-pay. The spending account appears only on Accounts.

## Tokens

The theme follows the Paytm home screen: a pale grey page, white rounded section cards with a bold navy title, navy line icons, sky-blue links, and outlined pill chips. Hex values are read from a screenshot, so treat them as close estimates and replace them with the official tokens if the team has them.

| Token | Value | Use |
|---|---|---|
| `color.navy` | `#002E6E` | Primary buttons, icon circles, line icons, active tab |
| `color.sky` | `#00B9F1` | Links ("View All →"), progress fill, slider tint, focus |
| `color.skyTint` | `#E3F4FD` | Banner and proposal-card background, selected chip |
| `color.ink` | `#101010` | Section titles, amounts |
| `color.inkSecondary` | `#6B7280` | Captions, labels |
| `color.surface` | `#FFFFFF` | Section cards, sheets, chips |
| `color.background` | `#F3F5F8` | Screen background |
| `color.border` | `#E3E7ED` | Chip outlines, hairlines |
| `color.locked` | `#8A94A6` | Locked amounts and lock icon |
| `color.lockedFill` | `#EEF1F6` | Background of the "Already saved" block |
| `color.new` | `#0A8F5B` | New amount, on-track chip |
| `color.warn` | `#B26A00` | Behind chip, withdrawal |
| `color.danger` | `#D32F2F` | Delete, validation errors |

| Type style | SwiftUI | Use |
|---|---|---|
| Display | `.largeTitle.bold()`, monospaced digits | Account balance, new amount |
| Section title | `.title3.bold()`, `ink` | Title at the top of each section card |
| Amount | `.headline`, monospaced digits | Goal amounts |
| Body | `.body` | Copy |
| Tile label | `.caption`, centred, two lines max | Under icon tiles |
| Caption | `.footnote`, `inkSecondary` | Labels, notes |
| Link | `.subheadline.weight(.semibold)`, `sky`, trailing arrow | "View All →", "Change for this credit only →" |

System font (SF Pro) throughout.

**Layout pattern.** Every screen is a stack of white section cards on the grey page, as on the Paytm home screen. Each card has its bold title top-left and, where there is more to see, a sky link top-right. Cards have no shadow and no border; the grey page separates them.

Spacing 4 / 8 / 12 / 16 / 24. Screen margin 8, card padding 16, gap between cards 12. Card radius 20. Buttons and chips are full pills. Icon circle 48 pt, navy fill, white line icon. Minimum tap target 44 pt. Amounts use Indian grouping (₹1,50,000) and no decimals.

**Icons.** SF Symbols in the outline weight, navy, to match Paytm's line icons: `car` for Car, `cross.case` for Emergency, `airplane` for Vacation, `arrow.left.arrow.right` for Transfer, `lock` for locked amounts, `arrow.triangle.2.circlepath` for Sync.

**Entry point.** PiPlanner appears as a tile in the "Free Tools" row of the Paytm home screen, beside Track Your Spends: a tinted card titled "Plan Your Savings" with a small goal illustration. One mocked home screen with this tile opens the demo, so judges see where the feature lives.

## Components

| Component | Description |
|---|---|
| `SectionCard` | White card, radius 20, bold title, optional sky link top-right. The container for everything else |
| `IconTile` | Navy line icon over a two-line centred label, four to a row. Used for quick actions: Sync, New goal, Transfer, History |
| `PillChip` | White pill with a 1 pt border and a small leading icon. Used for chat starters and filters |
| `Banner` | `skyTint` card with a bold line, a caption, and a white pill button. Used for "New credit found" and the Welcome hero |
| `AccountRow` | Bank name, masked label, balance, "Dedicated savings" toggle (navy when on) |
| `GoalCard` | Navy icon circle, name, status chip, saved / adjusted target, sky progress bar, "Needs ₹X a month", standing % |
| `StatusChip` | Pill: On track (green), Behind by ₹X (amber), Ended (grey) |
| `LockedBlock` | Grey panel with a lock icon listing amounts that cannot change |
| `SplitRow` | Goal name, slider, percentage field, rupee result |
| `SplitTotal` | "Total 100%" in green, or "Total 90%, 10% left" in red |
| `ScopeLabel` | Pill reading "This credit only" or "From the next credit" |
| `ProposalCard` | Grok's draft: rows of goal and amount, one sentence, Confirm and Edit |
| `HistoryRow` | Icon by type, title, date, previous → new balance, new amount, per-goal amounts, and an "Assign now", "Custom split", or "Typed" tag |
| `AmountField` | Large centred rupee field with Indian grouping as you type. Used on Manual amount |
| `ChoiceCard` | Two stacked white cards with a navy icon circle, title, and one-line caption. Used on Update balance |
| `PinPad` | Six dots and a numeric pad on a white sheet, bank name and masked label above. Mock, tagged "Demo" |
| `PendingNote` | Small sky-tint strip on a goal card: "Change saved. Applies at the next credit." |
| `DeltaHeader` | Previous, fetched, and new amount in three lines |
| `PrimaryButton` | Navy pill, white label, full width, 52 pt high |
| `SecondaryButton` | White pill with a navy 1 pt border and navy label |
| `ProposalCard` background | `skyTint`, with a small "Powered by Grok" caption bottom-right, as the Pocket Money banner carries its partner mark |

## Wireframes

### Accounts

```text
┌──────────────────────────────────┐
│ Your accounts                    │
│ Pick one for dedicated savings.  │
│ ┌──────────────────────────────┐ │
│ │ Savings · HDFC ••4821        │ │
│ │ ₹1,00,000                    │ │
│ │ Dedicated savings      [ ON ]│ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ Spending · SBI ••7730        │ │
│ │ ₹72,000                      │ │
│ │ Dedicated savings      [OFF ]│ │
│ │ Everyday spend. Not split.   │ │
│ └──────────────────────────────┘ │
│                                  │
│ [          Continue            ] │
└──────────────────────────────────┘
```

### Goals tab

Three section cards on the grey page: the balance card with its row of icon tiles, a "New credit found" banner when Sync finds one, and "Your Goals" with a "View All →" link.

```text
┌──────────────────────────────────┐
│ Good evening, Rahul           ⚙  │
│ Dedicated savings                │
│ ₹1,50,000                        │
│ Last synced today, 7:42 pm       │
│  (⟳)    (+)     (⇄)     (☰)     │  <- navy icon circles
│  Sync  New goal Transfer History │
│                                  │
│ Your Goals            View All → │
│ ┌──────────────────────────────┐ │
│ │ Car            Behind ₹1,058 │ │
│ │ ₹85,000 of ₹13,10,796        │ │
│ │ ▓░░░░░░░░░░░░░░░░░░░         │ │
│ │ Needs ₹25,537 a month · 50%  │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ Emergency          On track  │ │
│ │ ₹55,000 of ₹2,14,000         │ │
│ │ ▓▓▓▓▓░░░░░░░░░░░░░░░         │ │
│ │ Needs ₹13,250 a month · 30%  │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ Vacation           On track  │ │
│ │ ₹10,000 of ₹51,720           │ │
│ │ Needs ₹6,953 a month · 20%   │ │
│ └──────────────────────────────┘ │
│ + New goal                       │
├──────────────────────────────────┤
│   Goals      History       Ask   │
└──────────────────────────────────┘
```

With consent No the first tile reads "Update balance", and the caption reads "Last updated".

### Consent sheet

```text
┌──────────────────────────────────┐
│ Update this balance              │
│ automatically?                   │
│ Savings · HDFC ••4821            │
│ ✓ Reads only this balance        │
│ ✓ Stores the last balance to     │
│   find what is new               │
│ ✓ Never sends account details    │
│   to Grok                        │
│ ✓ Change it any time             │
│                                  │
│ [   Yes, update automatically  ] │  <- navy pill
│ [   No, I'll update it myself  ] │  <- outlined pill
└──────────────────────────────────┘
```

Both buttons are real choices, so the second is an outlined pill of equal width, not a text link.

### Update balance (consent No)

```text
┌──────────────────────────────────┐
│ Update balance                ✕  │
│ ┌──────────────────────────────┐ │
│ │ (✎) Manually                 │ │
│ │     Type the amount yourself │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ (⟳) Balance sync             │ │
│ │     Check with your UPI PIN  │ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

If the account is on another UPI app, tapping Balance sync shows the "not linked in Paytm" line under the card and moves to Manual amount.

### UPI PIN → Check balance → Fetch

```text
┌──────────────────────────────────┐
│ Check balance            [Demo]  │
│ HDFC Bank ••4821                 │
│ No money is debited.             │
│                                  │
│         ●  ●  ●  ○  ○  ○         │
│                                  │
│        1     2     3             │
│        4     5     6             │
│        7     8     9             │
│              0     ⌫             │
│ [       Check balance          ] │
└──────────────────────────────────┘
        ↓ after the PIN
┌──────────────────────────────────┐
│ ✓ Balance fetched                │
│ ₹1,50,000                        │
│ [          Continue            ] │
└──────────────────────────────────┘
```

### Manual amount

```text
┌──────────────────────────────────┐
│ How much did you add?            │
│                                  │
│            ₹50,000               │  <- AmountField, Display
│                                  │
│ [          Continue            ] │
│ Record a withdrawal →            │  <- not shown during setup
└──────────────────────────────────┘
```

During setup the title is "How much is in this account?"

### History entry (open)

Sync, a PIN balance check, and a manual amount all land here. With one goal the split is a single text row at 100% and no sliders. A typed entry has no "Balance now" line and carries a "Typed" tag.

```text
┌──────────────────────────────────┐
│ ‹ New credit       [Assign now]  │
│ Previous balance      ₹1,00,000  │
│ Balance now           ₹1,50,000  │
│ New amount             ₹50,000   │  <- color.new, Display
│                                  │
│ 🔒 Already saved, not changing   │  <- LockedBlock
│    Car ₹60,000 · Emergency ₹40,000│
│                                  │
│ Split ₹50,000  [This credit only]│
│ Car        ───●────  50% ₹25,000 │
│ Emergency  ──●─────  30% ₹15,000 │
│ Vacation   ─●──────  20% ₹10,000 │
│ + Add a goal                     │
│ Total 100%                       │
│ Use this split from the next     │
│ credit too               [ ON ]  │
│                                  │
│ "₹1,00,000 was already assigned. │
│  This ₹50,000 is new. Car gets   │
│  ₹1,058 less than it needs."     │
│                                  │
│ [       Save and lock          ] │
│ You can change this split once.  │
│ Edit a goal →   Delete a goal →  │
└──────────────────────────────────┘
```

Before the customer taps "Update percentages for this amount", the slider rows are plain text rows (Car 60% ₹30,000, Emergency 40% ₹20,000) with that link beneath them. After Save the same screen shows text rows only, a lock beside the title, and no buttons.

### Goal form (edit mode)

```text
┌──────────────────────────────────┐
│ ‹ Edit goal               Save   │
│ Name            Car              │
│ Target          ₹10,00,000       │
│ Start           Oct 2026         │
│ End             Sep 2030         │
│ Inflation       7%            ›  │
│ Share of new credits   50%       │
│ [From the next credit]           │
│ Changes apply at the next credit.│
│ Earlier history stays as it is.  │
│ ──────────────────────────────── │
│ Saved so far         ₹85,000  🔒 │
│ Target with inflation ₹13,10,796 │
│ Needs a month         ₹25,537    │
└──────────────────────────────────┘
```

### Delete screen

```text
┌──────────────────────────────────┐
│ ‹ Delete Vacation                │
│ This releases ₹10,000.           │
│ Choose where it goes.            │
│                                  │
│ Car        ───●────  50%  ₹5,000 │
│ Emergency  ───●────  50%  ₹5,000 │
│ + Create a goal                  │
│ Total 100%                       │
│ Split equally. Change it once.   │
│                                  │
│ New credits will then split      │
│ Car 62.5% · Emergency 37.5%      │
│                                  │
│ [   Delete and move ₹10,000    ] │  <- color.danger
│ Cancel                           │
└──────────────────────────────────┘
```

The screen opens on the equal split. The demo then edits it to 60/40 (₹6,000 / ₹4,000). Creating a goal resets the rows to equal shares across all goals. With no other goal left, the rows are empty and the button stays disabled until a goal is created.

### History tab

```text
┌──────────────────────────────────┐
│ History                          │
│ ⇄ Transfer             5 Oct     │
│   Emergency → Car      ₹5,000    │
│ ↓ New credit · Custom split 5 Oct│
│   ₹1,00,000 → ₹1,50,000  +₹50,000│
│   Car ₹25,000 · Emergency ₹15,000│
│   Vacation ₹10,000               │
│ 🔒 Opening balance       5 Oct   │
│   ₹1,00,000                      │
│   Car ₹60,000 · Emergency ₹40,000│
└──────────────────────────────────┘
```

An open entry sits at the top with the "Assign now" pill in place of the lock.

### Proposal card (chat)

```text
┌──────────────────────────────────┐
│ Grok's proposal                  │
│ New goal: Vacation               │
│ ₹50,000 by Mar 2027, 7% inflation│
│ This ₹50,000:                    │
│   Car ₹25,000 · Emergency ₹15,000│
│   Vacation ₹10,000               │
│ [ Confirm ]   [ Edit ]           │
│ Checked by PiPlanner. Estimate.  │
└──────────────────────────────────┘
```

## Copy

| Place | Text |
|---|---|
| Welcome | Every credit to savings gets a goal before it can be spent. |
| Consent title | Allow PiPlanner to check this balance? |
| Consent yes | Yes, update automatically |
| Consent no | No, I'll update it myself |
| Update choice | Manually · Balance sync |
| PIN screen | Check balance. No money is debited. |
| Other UPI app | This account is not linked in Paytm, so we can't check it. Enter the balance instead. |
| Single goal | This is your only goal, so it gets 100%. |
| Manual amount, setup | How much is in this account? |
| Manual amount, later | How much did you add? |
| Inflation label | Estimate, not a guarantee. |
| Sync, nothing new | No new credit since the last sync. |
| Open entry banner | ₹50,000 to assign |
| Entry button | Save and lock |
| Edit note | Changes apply at the next credit. Earlier history stays as it is. |
| Pending edit | Change saved. Applies at the next credit. |
| Delete hint | Split equally. Change it once. |
| Last goal | Create a goal to receive this money. |
| Transfer error | Emergency has only ₹50,000 saved. |
| Split error | Total 90%. Assign the remaining 10%. |
| Withdrawal title | Your savings balance went down by ₹X. |
| Grok unavailable | Grok is unavailable. You can still do this by hand. |

## Motion and accessibility

- Sheets use the system presentation. After Save on a History entry, each goal's amount counts up to its new value over about half a second, then a lock icon appears on the credit row.
- Status is never colour alone: every chip has text.
- Sliders always have a paired numeric field for exact entry and VoiceOver.
- Dynamic Type supported up to the first accessibility size; amounts wrap below labels instead of truncating.
