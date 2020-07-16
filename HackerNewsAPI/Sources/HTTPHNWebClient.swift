//
//  HTTPHNWebClient.swift
//  HackerNewsAPI
//
//  Created by Nicolas Gaulard-Querol on 16/07/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

public class HTTPHNWebClient {
    private let urlSession = URLSession(configuration: .default)

    private var userCookie: HTTPCookie? {
        guard
            let cookie = HTTPCookieStorage.shared.cookies(for: HNWebpage.login.path)?.last
        else {
            return nil
        }

        return cookie
    }

    public init() {}

    private func performLoginRequest(
        account: String,
        password: String,
        completion: @escaping HNWebResultCallback<Void>
    ) {
        var request = URLRequest(url: HNWebpage.login.path)
        request.httpMethod = "POST"
        request.httpBody = "acct=\(account)&pw=\(password)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .data(using: .utf8)
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        let dataTask = urlSession.dataTask(with: request) { data, response, error in
            let taskResult = self.validateResponse(data, response, error),
                authResult = taskResult.flatMap { _ in self.verifyLoginCookie() }

            completion(authResult)
        }

        dataTask.resume()
    }

    private func validateResponse(
        _ data: Data?,
        _ response: URLResponse?,
        _ error: Error?
    ) -> Result<Void, HNWebError> {
        switch (data, response as? HTTPURLResponse, error as NSError?) {
        case let (_, _, .some(error)) where error.code == NSURLErrorTimedOut:
            return .failure(.requestTimedOut)

        case let (_, _, .some(error)) where error.code == NSURLErrorUserAuthenticationRequired:
            return .failure(.missingAuthentication)

        case let (_, _, .some(error)):
            return .failure(.networkError(error))

        case let (_, .some(response), _) where response.statusCode != 200:
            return .failure(.invalidHTTPStatus(response.statusCode))

        case (_, .some, _):
            return .success(())

        default:
            return .failure(.unknown)
        }
    }

    private func verifyLoginCookie() -> HNWebResult<Void> {
        guard let cookie = userCookie else {
            return .failure(HNWebError.missingAuthentication)
        }

        guard
            cookie.domain == HNWebpage.login.path.host,
            cookie.path == "/",
            cookie.name == "user",
            cookie.value.split(separator: "&").count == 2
        else {
            return .failure(.invalidAuthentication)
        }

        if let expiry = cookie.expiresDate, Date() >= expiry {
            return .failure(.expiredAuthentication(expiry))
        }

        return .success(())
    }
}

// MARK: - HNWebClient

extension HTTPHNWebClient: HNWebClient {
    public func login(
        withAccount account: String,
        andPassword password: String,
        completion: @escaping HNWebResultCallback<Void>
    ) {
        if case .success = verifyLoginCookie() {
            completion(.success(()))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.performLoginRequest(account: account, password: password) { result in
                DispatchQueue.main.async { completion(result) }
            }
        }
    }

    public func logout(completion: @escaping HNWebResultCallback<Void>) {
        fatalError("Not implemented")
    }

    public func upvote(item: Int, completion: @escaping HNWebResultCallback<Void>) {
        fatalError("Not implemented")
    }

    public func downvote(item: Int, completion: @escaping HNWebResultCallback<Void>) {
        fatalError("Not implemented")
    }
}
