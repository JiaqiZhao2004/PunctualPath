//
//  ToggleButton.swift
//  PunctualPath
//
//  Created by Roy Zhao on 7/30/24.
//

import SwiftUI

struct ToggleButton: View {
    let text: String
    let on: Bool
    var body: some View {
        Text(text)
            .font(.system(size: 17))
            .bold()
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(.black.opacity(on ? 0.75 : 0.25))
            .clipShape(.capsule)
    }
}
