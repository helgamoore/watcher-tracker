//
//  GeminiImageGeneratorView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 19/09/2026.
//

import SwiftUI

struct GeminiImageGeneratorView: View {

    var body: some View {
        VStack(spacing: 16) {

            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("Gemini Image Generator")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "Google Gemini image-generation integration will be implemented here."
            )
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(32)
        .frame(
            minWidth: 600,
            minHeight: 450
        )
    }
}

#Preview {
    GeminiImageGeneratorView()
}
