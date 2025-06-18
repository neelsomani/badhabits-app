import Foundation
import GoogleAPIClientForREST_Drive
import GoogleSignIn
import GTMSessionFetcherCore

class GoogleDriveService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var lastSynced: Date?
    
    private var driveService: GTLRDriveService?
    private var user: GIDGoogleUser?
    private var fileID: String? {
        get {
            return UserDefaults.standard.string(forKey: "GoogleDriveFileID")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "GoogleDriveFileID")
        }
    }
    private weak var viewModel: HabitViewModel?
    
    private let fileName = "Bad Habits Data"
    
    init(viewModel: HabitViewModel? = nil) {
        self.viewModel = viewModel
        
        // Get client ID from GoogleService-Info.plist
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
        }
        
        // Initialize Google Sign-In configuration
        let signInConfig = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = signInConfig
        
        // Restore sign-in state
        restoreSignIn()
    }
    
    private func restoreSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            DispatchQueue.main.async {
                if let user = user {
                    self?.isAuthenticated = true
                    self?.driveService = GTLRDriveService()
                    self?.driveService?.authorizer = user.fetcherAuthorizer
                    // Notify that authentication was restored
                    NotificationCenter.default.post(name: .authenticationRestored, object: nil)
                    // After restoring sign-in, pull data
                    self?.pullDataFromDrive()
                } else if let error = error {
                    self?.isAuthenticated = false
                } else {
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func setViewModel(_ viewModel: HabitViewModel) {
        self.viewModel = viewModel
    }
    
    func clearError() {
        self.errorMessage = nil
    }
    
    func signIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            self.errorMessage = "Unable to get window for sign-in"
            return
        }
        
        // Clear any previous errors
        self.errorMessage = nil
        
        // Configure sign-in with required scopes
        guard let clientID = GIDSignIn.sharedInstance.configuration?.clientID else {
            self.errorMessage = "Google Sign-In not properly configured"
            return
        }
        let signInConfig = GIDConfiguration(clientID: clientID)
        
        // Give it to the SDK
        GIDSignIn.sharedInstance.configuration = signInConfig
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Check if it's a cancellation error
                    if let signInError = error as? GIDSignInError {
                        switch signInError.code {
                        case .canceled:
                            // User cancelled, don't show error
                            return
                        default:
                            self?.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                        }
                    } else {
                        self?.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let user = result?.user else {
                    self?.errorMessage = "Sign-in failed: No user returned"
                    return
                }
                
                // Successfully signed in (but without drive.file scope yet)
                self?.isAuthenticated = true
                self?.driveService = GTLRDriveService()
                self?.driveService?.authorizer = user.fetcherAuthorizer
                
                // Now request Drive scopes
                user.addScopes(
                    ["https://www.googleapis.com/auth/drive.file"],
                    presenting: rootViewController
                ) { [weak self] signInResult, error in
                    DispatchQueue.main.async {
                        if let error = error as? GIDSignInError,
                           error.code == .scopesAlreadyGranted {
                            // treat as success - scopes were already granted
                            self?.driveService?.authorizer = user.fetcherAuthorizer
                            self?.errorMessage = nil // Clear any previous errors
                            self?.pullDataFromDrive()
                            return
                        }
                        else if let error = error {
                            // Check if it's a cancellation error
                            if let signInError = error as? GIDSignInError {
                                switch signInError.code {
                                case .canceled:
                                    // User cancelled Drive scope request, but they're still signed in
                                    self?.errorMessage = "Drive access is required for sync. Please try again and grant Drive permissions."
                                    return
                                default:
                                    self?.errorMessage = "Drive scope denied: \(error.localizedDescription)"
                                }
                            } else {
                                self?.errorMessage = "Drive scope denied: \(error.localizedDescription)"
                            }
                            return
                        }
                        
                        guard let result = signInResult else { return }
                        
                        // Now we have drive.file access
                        self?.driveService?.authorizer = result.user.fetcherAuthorizer
                        self?.errorMessage = nil // Clear any previous errors
                        
                        // After successful sign-in, try to pull data
                        self?.pullDataFromDrive()
                    }
                }
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        
        // Set authentication state immediately
        self.isAuthenticated = false
        
        // Update other properties asynchronously
        DispatchQueue.main.async {
            self.driveService = nil
            // Don't clear fileID - we want to keep it for next sign-in
            self.errorMessage = nil // Clear any errors when signing out
            self.lastSynced = nil // Clear last synced timestamp
            self.isSyncing = false // Ensure syncing state is cleared
        }
    }
    
    // MARK: - Data Sync Methods
    
    func pullDataFromDrive() {
        guard isAuthenticated else { return }
        
        self.isSyncing = true
        self.errorMessage = nil
        
        // If we have a stored fileID, try to use it directly
        if let storedFileID = fileID {
            // Try to download directly with stored fileID
            downloadFile()
        } else {
            // No stored fileID, create new file
            createFile(data: Data()) { [weak self] success in
                if success {
                    self?.downloadFile()
                } else {
                    DispatchQueue.main.async {
                        self?.isSyncing = false
                        self?.errorMessage = "Failed to create Google Drive file"
                    }
                }
            }
        }
    }
    
    func pushDataToDrive(entries: [HabitEntry]) {
        guard isAuthenticated else { return }
        
        self.isSyncing = true
        self.errorMessage = nil
        
        if let fileID = fileID {
            // Update existing file
            updateFile(fileID: fileID, data: Data())
        } else {
            // Create new file
            createFile(data: Data())
        }
    }
    
    // MARK: - File Operations
    
    private func createFile(data: Data, completion: @escaping (Bool) -> Void = { _ in }) {
        let file = GTLRDrive_File()
        file.name = fileName
        file.mimeType = "application/vnd.google-apps.spreadsheet"
        
        // Create a simple spreadsheet with headers
        let csvData = createCSVData(from: getLocalEntries())
        let uploadParameters = GTLRUploadParameters(data: csvData, mimeType: "text/csv")
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        query.fields = "id"
        
        driveService?.executeQuery(query) { [weak self] (ticket: GTLRServiceTicket?, result: Any?, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to create file: \(error.localizedDescription)"
                    self?.isSyncing = false
                    completion(false)
                    return
                }
                
                if let createdFile = result as? GTLRDrive_File {
                    self?.fileID = createdFile.identifier
                    // Update last synced timestamp
                    self?.lastSynced = Date()
                    self?.isSyncing = false
                    completion(true)
                } else {
                    self?.errorMessage = "Failed to create file: No file returned"
                    self?.isSyncing = false
                    completion(false)
                }
            }
        }
    }
    
    private func updateFile(fileID: String, data: Data) {
        let file = GTLRDrive_File()
        file.name = fileName
        
        // Convert data to CSV format for Google Sheets
        let csvData = createCSVData(from: getLocalEntries())
        let uploadParameters = GTLRUploadParameters(data: csvData, mimeType: "text/csv")
        let query = GTLRDriveQuery_FilesUpdate.query(withObject: file, fileId: fileID, uploadParameters: uploadParameters)
        
        driveService?.executeQuery(query) { [weak self] (ticket: GTLRServiceTicket?, result: Any?, error: Error?) in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                if let error = error {
                    self?.errorMessage = "Failed to update file: \(error.localizedDescription)"
                    return
                }
                
                // Update last synced timestamp
                self?.lastSynced = Date()
            }
        }
    }
    
    private func downloadFile() {
        guard let fileID = fileID else {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.errorMessage = "No file ID available"
            }
            return
        }
        
        // Export Google Sheet as CSV
        let query = GTLRDriveQuery_FilesExport.queryForMedia(withFileId: fileID, mimeType: "text/csv")
        
        driveService?.executeQuery(query) { [weak self] (ticket: GTLRServiceTicket?, result: Any?, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    // Check if the file doesn't exist (user deleted it)
                    let errorDescription = error.localizedDescription.lowercased()
                    if errorDescription.contains("404") || errorDescription.contains("not found") {
                        // File was deleted, clear the stored fileID and create a new one
                        self?.fileID = nil
                        self?.createFile(data: Data()) { success in
                            if success {
                                self?.downloadFile()
                            } else {
                                self?.isSyncing = false
                                self?.errorMessage = "Failed to create new Google Drive file"
                            }
                        }
                        return
                    }
                    self?.isSyncing = false
                    self?.errorMessage = "Failed to download file: \(error.localizedDescription)"
                    return
                }
                
                guard let dataObj = result as? GTLRDataObject else {
                    self?.isSyncing = false
                    self?.errorMessage = "Failed to download file: Unexpected data format"
                    return
                }
                
                let data = dataObj.data
                if data.count > 0 {
                    self?.processDownloadedData(data)
                } else {
                    self?.lastSynced = Date()
                    self?.isSyncing = false
                }
            }
        }
    }
    
    // MARK: - Data Processing
    
    private func processDownloadedData(_ data: Data) {
        guard let csvString = String(data: data, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to decode CSV data"
            }
            return
        }
        
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            // Empty or only header row
            DispatchQueue.main.async {
                self.isSyncing = false
            }
            return
        }
        
        // Parse header row to understand column structure
        let headerLine = lines[0]
        let headers = headerLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Find expected column indices
        let dateIndex = headers.firstIndex(of: "Date") ?? 0
        let timeIndex = headers.firstIndex(of: "Time") ?? 1
        let categoryIndex = headers.firstIndex(of: "Reason") ?? headers.firstIndex(of: "Category") ?? 2
        let notesIndex = headers.firstIndex(of: "Notes") ?? 3
        
        var entries: [HabitEntry] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Skip header row
        for i in 1..<lines.count {
            let line = lines[i]
            let columns = line.components(separatedBy: ",")
            
            guard columns.count >= 4 else { continue }
            
            let dateString = columns[safe: dateIndex] ?? ""
            let timeString = columns[safe: timeIndex] ?? ""
            let categoryName = columns[safe: categoryIndex] ?? ""
            let notes = (columns[safe: notesIndex] ?? "").replacingOccurrences(of: ";", with: ",")
            
            // Skip rows with missing essential data
            guard !dateString.isEmpty && !timeString.isEmpty && !categoryName.isEmpty else { continue }
            
            // Combine date and time
            let dateTimeString = "\(dateString) \(timeString)"
            guard let date = dateFormatter.date(from: dateTimeString) else { continue }
            
            // Find or create category
            let category = findOrCreateCategory(name: categoryName)
            
            // Parse custom fields - only for columns that exist in the app
            var customFields: [String: CustomFieldValue] = [:]
            let customColumns = viewModel?.customColumns ?? []
            for column in customColumns {
                if let columnIndex = headers.firstIndex(of: column.name),
                   columnIndex < columns.count {
                    let value = columns[columnIndex].replacingOccurrences(of: ";", with: ",")
                    customFields[column.name] = .string(value)
                }
            }
            
            let entry = HabitEntry(
                date: date,
                category: category,
                notes: notes,
                customFields: customFields
            )
            entries.append(entry)
        }
        
        // Update last synced timestamp
        self.lastSynced = Date()
        
        // Check for conflicts with local data
        checkForConflicts(localEntries: getLocalEntries(), remoteEntries: entries)
    }
    
    private func findOrCreateCategory(name: String) -> HabitCategory {
        let categories = viewModel?.categories ?? []
        if let existing = categories.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existing
        } else {
            // Create new category
            let newCategory = HabitCategory(name: name, isCustom: true)
            viewModel?.addCategory(name: name)
            return newCategory
        }
    }
    
    private func checkForConflicts(localEntries: [HabitEntry], remoteEntries: [HabitEntry]) {
        if localEntries.count != remoteEntries.count {
            // Conflict detected - prioritize longer list
            let shouldUseRemote = remoteEntries.count > localEntries.count
            
            DispatchQueue.main.async {
                if shouldUseRemote {
                    // Use remote data
                    self.updateLocalData(with: remoteEntries)
                } else {
                    // Use local data
                    self.pushDataToDrive(entries: localEntries)
                }
            }
        } else {
            // No conflict, data is in sync
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }
    }
    
    private func updateLocalData(with entries: [HabitEntry]) {
        // This will be called by the ViewModel
        DispatchQueue.main.async {
            self.isSyncing = false
        }
        NotificationCenter.default.post(name: .updateLocalData, object: entries)
    }
    
    // MARK: - Helper Methods
    
    private func createCSVData(from entries: [HabitEntry]) -> Data {
        // Start with standard headers
        var csvString = "Date,Time,Reason,Notes"
        
        // Add custom column headers - only include columns that exist in the app
        let customColumns = viewModel?.customColumns ?? []
        for column in customColumns {
            csvString += ",\(column.name)"
        }
        csvString += "\n"
        
        // Add data rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        for entry in entries {
            let date = dateFormatter.string(from: entry.date)
            let time = timeFormatter.string(from: entry.date)
            let category = entry.category.name
            let notes = entry.notes.replacingOccurrences(of: ",", with: ";") // Escape commas
            
            csvString += "\(date),\(time),\(category),\(notes)"
            
            // Add custom field values - only for columns that exist in the app
            for column in customColumns {
                let value = entry.customFields[column.name]?.stringValue ?? ""
                csvString += ",\(value.replacingOccurrences(of: ",", with: ";"))"
            }
            csvString += "\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    private func getLocalEntries() -> [HabitEntry] {
        return viewModel?.getLocalEntries() ?? []
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let updateLocalData = Notification.Name("updateLocalData")
    static let authenticationRestored = Notification.Name("authenticationRestored")
}

// MARK: - Array Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
