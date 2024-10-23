//
//  AnisetteServerList.swift
//  SideStore
//
//  Created by ny on 6/18/24.
//  Copyright © 2024 SideStore. All rights reserved.
//

import UIKit
import SwiftUI
import AltStoreCore

typealias SUIButton = SwiftUI.Button

// MARK: - AnisetteServerData
// Codable - Swift内置协议，结合了Encodable 和 Decodable 两个协议，可以实现将对象编码为JSON数据，或者从JSON数据解码为对象。
struct AnisetteServerData: Codable {
    let servers: [Server]
}

// MARK: - Server
struct Server: Codable {
    var name: String
    var address: String
}

class AnisetteViewModel: ObservableObject {
    // @Published 属性包装器，它使得任何对这个列表的修改都会自动通知观察者，从而更新相关的 UI 元素。
    @Published var selected: String = ""

    @Published var source: String = "https://servers.sidestore.io/servers.json"
    @Published var servers: [Server] = []
    
    func getListOfServers() async {
        guard let url = URL(string: source) else { return }
        // 这段代码的整体作用是发起一个网络请求，获取 JSON 数据，解码为 AnisetteServerData 对象，
        // 并将解码后的服务器数据更新到 UI 中。如果在请求或解码过程中发生错误，程序会优雅地处理这些错误。
        await URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                return
            }
            if let data = data {
                do {
                    let decoder = Foundation.JSONDecoder()
                    let servers = try decoder.decode(AnisetteServerData.self, from: data)

                    // 在主线程执行UI更新操作
                    DispatchQueue.main.async {
                        // 将反序列化得到的AnisetteServerData 中的servers 赋值给 viewModel.servers
                        self.servers = servers.servers
                    }
                } catch {
                    // Handle decoding error
                    print("Failed to decode JSON: \(error)")
                }
            }
        }.resume() // 启动数据任务
    }
}


// 遵循View 协议的结构体，用于呈现 AnisetteServers 视图。
struct AnisetteServers: View {
    // 使用 @Environment 属性包装器来访问视图的环境值，具体是 presentationMode。
    // 这个值用于控制视图的显示状态，比如关闭当前视图或返回上一个视图。
    @Environment(\.presentationMode) var presentationMode
    // 使用 @StateObject 属性包装器来创建一个状态对象 viewModel
    // @StateObject 用于管理视图模型的生命周期，并在视图重新渲染时保持状态。
    @StateObject var viewModel: AnisetteViewModel = AnisetteViewModel()
    // 使用 @State 属性包装器定义一个可选的字符串变量 selected，初始化为 nil。这个变量可能用于跟踪用户在视图中选择的项。
    @State var selected: String? = nil
    var errorCallback: () -> ()

   // some View隐藏具体的返回类型
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
                .onAppear {
                    Task {
                        await viewModel.getListOfServers()
                    }
                }
            VStack {
                // if #available(iOS 16.0, *) 是用来检查操作系统版本的条件语句。用于确保某段代码只在特定的操作系统版本或更高的版本上执行
                if #available(iOS 16.0, *) {
                    // $ 符号 用于将 SwiftUI 中的 @State、@Binding 或 @Published 属性转换为 Binding 类型，
                    // 以便视图可以进行双向绑定，允许数据和 UI 同步更新
                    SwiftUI.List($viewModel.servers, id: \.address, selection: $selected) { server in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(server.name.wrappedValue)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(server.address.wrappedValue)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selected != nil {
                                if server.address.wrappedValue == selected {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .onAppear {
                                            UserDefaults.standard.menuAnisetteURL = server.address.wrappedValue
                                            print(UserDefaults.synchronize(.standard)())
                                            print(UserDefaults.standard.menuAnisetteURL)
                                            print(server.address.wrappedValue)
                                        }
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .listRowBackground(Color(UIColor.systemBackground))
                } else {
                    List(selection: $selected) {
                        ForEach($viewModel.servers, id: \.name) { server in
                            VStack {
                                HStack {
                                    Text("\(server.name.wrappedValue)")
                                        .foregroundColor(.primary)
                                        .frame(alignment: .center)
                                    Text("\(server.address.wrappedValue)")
                                        .foregroundColor(.secondary)
                                        .frame(alignment: .center)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    .listStyle(.plain)
                }
                
                VStack(spacing: 16) {
                    TextField("Anisette Server List", text: $viewModel.source)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemFill)))
                        .foregroundColor(.primary)
                        .frame(height: 60)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                        .onChange(of: viewModel.source) { newValue in
                            UserDefaults.standard.menuAnisetteList = newValue
                            Task {
                                await viewModel.getListOfServers()
                            }
                        }

                    HStack(spacing: 16) {
                        SUIButton(action: {
                            // 关闭当前视图并返回上一个视图。
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Back")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor))
                        .foregroundColor(.white)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)

                        SUIButton(action: {
                            Task {
                                await viewModel.getListOfServers()
                            }
                        }) {
                            Text("Refresh Servers")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor))
                        .foregroundColor(.white)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                    }

                    SUIButton(action: {
                        #if !DEBUG
                        if Keychain.shared.adiPb != nil {
                            Keychain.shared.adiPb = nil
                        }
                        #endif
                        print("Cleared adi.pb from keychain")
                        errorCallback()
                        // 关闭当前视图并返回上一个视图。
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Reset adi.pb")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.red))
                    .foregroundColor(.white)
                    .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        // 这里的 navigationBarHidden 设置为 true，用于隐藏导航栏。
        .navigationBarHidden(true)
        // 这里的 navigationTitle 设置为空字符串，用于隐藏导航栏标题。
        .navigationTitle("")
    }
}
