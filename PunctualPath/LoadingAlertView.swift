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
    
    var body: some View {
        VStack {
        }
        .onAppear {
            downloadImage()
        }
        .alert(isPresented: $isImgDownloadViewPresented) {
            Alert(
                title: Text("Loading"),
                message: Text("Downloading image..."),
                primaryButton: .default(Text("Cancel"), action: {
                    cancelDownload()
                }),
                secondaryButton: .default(Text("OK"))
            )
        }
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
    
    func downloadImage() {
        // Simulate an image download process
        getImg()
    }
    
    func cancelDownload() {
        // Logic to cancel the download if needed
        isImgDownloadViewPresented = false
    }
    
    func getImg() {
        Task {
            guard let image = await url.getImg() else {
                print("Failed to fetch image.")
                return
            }
            self.image = image
            print("Fetched image successfully.")
            isImgDownloadViewPresented = false
        }
    }
}
