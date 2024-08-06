//
//  LargeCapsuleText.swift
//  PunctualPath
//
//  Created by Roy Zhao on 8/6/24.
//

import SwiftUI

struct CapsuleButton: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 17))
            .bold()
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(.black.opacity(0.75))
            .clipShape(.capsule)
    }
}
