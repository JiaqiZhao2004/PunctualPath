//
//  DiagonalStripes.swift
//  PunctualPath
//
//  Created by Roy Zhao on 8/7/24.
//

import SwiftUI

struct DiagonalStripes: Shape {
    var stripeWidth: CGFloat
    var offset: CGFloat
        
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stripeSpacing = stripeWidth * 2
        
        for startX in stride(from: -rect.width * 3, through: rect.width * 3, by: stripeSpacing) {
            let start = CGPoint(x: startX + offset, y: -rect.height * 0.2)
            let end = CGPoint(x: startX + rect.height + offset, y: rect.height * 1.2)
            path.move(to: start)
            path.addLine(to: end)
        }
        
        return path
    }
}


extension DiagonalStripes {
    func fill<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1) -> some View {
        self.stroke(content, lineWidth: lineWidth)
            .background(content)
    }
}

struct DiagonalStripesBackground: ViewModifier {
    var stripeWidth: CGFloat
    var stripeColor: Color
    var backgroundColor: Color
    
    @State private var offset: CGFloat = 0
    @State private var timer: Timer? = nil
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    backgroundColor
                    DiagonalStripes(stripeWidth: stripeWidth, offset: offset)
                        .stroke(stripeColor, lineWidth: stripeWidth)
                        .ignoresSafeArea()
                        .onAppear {
                            withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
                                offset = stripeWidth * 2
                            }
                        }
                }
            )
    }
}

extension View {
    func diagonalStripesBackground(stripeWidth: CGFloat, stripeColor: Color, backgroundColor: Color) -> some View {
        self.modifier(DiagonalStripesBackground(stripeWidth: stripeWidth, stripeColor: stripeColor, backgroundColor: backgroundColor))
    }
}

