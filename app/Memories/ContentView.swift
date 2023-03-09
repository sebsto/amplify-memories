//
//  ContentView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 23/02/2023.
//

import SwiftUI
import AuthenticationServices // for Signin with Apple button

struct ContentView: View {
    
    @EnvironmentObject private var model: ViewModel
    
    let splashImageURL: URL?
    
    init() {
        self.splashImageURL = Bundle.main.url(forResource: "splash", withExtension: "jpg")
    }
    
    var body: some View {
        ZStack {
            switch model.state {
            case .signedOut:
                unauthenticatedView()
                
            case .loading:
                loadingView()
                    .task() {
                        await self.model.todaysMemories()
                    }
                
            case .dataAvailable:
                MainView()
                
            case .error(let error):
                Text("An unknown error happened: \(error.localizedDescription)")
                
            }
        }
        .environmentObject(self.model)
        .task {
            
            // get the initial authentication status.
            // This call will change app state according to result
            try? await self.model.getInitialAuthStatus()
            
            // start a long polling to listen to auth updates
            await self.model.listenAuthUpdate()
        }
        
    }
    
    @ViewBuilder
    func unauthenticatedView() -> some View {
        ZStack {
            AsyncImage(url: splashImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                SignInWithAppleButton(
                    onRequest: { model.configureRequest($0) },
                    onCompletion: { model.handleResult($0) }
                )
                .cornerRadius(10)
                .frame(maxWidth: 300, maxHeight: 70)
                Spacer()
                //signOutButton()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    func loadingView() -> some View {
        VStack {
            ProgressView()
                .padding(.bottom)
            Text("Loading...")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let cv = ContentView()
        return Group {
            cv.unauthenticatedView()
        }
    }
}
