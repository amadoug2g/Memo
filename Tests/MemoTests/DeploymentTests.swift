import XCTest
import Foundation

/// Validates the app bundle structure and deployment assumptions.
///
/// macOS launch requirements on modern versions (Ventura+):
///   - `open Foo.app` requires a valid code signature (ad-hoc is fine)
///   - Unsigned binaries get "Launchd job spawn failed" (POSIX error 163)
///   - Ad-hoc signing changes CDHash on each rebuild, which invalidates
///     Accessibility (TCC) entries. This is an accepted trade-off: the
///     session-level cache in AppDelegate avoids repeated prompts within
///     a running session, and unchanged rebuilds keep the same CDHash.
final class DeploymentTests: XCTestCase {

    private let fm = FileManager.default
    private lazy var projectRoot: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // MemoTests/
            .deletingLastPathComponent()  // Tests/
            .deletingLastPathComponent()  // project root
    }()

    private lazy var bundlePath: URL = projectRoot.appendingPathComponent("Memo.app")
    private lazy var binaryPath: URL = bundlePath
        .appendingPathComponent("Contents/MacOS/Memo")
    private lazy var plistPath: URL = bundlePath
        .appendingPathComponent("Contents/Info.plist")

    // MARK: - Bundle structure

    func test_appBundle_exists() throws {
        try XCTSkipUnless(
            fm.fileExists(atPath: bundlePath.path),
            "Memo.app not built yet — run ./run.sh first"
        )
    }

    func test_appBundle_hasBinary() throws {
        try XCTSkipUnless(fm.fileExists(atPath: binaryPath.path), "Binary not built yet")
        XCTAssertTrue(
            fm.isExecutableFile(atPath: binaryPath.path),
            "Memo.app/Contents/MacOS/Memo must exist and be executable"
        )
    }

    func test_appBundle_hasInfoPlist() throws {
        try XCTSkipUnless(fm.fileExists(atPath: bundlePath.path), "Memo.app not built yet")
        XCTAssertTrue(
            fm.fileExists(atPath: plistPath.path),
            "Memo.app/Contents/Info.plist must exist"
        )
    }

    func test_infoPlist_hasRequiredKeys() throws {
        try XCTSkipUnless(fm.fileExists(atPath: plistPath.path), "Info.plist not found")

        let data = try Data(contentsOf: plistPath)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        let dict = try XCTUnwrap(plist as? [String: Any])

        XCTAssertEqual(dict["CFBundleIdentifier"] as? String, "com.amadoug2g.memo")
        XCTAssertEqual(dict["CFBundleName"] as? String, "Memo")
        XCTAssertEqual(dict["CFBundleExecutable"] as? String, "Memo")
        XCTAssertEqual(dict["LSUIElement"] as? Bool, true,
            "LSUIElement must be true for a menu-bar-only app")
        XCTAssertNotNil(dict["NSMicrophoneUsageDescription"],
            "Microphone usage description is required for recording")
    }

    // MARK: - Code signing (must be ad-hoc signed to launch)

    func test_binary_isAdHocSigned() throws {
        try XCTSkipUnless(fm.fileExists(atPath: binaryPath.path), "Binary not built yet")

        // On modern macOS, `open Foo.app` REQUIRES a code signature.
        // Unsigned binaries fail with "Launchd job spawn failed" (POSIX 163).
        // Ad-hoc signing (`codesign --force --sign -`) satisfies this requirement.
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["--verify", "--strict", bundlePath.path]
        let pipe = Pipe()
        task.standardError = pipe
        try task.run()
        task.waitUntilExit()

        XCTAssertEqual(task.terminationStatus, 0,
            "Memo.app must be code-signed (ad-hoc) to launch on modern macOS. " +
            "Unsigned binaries get POSIX error 163. " +
            "run.sh must use: codesign --force --sign - Memo.app")
    }

    func test_runScript_adHocSigns() throws {
        let runSh = projectRoot.appendingPathComponent("run.sh")
        let content = try String(contentsOf: runSh, encoding: .utf8)

        // run.sh MUST ad-hoc sign the bundle so `open` works.
        XCTAssertTrue(
            content.contains("codesign --force --sign -"),
            "run.sh must ad-hoc sign the app bundle. Without this, " +
            "`open Memo.app` fails with 'Launchd job spawn failed'."
        )

        // It must NOT strip the signature (that was the old broken approach).
        XCTAssertFalse(
            content.contains("codesign --remove-signature"),
            "run.sh must NOT strip the code signature — unsigned apps " +
            "cannot launch on modern macOS (POSIX error 163)."
        )
    }

    func test_runScript_onlyResignsWhenBinaryChanged() throws {
        let runSh = projectRoot.appendingPathComponent("run.sh")
        let content = try String(contentsOf: runSh, encoding: .utf8)

        // CRITICAL for UX: re-signing on every run invalidates the Accessibility
        // TCC entry (CDHash changes), forcing the user to re-grant every launch.
        // The script must compare binaries and only re-sign when code changed.
        XCTAssertTrue(
            content.contains("cmp -s"),
            "run.sh must compare binaries with `cmp -s` and skip re-signing " +
            "when the binary is unchanged. Re-signing every run invalidates " +
            "the Accessibility TCC entry and forces repeated permission prompts."
        )
    }

    func test_runScript_launchesFromProjectDirectory() throws {
        let runSh = projectRoot.appendingPathComponent("run.sh")
        let content = try String(contentsOf: runSh, encoding: .utf8)

        XCTAssertTrue(
            content.contains("open \"$BUNDLE\""),
            "run.sh should launch the local Memo.app bundle"
        )

        // Must NOT try to copy to /Applications (would need proper signing)
        XCTAssertFalse(
            content.contains("/Applications"),
            "run.sh must not deploy to /Applications for dev builds"
        )
    }

    // MARK: - Script basics

    func test_runScript_exists_and_isExecutable() {
        let runSh = projectRoot.appendingPathComponent("run.sh")
        XCTAssertTrue(fm.fileExists(atPath: runSh.path), "run.sh must exist")
        XCTAssertTrue(fm.isExecutableFile(atPath: runSh.path), "run.sh must be executable")
    }

    func test_runScript_killsExistingInstance() throws {
        let runSh = projectRoot.appendingPathComponent("run.sh")
        let content = try String(contentsOf: runSh, encoding: .utf8)

        XCTAssertTrue(
            content.contains("pkill -x \"$APP_NAME\"") || content.contains("pkill -x Memo"),
            "run.sh must kill any running Memo instance before relaunching"
        )
    }
}
