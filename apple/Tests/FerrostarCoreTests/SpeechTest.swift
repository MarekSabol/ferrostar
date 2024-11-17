import AVFoundation
import XCTest
@testable import FerrostarCore
import FerrostarCoreFFI


class MockAVSpeechSynthesizer: AVSpeechSynthesizer {
    var speakCalled = false
    var stopSpeakingCalled = false

    override func speak(_ utterance: AVSpeechUtterance) {
        speakCalled = true
    }

    override func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        stopSpeakingCalled = true
        return true
    }
}

extension FerrostarCoreTests {
    func testSpokenInstructionTriggered_whenNotMuted_speaksInstruction() {
        let mockSynthesizer = MockAVSpeechSynthesizer()
        let observer = AVSpeechSpokenInstructionObserver(isMuted: false)
        observer.synthesizer = mockSynthesizer

        let instruction = SpokenInstruction(
            text: "Turn left in 200 meters",
            ssml: nil,
            triggerDistanceBeforeManeuver: 0,
            utteranceId: UUID()  // Use UUID for `utteranceId`
        )
        observer.spokenInstructionTriggered(instruction)

        XCTAssertTrue(mockSynthesizer.speakCalled, "Expected synthesizer to speak when not muted")
    }

    func testSpokenInstructionTriggered_whenMuted_doesNotSpeakInstruction() {
        let mockSynthesizer = MockAVSpeechSynthesizer()
        let observer = AVSpeechSpokenInstructionObserver(isMuted: true)
        observer.synthesizer = mockSynthesizer

        let instruction = SpokenInstruction(
            text: "Turn right in 100 meters",
            ssml: nil,
            triggerDistanceBeforeManeuver: 0,
            utteranceId: UUID()  // Use UUID for `utteranceId`
        )
        observer.spokenInstructionTriggered(instruction)

        XCTAssertFalse(mockSynthesizer.speakCalled, "Expected synthesizer not to speak when muted")
    }

    func testStopAndClearQueue_stopsSpeakingImmediately() {
        let mockSynthesizer = MockAVSpeechSynthesizer()
        let observer = AVSpeechSpokenInstructionObserver(isMuted: false)
        observer.synthesizer = mockSynthesizer

        observer.stopAndClearQueue()

        XCTAssertTrue(mockSynthesizer.stopSpeakingCalled, "Expected synthesizer to stop speaking immediately")
    }


}
