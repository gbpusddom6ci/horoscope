import SwiftUI
import PhotosUI
import UIKit

struct PalmReadingView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics

    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedImageData: Data?

    @State private var isAnalyzing = false
    @State private var interpretation: String?
    @State private var errorMessage: String?
    @State private var activeAnalysisRequestID: UUID?

    var body: some View {
        MysticScreenScaffold(
            "palm.title",
            starCount: 40,
            starMode: .modal
        ) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MysticSpacing.lg) {
                    VStack(spacing: MysticSpacing.md) {
                        Spacer().frame(height: 40)

                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(MysticGradients.lavenderGlow)
                            .shadow(color: MysticColors.neonLavender.opacity(0.4), radius: 12)

                        GlowingText(String(localized: "palm.title"), font: MysticFonts.title(32), color: MysticColors.neonLavender)

                        Text("palm.subtitle")
                            .font(MysticFonts.body(15))
                            .foregroundColor(MysticColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MysticSpacing.xl)
                    }
                    .fadeInOnAppear(delay: 0)

                    MysticCard(glowColor: MysticColors.neonLavender) {
                        VStack(spacing: MysticSpacing.md) {
                            imagePreview

                            HStack(spacing: MysticSpacing.sm) {
                                MysticButton(String(localized: "palm.camera"), icon: "camera.fill", style: .secondary) {
                                    openCamera()
                                }
                                .disabled(isAnalyzing)
                                .accessibilityHint(Text(String(localized: "palm.camera.hint")))
                                .accessibilityIdentifier("palm.camera.button")

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.on.rectangle")
                                        Text("palm.gallery")
                                    }
                                    .font(MysticFonts.body(14))
                                    .foregroundColor(MysticColors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(MysticColors.inputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MysticRadius.md)
                                            .stroke(MysticColors.cardBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isAnalyzing)
                                .accessibilityLabel(Text(String(localized: "palm.gallery")))
                                .accessibilityHint(Text(String(localized: "palm.gallery.hint")))
                                .accessibilityIdentifier("palm.gallery.button")
                            }

                            MysticButton(
                                String(localized: "palm.analyze"),
                                icon: "sparkles",
                                style: .primary,
                                isLoading: isAnalyzing
                            ) {
                                analyzePalm()
                            }
                            .disabled(selectedImageData == nil || isAnalyzing)
                            .accessibilityHint(Text(String(localized: "palm.analyze.hint")))
                            .accessibilityIdentifier("palm.analyze")

                            if isAnalyzing {
                                HStack(spacing: MysticSpacing.xs) {
                                    ProgressView()
                                        .tint(MysticColors.neonLavender)
                                    Text("palm.analyzing")
                                        .font(MysticFonts.caption(13))
                                        .foregroundColor(MysticColors.textMuted)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(Text(String(localized: "palm.analyzing")))
                                .accessibilityIdentifier("palm.analyzing.state")
                            }
                        }
                    }
                    .padding(.horizontal, MysticSpacing.md)
                    .fadeInOnAppear(delay: 0.15)

                    if let errorMessage {
                        MysticCard(glowColor: MysticColors.celestialPink) {
                            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                                Text(errorMessage)
                                    .font(MysticFonts.body(14))
                                    .foregroundColor(MysticColors.celestialPink)

                                if Self.shouldShowRetryAction(
                                    hasSelectedImage: selectedImageData != nil,
                                    isAnalyzing: isAnalyzing
                                ) {
                                    Button(String(localized: "common.retry")) {
                                        analyzePalm()
                                    }
                                    .buttonStyle(.plain)
                                    .font(MysticFonts.caption(13))
                                    .foregroundColor(MysticColors.neonLavender)
                                    .frame(minHeight: MysticAccessibility.minimumTapTarget, alignment: .leading)
                                    .accessibilityHint(Text(String(localized: "palm.retry.hint")))
                                    .accessibilityIdentifier("palm.retry.button")
                                }
                            }
                        }
                        .padding(.horizontal, MysticSpacing.md)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("palm.error.card")
                    }

                    if let interpretation {
                        MysticCard(glowColor: MysticColors.mysticGold) {
                            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(MysticColors.mysticGold)
                                    Text("palm.ai_title")
                                        .font(MysticFonts.heading(16))
                                        .foregroundColor(MysticColors.textPrimary)
                                }

                                Text(interpretation)
                                    .font(MysticFonts.body(14))
                                    .foregroundColor(MysticColors.textSecondary)
                                    .lineSpacing(3)
                            }
                        }
                        .padding(.horizontal, MysticSpacing.md)
                        .fadeInOnAppear(delay: 0)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("palm.result.card")
                    }

                    VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                        Text("palm.line_guide")
                            .font(MysticFonts.heading(18))
                            .foregroundColor(MysticColors.textPrimary)
                            .padding(.horizontal, MysticSpacing.md)

                        lineInfo(name: String(localized: "palm.line.life.title"), desc: String(localized: "palm.line.life.desc"), color: MysticColors.auroraGreen)
                        lineInfo(name: String(localized: "palm.line.heart.title"), desc: String(localized: "palm.line.heart.desc"), color: MysticColors.celestialPink)
                        lineInfo(name: String(localized: "palm.line.head.title"), desc: String(localized: "palm.line.head.desc"), color: MysticColors.neonLavender)
                        lineInfo(name: String(localized: "palm.line.fate.title"), desc: String(localized: "palm.line.fate.desc"), color: MysticColors.mysticGold)
                    }
                    .fadeInOnAppear(delay: 0.2)

                    Color.clear.frame(height: max(72, chromeMetrics.contentBottomReservedSpace))
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker(image: $selectedImage, imageData: $selectedImageData)
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            loadPhotoItem(newValue)
        }
        .onChange(of: selectedImage) { _, newImage in
            guard let newImage else { return }
            activeAnalysisRequestID = nil
            isAnalyzing = false
            selectedImageData = optimizedImageData(for: newImage)
            interpretation = nil
            errorMessage = nil
        }
    }

    private var imagePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: MysticRadius.lg)
                .fill(MysticColors.inputBackground)
                .frame(height: 220)

            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 210)
                    .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
                    .padding(6)
            } else {
                VStack(spacing: MysticSpacing.sm) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 36))
                        .foregroundColor(MysticColors.textMuted)
                    Text("palm.image_placeholder")
                        .font(MysticFonts.body(14))
                        .foregroundColor(MysticColors.textMuted)
                }
            }
        }
        .accessibilityIdentifier("palm.image.preview")
    }

    private func lineInfo(name: String, desc: String, color: Color) -> some View {
        MysticCard(glowColor: color.opacity(0.5)) {
            HStack(spacing: MysticSpacing.md) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1))
                    .overlay(Image(systemName: "line.diagonal").foregroundColor(color))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(MysticFonts.body(15))
                        .fontWeight(.semibold)
                        .foregroundColor(MysticColors.textPrimary)
                    Text(desc)
                        .font(MysticFonts.caption(13))
                        .foregroundColor(MysticColors.textSecondary)
                }

                Spacer()
            }
        }
        .padding(.horizontal, MysticSpacing.md)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = String(localized: "palm.error.camera_unavailable")
            return
        }

        errorMessage = nil
        showCamera = true
    }

    private func loadPhotoItem(_ item: PhotosPickerItem) {
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        errorMessage = String(localized: "palm.error.load_image_failed")
                    }
                    return
                }

                await MainActor.run {
                    activeAnalysisRequestID = nil
                    isAnalyzing = false
                    selectedImage = image
                    selectedImageData = optimizedImageData(for: image) ?? data
                    interpretation = nil
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    activeAnalysisRequestID = nil
                    isAnalyzing = false
                    errorMessage = String(localized: "palm.error.load_image_failed")
                }
            }
        }
    }

    private func optimizedImageData(
        for image: UIImage,
        maxDimension: CGFloat = 1600,
        compressionQuality: CGFloat = 0.78
    ) -> Data? {
        let inputSize = image.size
        let longestSide = max(inputSize.width, inputSize.height)
        guard longestSide > 0 else { return nil }

        let scale = min(1, maxDimension / longestSide)
        let targetSize = CGSize(
            width: max(1, floor(inputSize.width * scale)),
            height: max(1, floor(inputSize.height * scale))
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    private func analyzePalm() {
        guard let selectedImageData else {
            errorMessage = String(localized: "palm.error.select_image")
            return
        }

        isAnalyzing = true
        interpretation = nil
        errorMessage = nil
        let requestID = UUID()
        activeAnalysisRequestID = requestID

        Task {
            do {
                let result = try await AIService.shared.interpretPalm(imageData: selectedImageData)
                await MainActor.run {
                    guard activeAnalysisRequestID == requestID else { return }
                    interpretation = result
                }
            } catch {
                await MainActor.run {
                    guard activeAnalysisRequestID == requestID else { return }
                    errorMessage = Self.userFacingErrorMessage(for: error)
                }
            }

            await MainActor.run {
                guard activeAnalysisRequestID == requestID else { return }
                activeAnalysisRequestID = nil
                isAnalyzing = false
            }
        }
    }

    static func userFacingErrorMessage(for error: Error) -> String {
        if let configError = error as? ConfigurationError {
            return configError.localizedDescription
        }

        if let aiError = error as? AIServiceError {
            return aiError.localizedDescription
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return String(localized: "palm.error.offline")
            case .timedOut:
                return String(localized: "palm.error.timeout")
            default:
                return String(localized: "palm.error.server")
            }
        }

        return String(localized: "palm.error.generic")
    }

    nonisolated static func shouldShowRetryAction(hasSelectedImage: Bool, isAnalyzing: Bool) -> Bool {
        hasSelectedImage && !isAnalyzing
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    @Binding var image: UIImage?
    @Binding var imageData: Data?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let selected = info[.originalImage] as? UIImage {
                parent.image = selected
                parent.imageData = selected.jpegData(compressionQuality: 0.85)
            }
            parent.dismiss()
        }
    }
}

#Preview { PalmReadingView().environment(AuthService()) }
