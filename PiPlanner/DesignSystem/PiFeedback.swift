import SwiftUI

/// `w`: amber information strip.
struct PiWarningBanner: View {
    let text: Text

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: PiIcon.info)
                .font(.system(size: 17))
                .accessibilityHidden(true)
            text
                .font(PiFont.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(PiColor.warningText)
        .padding(.horizontal, 14)
        .padding(.vertical, PiSpacing.m)
        .background(PiColor.warningTint, in: RoundedRectangle(cornerRadius: PiRadius.pinKey, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// `er`: red validation line.
struct PiErrorLine: View {
    let text: Text
    var isCentered = false

    var body: some View {
        HStack(spacing: PiSpacing.s) {
            Image(systemName: PiIcon.error)
                .font(.system(size: 15))
                .accessibilityHidden(true)
            text
                .font(PiFont.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(PiColor.danger)
        .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// `toast`: dark capsule at the bottom of the screen.
struct PiToast: View {
    let text: Text

    var body: some View {
        HStack(spacing: PiSpacing.s) {
            Image(systemName: PiIcon.info)
                .foregroundStyle(PiColor.skyHighlight)
                .accessibilityHidden(true)
            text
        }
        .font(PiFont.body)
        .foregroundStyle(.white)
        .padding(.horizontal, PiSpacing.l)
        .padding(.vertical, PiSpacing.m)
        .background(PiColor.toast, in: RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 14, y: 12)
        .accessibilityElement(children: .combine)
    }
}

/// Shows a toast at the bottom of a view while `message` is non-nil, then clears it.
struct PiToastModifier: ViewModifier {
    @Binding var message: String?
    var duration: Duration = .seconds(2.5)

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    PiToast(text: Text(verbatim: message))
                        .padding(.bottom, 96)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: message) {
                            try? await Task.sleep(for: duration)
                            withAnimation { self.message = nil }
                        }
                        .onAppear {
                            UIAccessibility.post(notification: .announcement, argument: message)
                        }
                }
            }
            .animation(.snappy, value: message)
    }
}

extension View {
    func piToast(_ message: Binding<String?>) -> some View {
        modifier(PiToastModifier(message: message))
    }
}

#Preview {
    VStack(spacing: PiSpacing.m) {
        PiWarningBanner(text: Text("This account is not linked in Paytm, so we can't check it. Enter the balance instead."))
        PiErrorLine(text: Text("Incorrect PIN."), isCentered: true)
        PiToast(text: Text("No new credit since the last sync."))
    }
    .padding()
}
