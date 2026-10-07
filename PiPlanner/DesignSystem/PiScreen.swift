import SwiftUI

/// Pushed-screen scaffold: grey page, pinned header, scrolling content, and a bottom dock for CTAs.
///
/// Mirrors the mockup `build()` helper, which moves buttons, chips and inputs into a dock at the bottom.
struct PiScreen<Header: View, Content: View, Dock: View>: View {
    private let header: Header
    private let content: Content
    private let dock: Dock

    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder dock: () -> Dock
    ) {
        self.header = header()
        self.content = content()
        self.dock = dock()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PiSpacing.m) {
                content
            }
            .padding(.horizontal, PiSpacing.screen)
            .padding(.bottom, PiSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            if Header.self != EmptyView.self {
                header
                    .padding(.horizontal, PiSpacing.screen - 2)
                    .background(PiColor.page)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if Dock.self != EmptyView.self {
                VStack(spacing: PiSpacing.s) { dock }
                    .padding(.horizontal, PiSpacing.screen)
                    .padding(.top, PiSpacing.m)
                    .padding(.bottom, PiSpacing.s)
                    .background(PiColor.page)
            }
        }
        .background(PiColor.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    /// Chat screens: short threads start at the top, and new messages scroll into view.
    @ViewBuilder
    func chatScrollAnchor() -> some View {
        if #available(iOS 18, *) {
            defaultScrollAnchor(.top, for: .alignment)
                .defaultScrollAnchor(.bottom, for: .initialOffset)
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
        } else {
            self
        }
    }

    /// A Done button above the keyboard while this field is focused. Number pads have no return key.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

extension PiScreen where Dock == EmptyView {
    init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.init(header: header, content: content, dock: { EmptyView() })
    }
}

extension PiScreen where Header == EmptyView {
    init(@ViewBuilder content: () -> Content, @ViewBuilder dock: () -> Dock) {
        self.init(header: { EmptyView() }, content: content, dock: dock)
    }
}

extension PiScreen where Header == EmptyView, Dock == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(header: { EmptyView() }, content: content, dock: { EmptyView() })
    }
}

/// Bottom-sheet scaffold (`S()` frames): white surface, drag indicator, height fitted to content.
struct PiSheet<Content: View>: View {
    private let content: Content
    @State private var contentHeight: CGFloat = 320

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PiSpacing.m) {
            content
        }
        .padding(.horizontal, PiSpacing.xl)
        .padding(.top, 28)
        .padding(.bottom, PiSpacing.l)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            contentHeight = height
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(PiRadius.hero)
        .presentationBackground(PiColor.surface)
    }
}

#Preview("Screen") {
    PiScreen {
        PiNavBar(title: "Accounts", trailing: .tag("Step 1 of 3", .step))
    } content: {
        PiLargeTitle("Your accounts")
        PiCard { Text("Content") }
    } dock: {
        Button("Continue") {}.buttonStyle(.piPrimary)
    }
}
