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

    var body: some View {
        ZStack {
            StarField(starCount: 40)

            VStack(spacing: 0) {
                MysticTopBar("palm.title")

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
                                .accessibilityIdentifier("palm.analyze")
                            }
                        }
                        .padding(.horizontal, MysticSpacing.md)
                        .fadeInOnAppear(delay: 0.15)

                        if let errorMessage {
                            MysticCard(glowColor: MysticColors.celestialPink) {
                                Text(errorMessage)
                                    .font(MysticFonts.body(14))
                                    .foregroundColor(MysticColors.celestialPink)
                            }
                            .padding(.horizontal, MysticSpacing.md)
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
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker(image: $selectedImage, imageData: $selectedImageData)
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            loadPhotoItem(newValue)
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
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImageData = data
                    selectedImage = image
                    interpretation = nil
                    errorMessage = nil
                }
            }
        }
    }

    private func analyzePalm() {
        guard let selectedImageData else {
            errorMessage = String(localized: "palm.error.select_image")
            return
        }

        isAnalyzing = true
        interpretation = nil
        errorMessage = nil

        Task {
            do {
                let result = try await AIService.shared.interpretPalm(imageData: selectedImageData)
                await MainActor.run {
                    interpretation = result
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                isAnalyzing = false
            }
        }
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
