//
//  HttpClient.swift
//  gateguard
//
//  Created by Sławek Peszke on 04/12/2017.
//  Copyright © 2017 inFullMobile. All rights reserved.
//

import Foundation


enum HttpRequestMethod: String {
    case get = "GET"
    case post = "POST"
}


enum ServiceEndpoint {
    case token
    case registerToken
}


protocol HttpClient {
    typealias RequestParameters = [String: Any]
    typealias JsonResponse = [String: Any]
    
    func request(for endpoint: ServiceEndpoint,
                 parameters: RequestParameters,
                 method: HttpRequestMethod,
                 completion: @escaping (Result<Data>) -> Void)
}


class HttpClientImpl: HttpClient {
    func request(for endpoint: ServiceEndpoint,
                 parameters: HttpClient.RequestParameters,
                 method: HttpRequestMethod,
                 completion: @escaping (Result<Data>) -> Void) {
        
        let request = URLRequest.urlRequest(with: endpoint.url, method: method, parameters: parameters)
        
        
        let session = URLSession.defaultSession()
        
        let task = session.dataTask(with:request, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    completion(.success(data))
                } else if let response = response as? HTTPURLResponse, response.statusCode == 204 {
                    completion(.error(GateGuardError.noData))
                } else if let error = error {
                    completion(.error(error))
                } else {
                    completion(.error(GateGuardError.unknown))
                }
            }
        })
        
        task.resume()
    }
}

// MARK: Extensions

extension URL {
    static let gateGuardHost = URL(string: "https://gateguard.herokuapp.com")!
}

extension URLSession {
    static func defaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = nil
        configuration.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = false
        }

        return URLSession(configuration: configuration)
    }
}

extension URLRequest {
    static func urlRequest(with url: URL, method: HttpRequestMethod = .get, parameters: HttpClient.RequestParameters = [:]) -> URLRequest {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { fatalError() }
        
        var request: URLRequest
        switch method {
        case .get:
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0, value: "\($1)") }
            request = URLRequest(url: urlComponents.url ?? url)
        case .post:
            request = URLRequest(url: url)
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }

        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }
}

// MARK: Extensions

extension ServiceEndpoint {
    var url: URL {
        switch self {
        case .token:
            return URL.gateGuardHost.appendingPathComponent("token")
        case .registerToken:
            return URL.gateGuardHost.appendingPathComponent("register-token")
        }
    }
}
