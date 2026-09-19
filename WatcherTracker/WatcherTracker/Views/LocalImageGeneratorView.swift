//
//  LocalImageGeneratorView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 19/09/2026.
//

import SwiftUI

struct LocalImageGeneratorView: View {

    var body: some View {
        VStack(spacing: 16) {

            Image(systemName: "cpu")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("Local AI Image Generator")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "Local Juggernaut image-generation integration will be implemented here."
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
    LocalImageGeneratorView()
}
