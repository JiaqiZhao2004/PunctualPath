//
//  RootView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 7/3/24.
//

import SwiftUI

//class RootViewModel: ObservableObject {
//    
//    var shared = RootViewModel()
//    
//    func loadBeijingSubway() throws -> BeijingSubway {
//        let URLsPath = "/Users/royzhao/Library/CloudStorage/OneDrive-UniversityofIllinois-Urbana/Coding/PunctualPath/PunctualPath/urls.json"
////        getURLs(path: URLsPath)
//        guard let bs = BeijingSubway.fromJsonFile(URLsPath) else {
//            throw URLError(.badURL)
//            // TODO: incorrect error type
//        }
//        return bs
//    }
//}

//func loadBeijingSubway() throws -> BeijingSubway {
//    let URLsPath = "/Users/royzhao/Library/CloudStorage/OneDrive-UniversityofIllinois-Urbana/Coding/PunctualPath/PunctualPath/urls.json"
////        getURLs(path: URLsPath)
//    guard let bs = BeijingSubway.fromJsonFile(URLsPath) else {
//        throw URLError(.badURL)
//        // TODO: incorrect error type
//    }
//    return bs
//}




struct RootView: View {
//    @StateObject private var viewModel = RootViewModel()
//    @State var beijingSubway: BeijingSubway = loadBeijingSubwayNoThrow()
    
    var body: some View {
        VStack {
            NavigationLink {
//                LineSearchView(beijingSubway: $beijingSubway)
            } label: {
                Text("Sign In With Email")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview {
    RootView()
}
