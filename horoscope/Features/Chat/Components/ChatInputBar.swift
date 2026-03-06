import SwiftUI

struct ChatInputBar: View {
    @Binding var inputText: String
    let isLoading: Bool
    let inlineStatusMessage: String?
    let canSend: Bool
    let onSend: () -> Void

    var body: some View {
        AuroraInputBar(
            inputText: $inputText,
            isLoading: isLoading,
            inlineStatusMessage: inlineStatusMessage,
            canSend: canSend,
            onSend: onSend
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chat.composer")
    }
}
