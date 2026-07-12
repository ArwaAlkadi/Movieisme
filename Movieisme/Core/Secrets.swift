//
//  Secrets.swift
//  MoviesApp
//
//  Loads API secrets from Secrets.plist (not committed to git).
//

import Foundation

enum Secrets {

    private static let dict: [String: Any] = {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization
                .propertyList(from: data, format: nil) as? [String: Any]
        else {
            fatalError("Secrets.plist is missing. Add it to the app target.")
        }
        return plist
    }()

    /// Airtable Personal Access Token (without the "Bearer" prefix).
    static var airtableToken: String {
        dict["AIRTABLE_TOKEN"] as? String ?? ""
    }

    /// Airtable Base ID (starts with "app").
    static var airtableBaseID: String {
        dict["AIRTABLE_BASE_ID"] as? String ?? ""
    }
}
