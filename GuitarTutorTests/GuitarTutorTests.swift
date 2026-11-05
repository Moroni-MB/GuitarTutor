//
//  GuitarTutorTests.swift
//  GuitarTutorTests
//
//  Created by Moroni Montoya Bernal on 9/22/26.
//

import Testing
@testable import GuitarTutor

struct GuitarTutorTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // Swift Testing Documentation
        // https://developer.apple.com/documentation/testing
    }
    
    @Test func findClosestGuitarNote() {
        let note = GuitarNote.getNote(frequency: 111.0)
        
        #expect (note == "A2")
    }
    
    @Test func findClosestGuitarNote() {
        let note = GuitarNote.getNote(frequency: 82.0)
        
        #expect (note == "E2")
    }
    
    @Test func findClosestGuitarNote() {
        let note = GuitarNote.getNote(frequency: 195.0)
        
        #expect (note == "G3")
    }

}
