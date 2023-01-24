import SwiftUI
import ActomatonUI

/// 色々Genericを使っている。すなわち、外部の構造体などを直接参照するのではなく、Genericsとし、型にEquatableなどに準拠していることを求めるだけにとどめている。これによりこの構造体の外部への依存性を低めている。
/// InnerStateについては保持しているだけで特別なことはしていない。
public struct TabItem<InnerState, ID>: Equatable, Identifiable, Sendable
    where InnerState: Equatable & Sendable, ID: Hashable & Sendable
{
    public var common: Common
    public var inner: InnerState

    public init(
        id: ID,
        inner: InnerState,
        tabItemTitle: String,
        tabItemIcon: Image
    )
    {
        self.common = Common(id: id, tabItemTitle: tabItemTitle, tabItemIcon: tabItemIcon)
        self.inner = inner
    }

    public var id: ID
    {
        self.common.id
    }

    /// id, タブのタイトル・画像を含む、本構造体の核となる情報を収めた内部構造体。
    public struct Common: Equatable, Identifiable, Sendable
    {
        public var id: ID

        public var tabItemTitle: String
        public var tabItemIcon: Image

        public init(
            id: ID,
            tabItemTitle: String,
            tabItemIcon: Image
        )
        {
            self.id = id
            self.tabItemTitle = tabItemTitle
            self.tabItemIcon = tabItemIcon
        }
    }
}

// MARK: - @unchecked Sendable

// TODO: Remove `@unchecked Sendable` when `Sendable` is supported by each module.
extension Image: @unchecked Sendable {}
