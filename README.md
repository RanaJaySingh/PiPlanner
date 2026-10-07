# PiPlanner

A Grok-powered goal ledger for one dedicated savings account. Every new credit becomes a History entry split across goals; saved entries never change. No money moves.

Product rules, demo profile and the three-minute script are in [docs/HACKATHON.md](docs/HACKATHON.md). Screens follow [docs/design/PiPlanner-Scenario-Mockups.dc.html](docs/design/PiPlanner-Scenario-Mockups.dc.html), with flows in [docs/SCREEN_FLOW.md](docs/SCREEN_FLOW.md) and [docs/USER_FLOW.md](docs/USER_FLOW.md).

## Requirements

Xcode 26 or later, iOS 17+ simulator. No third-party dependencies.

## Run

Open `PiPlanner.xcodeproj` and run the `PiPlanner` scheme. The app starts at Welcome with Rahul's demo accounts (Savings · HDFC ••4821 at ₹1,00,000, Spending · SBI ••7730).

Launch arguments, for rehearsals and UI tests:

| Argument | Effect |
| --- | --- |
| `-ui-testing` | Fixed clock (5 Oct 2026, 7:42 pm IST) and the offline Grok |
| `-demo-stage <stage>` | Start part-way: `afterOpening`, `openCredit`, `afterCustomCredit`, `afterTransfer` |

In the app, **Settings → Demo** controls the mock bank (linked in Paytm, the next balance read) and **Settings → Reset demo** returns to Welcome. The mock UPI PIN accepts any six digits except `000000`.

## Grok

Settings → Grok switches between:

- **Mock** (default): offline, parses the demo sentences into the same JSON contract the live model returns.
- **Live**: xAI chat completions. The API key is stored in the Keychain.
- **Off**: everything works through forms.

Grok only drafts. `GrokOrchestrator` validates every reply through the engine before a card is shown, rewrites answers that quote rupee figures the engine did not produce, and hands over to the Goal form after two follow-ups in setup (one in Ask). The request contains goal names, amounts, dates, percentages and status, never account data.

Goals have no inflation adjustment: required savings are `(target − saved) / months remaining`, and Grok's opening split is weighted by that monthly need in steps of 10%.

## Architecture

```text
View ──> ViewModel ──> LedgerStore (@MainActor, @Observable) ──> Ledger (value type)
                            │
                            ├── BalanceFetching (MockBank actor)
                            └── GrokOrchestrator ──> GrokClient (Mock / LiveXAI)
```

- `Engine/`: the pure ledger. Saved amounts are derived from History slices, so totals cannot drift from History.
- `Store/`: `LedgerStore` applies each change atomically (copy, mutate, assign) and owns setup and chat state.
- `App/`: `Router` keeps a typed path per tab plus sheet enums; `RootView` switches between setup and the tabs.
- `Features/`: one folder per area, screens named after mockup ids (`Screen13EntryView` is mockup 13).
- `DesignSystem/`: primitives from the mockup HTML (`PiScreen`, `PiCard`, `PiSplitRow`, …).

## Tests

```sh
xcodebuild -project PiPlanner.xcodeproj -scheme PiPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

- `PiPlannerTests` (Swift Testing): the engine on Rahul's numbers, the QA rules, formatting, the mock bank, Grok parsing and validation, and the live client against a stubbed network.
- `PiPlannerUITests` (XCTest): journeys J1–J8 and the three-minute demo, attaching a screenshot named after each mockup id. Export them with `scripts/export-shots.sh <result.xcresult> <folder>`.

### QA matrix coverage

| Rule | Covered by |
| --- | --- |
| Goal savings equal their slices; goals sum to the balance | `LedgerRuleTests`: saved is derived, assigned equals snapshot, slices balance |
| Standing split sums to 100 after create, edit, delete | `LedgerDemoTests` delete / carry-forward, `GoalsJourneyUITests` standing split |
| Saved entries never reopen; one change while open | `LedgerRuleTests` split changes once, `CreditJourneyUITests` |
| No Sync or Update balance while an entry is open | `LedgerRuleTests` one open entry, `CreditJourneyUITests` banner test |
| Goal edits wait for the next entry | `LedgerRuleTests` held edits, `GoalsJourneyUITests` edit |
| Transfer cannot exceed the source saving | `LedgerRuleTests`, `GrokOrchestratorTests`, `GoalsJourneyUITests` |
| Delete proposes an equal split; the last goal needs a receiver | `LedgerDemoTests` delete, `LedgerRuleTests` last goal |
| Unchanged balance writes nothing; lower opens Withdrawal | `LedgerRuleTests` balance change, `EdgeJourneyUITests` withdrawal |
| Consent No needs a PIN; accounts not in Paytm are manual only | `FormattingAndBankTests` PIN, `EdgeJourneyUITests` not linked |
| Automatic, PIN and manual routes write the same entry | `LedgerRuleTests` routes agree, `DemoRehearsalUITests` consent No |
| One goal is 100% with no split screen | `LedgerDemoTests` single goal, `SetupJourneyUITests` form fallback |
| Grok quotes only engine figures; no account data leaves | `GrokOrchestratorTests` rupee audit and trust boundary, `LiveXAIClientTests` |
| No screen reviews or blocks a payment | `GrokOrchestratorTests` payments refused |
