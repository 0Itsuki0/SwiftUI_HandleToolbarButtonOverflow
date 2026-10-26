
struct HandleToolBarOverflowDemo: View {
    @State private var axis: Axis = .vertical
    @State private var id: Int = 0

    var body: some View {
        NavigationStack {
            VStack {
                Text(
                    """
                    var defaultText = "heart heart heart heart"
                    ToolbarButton(
                        defaultContent: {
                            Text(defaultText)
                        },
                        whileOverflowing: { directions, currentSize, targetSize in
                            defaultText.removeLast()
                            return Text(defaultText)
                        },
                        action: {}
                    )
                    """
                )
                .monospaced()
                .scaleEffect(0.8)

                Picker("Axis", selection: $axis) {
                    Text("Horizontal")
                        .tag(Axis.horizontal)
                    Text("Vertical")
                        .tag(Axis.vertical)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.yellow.opacity(0.2))
            .toolbar(content: { toolbar })
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) {
                old,
                new in
                guard old != new else { return }
                self.id += 1
            }

        }
    }

    @ContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            ForEach(1..<4) { index in
                var defaultText = "heart heart heart heart"
                ToolbarButton(
                    defaultContent: {
                        Text(defaultText)
                    },
                    whileOverflowing: { directions, currentSize, targetSize in
                        defaultText.removeLast()
                        return Text(defaultText)
                    },
                    action: {
                        
                    }
                )
                /// force view to reload on possible toolbar placement change.
                .id(id * index)
                .onChange(of: id) {
                    defaultText = "heart heart heart heart"
                }
            }
         }
        .axisBehavior(
            axis == .horizontal ? .horizontalOnly : .verticalPreferred
        )
    }
}

enum OverflowDirection {
    case horizontal
    case vertical
}

extension ToolbarButton where Overflow == Never {
    init(
        @ContentBuilder defaultContent: () -> Content,
        action: @escaping () -> Void,
    ) {
        self.defaultContent = defaultContent()
        self.whileOverflowing = nil
        self.action = action
    }

}

struct ToolbarButton<Content: View, Overflow: View>: View {

    init(
        @ContentBuilder defaultContent: () -> Content,
        @ContentBuilder whileOverflowing:
            @escaping (
                _ direction: Set<OverflowDirection>, _ currentSize: CGSize,
                _ targetSize: CGSize
            ) -> Overflow,
        action: @escaping () -> Void,
    ) {
        self.defaultContent = defaultContent()
        self.whileOverflowing = whileOverflowing
        self.action = action
    }

    @ContentBuilder let defaultContent: Content
    /// nil to allow overflow
    @ContentBuilder let whileOverflowing:
        (
            (
                _ direction: Set<OverflowDirection>, _ currentSize: CGSize,
                _ targetSize: CGSize
            ) -> Overflow
        )?
    let action: () -> Void

    @State private var allowedSize: CGSize?

    var body: some View {
        if let allowedSize {
            Button(
                action: action,
                label: { self.getView(allowedSize: allowedSize) }
            )
        } else {
            /// get the allowed toolbar button size for the current placement
            GeometryReader { proxy in
                Color.clear
                    /// do NOT use initial, it will contain the value before the view is actually lay out.
                    .onChange(of: proxy.size) {
                        self.allowedSize = proxy.size
                    }
            }
        }
    }

    /// current size: content size without wrapping in the button
    private func checkOverflow(currentSize: CGSize, allowedSize: CGSize) -> Set<
        OverflowDirection
    > {
        var overflows: Set<OverflowDirection> = []
        if currentSize.height > allowedSize.height {
            overflows.insert(.vertical)
        }
        if currentSize.width > allowedSize.width {
            overflows.insert(.horizontal)
        }
        return overflows
    }

    /// for estimation on the current size only.
    /// The target size has to be get with the `settledSize` modifier
    /// because we need to render it within the Toolbar to have the constraint from the Toolbar applied.
    private func getViewSize<V: View>(view: V) -> CGSize {
        let uiView = UIHostingController(rootView: view)
        // some large number for width and height
        let sizeThatFit = uiView.sizeThatFits(
            in: .init(width: 8000, height: 8000)
        )

        return sizeThatFit
    }

    private func getView(allowedSize: CGSize) -> AnyView {
        let base = Button(action: action, label: { defaultContent })
        // getting size for content only (not wrapped with a button) to better compare with the plain size
        let currentContentSize = getViewSize(view: defaultContent)

        var currentSize: CGSize = currentContentSize
        var overflow = self.checkOverflow(
            currentSize: currentSize,
            allowedSize: allowedSize
        )

        guard let whileOverflowing else {
            return AnyView(base)
        }

        if overflow.isEmpty {
            return AnyView(base)
        }

        var final: Overflow
        while !overflow.isEmpty {
            final = whileOverflowing(overflow, currentSize, allowedSize)
            currentSize = getViewSize(view: final)
            overflow = self.checkOverflow(
                currentSize: currentSize,
                allowedSize: allowedSize
            )
            if overflow.isEmpty {
                return AnyView(final)
            }
        }
        return AnyView(base)
    }
}
