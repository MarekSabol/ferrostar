import XCTest
@testable import FerrostarCore

final class MockURLSessionTests: XCTestCase {
    func testUninitializedSession() async throws {
        let session = MockURLSession()
        do {
            _ = try await session.loadData(with: URLRequest(url: URL(string: "https://example.com/")!))
            XCTFail("Expected an error")
        } catch MockURLSessionError.noResponseMockForMethodAndURL {
            // Expected failure
        }
    }

    func testMockedURL() async throws {
        let url = URL(string: "https://example.com/registered")!
        let mockData = Data("foobar".utf8)
        let mockResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!

        let session = MockURLSession()

        session.registerMock(forMethod: "GET", andURL: url, withData: mockData, andResponse: mockResponse)

        let (data, response) = try await session.loadData(with: URLRequest(url: url))
        XCTAssertEqual(data, mockData)
        XCTAssertEqual(response, mockResponse)

        do {
            _ = try await session.loadData(with: URLRequest(url: URL(string: "https://example.com/unregistered")!))
            XCTFail("Expected an error")
        } catch MockURLSessionError.noResponseMockForMethodAndURL {
            // Expected failure
        }
    }
    
    func testMultipleMocks() async throws {
            let url1 = URL(string: "https://example.com/multiple1")!
            let url2 = URL(string: "https://example.com/multiple2")!
            
            let mockData1 = Data("data1".utf8)
            let mockData2 = Data("data2".utf8)
            
            let mockResponse1 = HTTPURLResponse(url: url1, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            let mockResponse2 = HTTPURLResponse(url: url2, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
            
            let session = MockURLSession()
            
            session.registerMock(forMethod: "GET", andURL: url1, withData: mockData1, andResponse: mockResponse1)
            session.registerMock(forMethod: "GET", andURL: url2, withData: mockData2, andResponse: mockResponse2)
            
            let (data1, response1) = try await session.loadData(with: URLRequest(url: url1))
            XCTAssertEqual(data1, mockData1)
            XCTAssertEqual(response1, mockResponse1)
            
            let (data2, response2) = try await session.loadData(with: URLRequest(url: url2))
            XCTAssertEqual(data2, mockData2)
            XCTAssertEqual(response2, mockResponse2)
        }
        
        // Test that different HTTP headers in request don't affect the mock retrieval
        func testMockIgnoringHeaders() async throws {
            let url = URL(string: "https://example.com/headers")!
            let mockData = Data("headerTest".utf8)
            let mockResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            
            let session = MockURLSession()
            session.registerMock(forMethod: "GET", andURL: url, withData: mockData, andResponse: mockResponse)
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await session.loadData(with: request)
            XCTAssertEqual(data, mockData)
            XCTAssertEqual(response, mockResponse)
        }
}
