import SwiftUI
import ActomatonStore

struct RootView: View
{
    private let store: Store<Root.Action, Root.State>.Proxy

    init(store: Store<Root.Action, Root.State>.Proxy)
    {
        self.store = store
    }

    var body: some View
    {
        return VStack {
            NavigationView {
                List(exampleList, id: \.exampleTitle) { example in
                    navigationLink(example: example)
                }
                .navigationBarTitle(Text("🎭 Actomaton Gallery 🖼️"), displayMode: .large)
                .toolbar {
                    Toggle(isOn: store.usesTimeTravel.stateBinding(onChange: { .debugToggle($0) })) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
        }
    }

    private func navigationLink(example: Example) -> some View
    {
        NavigationLink(
            destination: example.exampleView(store: self.store)
                .navigationBarTitle(
                    "\(example.exampleTitle)",
                    displayMode: .inline
                ),
            isActive: self.store.current
                .stateBinding(onChange: Root.Action.changeCurrent)
                .transform(
                    get: { $0?.example.exampleTitle == example.exampleTitle },
                    set: { _, isPresenting in
                        isPresenting ? example.exampleInitialState : nil
                    }
                )
                // Comment-Out: `removeDuplictates()` introduced in #3 seems not needed in iOS 15.
                // https://github.com/inamiy/Harvest-SwiftUI-Gallery/pull/3
                //
                // Workaround for SwiftUI's duplicated `isPresenting = false` calls per 1 dismissal.
                // .removeDuplictates()
        ) {
            HStack(alignment: .firstTextBaseline) {
                example.exampleIcon
                    .frame(width: 44)
                Text(example.exampleTitle)
            }
            .font(.body)
            .padding(5)
        }
    }
}

struct RootView_Previews: PreviewProvider
{
    static var previews: some View
    {
        return Group {
            RootView(
                store: .init(
                    state: .constant(Root.State(usesTimeTravel: true)),
                    send: { _ in }
                )
            )
                .previewLayout(.fixed(width: 320, height: 480))
                .previewDisplayName("Root")

            RootView(
                store: .init(
                    state: .constant(Root.State(current: .counter(.init()), usesTimeTravel: true)),
                    send: { _ in }
                )
            )
                .previewLayout(.fixed(width: 320, height: 480))
                .previewDisplayName("Intro")
        }
    }
}
