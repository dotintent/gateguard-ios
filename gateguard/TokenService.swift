//
//  TokenService.swift
//  gateguard
//
//  Created by Sławek Peszke on 04/12/2017.
//  Copyright © 2017 inFullMobile. All rights reserved.
//

import Foundation


protocol TokenService {
    func getToken(with id: Int, completion: @escaping (Result<Token>) -> Void)
    func register(token: Token, completion: @escaping (Result<Void>) -> Void)
}


final class TokenServiceImpl: TokenService {
    
    // MARK: Properties
    
    let httpClient: HttpClient

    // MARK: Init
    
    init(httpClient: HttpClient = HttpClientImpl()) {
        self.httpClient = httpClient
    }

    // MARK: TokenService implementation
    
    func getToken(with id: Int, completion: @escaping (Result<Token>) -> Void) {
        httpClient.request(for: .token, parameters: ["id": id], method: .get) { (_ result) in
            switch result {
            case .success(let data):
                guard let token = try? JSONDecoder().decode(Token.self, from: data) else {
                    return completion(.error(GateGuardError.corruptedData))
                }
                completion(.success(token))

            case .error(let error):
                completion(.error(error))
            }
        }
    }
    
    func register(token: Token, completion: @escaping (Result<Void>) -> Void) {
        httpClient.request(for: .registerToken, parameters: ["id": token.id, "token": token.uuid.uuidString], method: .post) { (_ result) in
            switch result {
            case .success(_):
                completion(.success(Void()))
            case .error(let error):
                completion(.error(error))
            }
        }
    }
}
