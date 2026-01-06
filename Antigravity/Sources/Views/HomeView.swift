import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Binding var selectedFileURL: URL?
    @Binding var showAR: Bool
    @State private var isImporting: Bool = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Antigravity")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            
            Text("Visualize your STL models in AR")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: {
                isImporting = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import STL")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
            }
            .padding(.horizontal, 40)
            .sheet(isPresented: $isImporting) {
                DocumentPicker(selectedFileURL: $selectedFileURL, showAR: $showAR)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?
    @Binding var showAR: Bool
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.selectedFileURL = url
                parent.showAR = true
            }
        }
    }
}
