//
//  ContentView.swift
//  SaleSpot
//
//  Created by Aastha Patel on 8/16/25.
//

import SwiftUI
import MapKit
import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

struct Event: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var location: CLLocationCoordinate2D  // GPS coordinates
    var address: String                // Human-readable address
    var startDate: Date
    var endDate: Date
    var category: EventCategory
    var hostId: String                // Associates events with user
    var hostName: String
    var hostContact: String           // Phone number or contact info
    var isActive: Bool                // Is the sale currently happening?
    var createdDate: Date             // When this event was posted
    
    // Different types of sales
    enum EventCategory: String, CaseIterable, Codable {
        case yardSale = "Yard Sale"
        case garageSale = "Garage Sale"
        case estateSale = "Estate Sale"
        case movingSale = "Moving Sale"
        case blockSale = "Block Sale"
        case other = "Other"
        
        // Color for each category
        var color: Color {
            switch self {
            case .yardSale: return .yellow
            case .garageSale: return .blue
            case .estateSale: return .purple
            case .movingSale: return .green
            case .blockSale: return .red
            case .other: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .yardSale: return "house"
            case .garageSale: return "car"
            case .estateSale: return "building.2"
            case .movingSale: return "shippingbox"
            case .blockSale: return "house.and.flag"
            case .other: return "tag"
            }
        }
    }
    
    // Computed property to check if event is happening now
    var isHappeningNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate && isActive
    }
    
    // Computed property to check if event is upcoming
    var isUpcoming: Bool {
        return startDate > Date() && isActive
    }
    
    // Computed property to check if event has ended
    var hasEnded: Bool {
        return endDate < Date()
    }
}

// Make CLLocationCoordinate2D work with our Event struct
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
    }
}

struct UserProfile: Codable {
    var name: String
    var bio: String
    var phoneNumber: String
    var email: String
    var joinedDate: Date
    var socialLinks: [SocialLink]
    var profilePictureURL: String?
    
    static let empty = UserProfile(
        name: "",
        bio: "",
        phoneNumber: "",
        email: "",
        joinedDate: Date(),
        socialLinks: [],
        profilePictureURL: nil
    )
}

struct SocialLink: Identifiable, Codable {
    var id = UUID()
    var platform: SocialPlatform
    var url: String
    
    enum SocialPlatform: String, CaseIterable, Codable {
        case instagram = "Instagram"
        case facebook = "Facebook"
        case twitter = "Twitter"
        case tiktok = "TikTok"
        case website = "Website"
        case other = "Other"
        
        // Temporary icons for each social media platform
        var icon: String {
            switch self {
            case .instagram: return "camera.fill"
            case .facebook: return "f.square.fill"
            case .twitter: return "bird.fill"
            case .tiktok: return "music.note"
            case .website: return "globe"
            case .other: return "link"
            }
        }
        
        // Temporary color for each platform
        var color: Color {
            switch self {
            case .instagram: return .purple
            case .facebook: return .blue
            case .twitter: return .cyan
            case .tiktok: return .pink
            case .website: return .green
            case .other: return .gray
            }
        }
    }
}

struct SocialLinkRow: View {
    let link: SocialLink
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            
            Button(action: {
                openURL(link.url)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: link.platform.icon)
                        .font(.title3)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(link.platform.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(link.url)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(.leading, 8)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func openURL(_ urlString: String) {
        // Trim the URL
        var cleanURL = urlString.trimmingCharacters(in: .whitespaces)
        
        if !cleanURL.hasPrefix("http://") && !cleanURL.hasPrefix("https://") {
            cleanURL = "https://" + cleanURL
        }
        
        // Attempt to open URL
        if let url = URL(string: cleanURL) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }
}

struct AddSocialLinkView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedPlatform: SocialLink.SocialPlatform = .instagram
    @State private var urlText = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Platform") {
                    Picker("Social Media", selection: $selectedPlatform) {
                        ForEach(SocialLink.SocialPlatform.allCases, id: \.self) { platform in
                            HStack {
                                Image(systemName: platform.icon)
                                Text(platform.rawValue)
                            }
                            .tag(platform)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Link") {
                    TextField("Enter URL or username", text: $urlText)
                        .keyboardType(.URL)
                    
                    Text("Example: instagram.com/yourname or @yourname")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Social Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addLink()
                    }
                    .disabled(urlText.isEmpty)
                }
            }
        }
    }
    
    private func addLink() {
        let newLink = SocialLink(platform: selectedPlatform, url: urlText)
        dataManager.userProfile.socialLinks.append(newLink)
        dataManager.saveUserProfile()
        dismiss()
    }
}

class DataManager: ObservableObject {
    @Published var events: [Event] = []
    @Published var userProfile = UserProfile.empty

    private let db = Firestore.firestore()
    private var userId: String?
    private var eventsListener: ListenerRegistration?
      
    
    init() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userId = user?.uid
            if let userId = user?.uid {
                self?.loadUserProfile(userId: userId)
                self?.listenToEvents()
            } else {
                self?.userProfile = UserProfile.empty
                self?.eventsListener?.remove()
                self?.eventsListener = nil
                self?.events = []
            }
        }
    }
    
    deinit {
        eventsListener?.remove()
    }
    
    func listenToEvents() {
        eventsListener?.remove()
        eventsListener = db.collection("events")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error loading events: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No events found")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.events = documents.compactMap { doc -> Event? in
                        let data = doc.data()
                        
                        guard
                            let title = data["title"] as? String,
                            let description = data["description"] as? String,
                            let geoPoint = data["location"] as? GeoPoint,
                            let address = data["address"] as? String,
                            let startTimestamp = data["startDate"] as? Timestamp,
                            let endTimestamp = data["endDate"] as? Timestamp,
                            let categoryString = data["category"] as? String,
                            let category = Event.EventCategory(rawValue: categoryString),
                            let hostId = data["hostId"] as? String,
                            let hostName = data["hostName"] as? String,
                            let hostContact = data["hostContact"] as? String,
                            let isActive = data["isActive"] as? Bool,
                            let createdTimestamp = data["createdDate"] as? Timestamp
                        else {
                            print("Failed to parse event: \(doc.documentID)")
                            return nil
                        }
                        
                        return Event(
                            id: UUID(uuidString: doc.documentID) ?? UUID(),
                            title: title,
                            description: description,
                            location: CLLocationCoordinate2D(
                                latitude: geoPoint.latitude,
                                longitude: geoPoint.longitude
                            ),
                            address: address,
                            startDate: startTimestamp.dateValue(),
                            endDate: endTimestamp.dateValue(),
                            category: category,
                            hostId: hostId,
                            hostName: hostName,
                            hostContact: hostContact,
                            isActive: isActive,
                            createdDate: createdTimestamp.dateValue()
                        )
                    }
                    print("Loaded \(self?.events.count ?? 0) events from Firestore")
                }
            }
    }
    
    func loadUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error loading profile: \(error)")
                return
            }
            
            // No document yet (brand-new account): leave the profile alone
            guard let data = snapshot?.data() else { return }
            
            let socialLinksData = data["socialLinks"] as? [[String: String]] ?? []
            let socialLinks = socialLinksData.compactMap { linkData -> SocialLink? in
                guard
                    let platformString = linkData["platform"],
                    let platform = SocialLink.SocialPlatform(rawValue: platformString),
                    let url = linkData["url"]
                else { return nil }
                return SocialLink(platform: platform, url: url)
            }
            
            DispatchQueue.main.async {
                self?.userProfile = UserProfile(
                    name: data["name"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    joinedDate: (data["joinedDate"] as? Timestamp)?.dateValue() ?? Date(),
                    socialLinks: socialLinks,
                    profilePictureURL: data["profilePictureURL"] as? String
                )
            }
        }
    }
    
    // Save user profile to Firestore
    func saveUserProfile() {
        guard let userId = userId ?? Auth.auth().currentUser?.uid else { return }
        
        let socialLinksData = userProfile.socialLinks.map { link in
            return [
                "platform": link.platform.rawValue,
                "url": link.url
            ]
        }
        
        var profileData: [String: Any] = [
            "name": userProfile.name,
            "bio": userProfile.bio,
            "phoneNumber": userProfile.phoneNumber,
            "email": userProfile.email,
            "joinedDate": Timestamp(date: userProfile.joinedDate),
            "socialLinks": socialLinksData
        ]
        
        if let profilePictureURL = userProfile.profilePictureURL {
            profileData["profilePictureURL"] = profilePictureURL
        }
        
        db.collection("users").document(userId).setData(profileData, merge: true) { error in
            if let error = error {
                print("Error saving profile: \(error)")
            } else {
                print("Profile saved successfully")
            }
        }
    }
    
    func addEvent(_ event: Event) {
        let eventData: [String: Any] = [
            "title": event.title,
            "description": event.description,
            "location": GeoPoint(latitude: event.location.latitude, longitude: event.location.longitude),
            "address": event.address,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "category": event.category.rawValue,
            "hostId": event.hostId,
            "hostName": event.hostName,
            "hostContact": event.hostContact,
            "isActive": event.isActive,
            "createdDate": Timestamp(date: event.createdDate)
        ]
        
        db.collection("events").document(event.id.uuidString).setData(eventData) { error in
            if let error = error {
                print("Error saving event: \(error)")
            } else {
                print("Event saved successfully")
            }
        }
    }
    
    func removeEvent(_ event: Event) {
        db.collection("events").document(event.id.uuidString).delete { error in
            if let error = error {
                print("Error deleting event: \(error)")
            }
            else {
                print("Event deleted successfully")
            }
        }
    }
    
    func searchEvents(_ searchText: String) -> [Event] {
        if searchText.isEmpty {
            return events
        }
        return events.filter { event in
            event.title.localizedCaseInsensitiveContains(searchText) ||
            event.description.localizedCaseInsensitiveContains(searchText) ||
            event.hostName.localizedCaseInsensitiveContains(searchText)
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestPermission()
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // When location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            return
        }
        location = newLocation.coordinate
    }
    
    // When location permission changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            print("Location permission granted")
        } else if authorizationStatus == .denied {
            print("Location permission denied")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search sales...", text: $text)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }
}

struct SaleCard: View {
    let event: Event
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Show category and status
                HStack {
                    HStack(spacing: 4) {
                        Text(event.category.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(event.category.color.opacity(0.2))
                    .foregroundColor(event.category.color)
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    // Status
                    if event.isHappeningNow {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Live Now")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    } else if event.isUpcoming {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("Upcoming")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                // Title and description
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Location and time info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(event.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formatTimeRange(start: event.startDate, end: event.endDate))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // Host info
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(event.hostName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.15))
            }
            .background(Color.gray.opacity(0.15))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            EventDetailView(event: event)
        }
    }
    
    // Format date
    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        let startStr = formatter.string(from: start)
        formatter.dateFormat = "h:mm a"
        let endStr = formatter.string(from: end)
        return "\(startStr) - \(endStr)"
    }
}

struct MyEventCard: View {
    let event: Event
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false
    @State private var showingEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(event.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(event.category.color.opacity(0.2))
                    .foregroundColor(event.category.color)
                    .cornerRadius(6)
                
                Spacer()
                
                if event.isHappeningNow {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Live Now")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Text(event.title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(event.address)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: {
                    showingDetail = true
                }) {
                    Text("View Details")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                Button(action: {
                    showingEdit = true
                }) {
                    Text("Edit")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingDetail) {
            EventDetailView(event: event)
        }
        .sheet(isPresented: $showingEdit) {
            AddEventView(eventToEdit: event)
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataManager.removeEvent(event)
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
    }
}

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss
    @State private var showingHostProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category badge
                    HStack(spacing: 8) {
                        Text(event.category.rawValue)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(event.category.color.opacity(0.2))
                    .foregroundColor(event.category.color)
                    .cornerRadius(8)
                    
                    Text(event.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if event.isHappeningNow {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                            Text("This sale is happening right now")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Divider()
                    
                    // Details section
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(icon: "location.fill", title: "Location", detail: event.address)
                        
                        DetailRow(icon: "clock.fill", title: "Time",
                                detail: formatDateRange(start: event.startDate, end: event.endDate))
                                                
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Host")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(event.hostName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingHostProfile = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("View Profile")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                            }
                        }
                        
                        DetailRow(icon: "phone.fill", title: "Contact", detail: event.hostContact)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Sale Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHostProfile) {
                HostProfileView(hostId: event.hostId)
            }
        }
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let startStr = formatter.string(from: start)
        formatter.dateStyle = .none
        let endStr = formatter.string(from: end)
        return "\(startStr) - \(endStr)"
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(detail)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct SalePin: View {
    let event: Event
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Pin background
                Rectangle()
                    .fill(isSelected ? event.category.color : event.category.color.opacity(0.8))
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Pin symbol for type of event
                Image(systemName: event.category.icon)
                    .font(.system(size: isSelected ? 20 : 16))
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                // Show live events
                if event.isHappeningNow {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: isSelected ? 18 : 14, y: isSelected ? -18 : -14)
                }
            }
            
            // Add triangle to pointer
            Triangle()
                .fill(isSelected ? event.category.color : event.category.color.opacity(0.8))
                .frame(width: 12, height: 8)
                .offset(y: -4)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// Calculate distance between coordinates
func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
    let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
    let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
    let distanceInMeters = location1.distance(from: location2)
    let distanceInMiles = distanceInMeters / 1609.34 // Convert to miles
    return distanceInMiles
}

struct MapStatsBar: View {
    let eventCount: Int
    
    // Show number of sales nearby
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "map.fill")
                .foregroundColor(.blue)
            
            Text("\(eventCount) sales nearby")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MapEventCard: View {
    let event: Event
    let onClose: () -> Void
    @State private var showingFullDetail = false
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Card containing info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    
                    HStack(spacing: 4) {
                        Text(event.category.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(event.category.color.opacity(0.2))
                    .foregroundColor(event.category.color)
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    // Close button
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                // Status
                if event.isHappeningNow {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Happening Now")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                // Description preview
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let userLocation = locationManager.location {
                            let distance = distanceBetween(userLocation, event.location)
                            Text("\(event.address) • \(String(format: "%.1f", distance)) mi away")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        } else {
                            Text(event.address)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formatTime(event.startDate))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(event.hostName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            
                // View details button
                Button(action: {
                    showingFullDetail = true
                }) {
                    HStack {
                        Text("View Full Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .background(event.category.color.opacity(0.15))
                    .foregroundColor(event.category.color)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: -5)
        .sheet(isPresented: $showingFullDetail) {
            EventDetailView(event: event)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String
    let isEmpty: Bool
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            // Label and Value
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(isEmpty ? .gray : .primary)
                    .italic(isEmpty)
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct EditProfileFieldView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let field: ProfileView.ProfileField
    
    @State private var textValue = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    switch field {
                    case .name:
                        TextField("Enter your name", text: $textValue)
                    case .bio:
                        TextField("Tell us about yourself", text: $textValue, axis: .vertical)
                            .lineLimit(3...6)
                    case .phone:
                        TextField("Enter phone number", text: $textValue)
                            .keyboardType(.phonePad)
                    case .email:
                        TextField("Enter email address", text: $textValue)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                }
            }
            .navigationTitle("Edit \(fieldTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveField()
                    }
                }
            }
            .onAppear {
                switch field {
                case .name:
                    textValue = dataManager.userProfile.name
                case .bio:
                    textValue = dataManager.userProfile.bio
                case .phone:
                    textValue = dataManager.userProfile.phoneNumber
                case .email:
                    textValue = dataManager.userProfile.email
                }
            }
        }
    }
    
    private var fieldTitle: String {
        switch field {
        case .name: return "Name"
        case .bio: return "Bio"
        case .phone: return "Phone"
        case .email: return "Email"
        }
    }
    
    private func saveField() {
        switch field {
        case .name:
            dataManager.userProfile.name = textValue
        case .bio:
            dataManager.userProfile.bio = textValue
        case .phone:
            dataManager.userProfile.phoneNumber = textValue
        case .email:
            dataManager.userProfile.email = textValue
        }
        dataManager.saveUserProfile()
        dismiss()
    }
}

struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = 100
    
    private var initials: String {
        let letters = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
        return letters.isEmpty ? "?" : letters
    }
    
    var body: some View {
        Circle()
            .fill(Color.blue.opacity(0.85))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
}

struct HostProfileView: View {
    let hostId: String
    @State private var hostProfile: UserProfile?
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading profile...")
                } else if let profile = hostProfile {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(spacing: 12) {
                                InitialsAvatar(name: profile.name, size: 100)
                                
                                Text(profile.name.isEmpty ? "Anonymous User" : profile.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .padding(.top, 20)
                            
                            // Show Bio Section
                            if !profile.bio.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(profile.bio)
                                        .font(.body)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Contact Info
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Contact Information")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                if !profile.phoneNumber.isEmpty {
                                    ContactRow(icon: "phone.fill", label: "Phone", value: profile.phoneNumber)
                                }
                                
                                if !profile.email.isEmpty {
                                    ContactRow(icon: "envelope.fill", label: "Email", value: profile.email)
                                }
                                
                                if profile.phoneNumber.isEmpty && profile.email.isEmpty {
                                    Text("No contact information available")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Social Links
                            if !profile.socialLinks.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Social Links")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    VStack(spacing: 12) {
                                        ForEach(profile.socialLinks) { link in
                                            SocialLinkDisplay(link: link)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Show how long they've been a member
                            Text("Member since \(formatDate(profile.joinedDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Profile not found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Host Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadHostProfile()
        }
    }
    
    private func loadHostProfile() {
        db.collection("users").document(hostId).getDocument { snapshot, error in
            isLoading = false
            
            if let error = error {
                print("Error loading host profile: \(error)")
                return
            }
            
            if let data = snapshot?.data() {
                // Load user's social links
                let socialLinksData = data["socialLinks"] as? [[String: String]] ?? []
                let socialLinks = socialLinksData.compactMap { linkData -> SocialLink? in
                    guard
                        let platformString = linkData["platform"],
                        let platform = SocialLink.SocialPlatform(rawValue: platformString),
                        let url = linkData["url"]
                    else { return nil }
                    
                    return SocialLink(platform: platform, url: url)
                }
                
                hostProfile = UserProfile(
                    name: data["name"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    joinedDate: (data["joinedDate"] as? Timestamp)?.dateValue() ?? Date(),
                    socialLinks: socialLinks
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ContactRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
            
            Spacer()
            
            // Copy button
            Button(action: {
                UIPasteboard.general.string = value
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct SocialLinkDisplay: View {
    let link: SocialLink
    
    var body: some View {
        Button(action: {
            openURL(link.url)
        }) {
            HStack(spacing: 12) {
                Image(systemName: link.platform.icon)
                    .font(.title3)
                    .foregroundColor(link.platform.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.platform.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(link.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func openURL(_ urlString: String) {
        var cleanURL = urlString.trimmingCharacters(in: .whitespaces)
        
        if !cleanURL.hasPrefix("http://") && !cleanURL.hasPrefix("https://") {
            cleanURL = "https://" + cleanURL
        }
        
        if let url = URL(string: cleanURL) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }
}

extension ProfileView.ProfileField: Identifiable {
    var id: Self { self }
}

// Content View (Main Container with Tab Navigation)
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
                .tag(0)
            
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(.black)
    }
}

struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var dataManager: DataManager
    
    @State private var position: MapCameraPosition = .automatic
    @State private var hasCenteredOnUser = false
    
    @State private var selectedEvent: Event?
    
    // Find events within radius
    var nearbyEvents: [Event] {
        let activeEvents = dataManager.events.filter { !$0.hasEnded }
        guard let userLocation = locationManager.location else { return activeEvents }
        return activeEvents.filter { distanceBetween(userLocation, $0.location) <= 10.0 }
    }
    
    private func centerOnUserIfNeeded(_ coordinate: CLLocationCoordinate2D?) {
        guard !hasCenteredOnUser, let coordinate = coordinate else { return }
        hasCenteredOnUser = true
        position = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(position: $position) {
                    UserAnnotation()
                    // Use nearbyEvents instead of all events
                    ForEach(nearbyEvents) { event in
                        Annotation(event.title, coordinate: event.location) {
                            SalePin(event: event, isSelected: selectedEvent?.id == event.id)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedEvent = event
                                    }
                                }
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .ignoresSafeArea()
                
                VStack {
                    // Show number of nearby events
                    MapStatsBar(eventCount: nearbyEvents.count)
                        .padding()
                    
                    Spacer()
                }
                
                if let event = selectedEvent {
                    VStack {
                        Spacer()
                        
                        MapEventCard(event: event, onClose: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedEvent = nil
                            }
                        })
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { centerOnUserIfNeeded(locationManager.location) }
            .onChange(of: locationManager.location) { _, newLocation in
                centerOnUserIfNeeded(newLocation)
            }
        }
    }
}

struct ExploreView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var searchText = ""
    @State private var showingSortOptions = false
    @State private var selectedSortOption: SortOption = .distance
    @State private var selectedCategoryFilter: Event.EventCategory? = nil
    
    enum SortOption: String, CaseIterable {
        case distance = "Distance"
        case date = "Date"
        case none = "None"
    }
    
    var filteredAndSortedEvents: [Event] {
        var events = dataManager.searchEvents(searchText).filter { !$0.hasEnded }
        
        if let category = selectedCategoryFilter {
            events = events.filter { $0.category == category }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .distance:
            if let userLocation = locationManager.location {
                events = events.sorted { event1, event2 in
                    let dist1 = distanceBetween(userLocation, event1.location)
                    let dist2 = distanceBetween(userLocation, event2.location)
                    return dist1 < dist2
                }
            }
        case .date:
            events = events.sorted { $0.startDate < $1.startDate }
        case .none:
            break
        }
        
        return events
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Filter and Sort
                HStack(spacing: 12) {
                    Button(action: {
                        showingSortOptions = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort: \(selectedSortOption.rawValue)")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                    
                    // Filter Menu
                    Menu {
                        Button("All Categories") {
                            selectedCategoryFilter = nil
                        }
                        
                        Divider()
                        
                        ForEach(Event.EventCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategoryFilter = category
                            }) {
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue)
                                    if selectedCategoryFilter == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedCategoryFilter?.rawValue ?? "All")
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategoryFilter != nil ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                        .foregroundColor(selectedCategoryFilter != nil ? .blue : .primary)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Text("\(filteredAndSortedEvents.count) sales")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Scroll through Sale Cards
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAndSortedEvents) { event in
                            SaleCard(event: event)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Explore Sales")
            .confirmationDialog("Sort By", isPresented: $showingSortOptions, titleVisibility: .visible) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        selectedSortOption = option
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddLink = false
    @State private var editingField: ProfileField? = nil
    @State private var showingAddEvent = false
    
    enum ProfileField {
        case name, bio, phone, email
    }
    
    var myEvents: [Event] {
           guard let userId = authManager.user?.uid else { return [] }
           return dataManager.events.filter { $0.hostId == userId }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    InitialsAvatar(name: dataManager.userProfile.name, size: 100)
                        .padding(.top)
                    // Sign Out Button
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Profile Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Profile Information")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 16) {
                            ProfileRow(
                                icon: "person.fill",
                                label: "Name",
                                value: dataManager.userProfile.name.isEmpty ? "Add your name" : dataManager.userProfile.name,
                                isEmpty: dataManager.userProfile.name.isEmpty,
                                onEdit: { editingField = .name }
                            )
                            
                            ProfileRow(
                                icon: "text.alignleft",
                                label: "Bio",
                                value: dataManager.userProfile.bio.isEmpty ? "Add a bio" : dataManager.userProfile.bio,
                                isEmpty: dataManager.userProfile.bio.isEmpty,
                                onEdit: { editingField = .bio }
                            )
                            
                            ProfileRow(
                                icon: "phone.fill",
                                label: "Phone",
                                value: dataManager.userProfile.phoneNumber.isEmpty ? "Add phone number" : dataManager.userProfile.phoneNumber,
                                isEmpty: dataManager.userProfile.phoneNumber.isEmpty,
                                onEdit: { editingField = .phone }
                            )
                            
                            ProfileRow(
                                icon: "envelope.fill",
                                label: "Email",
                                value: dataManager.userProfile.email.isEmpty ? "Add email" : dataManager.userProfile.email,
                                isEmpty: dataManager.userProfile.email.isEmpty,
                                onEdit: { editingField = .email }
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // My Events
                    VStack(alignment: .leading, spacing: 16) {
                           HStack {
                               Text("My Events")
                                   .font(.title2)
                                   .fontWeight(.bold)
                               
                               Spacer()
                               
                               Button(action: {
                                   showingAddEvent = true
                               }) {
                                   Image(systemName: "plus.circle.fill")
                                       .font(.title2)
                                       .foregroundColor(.blue)
                               }
                           }
                           
                           if myEvents.isEmpty {
                               Text("You haven't created any events yet. Tap the '+' button to create your first sale!")
                                   .font(.subheadline)
                                   .foregroundColor(.secondary)
                                   .italic()
                                   .padding()
                           } else {
                               VStack(spacing: 12) {
                                   ForEach(myEvents) { event in
                                       MyEventCard(event: event)
                                   }
                               }
                           }
                    }
                   .padding()
                   .background(Color.green.opacity(0.1))
                   .cornerRadius(12)
                    
                    // Social Links
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Social Links")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddLink = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if dataManager.userProfile.socialLinks.isEmpty {
                            Text("You have no social links yet. Add your Instagram, Facebook, or other links with the '+' button above.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                                .padding()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(dataManager.userProfile.socialLinks) { link in
                                    SocialLinkRow(link: link, onDelete: {
                                        deleteSocialLink(link)
                                    })
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingAddLink) {
                AddSocialLinkView()
            }
            .sheet(item: $editingField) { field in
                EditProfileFieldView(field: field)
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView()
            }
        }
    }
    
    private func deleteSocialLink(_ link: SocialLink) {
        dataManager.userProfile.socialLinks.removeAll { $0.id == link.id }
        dataManager.saveUserProfile()
    }
}

struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var address = ""
    @State private var selectedCategory: Event.EventCategory = .garageSale
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(4 * 3600) // 4 hours later
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    var eventToEdit: Event? = nil

    init(eventToEdit: Event? = nil) {
        self.eventToEdit = eventToEdit
        _title = State(initialValue: eventToEdit?.title ?? "")
        _description = State(initialValue: eventToEdit?.description ?? "")
        _address = State(initialValue: eventToEdit?.address ?? "")
        _selectedCategory = State(initialValue: eventToEdit?.category ?? .garageSale)
        _startDate = State(initialValue: eventToEdit?.startDate ?? Date())
        _endDate = State(initialValue: eventToEdit?.endDate ?? Date().addingTimeInterval(4 * 3600))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                        .autocorrectionDisabled()
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Event.EventCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Location") {
                    TextField("Address", text: $address)
                        .autocorrectionDisabled()
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Time", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Contact Information") {
                    if !dataManager.userProfile.phoneNumber.isEmpty {
                        HStack {
                            Text("Phone")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(dataManager.userProfile.phoneNumber)
                        }
                    } else {
                        Text("Add a phone number in your profile to help buyers contact you")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle(eventToEdit == nil ? "Create Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(eventToEdit == nil ? "Create" : "Save") {
                        createEvent()
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !address.isEmpty &&
        endDate > startDate
    }
    
    private func createEvent() {
        guard let userId = authManager.user?.uid else {
            errorMessage = "You must be logged in to create an event"
            showError = true
            return
        }
        
        isSaving = true
        
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            DispatchQueue.main.async {
                isSaving = false
                
                guard let coordinate = placemarks?.first?.location?.coordinate else {
                    errorMessage = "We couldn't find that address. Include the city and state, then try again."
                    showError = true
                    return
                }
                
                let newEvent = Event(
                    id: eventToEdit?.id ?? UUID(),
                    title: title,
                    description: description,
                    location: coordinate,
                    address: address,
                    startDate: startDate,
                    endDate: endDate,
                    category: selectedCategory,
                    hostId: userId,
                    hostName: dataManager.userProfile.name.isEmpty ? "Anonymous" : dataManager.userProfile.name,
                    hostContact: dataManager.userProfile.phoneNumber,
                    isActive: true,
                    createdDate: eventToEdit?.createdDate ?? Date()
                )
                
                dataManager.addEvent(newEvent)
                dismiss()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
        .environmentObject(LocationManager())
        .environmentObject(AuthManager())
}
