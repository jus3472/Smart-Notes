import SwiftUI

struct DetailNoteView: View {
    let note: SNNote
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Title
                Text(note.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Date
                Text("Updated: \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                // Content
                Text(note.content)
                    .font(.body)
                    .padding(.top, 4)
                
                Divider()
                
                // If audio exists
                if let url = note.audioUrl {
                    Text("Associated Recording:")
                        .font(.headline)
                    
                    Text(url)
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding()
        }
        .navigationTitle("Note Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
