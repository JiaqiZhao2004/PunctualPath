//
//  LineSearchView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/14/24.
//

import SwiftUI

@MainActor
class LineSearchViewModel: ObservableObject {
    
    @Published var enteredName = ""
    @Published var direction = ""
    @Published var isFirstDirection = true
    @Published var subwayLine: SubwayLine? = nil
    @Published var errorMessage: String?
    @Published var responseData: String = ""
    
    var inParam: String = ""
    
    func validateLineName() {
        if let foundLine = subwayLines.first(where: { $0.nativeName == enteredName }) {
            subwayLine = foundLine
            updateDirection()
        } else {
            subwayLine = nil
            direction = "线路暂不支持或不存在"
        }
        print(direction)
    }
    
    func switchDirection() {
        isFirstDirection.toggle()
        updateDirection()
    }
    
    private func updateDirection() {
        if let subwayLine = subwayLine {
            direction = isFirstDirection ? subwayLine.firstDirection : subwayLine.secondDirection
        } else {
            direction = "线路暂不支持或不存在"
        }
    }
    
    func fetchSearchParam() {
        
    }
    
    func fetchData() {
            guard let url = URL(string: "https://m5.amap.com/ws/archive/bus/railway_depart_time?ent=2&in=\(inParam)") else {
                errorMessage = "Invalid URL"
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Invalid response from server"
                    }
                    return
                }

                guard let data = data else {
                    DispatchQueue.main.async {
                        self.errorMessage = "No data received"
                    }
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let jsonData = try JSONSerialization.data(withJSONObject: jsonResponse, options: .prettyPrinted)
                        let jsonString = String(data: jsonData, encoding: .utf8) ?? "Invalid JSON"
                        DispatchQueue.main.async {
                            self.responseData = jsonString
                            self.errorMessage = nil
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Failed to parse JSON"
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to parse response: \(error.localizedDescription)"
                    }
                }
            }

            task.resume()
        }
    
}


struct LineSearchView: View {
    
    @StateObject private var viewModel = LineSearchViewModel()
    
    var body: some View {
        VStack {
            TextField("地铁/公交线路", text: $viewModel.enteredName)
            .autocapitalization(.none)
            .padding()
            .background(Color.gray.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding()
            
            
            Text("方向：\(viewModel.direction)")
            
            Button(action: { viewModel.switchDirection() }, label: {
                Text("切换方向")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            })
            .frame(width: 70)
            .padding()
            .background(Color.gray.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Button(action: {
                viewModel.validateLineName()
                if (viewModel.subwayLine != nil) {
                    viewModel.fetchData()
                }
            }, label: {
                Text("查询")
                    .foregroundColor(.white)
                    .bold()
            })
            .frame(width: 70)
            .padding()
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }.navigationTitle("线路搜索")
    }
}

#Preview {
    NavigationStack {
        LineSearchView()
    }
}
