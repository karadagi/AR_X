import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Binding var selectedFileURL: URL?
    // showAR removed, we just set fileURL to trigger preview
    @Binding var showAR: Bool // Kept for compatibility if needed, or unused.
    @State private var isImporting: Bool = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("AR_X")
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
            
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
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
                // parent.showAR = true // Don't jump to AR, let ContentView show Preview
            }
        }
    }
}
