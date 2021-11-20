import Foundation
import SwiftUI

public struct User: Equatable
{
    public let id: UUID
    public var name: String
    public var icon: Image

    public init(
        id: UUID = .init(),
        name: String,
        icon: Image
    )
    {
        self.id = id
        self.name = name
        self.icon = icon
    }
}

extension User
{
    public static func makeSample() -> User
    {
        User(
            name: "User \(UInt8.random(in: .min ... .max))",
            icon: Image(systemName: "face.smiling")
        )
    }

    public static let anonymous = User(
        name: "Anonymous",
        icon: Image(systemName: "person.fill.questionmark")
    )
}