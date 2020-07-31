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
            let cookie = HTTPCookieStorage.shared
                .cookies(for: HNWebpage.login.path)?
                .last(where: isHNUserCookie)
        else {
            return nil
        }

        return cookie
    }

    public init() {}

    private func performLoginRequest(
        account: String,
        password: String,
        completion: @escaping HNWebResultCallback<String>
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
                authResult = taskResult.flatMap { _ in self.verifyHNUserCookie() }

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

    private func isHNUserCookie(_ cookie: HTTPCookie) -> Bool {
        cookie.name == "user"
            && cookie.domain == HNWebpage.login.path.host
            && cookie.path == "/"
    }

    private func verifyHNUserCookie() -> HNWebResult<String> {
        guard let cookie = userCookie else {
            return .failure(.missingAuthentication)
        }

        let userAndSignature = cookie.value.split(separator: "&")

        guard userAndSignature.count == 2 else {
            return .failure(.invalidAuthentication)
        }

        if let expiry = cookie.expiresDate, Date() >= expiry {
            return .failure(.expiredAuthentication(expiry))
        }

        return .success(String(userAndSignature[0]))
    }
}

// MARK: - HNWebClient

extension HTTPHNWebClient: HNWebClient {

    public var authenticatedUser: String? {
        switch verifyHNUserCookie() {
        case .success(let user): return user
        case .failure(_): return nil
        }
    }

    public func login(
        withAccount account: String,
        andPassword password: String,
        completion: @escaping HNWebResultCallback<String>
    ) {
        if let user = authenticatedUser {
            completion(.success(user))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.performLoginRequest(account: account, password: password) { result in
                DispatchQueue.main.async { completion(result) }
            }
        }
    }

    public func logout(completion: @escaping HNWebResultCallback<Void>) {
        guard let cookie = userCookie else { return }

        // TODO: Invalidate the user cookie server-side
        HTTPCookieStorage.shared.deleteCookie(cookie)

        DispatchQueue.main.async { completion(.success(())) }
    }

    public func upvote(item: Int, completion: @escaping HNWebResultCallback<Void>) {
        fatalError("Not implemented")
    }

    public func downvote(item: Int, completion: @escaping HNWebResultCallback<Void>) {
        fatalError("Not implemented")
    }
}
