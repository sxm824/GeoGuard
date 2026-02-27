//
//  SuperAdminLoginButtonExample.swift
//  GeoGuard
//
//  Example of adding a visible super admin button for development
//

import SwiftUI

// Add this to your LoginView for development/testing:

/*
 In LoginView, add this after the "Create Account" button:
 
 #if DEBUG
 // Super Admin Access (Development Only)
 Button {
     showingSuperAdminLogin = true
 } label: {
     HStack {
         Image(systemName: "crown.fill")
         Text("Super Admin Login")
     }
     .font(.caption)
     .foregroundColor(.red)
 }
 .padding(.top, 20)
 #endif
 */
