//
//  Error.swift
//  Flamingo 1.0
//
//  Created by Ilya Kulebyakin on 9/15/17.
//  Copyright © 2017 e-Legion. All rights reserved.
//

import Foundation

public enum Error: Swift.Error, LocalizedError {

    /// The underlying reason the response validation error occurred.
    ///
    /// - missingContentType:      The response did not contain a `Content-Type` and the `acceptableContentTypes`
    ///                            provided did not contain wildcard type.
    /// - unacceptableContentType: The response `Content-Type` did not match any type in the provided
    ///                            `acceptableContentTypes`.
    /// - unacceptableStatusCode:  The response status code was not acceptable.
    public enum ResponseValidationFailureReason: CustomStringConvertible {
        case missingContentType(acceptableContentTypes: [String])
        case unacceptableContentType(acceptableContentTypes: [String], responseContentType: String)
        case unacceptableStatusCode(code: Int)

        public var description: String {
            switch self {
            case .missingContentType(acceptableContentTypes: let types):
                return "Missing content type. Expected: \(types)"
            case .unacceptableContentType(acceptableContentTypes: let acceptable, responseContentType: let resonseType):
                return "Unacceptable content type. Expected: \(acceptable). Got \(resonseType)"
            case .unacceptableStatusCode(code: let code):
                return "Unacceptable status code \(code)"
            }
        }
    }

    public enum ParametersEncodingErrorReason: CustomStringConvertible {
        case jsonEncodingFailed(Swift.Error)
        case unableToRetrieveRequestURL
        case unableToAssembleURLAfterAddingURLQueryItems

        public var description: String {
            switch self {
            case .jsonEncodingFailed(let error):
                return "Json encoding failed. Error: \(error)"
            case .unableToRetrieveRequestURL:
                return "Unable to retrieve request URL"
            case .unableToAssembleURLAfterAddingURLQueryItems:
                return "Unable to assemble URL after adding URL query items"
            }
        }
    }
    
    case invalidRequest
    case unableToRetrieveDataAndError
    case unableToRetrieveHTTPResponse
    case parametersEncodingError(ParametersEncodingErrorReason)
    case responseValidationFailed(reason: ResponseValidationFailureReason)

    public var localizedDescription: String {
        switch self {
        case .invalidRequest:
            return "Invalid request"
        case .unableToRetrieveDataAndError:
            return "Unable to retrieve data and error"
        case .unableToRetrieveHTTPResponse:
            return "Unable to retrieve HTTP response"
        case .parametersEncodingError(let reason):
            return "Parameters encoding error. \(reason)"
        case .responseValidationFailed(reason: let reason):
            return "Response validation failed. \(reason)"
        }
    }

    public var errorDescription: String? {
        return localizedDescription
    }
}
