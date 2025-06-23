import SwiftUI

// 📗 Expanding Text View: Text input that grows with content
struct ExpandingTextView: View {
    @Binding var text: String
    let placeholder: String
    @State private var textHeight: CGFloat = 36 // Start with single line height
    
    private let lineHeight: CGFloat = 22 // Approximate line height for system font
    private let verticalPadding: CGFloat = 14 // Top + bottom padding
    private let maxHeight: CGFloat = 120 // Maximum height before scrolling
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(AppColors.placeholderText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .allowsHitTesting(false)
            }
            
            // Text Editor
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: textHeight, maxHeight: textHeight)
                .onAppear {
                    // Remove the default background and configure
                    UITextView.appearance().backgroundColor = .clear
                    updateHeight(for: text)
                }
                .onChange(of: text) { _, newValue in
                    updateHeight(for: newValue)
                }
        }
    }
    
    private func updateHeight(for text: String) {
        // Use more precise text measurement
        let font = UIFont.preferredFont(forTextStyle: .body)
        let constraintWidth = UIScreen.main.bounds.width - 100 // Account for margins
        
        let textToMeasure = text.isEmpty ? "A" : text // Measure at least one line
        
        let boundingRect = textToMeasure.boundingRect(
            with: CGSize(width: constraintWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: font,
                .paragraphStyle: {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineBreakMode = .byWordWrapping
                    return paragraphStyle
                }()
            ],
            context: nil
        )
        
        // Calculate new height based on content
        let contentHeight = ceil(boundingRect.height)
        let newHeight = contentHeight + verticalPadding
        
        // Ensure minimum single line height and respect maximum
        let finalHeight = max(36, min(newHeight, maxHeight))
        
        // Animate height changes smoothly
        withAnimation(.easeInOut(duration: 0.15)) {
            textHeight = finalHeight
        }
    }
}

#Preview {
    @Previewable @State var sampleText = ""
    return ExpandingTextView(text: $sampleText, placeholder: "Enter your note...")
        .padding()
        .background(AppColors.inputBackground)
        .cornerRadius(22)
        .padding()
        .background(AppColors.background)
} 