//
//  StationNetwork.swift
//  DDaRa
//
//  Created by 이정환 on 2022/12/21.
//

import Foundation
import Moya
import RxSwift

protocol SearchStationsUseCase {
    func getStationList() -> Single<Result<StationList.Response, NetworkError>>
    func getJsonToUrl(of urlString: String) -> Single<Result<URL?, NetworkError>>
    func getStringToUrl(of urlString: String) -> Single<Result<URL?, NetworkError>>
    func validStreamURL(of urlString: String) -> Single<Result<URL?, NetworkError>>
}

class NetworkService: SearchStationsUseCase {
    private let provider = MoyaProvider<StationAPI>()
    private let session: URLSession
    private let disposeBag = DisposeBag()
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func getStationList() -> Single<Result<StationList.Response, NetworkError>> {
        return provider.rx.request(.getStations)
            .map(StationList.Response.self)
            .map { data in
                return .success(data)
            }
            .catch { _ in
                return .just(Result.failure(NetworkError.networkError))
            }
    }
    
    func getJsonToUrl(of urlString: String) -> Single<Result<URL?, NetworkError>> {
        guard let url = URL(string: urlString) else {
            return .just(.failure(NetworkError.invalidURL))
        }
        
        return provider.rx.request(.getJsonToUrl(of: url))
            .map(TerrestrialApi.self)
            .map { terrestrialURL in
                guard let urlString = terrestrialURL.channelItem.first?.serviceUrl else {
                    return .failure(NetworkError.invalidJSON)
                }
                return .success(URL(string: urlString))
            }
            .catch { _ in
                return .just(Result.failure(NetworkError.apiError))
            }
    }
    
    func getStringToUrl(of urlString: String) -> Single<Result<URL?, NetworkError>> {
        guard let url = URL(string: urlString) else {
            return .just(.failure(NetworkError.invalidURL))
        }
        
        return provider.rx.request(.getJsonToUrl(of: url))
        map { data in
            
        }
        
        return session.rx.data(request: request as URLRequest)
            .map { data in
                let convertValue = String(decoding: data, as: UTF8.self).split(whereSeparator: \.isNewline)
                for i in 0..<convertValue.count {
                    if convertValue[i].contains("File1=") {
                        let urlString = convertValue[1].components(separatedBy: "File1=").joined()
                        return .success(URL(string: urlString))
                    }
                }
                return .failure(NetworkError.invalidJSON)
            }
            .catch { _ in
                return .just(Result.failure(NetworkError.apiError))
            }
            .asSingle()
    }
    
    func validStreamURL(of urlString: String) -> Single<Result<URL?, NetworkError>> {
        guard let url = URL(string: urlString) else {
            return .just(.failure(NetworkError.invalidStreamURL))
        }
        
        if UIApplication.shared.canOpenURL(url) {
            return .just(Result.success(url))
        } else {
            return .just(Result.failure(NetworkError.invalidStreamURL))
        }
    }
    
}
