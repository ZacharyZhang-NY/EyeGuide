import SwiftUI

struct FeatureItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let subtitle: String
    let mode: AIMode
}

struct FeatureGrid: View {
    let onFeatureTap: (AIMode) -> Void

    private let features = [
        FeatureItem(icon: "scope", label: "Locate", subtitle: "Keys, Phone, Door", mode: .findObject),
        FeatureItem(icon: "doc.text.viewfinder", label: "Read", subtitle: "Signs, Menus, Mail", mode: .readText),
        FeatureItem(icon: "person.2.fill", label: "Social", subtitle: "Recognize Faces", mode: .social),
        FeatureItem(icon: "eye.fill", label: "Scene", subtitle: "Describe surroundings", mode: .scene),
    ]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(features) { feature in
                Button {
                    onFeatureTap(feature.mode)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 44, height: 44)
                            Image(systemName: feature.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(Color.primary)
                        }
                        Spacer()
                        Text(feature.label)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primary)
                        Text(feature.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                }
                .accessibilityLabel("\(feature.label): \(feature.subtitle)")
            }
        }
    }
}
