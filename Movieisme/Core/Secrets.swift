//
//  Secrets.swift
//  MoviesApp
//
//  Loads API secrets from Secrets.plist (NOT committed to git).
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
            fatalError("⚠️ Secrets.plist is missing. Add it to the app target (see Secrets.example.plist).")
        }
        return plist
    }()

    /// Airtable Personal Access Token (بدون كلمة Bearer)
    static var airtableToken: String {
        dict["AIRTABLE_TOKEN"] as? String ?? ""
    }

    /// Airtable Base ID (يبدأ بـ app...)
    static var airtableBaseID: String {
        dict["AIRTABLE_BASE_ID"] as? String ?? ""
    }
}
