//
//  SignInView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isNewUser = false

    var body: some View {
        VStack(spacing: 20) {
            Text(isNewUser ? "Create Account" : "Log In")
                .font(.largeTitle.bold())

            if isNewUser {
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(isNewUser ? "Sign Up" : "Log In") {
                if isNewUser {
                    authViewModel.signUp(email: email, password: password, username: username)
                } else {
                    authViewModel.signIn(email: email, password: password)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button(isNewUser ? "Already have an account?" : "Need an account?") {
                isNewUser.toggle()
            }
            .font(.footnote)
            .foregroundColor(.blue)
        }
        .padding()
    }
}
