//
//  LoadingAlertView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 7/8/24.
//

import Foundation

import SwiftUI



struct ImageDownloadView: View {
    let url: TimetableURL
    @Binding var isImgDownloadViewPresented: Bool
    @State var image: UIImage? = nil
    @State var timetable: TimeTable? = nil
    
    var body: some View {
        VStack {
        }
        .onAppear {
            downloadImage { image in
                timetable = loadTimetable(img: image)
                isImgDownloadViewPresented = false
            }
        }
//        .alert(isPresented: $isImgDownloadViewPresented) {
//            Alert(
//                title: Text("Loading"),
//                message: Text("Downloading image..."),
//                primaryButton: .default(Text("Cancel"), action: {
//                    cancelDownload()
//                }),
//                secondaryButton: .default(Text("OK"))
//            )
//        }
        .overlay(
            isImgDownloadViewPresented ? ProgressView("Downloading...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
            : nil
        )
    }
    
    func cancelDownload() {
        isImgDownloadViewPresented = false
    }
    
    func downloadImage(completion: @escaping (UIImage) -> Void) {
        Task {
            guard let image = await url.getImg() else {
                print("Failed to fetch image.")
                return
            }
            self.image = image
            completion(image)
            print("Fetched image successfully.")
        }
    }
}


//#Preview {
//    var url = TimetableURL()
//    url.addURL("https://www.bjsubway.com/d/file/station/xltcx/line1/2023-12-30/1号线-八角游乐园站-环球度假区站方向-工作日.jpg?=1")
//    NavigationStack {
//        ImageDownloadView(url: url, isImgDownloadViewPresented: .constant(true))
//    }
//}
