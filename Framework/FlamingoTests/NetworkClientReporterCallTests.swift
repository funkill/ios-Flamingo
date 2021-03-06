//
//  NetworkClientReporterCallTests.swift
//  FlamingoTests
//
//  Created by Nikolay Ischuk on 23.01.2018.
//  Copyright © 2018 ELN. All rights reserved.
//

import Foundation
import XCTest
import Flamingo

private class MockLogger: Logger {
    private(set) var logSended: Bool = false

    public func log(_ message: String, context: [String: Any]?) {
        self.logSended = true
    }
}

private class MockReporter: LoggingClient {
    var willSendCallClosure: (() -> Void)?
    private(set) var willSendCalled: Bool = false
    private(set) var didRecieveCalled: Bool = false

    override func willSendRequest<Request>(_ networkRequest: Request) where Request: NetworkRequest {
        willSendCalled = true
        willSendCallClosure?()
        super.willSendRequest(networkRequest)
    }

    override func didRecieveResponse<Request>(for request: Request, context: NetworkContext) where Request: NetworkRequest {
        didRecieveCalled = true
        super.didRecieveResponse(for: request, context: context)
    }
}

class NetworkClientReporterCallTests: XCTestCase {

    var client: NetworkClient!

    override func setUp() {
        super.setUp()
        let configuration = NetworkDefaultConfiguration(baseURL: "http://www.mocky.io/")
        client = NetworkDefaultClient(configuration: configuration, session: .shared)
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    func test_reporterCalls() {
        let logger1 = MockLogger()
        let reporter1 = MockReporter(logger: logger1)
        let reporter2 = MockReporter(logger: SimpleLogger(appName: #file))
        client.addReporter(reporter1, storagePolicy: .weak)
        client.addReporter(reporter2, storagePolicy: .weak)

        let asyncExpectation = expectation(description: #function)

        let request = RealFailedTestRequest()
        client.removeReporter(reporter2)
        client.sendRequest(request) {
            (_, _) in

            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) {
            (_) in

            XCTAssertTrue(reporter1.willSendCalled)
            XCTAssertTrue(reporter1.didRecieveCalled)
            XCTAssertFalse(reporter2.willSendCalled)
            XCTAssertFalse(reporter2.didRecieveCalled)
            XCTAssertTrue(logger1.logSended, "Logs are not sended")
        }
    }

    func test_storagePolicy() {
        var wasCalled1 = false
        var wasCalled2 = false
        var reporter1: MockReporter! = MockReporter(logger: SimpleLogger(appName: #file))
        var reporter2: MockReporter! = MockReporter(logger: SimpleLogger(appName: #file))
        let configuration = NetworkDefaultConfiguration(baseURL: "http://www.mocky.io/", parallel: false)
        let networkClient = NetworkDefaultClient(configuration: configuration, session: .shared)
        networkClient.addReporter(reporter1, storagePolicy: .weak)
        networkClient.addReporter(reporter2, storagePolicy: .strong)
        reporter1.willSendCallClosure = {
            wasCalled1 = true
        }
        reporter2.willSendCallClosure = {
            wasCalled2 = true
        }
        reporter1 = nil
        reporter2 = nil

        let stubRequest = StubRequest()
        networkClient.sendRequest(stubRequest, completionHandler: nil)
        XCTAssertFalse(wasCalled1)
        XCTAssertTrue(wasCalled2)
    }
}
