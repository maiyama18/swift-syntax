// This test file has been translated from swift/test/Parse/brace_recovery_eof.swift

import XCTest

final class BraceRecoveryEofTests: XCTestCase {
  func testBraceRecoveryEof1() {
    AssertParse(
      """
      // Make sure source ranges satisfy the verifier.
      for foo in [1, 2] { 
        _ = foo#^DIAG^#
      """,
      diagnostics: [
        // TODO: Old parser expected note on line 2: to match this opening '{'
        DiagnosticSpec(message: "expected '}' to end 'for' statement"),
        // TODO: Old parser expected error on line 4: expected '}' at end of brace statement
      ]
    )
  }

}
