import SwiftUI

struct VoiceGuideButton: View {
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticService.impact()
            onTap()
        } label: {
            HStack {
                Text("Start Voice Guide")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color(red: 0.82, green: 0.96, blue: 0.33))
                        .frame(width: 40, height: 40)
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.black)
                }
            }
            .padding(.horizontal, 32)
            .frame(height: 80)
            .background(Color.primary)
            .foregroundStyle(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .accessibilityLabel("Start Voice Guide")
        .accessibilityHint("Double tap to start voice-guided navigation")
    }
}
