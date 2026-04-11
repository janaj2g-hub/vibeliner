import Foundation

struct TourStep {
    let title: String
    let body: String
    let buttonLabel: String
    let isFullWidth: Bool
}

extension TourStep {
    static let allSteps: [TourStep] = [
        TourStep(
            title: "Visual bugs are hard to describe",
            body: "You spot a visual bug. You open your AI tool. Now you have to explain it in words. \"The padding feels off\" is vague. The AI guesses. You go back and forth. Vibeliner lets you point instead of describe.",
            buttonLabel: "Next",
            isFullWidth: false
        ),
        TourStep(
            title: "Start by taking a screenshot",
            body: "Show exactly what you\u{2019}re working on by screenshotting it directly for an LLM.",
            buttonLabel: "Next",
            isFullWidth: false
        ),
        TourStep(
            title: "Point at what you see",
            body: "Five tools in the floating toolbar. Pin a spot, draw an arrow, highlight with a rectangle or circle, sketch with freehand. Each mark gets a number and a note that becomes part of the prompt.",
            buttonLabel: "Next",
            isFullWidth: false
        ),
        TourStep(
            title: "Marks become instructions",
            body: "Badges stay burned into the exported screenshot. Your note text becomes numbered lines in the prompt. The AI sees badge #1 on the image and reads the matching instruction in the text.",
            buttonLabel: "Next",
            isFullWidth: false
        ),
        TourStep(
            title: "Give your AI the full picture",
            body: "Paste the marked screenshot and the generated prompt into your AI tool. It sees the numbered badges, reads the notes, and knows exactly what to fix. No guessing, no back and forth.",
            buttonLabel: "Next",
            isFullWidth: false
        ),
        TourStep(
            title: "One paste or two",
            body: "IDE mode is for terminal tools like Claude Code and Codex. One paste: the prompt includes the file path so the AI reads the image from disk. App mode is for chat tools like Claude.ai and ChatGPT. Two pastes: prompt and image go in separately.",
            buttonLabel: "Next",
            isFullWidth: false
        ),
        TourStep(
            title: "Add more screenshots",
            body: "Click \"+ Add image\" in the toolbar to capture additional screenshots into the same session. Vibeliner arranges them side by side in a filmstrip so you can annotate across multiple views at once.",
            buttonLabel: "Next",
            isFullWidth: false
        ),
        TourStep(
            title: "Label what each image shows",
            body: "Each image gets a title and a role. Observed is what you see now. Expected is what it should look like. Reference is a mockup or design file. These labels carry into the prompt so the AI knows which image is which.",
            buttonLabel: "Next",
            isFullWidth: false
        ),
        TourStep(
            title: "You're all set",
            body: "Capture what you see. Annotate what matters. Copy the result. Paste it into your AI tool. That's the whole workflow. Press \u{2318}\u{21E7}6 anytime to start.",
            buttonLabel: "Got it",
            isFullWidth: true
        ),
    ]
}
