import SwiftUI
import ActomatonStore
import Counter

struct CounterExample: Example
{
    var exampleIcon: Image { Image(systemName: "goforward.plus") }

    var exampleInitialState: Root.State.Current
    {
        .counter(Counter.State())
    }

    func exampleView(store: Store<Root.Action, Root.State>.Proxy) -> AnyView
    {
        exampleView(
            store: store,
            actionPath: /Root.Action.counter,
            statePath: \.counter,
            makeView: CounterView.init
        )
    }
}