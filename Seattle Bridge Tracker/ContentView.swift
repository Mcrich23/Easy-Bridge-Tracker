//
//  ContentView.swift
//  Seattle Bridge Tracker
//
//  Created by Morris Richman on 8/16/22.
//

import SwiftUI
import URLImage
import Mcrich23_Toolkit
import SwiftUIBackports
import Introspect
import Foundation

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    var body: some View {
        NavigationView {
            VStack {
                if !NetworkMonitor.shared.isConnected {
                    Text("Please check your internet and try again.")
                } else {
                    switch viewModel.status {
                    case .loading:
                        ProgressView()
                    case .failed(let error):
                        errors(error: error)
                    case .success:
                        ZStack {
                            if Utilities.isFastlaneRunning {
                                NavigationLink(destination: demoView(), isActive: $viewModel.demoLink) {
                                    Text("South Park Bridge Link")
                                }
//                                .hidden()
                                .tag("South Park Bridge Link")
                            }
                            List {
                                ForEach(viewModel.bridgeFavorites, id: \.self) { key in
                                    Section {
                                        ForEach((viewModel.bridges[key] ?? []).sorted()) { bridge in
                                            BridgeRow(bridge: Binding(get: {
                                                print("get \(bridge)")
                                                return bridge
                                            }, set: { _ in
                                            }), viewModel: viewModel)
                                            .tag(bridge.name)
                                            
                                            if #available(iOS 15.0, *) {
                                                BridgeRow(bridge: Binding(get: {
                                                    print("get \(bridge)")
                                                    return bridge
                                                }, set: { _ in
                                                }), viewModel: viewModel)
                                                .tag(bridge.name)
                                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                    Button {
                                                        viewModel.toggleSubscription(for: bridge)
                                                    } label: {
                                                        if bridge.subscribed {
                                                            Image(systemName: "bell.slash.fill")
                                                        } else {
                                                            Image(systemName: "bell.fill")
                                                        }
                                                    }
                                                }
                                            } else {
                                                BridgeRow(bridge: Binding(get: {
                                                    print("get \(bridge)")
                                                    return bridge
                                                }, set: { _ in
                                                }), viewModel: viewModel)
                                                .tag(bridge.name)
                                            }
                                        }
                                    } header: {
                                        HStack {
                                            Text(key)
                                            if viewModel.bridges.keys.count >= 3 {
                                                Spacer()
                                                Button {
                                                    viewModel.toggleFavorite(bridgeLocation: key)
                                                } label: {
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.yellow)
                                                        .imageScale(.medium)
                                                }
                                            }
                                        }

                                    }
                                }
                                ForEach(Array(viewModel.bridges.keys), id: \.self) { key in
                                    if !Array(viewModel.bridgeFavorites).contains(key) {
                                        Section {
                                            ForEach((viewModel.bridges[key] ?? []).sorted()) { bridge in
    //                                            BridgeRow(bridge: Binding(get: {
    //                                                print("get \(bridge)")
    //                                                return bridge
    //                                            }, set: { _ in
    //                                            }), viewModel: viewModel)
                                                if #available(iOS 15.0, *) {
                                                    rowView(bridge: bridge)
                                                    .tag(bridge.name)
                                                    .swipeActions(allowsFullSwipe: true) {
                                                        Button {
                                                            viewModel.toggleSubscription(for: bridge)
                                                        } label: {
                                                            if bridge.subscribed {
                                                                Image(systemName: "bell.slash.fill")
                                                            } else {
                                                                Image(systemName: "bell.fill")
                                                            }
                                                        }
                                                        .tint(.yellow)
                                                    }
                                                } else {
                                                    rowView(bridge: bridge)
                                                    .tag(bridge.name)
                                                }
                                            }
                                            if !Utilities.areAdsDisabled && !Utilities.isFastlaneRunning {
                                                HStack {
                                                    Spacer()
                                                    BannerAds()
                                                    Spacer()
                                                }
                                            }
                                        } header: {
                                            HStack {
                                                Text(key)
                                                if viewModel.bridges.keys.count >= 3 {
                                                    Spacer()
                                                    Button {
                                                        viewModel.toggleFavorite(bridgeLocation: key)
                                                    } label: {
                                                        Image(systemName: "star")
                                                            .foregroundColor(.yellow)
                                                            .imageScale(.medium)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .backport.refreshable(action: {
                                await viewModel.fetchData(repeatFetch: false)
                            })
                            .tag("bridges")
                        .listStyle(GroupedListStyle())
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchData(repeatFetch: true)
            }
            .introspectNavigationController { navController in
                let bar = navController.navigationBar
                let hosting = UIHostingController(rootView: HelpMenu(viewModel: self.viewModel))
                
                guard let hostingView = hosting.view else { return }
                if bar.subviews.first(where: \.clipsToBounds) != nil {
                    bar.subviews.first(where: \.clipsToBounds)?.addSubview(hostingView)
                   hostingView.backgroundColor = .clear
                   
                   hostingView.translatesAutoresizingMaskIntoConstraints = false
                   NSLayoutConstraint.activate([
                       hostingView.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
                       hostingView.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -8)
                   ])
                } else {
                    print("Cannot add menu bar")
                }
            }
            .navigationBarTitle("Bridges", displayMode: .large)
        }
        .navigationViewStyle(.stack)
    }
    
    func errors(error: String) -> some View {
        VStack {
            Text("Unable to connect to server, please try again later. If issues persist, please email me at: [Support@mcrich23.com](mailto:Support@mcrich23.com).\n\nError: \(error)")
            Spacer()
        }
        .padding()
    }
    func rowView(bridge: Bridge) -> some View {
        BridgeRow(bridge: Binding(get: {
            return bridge
        }, set: { _ in
        }), viewModel: viewModel)
    }
    func demoView() -> some View {
        BridgeView(bridge: Binding(get: {
            let index = viewModel.bridges["Seattle, Wa"]?.firstIndex(where: { bridge in
                bridge.name == "South Park Bridge"
            })
            let bridge = viewModel.bridges["Seattle, Wa"]![index!]
            return bridge
        }, set: { _ in
        }), viewModel: viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
