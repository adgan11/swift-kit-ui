//
//  SKOTPField.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  One-time-code entry. A real hidden text field drives visible boxes, which is
//  the only approach that keeps iOS SMS autofill working — per-box TextFields
//  look right and then silently break the one feature that matters.
//
//  Usage:
//      SKOTPField(code: $code) { verify($0) }
//

import SwiftUI

public struct SKOTPField: View {
    @Binding private var code: String
    private let length: Int
    private let isInvalid: Bool
    private let onComplete: ((String) -> Void)?

    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameter isInvalid: flip to `true` after a rejected code to shake the
    ///   boxes. Driven by state rather than by calling a method on the view —
    ///   a `View` is a value type, so an imperative `shake()` on it can never
    ///   reach the live instance on screen.
    public init(
        code: Binding<String>,
        length: Int = 6,
        isInvalid: Bool = false,
        onComplete: ((String) -> Void)? = nil
    ) {
        self._code = code
        self.length = length
        self.isInvalid = isInvalid
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            hiddenInput
            boxes
        }
        .contentShape(.rect)
        .onTapGesture { focused = true }
        .keyframeAnimator(initialValue: CGFloat.zero, trigger: isInvalid) { view, offset in
            view.offset(x: offset)
        } keyframes: { _ in
            // Decaying oscillation. Skipped entirely under Reduce Motion by
            // collapsing to a single zero keyframe.
            if reduceMotion {
                CubicKeyframe(0, duration: 0.01)
            } else {
                CubicKeyframe(-10, duration: 0.06)
                CubicKeyframe(10, duration: 0.08)
                CubicKeyframe(-6, duration: 0.08)
                CubicKeyframe(4, duration: 0.07)
                CubicKeyframe(0, duration: 0.06)
            }
        }
        .onChange(of: isInvalid) { _, invalid in
            if invalid { SK.Haptic.play(.error) }
        }
        .accessibilityElement()
        .accessibilityLabel("Verification code")
        .accessibilityValue(code.isEmpty ? "Empty" : code.map(String.init).joined(separator: " "))
    }

    /// Invisible but still a real, focusable field — `.opacity(0)` alone would
    /// make it unfocusable on some iOS versions, hence the tiny frame.
    private var hiddenInput: some View {
        TextField("", text: $code)
            .skKeyboard(.number)
            .skOneTimeCode()
            .focused($focused)
            .frame(width: 1, height: 1)
            .opacity(0.001)
            .onChange(of: code) { _, new in
                let digits = String(new.filter(\.isNumber).prefix(length))
                if digits != new { code = digits }
                if digits.count == length {
                    focused = false
                    SK.Haptic.play(.success)
                    onComplete?(digits)
                } else if !digits.isEmpty {
                    SK.Haptic.play(.light)
                }
            }
    }

    private var boxes: some View {
        HStack(spacing: SK.Space.sm) {
            ForEach(0..<length, id: \.self) { index in
                box(at: index)
            }
        }
    }

    private func box(at index: Int) -> some View {
        let characters = Array(code)
        let filled = index < characters.count
        let isNext = index == characters.count && focused

        return Text(filled ? String(characters[index]) : "")
            .font(SK.Type_.numeric)
            .foregroundStyle(SK.Palette.label)
            .frame(width: 46, height: 56)
            .background(SK.Palette.surface, in: RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                    .strokeBorder(
                        isInvalid ? SK.Palette.danger
                            : (isNext ? SK.Palette.accent : SK.Palette.separator),
                        lineWidth: isInvalid || isNext ? SK.Stroke.thick : SK.Stroke.thin
                    )
            }
            .scaleEffect(isNext ? 1.04 : 1)
            .skAnimation(.snap, value: code)
            .skAnimation(.snap, value: focused)
    }

}

#Preview("SKOTPField") {
    @Previewable @State var code = ""
    @Previewable @State var invalid = false

    VStack(spacing: SK.Space.xl) {
        Text("Enter the 6-digit code")
            .font(SK.Type_.headline)
            .foregroundStyle(SK.Palette.label)
        SKOTPField(code: $code, isInvalid: invalid) { entered in
            // Anything but 123456 is rejected, so the shake is demonstrable.
            invalid = entered != "123456"
        }
        Text(invalid ? "That code is not right." : "Try 123456")
            .font(SK.Type_.caption)
            .foregroundStyle(invalid ? SK.Palette.danger : SK.Palette.labelTertiary)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
