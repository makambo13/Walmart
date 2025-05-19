//
//  Service.swift
//  walmart
//
//  Created by Makambo Yemomo on 5/15/25.
//

import Foundation

import Foundation

protocol NetworkServiceProtocol {
    func request<T: Codable>(with type: RequestType, completion: @escaping (Result<T, CustomError>) -> Void)
}

enum HttpMethod: String {
    case GET
    case POST
}

enum RequestType {
    case getCountryList
    
    var endPoint: String {
        switch self {
        case .getCountryList:
            return "/peymano-wmt/32dcb892b06648910ddd40406e37fdab/raw/db25946fd77c5873b0303b858e861ce724e0dcd0/"
        }
    }
    
    var httpMethod: HttpMethod {
        switch self {
        case .getCountryList:
            return .GET
        }
    }
}

struct NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://gist.githubusercontent.com"
    
    func request<T: Codable>(with type: RequestType, completion: @escaping (Result<T, CustomError>) -> Void) {
        guard let url = URL(string: baseURL + type.endPoint) else {return}
        
        var req = URLRequest(url: url)
        req.httpMethod = type.httpMethod.rawValue
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(CustomError(message: "Network error: \(error.localizedDescription)")))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(CustomError(message: "Invalid response format")))
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(CustomError(message: "HTTP Error: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(CustomError(message: "No data received")))
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let json = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(json))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(CustomError(message: "decoding error")))
                }
            }
        }.resume()
    }
}


struct CustomError: Error {
    let message: String
}
