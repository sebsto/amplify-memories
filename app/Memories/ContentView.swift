//
//  ContentView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 23/02/2023.
//

import SwiftUI
import AuthenticationServices // for Signin with Apple button

struct ContentView: View {
    
    @EnvironmentObject private var viewModel: ViewModel

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            SignInWithAppleButton(
                onRequest: { viewModel.configureRequest($0) },
                onCompletion: { viewModel.handleResult($0) }
            )
            .cornerRadius(10)
            .frame(maxWidth: 300, maxHeight: 45)
            Button {
                Task {
                    print("not implemented")
                }
            } label: {
                Text("Create memory")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
