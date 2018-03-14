//
//  StubClientFactoryTestCase.swift
//  FlamingoTests
//
//  Created by Dmitrii Istratov on 03-10-2017.
//  Copyright © 2017 ELN. All rights reserved.
//

import XCTest
import Flamingo

private func expectedFileFor(_ name: String) -> String? {
    return Bundle(for: StubClientFactoryTestCase.self).path(forResource: name, ofType: nil)
}

class StubClientFactoryTestCase: XCTestCase {
    private var url: URL {
        return URL(string: "method") ?? URL(fileURLWithPath: "")
    }

    private var stub: ResponseStub {
        return ResponseStub(body: Data())
    }

    public func test_simpleCreateClient() {
        let client = StubsSessionFactory.session()

        XCTAssertNotNil(client)
    }

    public func test_createClientWithOneMethod_expectedClient() {
        let key = RequestStub(url: url, method: .get)
        let client = StubsSessionFactory.session(key, stub: stub)

        XCTAssertTrue(client.hasStub(key))
    }

    public func test_createClientWithDictionary_expectedClient() {
        let stubMethod = RequestStubMap(url: self.url, method: HTTPMethod.get, params: nil, responseStub: self.stub)
        let stubMethod2 = RequestStubMap(url: URL(fileURLWithPath: "\\"), method: HTTPMethod.post, params: ["wqe": 234],
                                         responseStub: self.stub)
        let client = StubsSessionFactory.session(with: [stubMethod, stubMethod2])

        XCTAssertTrue(client.hasStub(stubMethod.requestStub))
        XCTAssertTrue(client.hasStub(stubMethod2.requestStub))
    }

    public func test_createFromNotExistsFile_expectedException() {
        let expectedFileName = "not exists file"

        XCTAssertException(
            _ = try StubsSessionFactory.session(fromFile: expectedFileName),
            expectedError: StubError.stubClientFactoryError(.fileNotExists(expectedFileName))
        )
    }

    public func test_createFromFile_expectedClient() {
        guard let expectedFileName = expectedFileFor("StubsList.json") else {
            XCTFail(" ")
            return
        }

        do {
            let client = try StubsSessionFactory.session(fromFile: expectedFileName)
            XCTAssertNotNil(client)
        } catch {
            XCTFail("\(error)")
        }
    }

    public func test_stubsParsing() {
        guard let expectedFileName = expectedFileFor("StubsList.json") else {
            XCTFail(" ")
            return
        }

        do {
            let stubFile = try StubFile(fromFile: expectedFileName)
            XCTAssertEqual(stubFile.stubs[0].url.absoluteString, "/method/text")
            XCTAssertEqual(stubFile.stubs[0].method.rawValue, "POST")
            XCTAssertEqual(stubFile.stubs[0].responseStub.statusCode, StatusCodes.ok)
            XCTAssertEqual(stubFile.stubs[0].responseStub.headers, ["Content-Type": "plain/text",
                                                                    "Cache-control": "no-cache", ])
            XCTAssertEqual(stubFile.stubs[0].responseStub.body, "text".data(using: .utf8))
            XCTAssertEqual(stubFile.stubs[0].params?["some"] as? Int, 4545)
            XCTAssertEqual(stubFile.stubs[0].params?["keystring"] as? String, "string")
            XCTAssertEqual((stubFile.stubs[0].params?["array"] as? [Int]) ?? [], [1, 2, 3])
            XCTAssertEqual((stubFile.stubs[0].params?["dict"] as? [String: String]) ?? [:], ["1": "1", "2": "2"])
            if let arrayOfDict = stubFile.stubs[0].params?["array_of_dict"] as? [[String: String]] {
                XCTAssertEqual(arrayOfDict[0], ["1": "1"])
                XCTAssertEqual(arrayOfDict[1], ["2": "2"])
            } else {
                XCTFail(" ")
            }
            XCTAssertEqual(stubFile.stubs[0].params?["null"] as? NSNull, NSNull())

            XCTAssertEqual(stubFile.stubs[1].url.absoluteString, "/method/nottext")
            XCTAssertEqual(stubFile.stubs[1].method.rawValue, "GET")
            XCTAssertEqual(stubFile.stubs[1].responseStub.statusCode, StatusCodes.unauthorized)
            XCTAssertEqual(stubFile.stubs[1].responseStub.headers, ["Content-Type": "application/json",
                                                                    "Cache-control": "no-cache", ])
            XCTAssertEqual(stubFile.stubs[1].responseStub.body, "{\"haha\": value}".data(using: .utf8))

            XCTAssertEqual(stubFile.stubs[2].url.absoluteString, "/method/errormethod")
            XCTAssertEqual(stubFile.stubs[2].method.rawValue, "PUT")
            XCTAssertEqual(stubFile.stubs[2].responseStub.statusCode, StatusCodes.unauthorized)
            XCTAssertEqual(stubFile.stubs[2].responseStub.headers, ["Cache-control": "no-cache"])
            XCTAssertEqual(stubFile.stubs[2].responseStub.body, nil)
            XCTAssertEqual(stubFile.stubs[2].responseStub.error?.code, 123)
            XCTAssertEqual(stubFile.stubs[2].responseStub.error?.domain, "123123")
            XCTAssertEqual(stubFile.stubs[2].responseStub.error?.message, "Some error message")
        } catch {
            XCTFail("\(error)")
        }
    }

    public func test_mappingFromFileWithBadFormat_expectedClient() {
        guard let expectedFileName = expectedFileFor("WrongList.json") else {
            XCTFail(" ")
            return
        }

        do {
            _ = try StubsSessionFactory.session(fromFile: expectedFileName)
            XCTFail(" ")
        } catch {
            XCTAssertTrue(error is Swift.DecodingError)
        }
    }
}

public func XCTAssertException(_ closure: @autoclosure () throws -> Void,
                               expectedError: Swift.Error,
                               message: String? = nil) {
    do {
        try closure()
    } catch {
        let expectedNSError = expectedError as NSError
        let actualNSError = error as NSError

        XCTAssertEqual(expectedNSError, actualNSError)

        return
    }

    XCTFail("Expected exception \(expectedError) but exception not throwed")
}
