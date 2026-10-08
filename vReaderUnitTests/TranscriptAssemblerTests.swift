import XCTest
@testable import vReader

final class TranscriptAssemblerTests: XCTestCase {
    func testPartialRevisionAndFinalizationDoNotDuplicate() {
        let run = UUID()
        var assembler = TranscriptAssembler()
        _ = assembler.apply(.init(runID: run, start: 0, end: 1, text: "Hello", isFinal: false))
        _ = assembler.apply(.init(runID: run, start: 0, end: 2, text: "Hello world", isFinal: false))
        XCTAssertEqual(assembler.partial.count, 1)
        _ = assembler.apply(.init(runID: run, start: 0, end: 2, text: "Hello world.", isFinal: true))
        _ = assembler.apply(.init(runID: run, start: 0, end: 2, text: "Hello world.", isFinal: true))
        XCTAssertTrue(assembler.partial.isEmpty)
        XCTAssertEqual(assembler.finalized.count, 1)
        XCTAssertEqual(assembler.text, "Hello world.")
    }

    func testRepeatedWordsInDistinctRangesAreRetained() {
        let run = UUID()
        var assembler = TranscriptAssembler()
        _ = assembler.apply(.init(runID: run, start: 0, end: 1, text: "Yes.", isFinal: true))
        _ = assembler.apply(.init(runID: run, start: 1, end: 2, text: "Yes.", isFinal: true))
        XCTAssertEqual(assembler.finalized.count, 2)
    }

    func testResumeRunWithResetTimestampDoesNotEraseEarlierSpeech() {
        var assembler = TranscriptAssembler()
        _ = assembler.apply(.init(runID: UUID(), start: 0, end: 1, text: "Before", isFinal: true))
        _ = assembler.apply(.init(runID: UUID(), start: 0, end: 1, text: "After", isFinal: true))
        XCTAssertEqual(assembler.text, "Before\nAfter")
    }

    func testInvalidRangesAndLatePartialCannotOverwriteFinal() {
        let run = UUID()
        var assembler = TranscriptAssembler()
        _ = assembler.apply(.init(runID: run, start: 0, end: 1, text: "Final", isFinal: true))
        _ = assembler.apply(.init(runID: run, start: 0, end: 1, text: "Old", isFinal: false))
        _ = assembler.apply(.init(runID: run, start: .nan, end: 2, text: "Invalid", isFinal: true))
        XCTAssertEqual(assembler.text, "Final")
        XCTAssertTrue(assembler.partial.isEmpty)
    }
}
