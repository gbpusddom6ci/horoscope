import SwiftUI

struct LibraryView: View {
    @State private var searchQuery = ""
    @State private var isGridView = true
    @State private var selectedFilter = "All"
    
    let filters = ["All", "Etsy", "Shopify", "Amazon", "Social", "Drafts"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("Library")
                        .font(AppTypography.titleExtraBold)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) { isGridView.toggle() }
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                // Search & Filters
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search listings, folders...", text: $searchQuery)
                            .font(AppTypography.body)
                    }
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                Button {
                                    withAnimation { selectedFilter = filter }
                                } label: {
                                    Text(filter)
                                        .font(AppTypography.captionMedium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? AppTheme.primary : Color.primary.opacity(0.05))
                                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Folders
                VStack(alignment: .leading, spacing: 16) {
                    Text("Folders")
                        .font(AppTypography.headline)
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            FolderCard(name: "Summer Collection", count: 12)
                            FolderCard(name: "Holiday 2026", count: 8)
                            FolderCard(name: "Evergreen", count: 45)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Content Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Captions")
                        .font(AppTypography.headline)
                        .padding(.horizontal, 24)
                    
                    if isGridView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            LibraryItemCard(title: "Ceramic Mug", platform: "Etsy", date: "Today")
                            LibraryItemCard(title: "Cyberpunk Art", platform: "Shopify", date: "Yesterday")
                            LibraryItemCard(title: "Soy Candle", platform: "Amazon", date: "Oct 12")
                            LibraryItemCard(title: "Tote Bag", platform: "Etsy", date: "Oct 10")
                        }
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 12) {
                            LibraryItemRow(title: "Ceramic Mug", platform: "Etsy", date: "Today")
                            LibraryItemRow(title: "Cyberpunk Art", platform: "Shopify", date: "Yesterday")
                            LibraryItemRow(title: "Soy Candle", platform: "Amazon", date: "Oct 12")
                            LibraryItemRow(title: "Tote Bag", platform: "Etsy", date: "Oct 10")
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer(minLength: 120)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct FolderCard: View {
    let name: String
    let count: Int
    
    var body: some View {
        Button {
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accent)
                    Spacer()
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)
            .padding(16)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    .shadow(color: AppTheme.accent.opacity(0.2), radius: 5, x: 0, y: 3)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct LibraryItemCard: View {
    let title: String
    let platform: String
    let date: String
    
    var body: some View {
        Button {
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(platform)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppTheme.primary.opacity(0.1))
                        .foregroundColor(AppTheme.primary)
                        .cornerRadius(6)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(date)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(16)
            .frame(height: 110, alignment: .topLeading)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct LibraryItemRow: View {
    let title: String
    let platform: String
    let date: String
    
    var body: some View {
        Button {
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(AppTheme.primary.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(platform)
                            .foregroundColor(AppTheme.primary)
                        Text("•")
                        Text(date)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LibraryView()
}
