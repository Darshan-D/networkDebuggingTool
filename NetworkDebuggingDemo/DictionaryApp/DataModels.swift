//
//  DataModels.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 06/06/25.
//

import Foundation

struct WordDefinitionResponse: Decodable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]
    let meanings: [Meaning]
    let license: License?
    let sourceUrls: [String]?
}

// MARK: - Phonetic

struct Phonetic: Decodable {
    let text: String?
    let audio: String?
    let sourceUrl: String?
    let license: License?
}

// MARK: - Meaning

struct Meaning: Decodable {
    let partOfSpeech: String
    let definitions: [Definition]
    let synonyms: [String]
    let antonyms: [String]
}

// MARK: - Definition

struct Definition: Decodable {
    let definition: String
    let synonyms: [String]
    let antonyms: [String]
    let example: String?
}

// MARK: - License

struct License: Decodable {
    let name: String
    let url: String
}
