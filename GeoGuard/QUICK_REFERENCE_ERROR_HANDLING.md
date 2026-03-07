# Quick Reference: Error Handling & Shared Components

## Error Handling

### Display an Error Alert

```swift
struct MyView: View {
    @State private var error: Error?
    
    var body: some View {
        VStack {
            // Your content
        }
        .errorAlert($error, title: "Error Title")
    }
}
```

### Create Custom Errors

```swift
enum MyError: LocalizedError {
    case somethingWentWrong
    
    var errorDescription: String? {
        switch self {
        case .somethingWentWrong:
            return "Something went wrong!"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .somethingWentWrong:
            return "Please try again later."
        }
    }
}
```

### Set Error in View Model

```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var error: Error?
    
    func doSomething() async {
        do {
            try await riskyOperation()
        } catch {
            self.error = error
        }
    }
}
```

---

## Shared Components

### StatCard

Display statistics with icon and color:

```swift
StatCard(
    title: "Active Users",
    value: "42",
    icon: "person.fill",
    color: .blue
)
```

**Use in Grid:**
```swift
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
    StatCard(title: "Users", value: "42", icon: "person.fill", color: .blue)
    StatCard(title: "Alerts", value: "5", icon: "bell.fill", color: .red)
}
```

---

### DetailRow

Display label-value pairs:

```swift
DetailRow(label: "Name", value: "John Doe")
DetailRow(label: "Status", value: "Active", color: .green)
DetailRow(label: "Email", value: "john@example.com")
```

**Use in Form:**
```swift
Form {
    Section("User Details") {
        DetailRow(label: "Name", value: user.fullName)
        DetailRow(label: "Email", value: user.email)
        DetailRow(label: "Role", value: user.role.displayName)
    }
}
```

---

### IncidentRowView

Display incident in a list:

```swift
List(incidents) { incident in
    NavigationLink {
        IncidentDetailView(incident: incident)
    } label: {
        IncidentRowView(incident: incident)
    }
}
```

---

### StatusBadge

Display severity indicator:

```swift
StatusBadge(status: incident.status, severity: incident.severity)
```

---

## AuthService Error Handling

### Access Auth Errors

```swift
struct MyView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            // Your content
        }
        .errorAlert($authService.authError, title: "Authentication Error")
    }
}
```

### Auth Error Types

```swift
enum AuthError: LocalizedError {
    case userDocumentNotFound(userId: String)
    case loadUserDataFailed(error: Error)
    case signOutFailed(error: Error)
}
```

### Check Auth State

```swift
if authService.isAuthenticated {
    // User is logged in
}

if authService.isLoading {
    // Loading user data
}

if let error = authService.authError {
    // Handle error
}
```

---

## Common Patterns

### Loading State with Error

```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "tray",
                    description: Text("No items found")
                )
            } else {
                List(viewModel.items) { item in
                    // Item view
                }
            }
        }
        .errorAlert($viewModel.error)
        .task {
            await viewModel.loadItems()
        }
    }
}
```

### Dashboard Stats Grid

```swift
var statsGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        StatCard(
            title: "Active",
            value: "\(activeCount)",
            icon: "checkmark.circle.fill",
            color: .green
        )
        
        StatCard(
            title: "Pending",
            value: "\(pendingCount)",
            icon: "clock.fill",
            color: .orange
        )
        
        StatCard(
            title: "Total",
            value: "\(totalCount)",
            icon: "chart.bar.fill",
            color: .blue
        )
        
        StatCard(
            title: "Critical",
            value: "\(criticalCount)",
            icon: "exclamationmark.triangle.fill",
            color: .red
        )
    }
}
```

### Detail View with Rows

```swift
Form {
    Section("Basic Info") {
        DetailRow(label: "Name", value: user.fullName)
        DetailRow(label: "Email", value: user.email)
        DetailRow(label: "Role", value: user.role.displayName)
    }
    
    Section("Status") {
        DetailRow(
            label: "Active",
            value: user.isActive ? "Yes" : "No",
            color: user.isActive ? .green : .red
        )
        DetailRow(label: "Last Login", value: user.lastLoginAt.formatted())
    }
}
```

---

## Best Practices

### Error Handling

1. **Always clear errors** when retrying operations
2. **Provide recovery suggestions** in error descriptions
3. **Log errors** to console for debugging
4. **Don't swallow errors** - always handle or propagate them

### Components

1. **Use shared components** instead of duplicating code
2. **Keep components focused** on a single purpose
3. **Make components flexible** with optional parameters
4. **Document usage** with comments and examples

### View Models

1. **Use @MainActor** for published properties
2. **Handle errors gracefully** - set error property
3. **Provide loading states** - isLoading property
4. **Clear previous errors** before new operations

---

## Troubleshooting

### Error Doesn't Show

Check:
- Is error binding correct? `$viewModel.error`
- Is error actually set in the view model?
- Is alert modifier placed correctly in view hierarchy?

### Component Not Found

Check:
- Is `ViewsSharedComponents.swift` in your target?
- Did you build the project after adding it?
- Are you importing SwiftUI?

### Auth Error Not Displaying

Check:
- Is `.errorAlert($authService.authError)` in root view?
- Is AuthService properly injected via `.environmentObject()`?
- Are you on the main thread when setting the error?

---

## Examples in Codebase

### Error Alerts
- `GeoGuardApp.swift` - Root level auth error handling
- `AdminSafetyDashboardView.swift` - Dashboard errors

### Shared Components
- `AdminDashboardView.swift` - StatCard usage
- `AdminIncidentDetailView.swift` - DetailRow usage
- `AdminIncidentListView.swift` - IncidentRowView usage

### Diagnostics
- `ViewsUserAccountDiagnosticsView.swift` - Complete diagnostic tool

---

**Quick Tip**: Press Cmd+Shift+O and type the component name to jump to its definition!
