import SwiftUI

/// 1 · Welcome.
struct Screen01WelcomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        PiScreen {
            PiNavBar(title: "PiPlanner", showsBack: false)
        } content: {
            PiWelcomeHero()
            PiCard {
                PiSectionHeader(Text("How it works"))
                PiChoiceRow(icon: PiIcon.stepOne, title: Text("Pick a savings account"), subtitle: Text("Only its balance is read."))
                PiChoiceRow(icon: PiIcon.stepTwo, title: Text("Set your goals"), subtitle: Text("A target, an end date and a share of each credit."))
                PiChoiceRow(icon: PiIcon.stepThree, title: Text("Split every new credit"), subtitle: Text("Saved amounts lock, so they stay put."))
            }
        } dock: {
            Button("Set up savings") {
                router.setupPath.append(.accounts)
            }
            .buttonStyle(.piPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        Screen01WelcomeView()
    }
    .environment(Router())
}
