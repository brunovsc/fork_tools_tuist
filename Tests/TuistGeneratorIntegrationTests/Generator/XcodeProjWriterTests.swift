
import FileSystem
import Foundation
import Path
import TuistCore
import TuistGeneratorTesting
import TuistSupport
import XcodeProj
import XCTest
@testable import TuistGenerator
@testable import TuistSupportTesting

final class XcodeProjWriterTests: TuistTestCase {
    private var subject: XcodeProjWriter!
    private var fileSystem: FileSysteming!

    override func setUp() {
        super.setUp()
        subject = XcodeProjWriter()
        fileSystem = FileSystem()
    }

    override func tearDown() {
        fileSystem = nil
        subject = nil
        super.tearDown()
    }

    func test_writeProject() async throws {
        // Given
        let path = try temporaryPath()
        let xcodeProjPath = path.appending(component: "Project.xcodeproj")
        let descriptor = ProjectDescriptor.test(path: path, xcodeprojPath: xcodeProjPath)

        // When
        try await subject.write(project: descriptor)

        // Then
        let exists = try await fileSystem.exists(xcodeProjPath)
        XCTAssertTrue(exists)
    }

    func test_writeProject_fileSideEffects() async throws {
        // Given
        let path = try temporaryPath()
        let xcodeProjPath = path.appending(component: "Project.xcodeproj")
        let filePath = path.appending(component: "MyFile")
        let contents = "Testing".data(using: .utf8)!
        let sideEffect = SideEffectDescriptor.file(.init(
            path: filePath,
            contents: contents
        ))
        let descriptor = ProjectDescriptor.test(
            path: path,
            xcodeprojPath: xcodeProjPath,
            sideEffects: [sideEffect]
        )

        // When
        try await subject.write(project: descriptor)

        // Then
        let fileHandler = FileHandler.shared
        XCTAssertTrue(fileHandler.exists(filePath))
        XCTAssertEqual(try fileHandler.readFile(filePath), contents)
    }

    func test_writeProject_deleteFileSideEffects() async throws {
        // Given
        let path = try temporaryPath()
        let xcodeProjPath = path.appending(component: "Project.xcodeproj")
        let filePath = path.appending(component: "MyFile")
        let fileHandler = FileHandler.shared
        try fileHandler.touch(filePath)

        let sideEffect = SideEffectDescriptor.file(FileDescriptor(path: filePath, state: .absent))
        let descriptor = ProjectDescriptor.test(
            path: path,
            xcodeprojPath: xcodeProjPath,
            sideEffects: [sideEffect]
        )

        // When
        try await subject.write(project: descriptor)

        // Then
        XCTAssertFalse(fileHandler.exists(filePath))
    }

    func test_generate_doesNotWipeUserData() async throws {
        // Given
        let path = try temporaryPath()
        let paths = try createFiles([
            "Foo.xcodeproj/xcuserdata/a",
            "Foo.xcodeproj/xcuserdata/b/c",
        ])

        let xcodeProjPath = path.appending(component: "Foo.xcodeproj")
        let descriptor = ProjectDescriptor.test(
            path: path,
            xcodeprojPath: xcodeProjPath
        )

        // When
        for _ in 0 ..< 2 {
            try await subject.write(project: descriptor)
        }

        // Then
        let exists = try await paths.concurrentMap { try await self.fileSystem.exists($0) }
        XCTAssertTrue(exists.allSatisfy { $0 })
    }

    func test_generate_replacesProjectSharedSchemes() async throws {
        // Given
        let path = try temporaryPath()
        let xcodeProjPath = path.appending(component: "Project.xcodeproj")
        let schemeA = SchemeDescriptor.test(name: "SchemeA", shared: true)
        let schemeB = SchemeDescriptor.test(name: "SchemeB", shared: true)
        let schemeC = SchemeDescriptor.test(name: "SchemeC", shared: true)

        let schemesWriteOperations = [
            [schemeA, schemeB],
            [schemeA, schemeC],
        ]

        // When
        for schemes in schemesWriteOperations {
            let descriptor = ProjectDescriptor.test(
                path: path,
                xcodeprojPath: xcodeProjPath,
                schemes: schemes
            )
            try await subject.write(project: descriptor)
        }

        // Then
        let fileHandler = FileHandler.shared
        let schemes = fileHandler.glob(xcodeProjPath, glob: "**/*.xcscheme").map(\.basename)
        XCTAssertEqual(schemes, [
            "SchemeA.xcscheme",
            "SchemeC.xcscheme",
        ])
    }

    func test_generate_preservesProjectUserSchemes() async throws {
        // Given
        let path = try temporaryPath()
        let xcodeProjPath = path.appending(component: "Project.xcodeproj")
        let userSchemeA = SchemeDescriptor.test(name: "UserSchemeA", shared: false)
        let userSchemeB = SchemeDescriptor.test(name: "UserSchemeB", shared: false)

        let schemesWriteOperations = [
            [userSchemeA],
            [userSchemeB],
        ]

        // When
        for schemes in schemesWriteOperations {
            let descriptor = ProjectDescriptor.test(
                path: path,
                xcodeprojPath: xcodeProjPath,
                schemes: schemes
            )
            try await subject.write(project: descriptor)
        }

        // Then
        let fileHandler = FileHandler.shared
        let schemes = fileHandler.glob(xcodeProjPath, glob: "**/*.xcscheme").map(\.basename)
        XCTAssertEqual(schemes, [
            "UserSchemeA.xcscheme",
            "UserSchemeB.xcscheme",
        ])
    }

    func test_generate_replacesWorkspaceSharedSchemes() async throws {
        // Given
        let path = try temporaryPath()
        let xcworkspacePath = path.appending(component: "Workspace.xcworkspace")
        let schemeA = SchemeDescriptor.test(name: "SchemeA", shared: true)
        let schemeB = SchemeDescriptor.test(name: "SchemeB", shared: true)
        let schemeC = SchemeDescriptor.test(name: "SchemeC", shared: true)

        let schemesWriteOperations = [
            [schemeA, schemeB],
            [schemeA, schemeC],
        ]

        // When
        for schemes in schemesWriteOperations {
            let descriptor = WorkspaceDescriptor.test(
                path: path,
                xcworkspacePath: xcworkspacePath,
                schemes: schemes
            )
            try await subject.write(workspace: descriptor)
        }

        // Then
        let fileHandler = FileHandler.shared
        let schemes = fileHandler.glob(xcworkspacePath, glob: "**/*.xcscheme").map(\.basename)
        XCTAssertEqual(schemes, [
            "SchemeA.xcscheme",
            "SchemeC.xcscheme",
        ])
    }

    func test_generate_preservesWorkspaceUserSchemes() async throws {
        // Given
        let path = try temporaryPath()
        let xcworkspacePath = path.appending(component: "Workspace.xcworkspace")
        let userSchemeA = SchemeDescriptor.test(name: "UserSchemeA", shared: false)
        let userSchemeB = SchemeDescriptor.test(name: "UserSchemeB", shared: false)

        let schemesWriteOperations = [
            [userSchemeA],
            [userSchemeB],
        ]

        // When
        for schemes in schemesWriteOperations {
            let descriptor = WorkspaceDescriptor.test(
                path: path,
                xcworkspacePath: xcworkspacePath,
                schemes: schemes
            )
            try await subject.write(workspace: descriptor)
        }

        // Then
        let fileHandler = FileHandler.shared
        let schemes = fileHandler.glob(xcworkspacePath, glob: "**/*.xcscheme").map(\.basename)
        XCTAssertEqual(schemes, [
            "UserSchemeA.xcscheme",
            "UserSchemeB.xcscheme",
        ])
    }

    func test_generate_local_scheme() async throws {
        // Given
        let path = try temporaryPath()
        let xcodeProjPath = path.appending(component: "Project.xcodeproj")
        let userScheme = SchemeDescriptor.test(name: "UserScheme", shared: false)
        let descriptor = ProjectDescriptor.test(path: path, xcodeprojPath: xcodeProjPath, schemes: [userScheme])

        // When
        try await subject.write(project: descriptor)

        // Then
        let fileHandler = FileHandler.shared
        let username = NSUserName()
        let schemesPath = xcodeProjPath.appending(components: "xcuserdata", "\(username).xcuserdatad", "xcschemes")
        let schemes = fileHandler.glob(schemesPath, glob: "*.xcscheme").map(\.basename)
        XCTAssertEqual(schemes, [
            "UserScheme.xcscheme",
        ])
    }
}
