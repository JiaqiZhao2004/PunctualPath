//
//  NormalText.swift
//  PunctualPath
//
//  Created by Roy Zhao on 7/30/24.
//

import SwiftUI

struct NormalText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 18))
            .bold()
            .fixedSize()
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
    }
}

#Preview {
    NormalText(text: "Sample")
}
