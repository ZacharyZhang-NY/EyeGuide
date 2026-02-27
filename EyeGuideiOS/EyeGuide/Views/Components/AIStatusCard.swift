import SwiftUI

struct AIStatusCard: View {
    let isActive: Bool
    let statusText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isActive ? Color.primary : Color.secondary)
                        .frame(width: 8, height: 8)
                        .opacity(isActive ? 1 : 0.4)
                    Text(isActive ? "Live" : "Standby")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                Spacer()
            }
            Spacer()
            Text("Environment Scan")
                .font(.title)
                .fontWeight(.semibold)
            Text(statusText)
                .font(.subheadline)
                .opacity(0.7)
                .padding(.top, 4)
        }
        .padding(24)
        .frame(height: 180)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.78, green: 0.72, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI Status: \(isActive ? "Active" : "Standby"). \(statusText)")
    }
}
