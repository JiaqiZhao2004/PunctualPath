//
//  CapsuleText.swift
//  PunctualPath
//
//  Created by Roy Zhao on 7/30/24.
//

import SwiftUI

struct CapsuleText: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 34))
            .fixedSize()
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(.black.opacity(0.75))
            .clipShape(.capsule)
    }
}

#Preview {
    CapsuleText(text: "222")
}
