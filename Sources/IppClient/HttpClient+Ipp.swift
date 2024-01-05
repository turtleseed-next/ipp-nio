import AsyncAlgorithms
import AsyncHTTPClient
import IppProtocol
import NIOCore

public extension HTTPClient {
    /// Executes an IPP request and returns the response.
    /// - Parameter request: The IPP request to execute.
    /// - Parameter data: The data to send with the request.
    ///
    /// - Returns: The IPP response.
    func execute(_ request: IppRequest, data: consuming HTTPClientRequest.Body? = nil, timeout: TimeAmount = .seconds(10)) async throws -> IppResponse {
        let httpRequest = try HTTPClientRequest(ippRequest: request, data: data)
        let httpResponse = try await execute(httpRequest, timeout: timeout)

        if httpResponse.status != .ok {
            throw IppHttpResponseError(response: httpResponse)
        }

        var buffer = try await httpResponse.body.collect(upTo: 20 * 1024)
        return try IppResponse(buffer: &buffer)
    }
}

public extension HTTPClientRequest {
    /// Creates a HTTP by encoding the IPP request and attaching the data if provided.
    init(ippRequest: IppRequest, data: consuming Body? = nil) throws {
        self.init(url: try ippRequest.validatedHttpTargetUrl)
        method = .POST
        headers.add(name: "content-type", value: "application/ipp")
        // TODO: auth

        // maybe pre-size this thing somehow?
        var buffer = ByteBuffer()
        ippRequest.write(to: &buffer)

        if let data {
            // TODO: check out if this is so great - it would be nice know the length
            body = .stream(chain([buffer].async, data), length: .unknown)
        } else {
            body = .bytes(buffer)
        }
    }
}

/// Represents the error when an IPP request fails with a HTTP response that is not 200 OK.
public struct IppHttpResponseError: Error, CustomStringConvertible {
    public let response: HTTPClientResponse

    public var description: String {
        "IPP request failed with response status \(response.status): \(response)"
    }
}
