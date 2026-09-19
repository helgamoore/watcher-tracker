//
//  ChatGPTImageGeneratorView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 19/09/2026.
//

import SwiftUI

struct ChatGPTImageGeneratorView: View {

    var body: some View {
        VStack(spacing: 16) {

            Image(
                systemName:
                    "bubble.left.and.bubble.right"
            )
            .font(.system(size: 44))
            .foregroundStyle(.secondary)

            Text("ChatGPT Image Generator")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "OpenAI image-generation integration will be implemented here."
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
    ChatGPTImageGeneratorView()
}
